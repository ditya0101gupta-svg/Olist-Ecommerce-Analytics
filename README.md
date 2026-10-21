# Olist E-Commerce Analytics | MySQL & Power BI

## Project Overview

An end-to-end data analytics project using the Brazilian Olist e-commerce dataset. This project combines MySQL-based data analysis with an interactive, five-page Power BI dashboard to explore marketplace sales, customer behavior, product performance, and delivery efficiency.

## Tools & Technologies

- **MySQL:** SQL queries and data analysis
- **Power BI:** Data modeling, DAX measures, and interactive visualizations
- **Power Query:** Data transformation and cleaning
- **GitHub:** Project documentation and version control

## Dashboard Pages

1. **Overview:** Marketplace KPIs, revenue trends, orders, customer metrics, and business insights.
2. **Sales:** Sales performance, revenue trends, and geographical analysis.
3. **Customers:** Customer distribution, purchasing patterns, and customer insights.
4. **Products:** Product categories, revenue contribution, best-selling products, and customer ratings.
5. **Delivery Performance:** Delivery times, order status, on-time delivery rates, and state-level performance.

## Dashboard Screenshots

### 1. Overview
![Overview Dashboard](01_Overview.png)

### 2. Sales Analysis
![Sales Dashboard](02_Sales.png)

### 3. Customer Analysis
![Customers Dashboard](03_Customers.png)

### 4. Product Performance
![Products Dashboard](04_Products.png)

### 5. Delivery Performance
![Delivery Performance Dashboard](05_Delivery_Performance.png)

## Key Business Insights

- Total marketplace sales are approximately **R$13.59 million**.
- Approximately **99,000 orders** were recorded.
- The overall **on-time delivery rate is 91.89%**.
- Average delivery time is approximately **12.5 days**.
- The average customer rating is approximately **4.09 out of 5**.
- **Alagoas** has the highest delayed delivery rate among the states shown, at approximately **23.93%**.

## Project Files

- `Olist_Analysis.sql` — SQL analysis script
- `PowerBI/Olist_Ecommerce_Analytics.pbix` — Interactive Power BI report
- `01_Overview.png` to `05_Delivery_Performance.png` — Dashboard screenshots

## Project Objective

To transform Brazilian e-commerce transactional data into actionable business insights, identify sales opportunities, understand customer and product performance, and highlight delivery inefficiencies using SQL and business intelligence tools.

## Dataset

Brazilian E-Commerce Public Dataset by Olist, available on Kaggle.

## Row-Level Security (RLS)

### Overview

Implemented state-based Row-Level Security (RLS) in Power BI Desktop to restrict access to customer and transaction data based on geographical location.

### Security Configuration

| Property | Configuration |
|---|---|
| Security Role | `SP_State_Access` |
| Table | `Customers` |
| Column | `customer_state` |
| Filter Condition | Equals `SP` |
| Security Type | Static Row-Level Security |
| Testing Method | Power BI Desktop — View as Role |

### DAX Security Filter

```dax
[customer_state] = "SP"
```

This security rule restricts the role to customers located in São Paulo (SP), Brazil.

### RLS Testing & Validation

The security role was tested using Power BI Desktop's **View as** functionality.

| KPI | Full Dataset | São Paulo RLS |
|---|---:|---:|
| Total Sales | R$13.59M | R$5.20M |
| Total Orders | 99K | 42K |
| Total Customers | 96K | 40K |
| Average Customer Rating | 4.09 | 4.17 |
| On-Time Delivery Rate | 91.89% | 94.11% |

### Validation Results

- Successfully activated the `SP_State_Access` security role.
- Verified that dashboard KPIs changed after applying RLS.
- Confirmed that the revenue-by-state visual displayed only São Paulo.
- Verified that customer-based restrictions propagated through related transaction tables.

### RLS Testing Screenshot

![São Paulo Row-Level Security Test](RLS_SP_State.png)

**Note:** RLS was configured and tested locally in Power BI Desktop. Deployment and user-role assignments in Power BI Service have not yet been completed.

## Data Model & Relationships

The Olist E-Commerce Analytics Power BI report uses a relational data model connecting customer, order, product, seller, payment, review, and product-category information.

### Table Relationships

| Primary Table | Related Table | Relationship |
|---|---|---|
| Customers | Orders | One-to-One (1:1) |
| Orders | Order_items | One-to-Many (1:*) |
| Products | Order_items | One-to-Many (1:*) |
| Sellers | Order_items | One-to-Many (1:*) |
| Orders | Payments | One-to-Many (1:*) |
| Category_Translation | Products | One-to-Many (1:*) |
| Orders | Reviews | One-to-Many (1:*) |

All seven relationships are active.

### Model Design

- Orders connects customer, transaction, payment, and review information.
- Order_items provides item-level transaction details, including product, seller, price, and freight.
- Products and Category_Translation support product-category analysis.
- Sellers supports seller-related analysis.
- Customers supports customer segmentation and geographic analysis.
- Customer Purchase Frequency is an additional summary table used for purchasing-behavior analysis.

### Benefits

- Supports sales and revenue analysis across products and categories.
- Enables customer purchasing-behavior analysis.
- Supports payment, review, and delivery-performance reporting.
- Provides a structured foundation for Power BI visuals and DAX calculations.

### Data Model Diagram

![Olist Power BI Data Model](Data_Model.png)

## Author

**Ditya Gupta**

Data Analytics | SQL | Power BI | Excel | Python
