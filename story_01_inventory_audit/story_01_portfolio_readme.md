
<p align="center">
  <img src="../repo_files/dark_logo_banner.png" width="1000"/>
  <br>
  <em>Inventory Audit Case Study</em>
</p>

<p align="center">
  <img alt="MIT License" src="https://img.shields.io/badge/license-MIT-blue">
  <img alt="Status" src="https://img.shields.io/badge/status-active-brightgreen">
  <img alt="Version" src="https://img.shields.io/badge/version-v0.2.0-blueviolet">
</p>

# 📘 SQL Stories — Story 01: Inventory Audit

## 🔎 Overview  
This story investigates **inventory efficiency challenges** for a simulated e-commerce retailer.  
Key risks addressed:  
- **Locked Capital (Excess Units)** → Inventory tying up working capital.  
- **Problematic Returns** → Non-restockable, driving unrecoverable losses.  
- **Under-Utilization** → Stock not moving, raising carrying costs.  

### ▶️ Where to Start
- **Scenario Brief** → [`scenario_01_inventory_audit.md`](scenario_01_inventory_audit.md) – Overview of the simulated business scenario.
- **Executive Summary (Quick Read)** → [`reports/inv_audit_exec_summary.md`](reports/inv_audit_exec_summary.md) – High-level insights, risks, and recommendations.  
- **Interactive Workbook (Deeper Dive)** → [`Live Google Sheets Workbook`](https://docs.google.com/spreadsheets/d/1PuANFstg9yOWV84X1mOoblQp4ProvaSo4iYJ1ONZM7k/edit?usp=sharing) – Drilldown exploration by SKU/category with pivots and filters.  
- **SQL Sessions (Technical Build)** → [`sql_sessions/`](sql_sessions/) – SQL queries for building the audit view and exploratory analysis.  
- **Analysis Notebook (Full Analysis & Visuals)** → [exec_report_viz.ipynb](https://nbviewer.org/github/G-Schumacher44/sql_stories_portfolio_demo/blob/main/story_01_inventory_audit/exec_report_viz.ipynb) – Visual storytelling and diagnostic deep-dive.
 
 > 📝 **Note for Portfolio Reviewers**  
> This case study is designed to demonstrate how I approach **end-to-end analytics problems** — from raw SQL queries to executive-ready insights.  
> 
> What you’ll see here:  
> - **Business Framing** → translating a messy, real-world inventory problem into clear objectives.  
> - **Technical Execution** → SQL views, exploratory analysis, and Python visualizations to surface risks and KPIs.  
> - **Stakeholder Communication** → executive summary, handoff document, and interactive workbook tailored for business users.  
> - **Portfolio Fit** → a balance of analytical rigor (cleaning, metrics, scoring system) and business impact (financial exposure, recommendations).  
> 
> This project shows both my **technical proficiency** and my **ability to communicate data-driven insights in a business-friendly way**.
---

## 🗂 About the Data  
This analysis is powered by a synthetic e-commerce dataset generated using my custom data generator(v0.2.5, pre-release):  
➡️ [ecom_sales_data_generator](https://github.com/G-Schumacher44/ecom_sales_data_generator)  

The generator simulates realistic customer, order, return, and loyalty program behaviors, allowing for:  
- Cohort and retention analysis across time.  
- Loyalty tier and CLV segmentation.  
- Channel performance benchmarking.  
- Reproducible datasets for training and portfolio storytelling. 

___

## 📐 Engineered Analytical Frameworks  

### 🚩Attention Flag System  
Broken down into 4 Tiers by a score composed of Return Rate %, Utilization Ratio, and Nonrestockable Returns volume.
  
    - Tier 0 (✅ Healthy) → Score < 0.20  
    - Tier 1 (🔵 Low) → 0.20 – 0.50  
    - Tier 2 (🟡 Moderate) → 0.50 – 0.80  
    - Tier 3 (🔴 High) → ≥ 0.80  

#### 📌 How the Attention Score Works

To prioritize which SKUs demand action, we designed a weighted scoring system that blends three diagnostic signals:

- Low Utilization → Flags items with excess stock sitting idle (utilization below 30%).
- High Return Rate → Highlights products with frequent customer returns (≥ 30%).
- Volume Sensitivity → Applies extra weight to lower-volume SKUs so that issues with smaller denominators aren’t overlooked.

These signals are combined into a *composite score between 0 and 1*. Products with higher scores indicate stronger red flags and are automatically grouped into four tiers **(Healthy → High Risk)**. This makes it easy for business users to focus on the most critical inventory problems first, while still keeping visibility on emerging risks across the full catalog.

#### ⛳️ Additional Flags

-  **Return Rate Flags:** ≤ 0.12 = ✅, 0.12–0.20 = ⚠️, > 0.20 = 🚨
-  **Utilization Ratio Flags:** ≤ 0.30 = ✅, > 0.30 = 🚨
  
___

## 📦 Key Deliverables  
- **Executive Summary** → [`reports/inv_audit_exec_summary.md`](reports/inv_audit_exec_summary.md)  
- **Interactive Workbook** → [`Live Google Sheets Workbook`](https://docs.google.com/spreadsheets/d/1PuANFstg9yOWV84X1mOoblQp4ProvaSo4iYJ1ONZM7k/edit?usp=sharing)
- **Analysis Notebook** → [exec_report_viz.ipynb](https://nbviewer.org/github/G-Schumacher44/sql_stories_portfolio_demo/blob/main/story_01_inventory_audit/exec_report_viz.ipynb) 
   


---

## 🖼 Visual Artifacts (`files/`)  
- Dashboard Snapshot → [Dashboard](files/dashboard.png)  
- Utilization Donut → [Utilization](files/cap_lock_donut.png)    
- Tier Breakdown → [Tier Breakdown](files/dist_attn_flags.png)  
- Utilization Histogram → [Histogram](files/util_hist.png)  

---

## 🛠 Technical Components 
- **Detailed Handoff** → [`reports/hand_off.md`](reports/hand_off.md)   
- **Audit View Build** → [`build_inventory_audit_view.sql`](sql_sessions/build_inventory_audit_view.sql)  
- **Cleanup Scripts** → [`cleanup_inv_audit_view.sql`](sql_sessions/cleanup_inv_audit_view.sql)  
- **Exploratory Queries** → [`eda_inv_audit.sql`](sql_sessions/eda_inv_audit.sql)  
- **Visualization Queries** → [`eda_inv_audit_viz.sql`](sql_sessions/eda_inv_audit_viz.sql)  

  
---

## 🥾 Next Steps  
- Automate SQL → Sheets refresh (Apps Script scaffolded).  
- Integrate scheduled summary emails.  
- Iteratively refine KPI thresholds with feedback.  

---

<p align="center">
  <a href="../README.md">🏠 <b>Main README</b></a>
  &nbsp;·&nbsp;
  <a href="../USAGE.md">📖 <b>Usage Guide</b></a>
  &nbsp;·&nbsp;
  <a href="./story_01_portfolio_readme.md">📦 <b>Case Study: Inventory Audit</b></a>
  &nbsp;·&nbsp;
  <a href="../story_02_customer_retention_snapshot/story_02_portfolio_readme.md">💡 <b>Case Study: Customer Retention</b></a>
</p>

<p align="center">
  <sub>✨ SQL · Python · Storytelling ✨</sub>
</p>