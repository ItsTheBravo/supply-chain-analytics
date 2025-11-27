-- =============================================================================
-- SUPPLY CHAIN ANALYTICS - SQL QUERIES
-- =============================================================================
-- Author: John-Paul McGrath
-- Created: November 2025
-- Description: Analytical queries demonstrating advanced SQL skills
-- =============================================================================


-- =============================================================================
-- QUERY 1: Overall Business Metrics
-- =============================================================================
-- CONCEPTS: COUNT, SUM, AVG, ROUND, CASE statements

SELECT 
    COUNT(*) as total_orders,
    ROUND(SUM(sales)::numeric, 2) as total_revenue,
    ROUND(AVG(sales)::numeric, 2) as avg_order_value,
    SUM(CASE WHEN late_delivery_risk = 1 THEN 1 ELSE 0 END) as late_orders,
    ROUND(100.0 * SUM(CASE WHEN late_delivery_risk = 1 THEN 1 ELSE 0 END) / COUNT(*), 1) as late_pct
FROM fact_orders;


-- =============================================================================
-- QUERY 2: Monthly Revenue Trend with Growth Rate
-- =============================================================================
-- CONCEPTS: CTE, JOIN, LAG() window function

WITH monthly_revenue AS (
    SELECT 
        d.year,
        d.month,
        d.month_name,
        SUM(f.sales) as revenue,
        COUNT(*) as order_count
    FROM fact_orders f
    JOIN dim_date d ON f.order_date_key = d.date_key
    GROUP BY d.year, d.month, d.month_name
)
SELECT 
    year,
    month_name,
    ROUND(revenue::numeric, 2) as revenue,
    order_count,
    ROUND((revenue - LAG(revenue) OVER (ORDER BY year, month))::numeric, 2) as revenue_change
FROM monthly_revenue
ORDER BY year, month;


-- =============================================================================
-- QUERY 3: Top 10 Customers by Revenue
-- =============================================================================
-- CONCEPTS: RANK() window function, aggregation, LIMIT

WITH customer_revenue AS (
    SELECT 
        c.customer_key,
        c.customer_name,
        c.customer_city,
        c.customer_country,
        COUNT(*) as total_orders,
        SUM(f.sales) as total_revenue
    FROM fact_orders f
    JOIN dim_customer c ON f.customer_key = c.customer_key
    GROUP BY c.customer_key, c.customer_name, c.customer_city, c.customer_country
)
SELECT 
    RANK() OVER (ORDER BY total_revenue DESC) as revenue_rank,
    customer_name,
    customer_city,
    customer_country,
    total_orders,
    ROUND(total_revenue::numeric, 2) as total_revenue
FROM customer_revenue
ORDER BY revenue_rank
LIMIT 10;


-- =============================================================================
-- QUERY 4: Cumulative Revenue Over Time
-- =============================================================================
-- CONCEPTS: SUM() OVER() running total, PARTITION BY for YTD reset

WITH monthly_revenue AS (
    SELECT 
        d.year,
        d.month,
        d.month_name,
        SUM(f.sales) as monthly_revenue
    FROM fact_orders f
    JOIN dim_date d ON f.order_date_key = d.date_key
    GROUP BY d.year, d.month, d.month_name
)
SELECT 
    year,
    month_name,
    ROUND(monthly_revenue::numeric, 2) as monthly_revenue,
    ROUND(SUM(monthly_revenue) OVER (ORDER BY year, month)::numeric, 2) as cumulative_revenue,
    ROUND(SUM(monthly_revenue) OVER (PARTITION BY year ORDER BY month)::numeric, 2) as ytd_revenue
FROM monthly_revenue
ORDER BY year, month;


-- =============================================================================
-- QUERY 5: Late Delivery Rate by Product Category
-- =============================================================================
-- CONCEPTS: Multiple JOINs, HAVING clause, CASE aggregation

SELECT 
    p.category_name,
    p.department_name,
    COUNT(*) as total_orders,
    SUM(CASE WHEN f.late_delivery_risk = 1 THEN 1 ELSE 0 END) as late_orders,
    ROUND(100.0 * SUM(CASE WHEN f.late_delivery_risk = 1 THEN 1 ELSE 0 END) / COUNT(*), 1) as late_pct,
    ROUND(AVG(f.sales)::numeric, 2) as avg_order_value,
    ROUND(SUM(f.sales)::numeric, 2) as total_revenue
FROM fact_orders f
JOIN dim_product p ON f.product_key = p.product_key
GROUP BY p.category_name, p.department_name
HAVING COUNT(*) > 1000
ORDER BY late_pct DESC;


-- =============================================================================
-- QUERY 6: Comprehensive Shipping Performance Report
-- =============================================================================
-- CONCEPTS: Multiple CTEs, window functions, CASE for status labels

WITH shipping_stats AS (
    SELECT 
        s.shipping_mode,
        COUNT(*) as total_orders,
        SUM(f.sales) as total_revenue,
        AVG(f.days_to_ship_actual) as avg_ship_days,
        SUM(CASE WHEN f.late_delivery_risk = 1 THEN 1 ELSE 0 END) as late_orders
    FROM fact_orders f
    JOIN dim_shipping s ON f.shipping_key = s.shipping_key
    GROUP BY s.shipping_mode
),
shipping_ranked AS (
    SELECT 
        shipping_mode,
        total_orders,
        total_revenue,
        avg_ship_days,
        late_orders,
        ROUND(100.0 * late_orders / total_orders, 1) as late_pct,
        ROUND(100.0 * total_orders / SUM(total_orders) OVER (), 1) as order_share_pct,
        RANK() OVER (ORDER BY late_orders DESC) as late_rank,
        RANK() OVER (ORDER BY total_revenue DESC) as revenue_rank
    FROM shipping_stats
)
SELECT 
    shipping_mode,
    total_orders,
    order_share_pct || '%' as market_share,
    ROUND(total_revenue::numeric, 2) as total_revenue,
    revenue_rank,
    ROUND(avg_ship_days::numeric, 1) as avg_ship_days,
    late_pct || '%' as late_rate,
    late_rank,
    CASE 
        WHEN late_pct > 75 THEN 'Critical'
        WHEN late_pct > 50 THEN 'Warning'
        ELSE 'Good'
    END as performance_status
FROM shipping_ranked
ORDER BY late_pct DESC;


-- =============================================================================
-- QUERY 7: Customer Cohort Analysis
-- =============================================================================
-- CONCEPTS: MIN() OVER() for first purchase, EXTRACT(), cohort analysis

WITH customer_first_order AS (
    SELECT 
        f.customer_key,
        f.sales,
        f.late_delivery_risk,
        d.year as order_year,
        d.quarter as order_quarter,
        MIN(d.full_date) OVER (PARTITION BY f.customer_key) as first_order_date
    FROM fact_orders f
    JOIN dim_date d ON f.order_date_key = d.date_key
),
customer_cohorts AS (
    SELECT 
        customer_key,
        sales,
        late_delivery_risk,
        EXTRACT(YEAR FROM first_order_date) as cohort_year,
        EXTRACT(QUARTER FROM first_order_date) as cohort_quarter
    FROM customer_first_order
)
SELECT 
    cohort_year,
    cohort_quarter,
    COUNT(DISTINCT customer_key) as unique_customers,
    COUNT(*) as total_orders,
    ROUND(COUNT(*)::numeric / COUNT(DISTINCT customer_key), 1) as orders_per_customer,
    ROUND(AVG(sales)::numeric, 2) as avg_order_value,
    ROUND(100.0 * SUM(CASE WHEN late_delivery_risk = 1 THEN 1 ELSE 0 END) / COUNT(*), 1) as late_pct
FROM customer_cohorts
GROUP BY cohort_year, cohort_quarter
ORDER BY cohort_year, cohort_quarter;


-- =============================================================================
-- END OF ANALYTICS QUERIES
-- =============================================================================
