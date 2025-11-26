"""
=============================================================================
SUPPLY CHAIN ETL PIPELINE
=============================================================================
Author: John-Paul McGrath
Created: November 2025
Description: Loads CSV data into PostgreSQL star schema
=============================================================================
"""

import pandas as pd
import numpy as np
from sqlalchemy import create_engine, text
from datetime import datetime
import warnings
warnings.filterwarnings('ignore')


def get_database_connection():
    connection_string = "postgresql://johnpaulmcgrath@localhost:5432/supply_chain_db"
    engine = create_engine(connection_string)
    print("✅ Database connection established")
    return engine


def load_raw_data(filepath):
    print(f"📂 Loading data from {filepath}...")
    df = pd.read_csv(filepath, encoding='latin-1')
    print(f"✅ Loaded {len(df):,} rows × {len(df.columns)} columns")
    return df


def load_dim_customer(df, engine):
    print("👥 Loading dim_customer...")
    
    customers = df[['Customer Id', 'Customer Fname', 'Customer Lname', 
                    'Customer Segment', 'Customer City', 'Customer State',
                    'Customer Country', 'Order Region']].copy()
    
    customers.columns = ['customer_id', 'customer_fname', 'customer_lname',
                         'customer_segment', 'customer_city', 'customer_state',
                         'customer_country', 'customer_region']
    
    customers['customer_name'] = customers['customer_fname'] + ' ' + customers['customer_lname']
    
    customers = customers[['customer_id', 'customer_name', 'customer_segment',
                           'customer_city', 'customer_state', 'customer_country',
                           'customer_region']].drop_duplicates()
    
    customers = customers.reset_index(drop=True)
    customers.index += 1
    customers.index.name = 'customer_key'
    customers = customers.reset_index()
    
    customers.to_sql('dim_customer', engine, if_exists='append', index=False)
    print(f"   ✅ Loaded {len(customers):,} unique customers")
    
    return customers


def load_dim_product(df, engine):
    print("📦 Loading dim_product...")
    
    products = df[['Product Card Id', 'Product Name', 'Category Name',
                   'Department Name', 'Product Price']].copy()
    
    products.columns = ['product_id', 'product_name', 'category_name',
                        'department_name', 'product_price']
    
    products = products.drop_duplicates()
    products = products.reset_index(drop=True)
    products.index += 1
    products.index.name = 'product_key'
    products = products.reset_index()
    
    products.to_sql('dim_product', engine, if_exists='append', index=False)
    print(f"   ✅ Loaded {len(products):,} unique products")
    
    return products


def load_dim_shipping(df, engine):
    print("🚚 Loading dim_shipping...")
    
    shipping = df[['Shipping Mode', 'Delivery Status', 'Order Status']].copy()
    shipping.columns = ['shipping_mode', 'delivery_status', 'order_status']
    
    shipping = shipping.drop_duplicates()
    shipping = shipping.reset_index(drop=True)
    shipping.index += 1
    shipping.index.name = 'shipping_key'
    shipping = shipping.reset_index()
    
    shipping.to_sql('dim_shipping', engine, if_exists='append', index=False)
    print(f"   ✅ Loaded {len(shipping):,} unique shipping combinations")
    
    return shipping


def load_dim_date(df, engine):
    print("📅 Loading dim_date...")
    
    order_dates = pd.to_datetime(df['order date (DateOrders)'])
    ship_dates = pd.to_datetime(df['shipping date (DateOrders)'])
    all_dates = pd.concat([order_dates, ship_dates]).drop_duplicates()
    
    date_dim = pd.DataFrame({'full_date': all_dates})
    date_dim['day_of_week'] = date_dim['full_date'].dt.day_name()
    date_dim['day_of_month'] = date_dim['full_date'].dt.day
    date_dim['month'] = date_dim['full_date'].dt.month
    date_dim['month_name'] = date_dim['full_date'].dt.month_name()
    date_dim['quarter'] = date_dim['full_date'].dt.quarter
    date_dim['year'] = date_dim['full_date'].dt.year
    date_dim['is_weekend'] = date_dim['day_of_week'].isin(['Saturday', 'Sunday'])
    
    date_dim = date_dim.drop_duplicates().sort_values('full_date')
    date_dim = date_dim.reset_index(drop=True)
    date_dim.index += 1
    date_dim.index.name = 'date_key'
    date_dim = date_dim.reset_index()
    
    date_dim.to_sql('dim_date', engine, if_exists='append', index=False)
    print(f"   ✅ Loaded {len(date_dim):,} unique dates")
    
    return date_dim


def load_fact_orders(df, engine, dim_customer, dim_product, dim_shipping, dim_date):
    print("📊 Loading fact_orders...")
    
    customer_lookup = dict(zip(dim_customer['customer_id'].astype(str),
                               dim_customer['customer_key']))
    
    product_lookup = dict(zip(dim_product['product_id'].astype(str),
                              dim_product['product_key']))
    
    dim_shipping['lookup_key'] = (dim_shipping['shipping_mode'] + '|' +
                                   dim_shipping['delivery_status'] + '|' +
                                   dim_shipping['order_status'])
    shipping_lookup = dict(zip(dim_shipping['lookup_key'], dim_shipping['shipping_key']))
    
    dim_date['date_str'] = dim_date['full_date'].astype(str)
    date_lookup = dict(zip(dim_date['date_str'], dim_date['date_key']))
    
    facts = pd.DataFrame()
    facts['order_number'] = df['Order Id'].astype(str)
    
    facts['customer_key'] = df['Customer Id'].astype(str).map(customer_lookup)
    facts['product_key'] = df['Product Card Id'].astype(str).map(product_lookup)
    
    shipping_keys = (df['Shipping Mode'] + '|' +
                     df['Delivery Status'] + '|' +
                     df['Order Status'])
    facts['shipping_key'] = shipping_keys.map(shipping_lookup)
    
    facts['order_date_key'] = pd.to_datetime(df['order date (DateOrders)']).astype(str).map(date_lookup)
    facts['ship_date_key'] = pd.to_datetime(df['shipping date (DateOrders)']).astype(str).map(date_lookup)
    
    facts['order_quantity'] = df['Order Item Quantity']
    facts['sales'] = df['Sales']
    facts['order_profit'] = df['Order Profit Per Order']
    facts['discount'] = df['Order Item Discount']
    facts['days_to_ship_scheduled'] = df['Days for shipment (scheduled)']
    facts['days_to_ship_actual'] = df['Days for shipping (real)']
    facts['late_delivery_risk'] = df['Late_delivery_risk']
    
    facts['late_delivery_predicted'] = None
    facts['prediction_probability'] = None
    
    facts.to_sql('fact_orders', engine, if_exists='append', index=False)
    print(f"   ✅ Loaded {len(facts):,} orders")
    
    return facts


def verify_load(engine):
    print("\n" + "="*50)
    print("📋 VERIFICATION")
    print("="*50)
    
    tables = ['dim_customer', 'dim_product', 'dim_shipping', 'dim_date', 'fact_orders']
    
    with engine.connect() as conn:
        for table in tables:
            result = conn.execute(text(f"SELECT COUNT(*) FROM {table}"))
            count = result.scalar()
            print(f"   {table}: {count:,} rows")
    
    print("="*50)
    print("✅ ETL COMPLETE!")
    print("="*50)


def clear_tables(engine):
    print("🗑️  Clearing existing data...")
    
    with engine.connect() as conn:
        conn.execute(text("TRUNCATE TABLE fact_orders CASCADE"))
        conn.execute(text("TRUNCATE TABLE dim_customer CASCADE"))
        conn.execute(text("TRUNCATE TABLE dim_product CASCADE"))
        conn.execute(text("TRUNCATE TABLE dim_shipping CASCADE"))
        conn.execute(text("TRUNCATE TABLE dim_date CASCADE"))
        conn.commit()
    
    print("   ✅ Tables cleared")


def main():
    print("\n" + "="*50)
    print("🚀 SUPPLY CHAIN ETL PIPELINE")
    print("="*50 + "\n")
    
    engine = get_database_connection()
    clear_tables(engine)
    
    df = load_raw_data('data/DataCoSupplyChainDataset.csv')
    
    dim_customer = load_dim_customer(df, engine)
    dim_product = load_dim_product(df, engine)
    dim_shipping = load_dim_shipping(df, engine)
    dim_date = load_dim_date(df, engine)
    
    facts = load_fact_orders(df, engine, dim_customer, dim_product, dim_shipping, dim_date)
    
    verify_load(engine)


if __name__ == "__main__":
    main()
