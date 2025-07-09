-- Dimension Tables for E-Commerce Data Warehouse
-- Star schema dimensional model for analytics and reporting

-- Create dimensions schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS dimensions;

-- Drop existing dimension tables if they exist
DROP TABLE IF EXISTS dimensions.dim_customer CASCADE;
DROP TABLE IF EXISTS dimensions.dim_product CASCADE;
DROP TABLE IF EXISTS dimensions.dim_date CASCADE;
DROP TABLE IF EXISTS dimensions.dim_geography CASCADE;

-- Customer Dimension (SCD Type 2)
CREATE TABLE dimensions.dim_customer (
    customer_key INTEGER IDENTITY(1,1) PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    full_name VARCHAR(101),
    email VARCHAR(100),
    phone VARCHAR(20),
    date_of_birth DATE,
    age INTEGER,
    gender VARCHAR(10),
    address_line1 VARCHAR(100),
    address_line2 VARCHAR(100),
    city VARCHAR(50),
    state VARCHAR(50),
    postal_code VARCHAR(20),
    country VARCHAR(50),
    customer_segment VARCHAR(20),
    email_domain VARCHAR(100),
    registration_date TIMESTAMP,
    customer_lifetime_months INTEGER,
    last_login_date TIMESTAMP,
    is_active BOOLEAN,
    -- SCD Type 2 fields
    effective_date TIMESTAMP NOT NULL,
    expiry_date TIMESTAMP,
    is_current BOOLEAN DEFAULT TRUE,
    -- ETL metadata
    created_at TIMESTAMP DEFAULT GETDATE(),
    updated_at TIMESTAMP DEFAULT GETDATE()
)
DISTSTYLE KEY
DISTKEY (customer_key)
SORTKEY (customer_id, effective_date);

-- Product Dimension (SCD Type 2)
CREATE TABLE dimensions.dim_product (
    product_key INTEGER IDENTITY(1,1) PRIMARY KEY,
    product_id INTEGER NOT NULL,
    product_name VARCHAR(200),
    product_description VARCHAR(MAX),
    category_id INTEGER,
    category_name VARCHAR(100),
    subcategory_name VARCHAR(100),
    brand VARCHAR(100),
    sku VARCHAR(50),
    price DECIMAL(10,2),
    cost DECIMAL(10,2),
    profit_margin DECIMAL(5,4),
    price_category VARCHAR(20),
    weight DECIMAL(8,2),
    dimensions VARCHAR(50),
    color VARCHAR(30),
    size VARCHAR(20),
    material VARCHAR(50),
    stock_quantity INTEGER,
    stock_status VARCHAR(20),
    reorder_level INTEGER,
    supplier_id INTEGER,
    is_active BOOLEAN,
    launch_date DATE,
    -- SCD Type 2 fields
    effective_date TIMESTAMP NOT NULL,
    expiry_date TIMESTAMP,
    is_current BOOLEAN DEFAULT TRUE,
    -- ETL metadata
    created_at TIMESTAMP DEFAULT GETDATE(),
    updated_at TIMESTAMP DEFAULT GETDATE()
)
DISTSTYLE ALL
SORTKEY (product_id, effective_date);

-- Date Dimension
CREATE TABLE dimensions.dim_date (
    date_key INTEGER PRIMARY KEY,
    date_actual DATE NOT NULL,
    day_of_week INTEGER,
    day_of_week_name VARCHAR(10),
    day_of_month INTEGER,
    day_of_year INTEGER,
    week_of_year INTEGER,
    month_number INTEGER,
    month_name VARCHAR(10),
    month_abbrev VARCHAR(3),
    quarter_number INTEGER,
    quarter_name VARCHAR(2),
    year_number INTEGER,
    is_weekend BOOLEAN,
    is_holiday BOOLEAN,
    holiday_name VARCHAR(50),
    fiscal_year INTEGER,
    fiscal_quarter INTEGER,
    fiscal_month INTEGER,
    -- Business calendar fields
    is_business_day BOOLEAN,
    business_day_of_month INTEGER,
    business_day_of_year INTEGER
)
DISTSTYLE ALL
SORTKEY (date_key);

-- Geography Dimension
CREATE TABLE dimensions.dim_geography (
    geography_key INTEGER IDENTITY(1,1) PRIMARY KEY,
    city VARCHAR(50),
    state VARCHAR(50),
    state_abbrev VARCHAR(2),
    postal_code VARCHAR(20),
    country VARCHAR(50),
    country_code VARCHAR(3),
    region VARCHAR(50),
    timezone VARCHAR(50),
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    -- ETL metadata
    created_at TIMESTAMP DEFAULT GETDATE(),
    updated_at TIMESTAMP DEFAULT GETDATE()
)
DISTSTYLE ALL
SORTKEY (state, city);

-- Create unique indexes for business keys
CREATE UNIQUE INDEX idx_dim_customer_business_key 
ON dimensions.dim_customer (customer_id, effective_date);

CREATE UNIQUE INDEX idx_dim_product_business_key 
ON dimensions.dim_product (product_id, effective_date);

CREATE UNIQUE INDEX idx_dim_geography_business_key 
ON dimensions.dim_geography (city, state, postal_code);

-- Grant permissions to ETL role
GRANT ALL ON SCHEMA dimensions TO "ecommerce-dwh-dev-glue-service-role";
GRANT ALL ON ALL TABLES IN SCHEMA dimensions TO "ecommerce-dwh-dev-glue-service-role";

-- Add comments for documentation
COMMENT ON SCHEMA dimensions IS 'Dimensional model schema for analytics';
COMMENT ON TABLE dimensions.dim_customer IS 'Customer dimension with SCD Type 2 for historical tracking';
COMMENT ON TABLE dimensions.dim_product IS 'Product dimension with SCD Type 2 for price and attribute changes';
COMMENT ON TABLE dimensions.dim_date IS 'Date dimension for time-based analysis';
COMMENT ON TABLE dimensions.dim_geography IS 'Geography dimension for location-based analysis';

-- Populate date dimension with 10 years of data
INSERT INTO dimensions.dim_date (
    date_key,
    date_actual,
    day_of_week,
    day_of_week_name,
    day_of_month,
    day_of_year,
    week_of_year,
    month_number,
    month_name,
    month_abbrev,
    quarter_number,
    quarter_name,
    year_number,
    is_weekend,
    is_holiday,
    fiscal_year,
    fiscal_quarter,
    fiscal_month,
    is_business_day
)
SELECT 
    CAST(TO_CHAR(date_series, 'YYYYMMDD') AS INTEGER) AS date_key,
    date_series AS date_actual,
    EXTRACT(DOW FROM date_series) + 1 AS day_of_week,
    TO_CHAR(date_series, 'Day') AS day_of_week_name,
    EXTRACT(DAY FROM date_series) AS day_of_month,
    EXTRACT(DOY FROM date_series) AS day_of_year,
    EXTRACT(WEEK FROM date_series) AS week_of_year,
    EXTRACT(MONTH FROM date_series) AS month_number,
    TO_CHAR(date_series, 'Month') AS month_name,
    TO_CHAR(date_series, 'Mon') AS month_abbrev,
    EXTRACT(QUARTER FROM date_series) AS quarter_number,
    'Q' || EXTRACT(QUARTER FROM date_series) AS quarter_name,
    EXTRACT(YEAR FROM date_series) AS year_number,
    CASE WHEN EXTRACT(DOW FROM date_series) IN (0, 6) THEN TRUE ELSE FALSE END AS is_weekend,
    FALSE AS is_holiday, -- Will be updated separately
    CASE 
        WHEN EXTRACT(MONTH FROM date_series) >= 4 THEN EXTRACT(YEAR FROM date_series)
        ELSE EXTRACT(YEAR FROM date_series) - 1
    END AS fiscal_year,
    CASE 
        WHEN EXTRACT(MONTH FROM date_series) IN (4,5,6) THEN 1
        WHEN EXTRACT(MONTH FROM date_series) IN (7,8,9) THEN 2
        WHEN EXTRACT(MONTH FROM date_series) IN (10,11,12) THEN 3
        ELSE 4
    END AS fiscal_quarter,
    CASE 
        WHEN EXTRACT(MONTH FROM date_series) >= 4 THEN EXTRACT(MONTH FROM date_series) - 3
        ELSE EXTRACT(MONTH FROM date_series) + 9
    END AS fiscal_month,
    CASE WHEN EXTRACT(DOW FROM date_series) NOT IN (0, 6) THEN TRUE ELSE FALSE END AS is_business_day
FROM (
    SELECT DATEADD(day, seq, '2020-01-01'::DATE) AS date_series
    FROM (
        SELECT ROW_NUMBER() OVER (ORDER BY 1) - 1 AS seq
        FROM information_schema.columns
        LIMIT 3653  -- 10 years + leap days
    )
) dates
WHERE date_series <= '2029-12-31';
