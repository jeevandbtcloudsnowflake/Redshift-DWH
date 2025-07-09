-- Advanced Analytics Queries for E-commerce Data Warehouse
-- These queries provide deep insights for business decision making

-- 1. Customer Lifetime Value (CLV) Analysis
WITH customer_metrics AS (
    SELECT 
        fs.customer_key,
        dc.customer_segment,
        dc.registration_date,
        COUNT(DISTINCT fs.order_id) as total_orders,
        SUM(fs.order_total_amount) as total_spent,
        AVG(fs.order_total_amount) as avg_order_value,
        MIN(dd.date_actual) as first_order_date,
        MAX(dd.date_actual) as last_order_date,
        DATEDIFF(day, MIN(dd.date_actual), MAX(dd.date_actual)) as customer_lifespan_days
    FROM facts.fact_sales fs
    JOIN dimensions.dim_customer dc ON fs.customer_key = dc.customer_key
    JOIN dimensions.dim_date dd ON fs.order_date_key = dd.date_key
    WHERE dc.is_current = true
    GROUP BY fs.customer_key, dc.customer_segment, dc.registration_date
),
clv_calculation AS (
    SELECT 
        customer_segment,
        AVG(total_spent) as avg_customer_value,
        AVG(total_orders) as avg_order_frequency,
        AVG(CASE WHEN customer_lifespan_days > 0 THEN customer_lifespan_days ELSE 365 END) as avg_customer_lifespan,
        AVG(avg_order_value) as avg_order_value,
        
        -- CLV = (Average Order Value × Purchase Frequency × Customer Lifespan)
        AVG(avg_order_value) * AVG(total_orders) * 
        (AVG(CASE WHEN customer_lifespan_days > 0 THEN customer_lifespan_days ELSE 365 END) / 365.0) as estimated_clv
    FROM customer_metrics
    GROUP BY customer_segment
)
SELECT 
    customer_segment,
    ROUND(avg_customer_value, 2) as avg_customer_value,
    ROUND(avg_order_frequency, 2) as avg_order_frequency,
    ROUND(avg_customer_lifespan, 0) as avg_customer_lifespan_days,
    ROUND(avg_order_value, 2) as avg_order_value,
    ROUND(estimated_clv, 2) as estimated_customer_lifetime_value
FROM clv_calculation
ORDER BY estimated_clv DESC;

-- 2. Product Affinity Analysis (Market Basket Analysis)
WITH order_products AS (
    SELECT 
        fs.order_id,
        dp.product_name,
        dp.category_name
    FROM facts.fact_sales fs
    JOIN dimensions.dim_product dp ON fs.product_key = dp.product_key
    WHERE dp.is_current = true
),
product_pairs AS (
    SELECT 
        op1.product_name as product_a,
        op2.product_name as product_b,
        COUNT(DISTINCT op1.order_id) as co_occurrence_count,
        COUNT(DISTINCT op1.order_id) * 1.0 / (
            SELECT COUNT(DISTINCT order_id) FROM order_products
        ) as support
    FROM order_products op1
    JOIN order_products op2 ON op1.order_id = op2.order_id
    WHERE op1.product_name < op2.product_name  -- Avoid duplicates
    GROUP BY op1.product_name, op2.product_name
    HAVING COUNT(DISTINCT op1.order_id) >= 5  -- Minimum support threshold
)
SELECT 
    product_a,
    product_b,
    co_occurrence_count,
    ROUND(support * 100, 2) as support_percent,
    RANK() OVER (ORDER BY co_occurrence_count DESC) as affinity_rank
FROM product_pairs
ORDER BY co_occurrence_count DESC
LIMIT 20;

-- 3. Seasonal Sales Analysis
WITH monthly_sales AS (
    SELECT 
        dd.month_number,
        dd.month_name,
        dp.category_name,
        SUM(fs.order_total_amount) as monthly_revenue,
        COUNT(DISTINCT fs.order_id) as monthly_orders
    FROM facts.fact_sales fs
    JOIN dimensions.dim_date dd ON fs.order_date_key = dd.date_key
    JOIN dimensions.dim_product dp ON fs.product_key = dp.product_key
    WHERE dp.is_current = true
    GROUP BY dd.month_number, dd.month_name, dp.category_name
),
category_totals AS (
    SELECT 
        category_name,
        SUM(monthly_revenue) as total_category_revenue
    FROM monthly_sales
    GROUP BY category_name
)
SELECT 
    ms.month_name,
    ms.category_name,
    ms.monthly_revenue,
    ROUND((ms.monthly_revenue / ct.total_category_revenue) * 100, 2) as percent_of_category_annual,
    ROUND(ms.monthly_revenue / SUM(ms.monthly_revenue) OVER (PARTITION BY ms.month_number) * 100, 2) as percent_of_month_total,
    RANK() OVER (PARTITION BY ms.category_name ORDER BY ms.monthly_revenue DESC) as month_rank_in_category
FROM monthly_sales ms
JOIN category_totals ct ON ms.category_name = ct.category_name
ORDER BY ms.month_number, ms.monthly_revenue DESC;

-- 4. Customer Churn Prediction Analysis
WITH customer_activity AS (
    SELECT 
        dc.customer_id,
        dc.customer_segment,
        dc.registration_date,
        COUNT(DISTINCT fs.order_id) as total_orders,
        SUM(fs.order_total_amount) as total_spent,
        MAX(dd.date_actual) as last_order_date,
        DATEDIFF(day, MAX(dd.date_actual), CURRENT_DATE) as days_since_last_order,
        AVG(DATEDIFF(day, LAG(dd.date_actual) OVER (PARTITION BY dc.customer_id ORDER BY dd.date_actual), dd.date_actual)) as avg_days_between_orders
    FROM dimensions.dim_customer dc
    LEFT JOIN facts.fact_sales fs ON dc.customer_key = fs.customer_key
    LEFT JOIN dimensions.dim_date dd ON fs.order_date_key = dd.date_key
    WHERE dc.is_current = true
    GROUP BY dc.customer_id, dc.customer_segment, dc.registration_date
)
SELECT 
    customer_segment,
    COUNT(*) as total_customers,
    
    -- Churn Risk Categories
    COUNT(CASE WHEN days_since_last_order <= 30 THEN 1 END) as active_customers,
    COUNT(CASE WHEN days_since_last_order BETWEEN 31 AND 90 THEN 1 END) as at_risk_customers,
    COUNT(CASE WHEN days_since_last_order > 90 OR days_since_last_order IS NULL THEN 1 END) as churned_customers,
    
    -- Percentages
    ROUND(COUNT(CASE WHEN days_since_last_order <= 30 THEN 1 END) * 100.0 / COUNT(*), 2) as active_percent,
    ROUND(COUNT(CASE WHEN days_since_last_order BETWEEN 31 AND 90 THEN 1 END) * 100.0 / COUNT(*), 2) as at_risk_percent,
    ROUND(COUNT(CASE WHEN days_since_last_order > 90 OR days_since_last_order IS NULL THEN 1 END) * 100.0 / COUNT(*), 2) as churned_percent,
    
    -- Average metrics for active customers
    AVG(CASE WHEN days_since_last_order <= 30 THEN total_spent END) as avg_active_customer_value,
    AVG(CASE WHEN days_since_last_order <= 30 THEN avg_days_between_orders END) as avg_purchase_frequency_active
    
FROM customer_activity
GROUP BY customer_segment
ORDER BY churned_percent;

-- 5. Revenue Attribution Analysis
WITH revenue_attribution AS (
    SELECT 
        dd.year_number,
        dd.quarter_number,
        dc.customer_segment,
        dp.category_name,
        fs.payment_method,
        fs.order_source,
        SUM(fs.order_total_amount) as revenue,
        COUNT(DISTINCT fs.order_id) as orders,
        COUNT(DISTINCT fs.customer_key) as customers
    FROM facts.fact_sales fs
    JOIN dimensions.dim_date dd ON fs.order_date_key = dd.date_key
    JOIN dimensions.dim_customer dc ON fs.customer_key = dc.customer_key
    JOIN dimensions.dim_product dp ON fs.product_key = dp.product_key
    WHERE dc.is_current = true AND dp.is_current = true
    GROUP BY dd.year_number, dd.quarter_number, dc.customer_segment, 
             dp.category_name, fs.payment_method, fs.order_source
)
SELECT 
    year_number,
    quarter_number,
    customer_segment,
    category_name,
    payment_method,
    order_source,
    revenue,
    orders,
    customers,
    ROUND(revenue / SUM(revenue) OVER (PARTITION BY year_number, quarter_number) * 100, 2) as revenue_contribution_percent,
    RANK() OVER (PARTITION BY year_number, quarter_number ORDER BY revenue DESC) as revenue_rank
FROM revenue_attribution
WHERE revenue > 0
ORDER BY year_number, quarter_number, revenue DESC;

-- 6. Price Elasticity Analysis
WITH price_analysis AS (
    SELECT 
        dp.product_id,
        dp.product_name,
        dp.category_name,
        fs.unit_price,
        SUM(fs.quantity) as quantity_sold,
        COUNT(DISTINCT fs.order_id) as orders_count,
        AVG(fs.unit_price) as avg_price,
        STDDEV(fs.unit_price) as price_stddev
    FROM facts.fact_sales fs
    JOIN dimensions.dim_product dp ON fs.product_key = dp.product_key
    WHERE dp.is_current = true
    GROUP BY dp.product_id, dp.product_name, dp.category_name, fs.unit_price
    HAVING COUNT(DISTINCT fs.order_id) >= 3  -- Minimum orders for analysis
),
price_elasticity AS (
    SELECT 
        product_id,
        product_name,
        category_name,
        COUNT(*) as price_points,
        MIN(unit_price) as min_price,
        MAX(unit_price) as max_price,
        AVG(quantity_sold) as avg_quantity,
        
        -- Simple elasticity calculation
        CASE 
            WHEN MAX(unit_price) > MIN(unit_price) THEN
                (MAX(quantity_sold) - MIN(quantity_sold)) / 
                NULLIF((MAX(unit_price) - MIN(unit_price)), 0)
            ELSE 0
        END as price_elasticity_coefficient
    FROM price_analysis
    GROUP BY product_id, product_name, category_name
    HAVING COUNT(*) >= 2  -- Need at least 2 price points
)
SELECT 
    category_name,
    product_name,
    price_points,
    ROUND(min_price, 2) as min_price,
    ROUND(max_price, 2) as max_price,
    ROUND(avg_quantity, 2) as avg_quantity_sold,
    ROUND(price_elasticity_coefficient, 4) as elasticity_coefficient,
    CASE 
        WHEN price_elasticity_coefficient < -1 THEN 'Elastic'
        WHEN price_elasticity_coefficient BETWEEN -1 AND 0 THEN 'Inelastic'
        ELSE 'Positive Elasticity'
    END as elasticity_type
FROM price_elasticity
WHERE ABS(price_elasticity_coefficient) > 0.1  -- Filter out near-zero elasticity
ORDER BY ABS(price_elasticity_coefficient) DESC;
