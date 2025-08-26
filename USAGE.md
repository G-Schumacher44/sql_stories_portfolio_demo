<p align="center">
  <img src="repo_files/dark_logo_banner.png" width="1000"/>
  <br>
  <em>Automated Data Pipeline: Usage Guide</em>
</p>

<p align="center">
  <img alt="Guide" src="https://img.shields.io/badge/guide-pipeline_usage-blue">
  <img alt="Status" src="https://img.shields.io/badge/status-active-brightgreen">
  <img alt="Version" src="https://img.shields.io/badge/version-v1.0.0-blueviolet">
</p>

## 🧩 Purpose

The `run_story.sh` script is the main entry point for the data pipeline. It orchestrates a three-step process for any given "story" by using a file naming convention:

1.  **Build**: Automatically finds and executes any `build_*.sql` scripts within a story's `sql_sessions` directory.
2.  **Upload**: Runs the centralized `scripts/g_drive_uploader.py` Python script, which reads data from the newly created views and uploads it to a designated Google Sheet.
3.  **Cleanup**: Automatically finds and executes any `cleanup_*.sql` scripts to `DROP` the temporary views from the database.

___

## 🚀 How to Run the Pipeline

Execute the script from the root of the repository, passing the desired `story_name` as an argument.

**Syntax:**
```bash
./run_story.sh <story_name>
```
<details>
<summary><strong>Examples:</strong></summary>

<br>

*   **To run the pipeline for `story_01_inventory_audit`:**
    ```bash
    ./run_story.sh story_01_inventory_audit
    ```
    This will:
    1.  Create the `inventory_audit` view.
    2.  Upload its contents to the Google Sheet specified by `GDRIVE_SHEET_ID_story_01`.
    3.  Drop the `inventory_audit` view.

*   **To run the pipeline for `story_02_customer_retention_snapshot`:**
    ```bash
    ./run_story.sh story_02_customer_retention_snapshot
    ```
    This will:
    1.  Run all SQL scripts to create views prefixed with `dash_retention_`.
    2.  Find all of those `dash_retention_` views, and upload each one to a separate tab in the Google Sheet specified by `GDRIVE_SHEET_ID_story_02`.
    3.  Drop all `dash_retention_` views.

___

</details>

## 📊 Best Practices for Google Sheets Setup

To ensure your pipeline is robust and your dashboards don't break, it is critical to separate your raw data from your presentation layer (charts, slicers, etc.).

The uploader script is designed to aggressively overwrite data, even deleting and recreating sheets. If your visuals point directly to a sheet managed by the script, they will break.

### The Two-Sheet Architecture

1.  **Data Sheet (e.g., `inventory_audit_data`)**:
    *   This is the sheet the Python script writes to. Its name should match the `sheet_name` in your `stories_config.yaml`.
    *   **Do not build anything on this sheet.** Treat it as a temporary, machine-managed data source.

2.  **Dashboard Sheet (e.g., `Dashboard`)**:
    *   This is where you build all your charts, slicers, and pivot tables.
    *   In cell `A1` of this sheet, pull data from the data sheet using a formula. The simplest is `='inventory_audit_data'!A:Z`. A more robust option is `=QUERY(inventory_audit_data!A:Z, "SELECT * WHERE A IS NOT NULL")`.
    *   Point all your charts and slicers to the data range **on this `Dashboard` sheet**.

This setup decouples your presentation from the data ingestion, allowing the pipeline to run reliably without breaking your workbook.

> **Note for Existing Workbooks:** If you are migrating a dashboard from an old sheet, the process is simple: copy your charts and slicers into the new `Dashboard` sheet, then update their data ranges to point to the new local data. This one-time setup ensures long-term stability.

## 📚 Adding a New Story


**Step By Step Guide:**


To integrate a new story (e.g., `story_02_new_feature`) into this automated workflow, follow these steps:

1.  **Create Story Directory and SQL Scripts**:
    *   Create a new directory for your story (e.g., `story_02_new_feature`).
    *   Inside, create a `sql_sessions` subdirectory.
    *   Add your SQL scripts, following the naming convention:
        *   `build_*.sql` for creating views.
        *   `cleanup_*.sql` for dropping views.

2.  **Configure the Story Export**:
    *   Open `stories_config.yaml` in the root of the repository.
    *   Add a new entry for your story.
        *   **For a single view**:
            ```yaml
            story_02_new_feature:
              sheet_id_var: 'GDRIVE_SHEET_ID_story_02'
              exports:
                - db_view: 'your_view_name'
                  sheet_name: 'Your Desired Tab Name'
            ```
        *   **For multiple views based on a prefix**:
            ```yaml
            story_02_new_feature:
              sheet_id_var: 'GDRIVE_SHEET_ID_story_02'
              view_prefix: 'your_prefix_' # Will upload all views like your_prefix_kpi, etc.
            ```

3.  **Add Sheet ID to Secrets**:
    *   Add the new `GDRIVE_SHEET_ID_story_02` variable to your `secrets.yaml` file with the corresponding Google Sheet ID.

___

You can now run `./run_story.sh story_02_new_feature` to execute the full pipeline for your new story.
</details>

---

<div align="center">
  <a href="#-sql-case-studies--portfolio">
    ⬆️ <b>Back to Top</b>
  </a>
</div>

<p align="center">
  <a href="README.md">🏠 <b>Main README</b></a>
  &nbsp;·&nbsp;
  <a href="USAGE.md">📖 <b>Usage Guide</b></a>
  &nbsp;·&nbsp;
  <a href="story_01_inventory_audit/story_01_portfolio_readme.md">📦 <b>Case Study: Inventory Audit</b></a>
  &nbsp;·&nbsp;
  <a href="story_02_customer_retention_snapshot/story_02_portfolio_readme.md">💡 <b>Case Study: Customer Retention</b></a>
</p>

<p align="center">
  <sub>✨ SQL · Python · Storytelling ✨</sub>
</p>