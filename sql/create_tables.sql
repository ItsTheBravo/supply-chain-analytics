-- =============================================================================
-- SUPPLY CHAIN ANALYTICS - STAR SCHEMA
-- =============================================================================
-- Author: John-Paul McGrath
-- Created: November 2025
-- Description: Star schema design for supply chain late delivery analysis
-- =============================================================================

-- =============================================================================
-- DIMENSION TABLES
-- =============================================================================

-- Customer dimension
CREATE TABLE IF NOT EXISTS dim_customer (
    customer_key SERIAL PRIMARY KEY,
    customer_id VARCHAR(50),
    customer_name VARCHAR(100),
    customer_segment VARCHAR(50),
    customer_city VARCHAR(100),
    customer_state VARCHAR(100),
    customer_country VARCHAR(100),
    customer_region VARCHAR(50)
);

-- Product dimension
CREATE TABLE IF NOT EXISTS dim_product (
    product_key SERIAL PRIMARY KEY,
    product_id VARCHAR(50),
    product_name VARCHAR(255),
    category_name VARCHAR(100),
    department_name VARCHAR(100),
    product_price DECIMAL(10,2)
);

-- Shipping dimension
CREATE TABLE IF NOT EXISTS dim_shipping (
    shipping_key SERIAL PRIMARY KEY,
    shipping_mode VARCHAR(50),
    delivery_status VARCHAR(50),
    order_status VARCHAR(50)
);

-- Date dimension
CREATE TABLE IF NOT EXISTS dim_date (
    date_key SERIAL PRIMARY KEY,
    full_date DATE,
    day_of_week VARCHAR(20),
    day_of_month INTEGER,
    month INTEGER,
    month_name VARCHAR(20),
    quarter INTEGER,
    year INTEGER,
    is_weekend BOOLEAN
);

-- =============================================================================
-- FACT TABLE
-- =============================================================================

CREATE TABLE IF NOT EXISTS fact_orders (
    order_id SERIAL PRIMARY KEY,
    order_number VARCHAR(50),
    
    -- Foreign keys to dimensions
    customer_key INTEGER REFERENCES dim_customer(customer_key),
    product_key INTEGER REFERENCES dim_product(product_key),
    shipping_key INTEGER REFERENCES dim_shipping(shipping_key),
    order_date_key INTEGER REFERENCES dim_date(date_key),
    ship_date_key INTEGER REFERENCES dim_date(date_key),
    
    -- Measures
    order_quantity INTEGER,
    sales DECIMAL(12,2),
    order_profit DECIMAL(12,2),
    discount DECIMAL(5,2),
    
    -- Shipping metrics
    days_to_ship_scheduled INTEGER,
    days_to_ship_actual INTEGER,
    
    -- ML target
    late_delivery_risk INTEGER,
    
    -- ML predictions (populated later)
    late_delivery_predicted INTEGER,
    prediction_probability DECIMAL(5,4)
);

-- =============================================================================
-- INDEXES FOR PERFORMANCE
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_fact_customer ON fact_orders(customer_key);
CREATE INDEX IF NOT EXISTS idx_fact_product ON fact_orders(product_key);
CREATE INDEX IF NOT EXISTS idx_fact_shipping ON fact_orders(shipping_key);
CREATE INDEX IF NOT EXISTS idx_fact_order_date ON fact_orders(order_date_key);
CREATE INDEX IF NOT EXISTS idx_fact_late_risk ON fact_orders(late_delivery_risk);

-- =============================================================================
-- Schema creation complete!
-- =============================================================================
