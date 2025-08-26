# 📦 Scenario 03: Product Profitability Review for Finance Team


## 🧭 Background

Following a strong growth year, the **Finance Team** is assessing which products are driving real profitability versus those contributing to high operational costs or refund exposure. While top-line sales have climbed, the actual value captured per product varies widely due to category margins, **discounting**, **shipping economics**, and **returns**.

To support upcoming SKU rationalization and pricing decisions, Finance requests a profitability review focused on **true contribution margin** — after discounts, COGS, returns, and shipping variance (what the customer pays for shipping vs. what it actually costs).

This analysis will serve as a foundation for pricing strategy and category-level investment in the upcoming fiscal year.

## 🧑‍💼 Stakeholder

**Name:** Director of Finance  
**Objective:** Pinpoint products where low margins, excessive discounts, or high return rates erode overall profitability.

---

## 🎯 Business Objective

Create a SQL-powered profitability report that:

- Calculates **gross revenue, allocated discounts, net sales, COGS, shipping variance, and contribution margin** per SKU
- Identifies **high-revenue / low-margin SKUs** and **negative-contribution SKUs**
- Highlights **top and bottom performing categories by contribution margin**
- Quantifies **return-driven losses** and **links return reasons** to unprofitable SKUs
- Surfaces **shipping economics** (customer-paid vs. actual shipping cost) that erode margin

---

## 🧩 Available Data (ecom_retailer_v3.db)

- **`order_items`**: `order_id`, `product_id`, `quantity`, `unit_price` (and other line-level attributes)
- **`return_items`**: `order_id`, `product_id`, `quantity_returned`, `refunded_amount`
- **`returns`**: `order_id`, `return_reason` (classify avoidable vs. unavoidable)
- **`product_catalog`**: `product_id`, `product_name`, `category`, `unit_price`, **`cost_price`** (COGS baseline), `inventory_quantity`
- **`orders`**: `order_id`, `gross_total`, `net_total`, **`total_discount_amount`**, `shipping_cost` (customer paid), **`actual_shipping_cost`** (true expense), `order_channel`, `customer_tier`, `order_date`, `payment_processing_fee` (may be text)


---

🛠 Note on Data Source:  
This scenario uses `ecom_retailer_v3.db`, simulating product-level sales and return behavior. Product profitability is approximated via unit_price and returned value; no direct COGS data is included.

>✍️ Analytical Framing:  
This scenario moves from proxy margins to **true contribution analysis**: discounting, COGS via `cost_price`, returns, and shipping variance are all incorporated. It teaches negative contribution detection, allocation transparency, and loss attribution (returns vs. shipping), mirroring how finance partners evaluate SKU- and category-level value creation.

<div align="center">
  <a href="../README.md#-sql-case-studies--portfolio">
    ⬆️ <b>Back to Top</b>
  </a>
</div>

<p align="center">
  <a href="../README.md">🏠 <b>Main README</b></a>
  &nbsp;·&nbsp;
  <a href="../USAGE.md">📖 <b>Usage Guide</b></a>
  &nbsp;·&nbsp;
  <a href="../story_01_inventory_audit/story_01_portfolio_readme.md">📦 <b>Case Study: Inventory Audit</b></a>
  &nbsp;·&nbsp;
  <a href="./story_02_portfolio_readme.md">💡 <b>Case Study: Customer Retention</b></a>
</p>

<p align="center">
  <sub>✨ SQL · Python · Storytelling ✨</sub>
</p>