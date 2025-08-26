# 📦 Scenario 01: Inventory Audit for Fulfillment Team

## 🧭 Background

The Fulfillment Team faces challenges related to overstocking and capital inefficiency across the national warehouse network. This scenario simulates issues such as excess inventory tying up working capital, as well as the impact of returns quality and non‑restockable items on fulfillment operations and recovery value.

## 🧑‍💼 Stakeholder

**Name:** Fulfillment Team Lead  
**Objective:** Improve inventory efficiency and reduce capital lock‑ups tied to slow‑moving or low‑quality stock.

---

## 🎯 Business Objective

Develop a SQL‑powered diagnostic to:

- Quantify **inventory utilization** and surface **over‑allocated SKUs** and categories.
- Estimate **capital tied up** in excess units; provide 10/20/30% reduction scenarios.
- Analyze **return quality** (restockable vs non‑restockable) and its impact on write‑offs.
- Flag **Tiered attention levels** (Healthy → High Attention) to prioritize actions for Fulfillment & Merchandising.
- Track **category exposure** to show where working capital inefficiency is concentrated.

---

## 🧩 Available Data

- `product_catalog`: product_id, name, category, unit_price, inventory_quantity  
- `order_items`: units sold per product  
- `return_items`: units returned per product  
- `orders`, `returns`: metadata (time, reason codes) for deeper cuts

---

## 🛠️ Key Metrics

- **Inventory Utilization** = (Total Sold − Total Returned) ÷ Inventory  
- **Locked Capital (Excess Units)** = MAX(Inventory − Net Sold, 0) × Unit Price  
- **Return Rate** = Total Returned ÷ Total Sold  
- **Non‑Restockable Loss %** = Non‑restockable Qty ÷ Total Returned  
- **Attention Tier Mix** by Category (Tier 0 → Tier 3)

🛠 **Note on Data Source:**  
This scenario uses `ecom_retailer.db`, a simulated ecommerce dataset. It is designed to model typical patterns (overstocking, returns quality, capital tie‑ups) to build SQL diagnostics and KPI storytelling.

>✍️ Analytical Framing:  
This scenario challenges analysts to apply SQL diagnostics to real operational questions. It requires quantifying inventory utilization, measuring capital lock‑ups, and analyzing returns quality. The exercise integrates fulfillment and return logic, constructs tiered attention signals, and develops actionable KPIs with visualization hooks — making it both a practical operations audit and a strong assignment for building SQL and analytical storytelling skills.

---

<div align="center">
  <a href="../README.md">
    ⬆️ <b>Back to Top</b>
  </a>
</div>

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