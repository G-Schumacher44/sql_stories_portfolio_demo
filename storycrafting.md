# 🛠️ storycrafting.md

## 🎯 Purpose

This document explains how each SQL Story in this repo is created using a mix of synthetic data generation, structured business framing, and AI-assisted scenario design. The goal is to simulate realistic business questions and data challenges that strengthen SQL and analytical fluency.

---

## 🧬 Data Generation Strategy

All stories are powered by a dataset produced using the companion project:

➡️ [`ecom_sales_data_generator`](https://github.com/G-Schumacher44/ecom_sales_data_generator)

That repo provides:
- Modular Python scripts for data simulation
- Scenario-based YAML configurations
- Controlled injection of data messiness

🗂️ This repository includes `database.zip`, which contains the pre-built SQLite databases.
The output includes:
- Clean CSVs for each table (`orders`, `order_items`, `returns`, etc.)
- A zip archive with loading assets:  
  `ecom_data_gen_output/database.zip`

Inside that zip:
- `*.csv` files (one per table)
- `load_data.sql` to construct the schema and load into SQLite

---

### 🧪 Mess Injection (Realism Tuning)

The data generator supports configurable “mess” levels:
- `none`: perfectly clean, ideal for baselines or learners
- `medium`: includes nulls, case issues, date shifts, return spikes
- `heavy`: simulates real-world chaos — fuzzy joins, data mismatches, and edge-case outliers

This messiness emulates POS systems or early-stage data warehouses where governance is still maturing.

> The included database was configured with a `medium` mess injection.

---

## 🤖 AI's Role in Story Design

AI acts as a **co-author and validator**, helping shape business scenarios around each dataset. Contributions include:

- Business context and stakeholder goals
- Analytical framing and key metrics
- Prompt engineering for SQL challenges
- Narrative tone and documentation

AI helps keep every story grounded, engaging, and useful — from beginner tutorials to portfolio-grade projects.

---

## 📦 Story Format

Each story lives in its own folder (e.g., `story_01_inventory_accuracy/`) and follows a consistent structure:

- A `scenario_XX_name.md` brief describing the context and goals
- A `sql_sessions/` subdirectory that contains the SQL scripts for the automated pipeline:
  - `build_*.sql` scripts create the temporary views for analysis.
  - `cleanup_*.sql` scripts drop the views after the pipeline runs.
- Optional: Jupyter notebooks, QA notes, or other supporting artifacts like the `output_data` and `reports` folders.

---

## 🔄 Reusability

Every scenario is modular and remixable:
- Regenerate data with updated YAML for infinite variety
- Extend queries into notebooks or dashboards
- Fork scenarios into cleanup, reporting, or advanced SQL exercises

---

## 🌱 Why This Matters

Real analysts deal with:
- Unclear business questions
- Messy, mismatched data
- High expectations for clarity and insight

These stories replicate that — helping you build SQL muscle in realistic contexts with just the right level of friction.

> _Every scenario is a mini sandbox for growing analytical confidence and narrative clarity._

---

⬅️ [Return to Main Project README](README.md)

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