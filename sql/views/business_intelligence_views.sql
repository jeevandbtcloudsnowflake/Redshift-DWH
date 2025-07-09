-- Business Intelligence Views for E-commerce Data Warehouse
-- These views provide pre-aggregated data for common business questions

-- Customer 360 View
CREATE OR REPLACE VIEW analytics.customer_360 AS
SELECT 
    dc.customer_id,
    dc.full_name,
    dc.email,
    dc.customer_segment,
    dc.city,
    dc.state,
    dc.registration_date,
    
    -- Order Statistics
    COUNT(DISTINCT fs.order_id) as total_orders,
    SUM(fs.order_total_amount) as lifetime_value,
    AVG(fs.order_total_amount) as avg_order_value,
    MIN(dd.date_actual) as first_order_date,
    MAX(dd.date_actual) as last_order_date,
    
    -- Product Preferences
    COUNT(DISTINCT fs.product_key) as unique_products_purchased,
    
    -- Behavioral Metrics
    DATEDIFF(day, MAX(dd.date_actual), CURRENT_DATE) as days_since_last_order,
    CASE 
        WHEN DATEDIFF(day, MAX(dd.date_actual), CURRENT_DATE) <= 30 THEN 'Active'
        WHEN DATEDIFF(day, MAX(dd.date_actual), CURRENT_DATE) <= 90 THEN 'At Risk'
        ELSE 'Churned'
    END as customer_status,
    
    -- RFM Analysis Components
    DATEDIFF(day, MAX(dd.date_actual), CURRENT_DATE) as recency,
    COUNT(DISTINCT fs.order_id) as frequency,
    SUM(fs.order_total_amount) as monetary
    
FROM dimensions.dim_customer dc
LEFT JOIN facts.fact_sales fs ON dc.customer_key = fs.customer_key
LEFT JOIN dimensions.dim_date dd ON fs.order_date_key = dd.date_key
WHERE dc.is_current = true
GROUP BY 
    dc.customer_id, dc.full_name, dc.email, dc.customer_segment,
    dc.city, dc.state, dc.registration_date;

-- Product Performance Dashboard
CREATE OR REPLACE VIEW analytics.product_performance AS
SELECT 
    dp.product_id,
    dp.product_name,
    dp.category_name,
    dp.brand,
    dp.price,
    dp.cost,
    
    -- Sales Metrics
    SUM(fs.quantity) as total_units_sold,
    SUM(fs.line_total) as total_revenue,
    SUM(fs.quantity * dp.cost) as total_cost,
    SUM(fs.line_total) - SUM(fs.quantity * dp.cost) as gross_profit,
    
    -- Profitability
    CASE 
        WHEN SUM(fs.line_total) > 0 
        THEN ROUND(((SUM(fs.line_total) - SUM(fs.quantity * dp.cost)) / SUM(fs.line_total)) * 100, 2)
        ELSE 0 
    END as gross_margin_percent,
    
    -- Performance Metrics
    COUNT(DISTINCT fs.order_id) as orders_containing_product,
    COUNT(DISTINCT fs.customer_key) as unique_customers,
    AVG(fs.unit_price) as avg_selling_price,
    
    -- Ranking
    RANK() OVER (PARTITION BY dp.category_name ORDER BY SUM(fs.line_total) DESC) as revenue_rank_in_category,
    RANK() OVER (ORDER BY SUM(fs.line_total) DESC) as overall_revenue_rank
    
FROM dimensions.dim_product dp
LEFT JOIN facts.fact_sales fs ON dp.product_key = fs.product_key
WHERE dp.is_current = true
GROUP BY 
    dp.product_id, dp.product_name, dp.category_name, dp.brand, dp.price, dp.cost;

-- Monthly Sales Trends
CREATE OR REPLACE VIEW analytics.monthly_sales_trends AS
SELECT 
    dd.year_number,
    dd.month_number,
    dd.month_name,
    dd.quarter_number,
    
    -- Sales Metrics
    COUNT(DISTINCT fs.order_id) as total_orders,
    COUNT(DISTINCT fs.customer_key) as unique_customers,
    SUM(fs.order_total_amount) as total_revenue,
    SUM(fs.quantity) as total_units_sold,
    AVG(fs.order_total_amount) as avg_order_value,
    
    -- Growth Metrics
    LAG(SUM(fs.order_total_amount)) OVER (ORDER BY dd.year_number, dd.month_number) as prev_month_revenue,
    CASE 
        WHEN LAG(SUM(fs.order_total_amount)) OVER (ORDER BY dd.year_number, dd.month_number) > 0
        THEN ROUND(((SUM(fs.order_total_amount) - LAG(SUM(fs.order_total_amount)) OVER (ORDER BY dd.year_number, dd.month_number)) / LAG(SUM(fs.order_total_amount)) OVER (ORDER BY dd.year_number, dd.month_number)) * 100, 2)
        ELSE NULL
    END as revenue_growth_percent,
    
    -- Customer Metrics
    LAG(COUNT(DISTINCT fs.customer_key)) OVER (ORDER BY dd.year_number, dd.month_number) as prev_month_customers,
    CASE 
        WHEN LAG(COUNT(DISTINCT fs.customer_key)) OVER (ORDER BY dd.year_number, dd.month_number) > 0
        THEN ROUND(((COUNT(DISTINCT fs.customer_key) - LAG(COUNT(DISTINCT fs.customer_key)) OVER (ORDER BY dd.year_number, dd.month_number)) / LAG(COUNT(DISTINCT fs.customer_key)) OVER (ORDER BY dd.year_number, dd.month_number)) * 100, 2)
        ELSE NULL
    END as customer_growth_percent
    
FROM facts.fact_sales fs
JOIN dimensions.dim_date dd ON fs.order_date_key = dd.date_key
GROUP BY dd.year_number, dd.month_number, dd.month_name, dd.quarter_number
ORDER BY dd.year_number, dd.month_number;

-- Category Performance Analysis
CREATE OR REPLACE VIEW analytics.category_performance AS
SELECT 
    dp.category_name,
    
    -- Product Metrics
    COUNT(DISTINCT dp.product_id) as total_products,
    COUNT(DISTINCT CASE WHEN fs.product_key IS NOT NULL THEN dp.product_id END) as products_with_sales,
    
    -- Sales Metrics
    SUM(fs.quantity) as total_units_sold,
    SUM(fs.line_total) as total_revenue,
    AVG(fs.unit_price) as avg_selling_price,
    
    -- Customer Metrics
    COUNT(DISTINCT fs.customer_key) as unique_customers,
    COUNT(DISTINCT fs.order_id) as total_orders,
    
    -- Market Share
    ROUND((SUM(fs.line_total) / SUM(SUM(fs.line_total)) OVER ()) * 100, 2) as revenue_market_share_percent,
    
    -- Performance Ranking
    RANK() OVER (ORDER BY SUM(fs.line_total) DESC) as revenue_rank,
    RANK() OVER (ORDER BY SUM(fs.quantity) DESC) as volume_rank
    
FROM dimensions.dim_product dp
LEFT JOIN facts.fact_sales fs ON dp.product_key = fs.product_key
WHERE dp.is_current = true
GROUP BY dp.category_name
ORDER BY total_revenue DESC;

-- Geographic Sales Analysis
CREATE OR REPLACE VIEW analytics.geographic_sales AS
SELECT 
    dc.state,
    dc.city,
    
    -- Customer Metrics
    COUNT(DISTINCT dc.customer_id) as total_customers,
    COUNT(DISTINCT CASE WHEN fs.customer_key IS NOT NULL THEN dc.customer_id END) as active_customers,
    
    -- Sales Metrics
    COUNT(DISTINCT fs.order_id) as total_orders,
    SUM(fs.order_total_amount) as total_revenue,
    AVG(fs.order_total_amount) as avg_order_value,
    
    -- Performance Metrics
    ROUND(SUM(fs.order_total_amount) / COUNT(DISTINCT dc.customer_id), 2) as revenue_per_customer,
    ROUND(COUNT(DISTINCT fs.order_id) * 1.0 / COUNT(DISTINCT dc.customer_id), 2) as orders_per_customer,
    
    -- Market Share
    ROUND((SUM(fs.order_total_amount) / SUM(SUM(fs.order_total_amount)) OVER ()) * 100, 2) as revenue_market_share_percent,
    
    -- Ranking
    RANK() OVER (ORDER BY SUM(fs.order_total_amount) DESC) as revenue_rank,
    RANK() OVER (ORDER BY COUNT(DISTINCT fs.order_id) DESC) as order_volume_rank
    
FROM dimensions.dim_customer dc
LEFT JOIN facts.fact_sales fs ON dc.customer_key = fs.customer_key
WHERE dc.is_current = true
GROUP BY dc.state, dc.city
HAVING COUNT(DISTINCT fs.order_id) >= 5  -- Only include locations with meaningful activity
ORDER BY total_revenue DESC;

-- Customer Cohort Analysis
CREATE OR REPLACE VIEW analytics.customer_cohorts AS
WITH cohort_data AS (
    SELECT 
        dc.customer_id,
        DATE_TRUNC('month', dc.registration_date) as cohort_month,
        DATE_TRUNC('month', dd.date_actual) as order_month,
        DATEDIFF(month, DATE_TRUNC('month', dc.registration_date), DATE_TRUNC('month', dd.date_actual)) as period_number,
        fs.order_total_amount
    FROM dimensions.dim_customer dc
    LEFT JOIN facts.fact_sales fs ON dc.customer_key = fs.customer_key
    LEFT JOIN dimensions.dim_date dd ON fs.order_date_key = dd.date_key
    WHERE dc.is_current = true
)
SELECT 
    cohort_month,
    period_number,
    COUNT(DISTINCT customer_id) as customers,
    SUM(order_total_amount) as revenue,
    AVG(order_total_amount) as avg_order_value,
    
    -- Retention Rate
    ROUND(
        COUNT(DISTINCT customer_id) * 100.0 / 
        FIRST_VALUE(COUNT(DISTINCT customer_id)) OVER (
            PARTITION BY cohort_month 
            ORDER BY period_number 
            ROWS UNBOUNDED PRECEDING
        ), 2
    ) as retention_rate_percent
    
FROM cohort_data
WHERE order_month IS NOT NULL
GROUP BY cohort_month, period_number
ORDER BY cohort_month, period_number;
