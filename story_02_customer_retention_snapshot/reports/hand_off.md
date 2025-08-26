

# 📑 Handoff Guide – Story 02: Customer Retention Snapshot

## 🔧 Setup
- Database: `ecom_retailer.db`
- SQL build script: `sql_sessions/build_02_retention_views.sql`
- Notebook: `Executive_Retention_Report.ipynb`
- Executive Summary: `executive_retention_summary.md`

## 🗂 About the Data  
This analysis is powered by a synthetic e-commerce dataset generated using my custom data generator(v0.2.5, pre-release):  
➡️ [ecom_sales_data_generator](https://github.com/G-Schumacher44/ecom_sales_data_generator)  

The generator simulates realistic customer, order, return, and loyalty program behaviors, allowing for:  
- Cohort and retention analysis across time.  
- Loyalty tier and CLV segmentation.  
- Channel performance benchmarking.  
- Reproducible datasets for training and portfolio storytelling.  

## ⚙️ Tech Stack
- **SQLite** – backend database for orders, customers, returns, and loyalty views
- **SQL (SQLite dialect)** – cohort view definitions and metrics calculations
- **Python (Pandas, Matplotlib, Seaborn)** – data querying, transformations, visualization
- **Jupyter Notebook** – analysis environment for reproducibility
- **Markdown** – structured reporting (`executive_retention_summary.md`, this handoff)

## 🔄 Workflow

1. **Build Views:** Run `build_02_retention_views.sql` to create cohort, loyalty, and CLV tables.
2. **Analyze:** Open `Executive_Retention_Report.ipynb` to run queries and visualize retention KPIs.
3. **Summarize:** Insights distilled into `executive_retention_summary.md`.
4. **Deliver:** This handoff guide ties deliverables together for stakeholders or future analysts.

## 📦 Deliverables
- SQL sessions (cohort, loyalty, CLV views)
- Retention analysis notebook (queries + visuals)
- Executive summary (one-page insights + actions)
- This handoff guide

## 📊 Key Insights Recap
- Early retention decay: sharp drop between Month 1→3.
- Seasonal spikes: Nov/Dec cohorts outperform (50%+).
- Loyalty program gaps: Bronze 0%, Platinum 45–50%.
- Channel mix: Phone/Email strong, Social Media weak.

## ➡️ Next Steps
- Refine Bronze/Silver loyalty tiers.
- Codify holiday campaign playbook.
- Add demographic/age cohort analysis.
- Explore cart abandonment + CLV segmentation.

---

<p align="center">
  <a href="../../README.md">🏠 <b>Main README</b></a>
  &nbsp;·&nbsp;
  <a href="../../USAGE.md">📖 <b>Usage Guide</b></a>
  &nbsp;·&nbsp;
  <a href="../../story_01_inventory_audit/story_01_portfolio_readme.md">📦 <b>Case Study: Inventory Audit</b></a>
  &nbsp;·&nbsp;
  <a href="../../story_02_customer_retention_snapshot/story_02_portfolio_readme.md">💡 <b>Case Study: Customer Retention</b></a>
</p>

<p align="center">
  <sub>✨ SQL · Python · Storytelling ✨</sub>
</p>