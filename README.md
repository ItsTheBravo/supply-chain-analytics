# 🚚 Supply Chain Late Delivery Intelligence

A full-stack analytics project demonstrating end-to-end data pipeline development, from raw data to predictive insights.

![Dashboard Preview](tableau/screenshots/dashboard_main.png)

## 🎯 Business Problem

Over 54% of orders are delivered late. This project builds a predictive analytics solution to:
- Identify root causes of late deliveries
- Predict at-risk orders before they ship
- Provide actionable insights for operations teams

## 🔗 Live Dashboard

**[View Interactive Dashboard on Tableau Public](YOUR_TABLEAU_PUBLIC_URL_HERE)**

## 🏗️ Architecture
```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Raw Data      │────▶│   PostgreSQL    │────▶│    Tableau      │
│   (CSV)         │     │   Star Schema   │     │   Dashboard     │
└─────────────────┘     └─────────────────┘     └─────────────────┘
        │                       │                       │
        ▼                       ▼                       ▼
   180k orders            ETL Pipeline            Interactive
   53 features            Python + SQL            Visualizations
                                │
                                ▼
                    ┌─────────────────┐
                    │  ML Model       │
                    │  Random Forest  │
                    │  71% Accuracy   │
                    └─────────────────┘
```

## 📊 Key Findings

| Insight | Details |
|---------|---------|
| 🚨 Shipping Mode Paradox | First Class has 95% late rate vs Standard at 38% |
| 📦 Systemic Problem | Late rate consistent across all product categories (54-57%) |
| 🤖 ML Predictor | Shipping mode alone accounts for 31% of predictive power |
| 💡 Root Cause | Company is overpromising delivery times, not a logistics capacity issue |

## 🛠️ Tech Stack

| Layer | Technology |
|-------|------------|
| Database | PostgreSQL 15 |
| ETL | Python (pandas, SQLAlchemy) |
| Analysis | SQL (CTEs, Window Functions) |
| ML | scikit-learn (Random Forest) |
| Visualization | Tableau Public |
| Version Control | Git/GitHub |

## 📁 Project Structure
```
supply-chain-analytics/
├── notebooks/
│   ├── 01_data_exploration.ipynb    # EDA with visualizations
│   └── 02_machine_learning.ipynb    # ML model development
├── sql/
│   ├── create_tables.sql            # Star schema DDL
│   └── analytics_queries.sql        # Advanced SQL queries
├── src/
│   └── etl_pipeline.py              # Python ETL script
├── tableau/
│   ├── tableau_export.csv           # Data export for Tableau
│   └── screenshots/                 # Dashboard images
└── README.md
```

## 🤖 Machine Learning Model

**Random Forest Classifier** predicting late delivery risk:

| Metric | Score |
|--------|-------|
| Accuracy | 70.9% |
| Precision | 86.1% |
| Recall | 55.9% |
| F1 Score | 67.8% |
| AUC-ROC | 0.771 |

**Top Predictive Features:**
1. Shipping Mode (31%)
2. Scheduled Ship Days (28%)
3. Fast Shipping Flag (20%)
4. Order Status (17%)

## 📈 SQL Skills Demonstrated

- Common Table Expressions (CTEs)
- Window Functions (RANK, LAG, SUM OVER)
- Complex JOINs across star schema
- CASE statements for conditional logic
- Cohort analysis

## 👤 Author

**John-Paul McGrath**
- GitHub: [@ItsTheBravo](https://github.com/ItsTheBravo)
- LinkedIn: [johnpaulmcgrath](https://linkedin.com/in/johnpaulmcgrath)

---

*Built as part of a career transition into Business Intelligence & Data Analytics*# Supply Chain Late Delivery Intelligence Platform

An end-to-end data analytics project demonstrating SQL, Python, Machine Learning, and Tableau.

## 🎯 Business Problem

Late deliveries cost companies millions in customer churn and expedited shipping. This project builds a predictive analytics platform to identify orders at risk of late delivery BEFORE they ship.

## 🏗️ Architecture
```
Raw Data (Kaggle) → Python ETL → PostgreSQL → ML Model → Tableau Dashboard
```

## 💻 Tech Stack

| Component | Technology |
|-----------|------------|
| Database | PostgreSQL (star schema) |
| ETL | Python (pandas, SQLAlchemy) |
| ML | scikit-learn (Random Forest) |
| Visualization | Tableau |
| Version Control | Git/GitHub |

## 📊 Dataset

- **Source:** [DataCo Smart Supply Chain](https://www.kaggle.com/datasets/shashwatwork/dataco-smart-supply-chain-for-big-data-analysis)
- **Records:** 180,000+ orders
- **Features:** 53 columns
- **Period:** 2015-2019

## 🚀 Project Status

- [x] Project setup & data acquisition
- [ ] Data exploration & profiling
- [ ] Database design (star schema)
- [ ] ETL pipeline
- [ ] SQL analytics
- [ ] Machine learning model
- [ ] Tableau dashboard
- [ ] Documentation

## 👤 Author

**John-Paul McGrath**  
[GitHub](https://github.com/ItsTheBravo) | [LinkedIn](https://linkedin.com/in/john-paul-mcgrath-b1a639137/)

---
*Part of my Data Analytics Portfolio - transitioning from Supply Chain to BI/Data Science*
