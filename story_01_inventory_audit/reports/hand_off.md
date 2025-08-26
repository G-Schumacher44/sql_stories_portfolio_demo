# Inventory Audit Analysis - Handoff Document

## 📌 Overview

This document details the analysis conducted for Scenario 01, focusing on discrepancies between reported inventory and shippable stock. Key issues addressed include overselling, underutilization of inventory, and problematic returns that impact stock accuracy and fulfillment reliability. By consolidating data from multiple sources, we examined mismatches between recorded stock and actual sales, identified oversold SKUs, flagged slow-moving inventory with excess stock, and surfaced return patterns indicative of mis-picks or systemic errors. This comprehensive approach enables targeted interventions to improve inventory accuracy and operational efficiency.


## 📦 Key Deliverables

This project produced two primary deliverables for the Fulfillment team:

1. **Executive Summary (Markdown + Visuals)**  
   - Concise report highlighting locked capital exposure, underutilized inventory, and high non‑restockable return losses.  
   - Includes attention flag breakdowns, category‑level summaries, and recommendations for reducing waste.  
   - Designed for quick stakeholder review and decision‑making.  

2. **Interactive Workbook (Excel/Google Sheets)**  
   - Drill-down tool with pivot tables and filters at the SKU level.  
   - Tracks utilization ratios, return rates, and locked capital by product, category, or attention tier.  
   - Provides visual flags (✅🔵🟡🔴) for at-a-glance risk recognition.  
   - Includes scaffolding for semi-automated data refresh via Apps Script.  
   - **Live version available here:** [Inventory Audit Workbook – Google Sheets](https://docs.google.com/spreadsheets/d/1PuANFstg9yOWV84X1mOoblQp4ProvaSo4iYJ1ONZM7k/edit?gid=2045234789#gid=2045234789)  

Together, these deliverables enable both **strategic overview** (executive summary) and **operational action** (SKU‑level workbook).

## 🎯 Objectives

- Quantify the amount of locked capital tied up in slow-moving or stagnant inventory.  
- Identify SKUs with high return rates that cannot be restocked, creating non-recoverable losses.  
- Flag under-utilized inventory where utilization ratios fall below efficiency thresholds.  
- Provide actionable insights to reduce financial waste and improve inventory management processes.   

## 🗄️ Data Sources

- **Scenario 01 (ecom_retailer.db, SQLite)** – synthetic e‑commerce database used for this analysis.  
- **`product_catalog`** – SKU master data including product details and inventory quantities.  
- **`order_items`** – Records of individual items sold per order.  
- **`return_items`** – Details of returned items linked to orders.  
- **`orders` and `returns`** – Transactional tables capturing order and return events.  
- **`inventory_audit` (VIEW)** – Consolidated per-SKU audit view integrating sales, returns, inventory, and computed metrics such as utilization ratios, oversold flags, and locked capital estimations.

> Note: The dataset is synthetic and purpose-built to simulate common e-commerce inventory scenarios including overselling, slow movers, returns, and utilization challenges. Find the generator script(v0.2.5) [here](https://github.com/G-Schumacher44/ecom_sales_data_generator)

## 🔧 Technical Summary

- **Data Consolidation:** Built the `inventory_audit` view in SQLite combining `product_catalog`, `order_items`, `return_items`, and transaction tables.  
- **Computed Metrics:**  
  - `inventory_utilization = (total_sold - total_returned) / inventory_quantity`  (net of returns)  
  - `return_rate = total_returned / total_sold`  
  - `locked_capital = (inventory_quantity - total_sold) * unit_price`  
  - `inv_attention_tier` flag derived from thresholds across utilization, return rate, and overselling signals.  
- **Assumptions:**   
  - Thresholds (30% utilization, 20% return rate) chosen to reflect realistic operational pain points.  
  - Locked capital measured as “potentially stranded value,” not absolute write-off.  
 
 ## 💡 Why These Tools?

- **SQLite:** Chosen for simplicity and portability; lightweight, no server setup required, perfect for synthetic data exploration.  
- **Python (Jupyter + Pandas/Matplotlib):** Used for deeper analysis and visualizations beyond what pivot tables can show; enables reproducible, code-driven EDA.  
- **Google Sheets Workbook:** Provides an accessible, non-technical interface for the fulfillment team. Stakeholders can filter, pivot, and explore without writing SQL.  
- **Hybrid Workflow:** SQL handled heavy data prep; Python added flexibility for diagnostics; Sheets gave the business team a hands-on operational view.  

This layered approach ensured the right tool was used for each stage of the project, balancing rigor with usability.


## 📊 KPI & Threshold Reference

This section defines the primary Key Performance Indicators (KPIs) used to monitor inventory health and their threshold criteria:

- **Inventory Utilization Ratio:** Percentage of inventory sold relative to stock on hand. Items with utilization below 30% are flagged as underutilized slow movers.  
- **Return Rate:** Percentage of units returned relative to units sold. Return rates exceeding 20% indicate potential quality or operational issues.  
- **Non-Restockable Loss:** Percentage of returned units that cannot be restocked, multiplied by their dollar value. High values indicate unrecoverable capital tied up in quality or return issues.  
- **Oversold Flag:** Identifies SKUs where recorded sales exceed available inventory, signaling overselling risk.  
- **Locked Capital:** Represents the monetary value tied up in slow-moving inventory, highlighting financial exposure from excess stock.

Thresholds are set to prioritize actionable alerts that reflect meaningful operational risks and financial impacts.

## 🚨 Attention Flag System

The inventory attention score consolidates key signals including utilization ratio, oversold risk, return rate, and locked capital exposure into a single metric to prioritize focus areas. Explicit KPI cutoffs guide tier assignments:

#### 📌 How the Attention Score Works

To prioritize which SKUs demand action, we designed a weighted scoring system that blends three diagnostic signals:

- Low Utilization → Flags items with excess stock sitting idle (utilization below 30%).
- High Return Rate → Highlights products with frequent customer returns (≥ 30%).
- Volume Sensitivity → Applies extra weight to lower-volume SKUs so that issues with smaller denominators aren’t overlooked.

These signals are combined into a *composite score between 0 and 1*. Products with higher scores indicate stronger red flags and are automatically grouped into four tiers **(Healthy → High Risk)**. This makes it easy for business users to focus on the most critical inventory problems first, while still keeping visibility on emerging risks across the full catalog.

### 🚩 Flag Tiers 

- **Tier 0 – Healthy (✅):** Score < 0.20; utilization ≥ 30%, return rate ≤ 20%, no overselling, minimal locked capital.  
- **Tier 1 – Low Attention (🔵):** Score between 0.20 and 0.50; minor deviations such as utilization slightly below threshold or moderate return rates.  
- **Tier 2 – Moderate Attention (🟡):** Score between 0.50 and 0.80; moderate discrepancies including overselling risk or elevated returns requiring review.  
- **Tier 3 – High Attention (🔴):** Score ≥ 0.80; critical issues with significant overselling, very low utilization, high returns, or substantial locked capital demanding immediate action.

>This tiered system enables efficient triage of inventory issues for proactive management.

### Additional Flags
-  **Return Rate Flags:** ≤ 0.12 = ✅, 0.12–0.20 = ⚠️, > 0.20 = 🚨
-  **Utilization Ratio Flags:** ≤ 0.30 = ✅, > 0.30 = 🚨

## 🔜 Next Steps

- Review identified discrepancies and investigate overselling, slow movers, and systemic return issues.  
- Update inventory management procedures to address common root causes.  
- Schedule regular audits and integrate automated discrepancy alerts.

### 🤖 Automation Layer (Future Potential)

Looking ahead, this workflow could be automated by scripting the SQL queries to run on a scheduled basis, with outputs pushed directly to Google Sheets for real-time access. Summary reports and alerts could be automatically emailed to stakeholders to ensure timely awareness of inventory issues. Currently, the workbook includes a scaffolded Google Apps Script for manual data refreshes, and future development could extend this to full automation, reducing manual effort and improving responsiveness.

### 🔄 Peer Review & Iteration

We encourage the team to provide feedback on the KPI thresholds, flagging logic, and dashboard usability to ensure these tools meet operational needs effectively. Future iterations will incorporate this feedback, refine threshold settings, enhance automation, and improve user experience. This collaborative approach will support continuous improvement and ensure the inventory accuracy monitoring remains aligned with business priorities.

## 📬 Contact


For questions or further assistance, please reach out to the analytics team at me@garrettschumacher.com.

## 📂 Included Documents

The following key files are included as part of the handoff package:

- `inv_audit_exec_summary.md` – Executive summary of findings providing a high-level overview of audit results and key insights for stakeholders.
- `dashboard.png` – Visual snapshot of the dashboard illustrating inventory accuracy metrics and attention flags for quick status assessment.
- `inventory_audit_workbook.xlsx` – Static version of the analysis workbook.  
- [Google Sheets Workbook (Live Interactive Version)](https://docs.google.com/spreadsheets/d/1PuANFstg9yOWV84X1mOoblQp4ProvaSo4iYJ1ONZM7k/edit?gid=2045234789#gid=2045234789) – Shared live tool for ongoing exploration and drilldowns.
- `build_inventory_audit_view.sql` – Core SQL script defining the audit view that consolidates and prepares inventory data for analysis.
- `eda_inv_audit.sql` – Exploratory data analysis queries used to investigate patterns and anomalies in the inventory data.
- `eda_inv_audit_viz.sql` – EDA visualization queries that support graphical representations of inventory trends and discrepancies.
- `exec_report_viz.ipynb` – Jupyter notebook with executive report visuals designed to communicate findings through interactive charts and narratives.

---

<div align="center">
  <a href="../../README.md">
    ⬆️ <b>Back to Top</b>
  </a>
</div>

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
