import os
import sqlite3
import pandas as pd
import yaml
import gspread
from google.oauth2 import service_account
from gspread_dataframe import set_with_dataframe
from gspread.exceptions import SpreadsheetNotFound, WorksheetNotFound
import sys
import argparse
import time

# --- Constants and Path Configuration ---
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))
STORIES_CONFIG_PATH = os.path.join(REPO_ROOT, "stories_config.yaml")
SECRETS_PATH = os.path.join(REPO_ROOT, "secrets.yaml")

# --- Custom Exceptions for Clearer Error Handling ---
class FileAccessError(Exception):
    """Custom exception for local file access or permission issues."""
    pass

class ConfigError(Exception):
    """Custom exception for configuration issues."""
    pass

# --- Utility Functions ---
def with_backoff(fn, retries=5, base=1.8):
    """Run callable with exponential backoff on transient errors (e.g., Sheets 5xx)."""
    for attempt in range(retries):
        try:
            return fn()
        except Exception as e:
            msg = str(e).lower()
            # Retry only on likely transient server-side failures
            if ("500" in msg or "internal" in msg or "backend" in msg) and attempt < retries - 1:
                sleep = base ** attempt
                print(f"[warn] Sheets transient error (attempt {attempt+1}/{retries}) — sleeping {sleep:.1f}s…")
                time.sleep(sleep)
                continue
            raise

# --- Configuration and Authentication ---
def load_yaml_config(file_path, file_description):
    """Loads a YAML file, raising a clear error if it's not found."""
    if not os.path.exists(file_path):
        raise FileAccessError(f"{file_description} not found at: {file_path}")
    with open(file_path, "r") as f:
        return yaml.safe_load(f)

def get_gspread_client(secrets):
    """Authenticate and return a gspread Client using service account credentials."""
    creds_path = secrets.get("google_drive", {}).get("service_account_path")
    if not creds_path:
        raise ConfigError("`service_account_path` not found in secrets.yaml under `google_drive`.")
    
    SERVICE_ACCOUNT_FILE = os.path.join(REPO_ROOT, creds_path)

    try:
        with open(SERVICE_ACCOUNT_FILE, "r") as f:
            creds_data = f.read()
        if not creds_data:
             raise ValueError("Service account file is empty.")
    except FileNotFoundError:
        raise FileAccessError(f"Service account file not found at: {SERVICE_ACCOUNT_FILE}")
    except PermissionError:
        raise FileAccessError(f"Read permission denied for service account file: {SERVICE_ACCOUNT_FILE}")
    
    creds = service_account.Credentials.from_service_account_file(
        SERVICE_ACCOUNT_FILE,
        scopes=["https://www.googleapis.com/auth/spreadsheets", "https://www.googleapis.com/auth/drive"]
    )
    return gspread.authorize(creds)

def check_db_permissions(db_path):
    """Verifies read/write permissions for the SQLite database and its directory."""
    db_dir = os.path.dirname(db_path)
    try:
        with open(db_path, "rb"): pass
        test_file = os.path.join(db_dir, ".permission_test")
        with open(test_file, "w"): pass
        os.remove(test_file)
    except FileNotFoundError:
        raise FileAccessError(f"Database file not found at: {db_path}")
    except (PermissionError, OSError) as e:
        raise FileAccessError(f"Permission denied for database or its directory: {db_dir}\n  Original error: {e!r}")

# --- Fetch Views from DB ---
def get_views_by_prefix(conn, prefix):
    """
    Retrieve all view names from the SQLite database that start with a given prefix.
    
    Args:
        conn (sqlite3.Connection): SQLite database connection object.
        prefix (str): The prefix to search for (e.g., 'dash_').
    
    Returns:
        list of dict: List of export definitions, e.g., [{'db_view': 'dash_view1', 'sheet_name': 'dash_view1'}].
    """
    query = "SELECT name FROM sqlite_master WHERE type='view' AND name LIKE ?"
    cursor = conn.cursor()
    cursor.execute(query, (f"{prefix}%",))
    results = cursor.fetchall()
    return [{'db_view': row[0], 'sheet_name': row[0]} for row in results]

# --- Export Logic ---
def get_sheet_id_from_secrets(story_config, secrets):
    """Loads the correct Google Sheet ID from secrets.yaml based on the story config."""
    sheet_id_var = story_config.get('sheet_id_var')
    if not sheet_id_var:
        raise ConfigError("Story configuration is missing 'sheet_id_var'.")

    sheet_id = secrets.get("variables", {}).get(sheet_id_var)

    if not sheet_id:
        raise ConfigError(f"Variable '{sheet_id_var}' not found in secrets.yaml under 'variables'.")
    
    return sheet_id

def export_story_to_sheet(story_name, stories_config):
    """
    Connects to SQLite, gets the configuration for the specified story,
    and exports the defined views to the corresponding Google Sheet.
    
    Args:
        story_name (str): The key for the story in STORIES_CONFIG.
        stories_config (dict): The loaded stories configuration.
        db_path (str): The full path to the database file.
    """
    if story_name not in stories_config:
        raise ConfigError(
            f"Story '{story_name}' not found in stories_config.yaml. "
            f"Available stories: {list(stories_config.keys())}"
        )
    
    story_config = stories_config[story_name]

    try:
        secrets = load_yaml_config(SECRETS_PATH, "Secrets file")
        sheet_id = get_sheet_id_from_secrets(story_config, secrets)
        with sqlite3.connect(db_path) as conn:
            exports_to_process = []
            if 'view_prefix' in story_config:
                prefix = story_config['view_prefix']
                print(f"🔍 Finding views with prefix '{prefix}' for story '{story_name}'...")
                exports_to_process = get_views_by_prefix(conn, prefix)
            elif 'exports' in story_config:
                print(f"📋 Using defined export list for story '{story_name}'...")
                exports_to_process = story_config['exports']
            
            if not exports_to_process:
                print(f"⚠️ No views found or defined for story '{story_name}'. Nothing to export.")
                return

            gspread_client = get_gspread_client(secrets)
            spreadsheet = with_backoff(lambda: gspread_client.open_by_key(sheet_id))

            print(f"🚀 Starting export to Google Sheet: '{spreadsheet.title}'")
            for export_item in exports_to_process:
                view_name = export_item['db_view']
                sheet_name = export_item['sheet_name']
                
                df = pd.read_sql_query(f"SELECT * FROM {view_name}", conn)

                # --- Data Sanitization Step ---
                # To eliminate any possibility of data types causing the 500 error,
                # we will convert all data to strings and fill NaNs. This makes the
                # payload as simple as possible for the Google Sheets API.
                df = df.fillna('').astype(str)

                # Modified "Nuke and Pave" strategy to handle the "can't delete last sheet" error.
                worksheet_to_use = None
                try:
                    existing_worksheet = with_backoff(lambda: spreadsheet.worksheet(sheet_name))
                    
                    # If the sheet exists, decide whether to clear it or delete it.
                    if len(spreadsheet.worksheets()) == 1:
                        print(f"   - Found sheet '{sheet_name}', but it's the only one. Clearing it to avoid errors.")
                        with_backoff(lambda: existing_worksheet.clear())
                        worksheet_to_use = existing_worksheet
                    else:
                        print(f"   - Found existing sheet '{sheet_name}'. Deleting it to ensure a clean slate.")
                        with_backoff(lambda: spreadsheet.del_worksheet(existing_worksheet))
                        # worksheet_to_use will be created in the next step.

                except WorksheetNotFound:
                    print(f"   - No existing sheet named '{sheet_name}' found. A new one will be created.")
                    pass # This is expected if the sheet doesn't exist yet.

                # If we deleted the sheet or it never existed, create it now.
                if worksheet_to_use is None:
                    print(f"   - Creating new worksheet '{sheet_name}'")
                    worksheet_to_use = with_backoff(lambda: spreadsheet.add_worksheet(title=sheet_name, rows=1, cols=1))
                
                print(f"   - Writing {df.shape[0]} rows × {df.shape[1]} cols to '{sheet_name}'")
                with_backoff(lambda: set_with_dataframe(worksheet_to_use, df, include_index=False, include_column_header=True, resize=True))
                print(f"✅ Exported '{view_name}' to sheet '{sheet_name}'")

            print(f"🎉 All views for story '{story_name}' exported successfully.")

    except (SpreadsheetNotFound, ConfigError, FileAccessError) as e:
        print(f"❌ Error processing story '{story_name}':")
        if isinstance(e, SpreadsheetNotFound):
            print(f"   Spreadsheet not found. Please check:")
            print(f"   1. The Google Sheet ID is correct in your secrets.yaml.")
            print(f"   2. The service account has 'Editor' permissions on the sheet.")
        else:
            print(f"   {e!r}")
        sys.exit(1)
    except PermissionError:
        print("❌ Google API Permission Denied. This is not a local file issue.")
        print("   The Google API has rejected the request. Please check the following:")
        print("   1. The 'Google Sheets API' and 'Google Drive API' are ENABLED in your Google Cloud project.")
        print(f"   2. The service account email has been shared with your Google Sheet with 'Editor' permissions.")
        sys.exit(1)
    except Exception as e:
        print(f"❌ An unexpected error occurred: {e!r}")
        sys.exit(1)

def main():
    """Main function to parse arguments and trigger the export."""
    stories_config = load_yaml_config(STORIES_CONFIG_PATH, "Stories config file")

    parser = argparse.ArgumentParser(description="Uploads specific story data to Google Drive.")
    parser.add_argument(
        "story_name",
        type=str,
        choices=stories_config.keys(),
        help="The name of the story to process."
    )
    parser.add_argument(
        "--db_name",
        type=str,
        default="ecom_retailer.db",
        help="The name of the database file to use (e.g., 'ecom_retailer_v3.db')."
    )
    args = parser.parse_args()

    db_path = os.path.join(REPO_ROOT, args.db_name)
    check_db_permissions(db_path)
    
    export_story_to_sheet(args.story_name, stories_config, db_path)

if __name__ == "__main__":
    main()
