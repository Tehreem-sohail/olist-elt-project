# Olist ELT Pipeline: Late Delivery and Customer Reviews

An end-to-end ELT data pipeline built on the Olist Brazilian E-Commerce Public Dataset (about 100,000 anonymised orders, 2016-2018). Raw CSV files are loaded unchanged into SQLite, cleaned and joined with SQL, and then used to answer two questions:

1. How much does late delivery hurt customer review scores?
2. Can an order be predicted to be late at the time it is placed?

## Key Findings

Analysis of 95,824 delivered orders that have items and a review (7.99% of them were delivered late):

- **Late delivery strongly lowers reviews.** On-time orders average a review score of 4.29, late orders 2.57. 46.2% of late orders get a score of 1, versus 6.6% of on-time orders.
- **The damage grows with the delay.** Orders 1-3 days late average 3.76, 4-7 days late 2.32, and 8 or more days late about 1.7.
- **Late deliveries are concentrated in certain states.** Maranhão has the highest late rate (19.24%), while São Paulo, Minas Gerais and Paraná are the lowest (4.92% to 5.83%).
- **Late deliveries are concentrated in certain periods.** The late rate peaks in November 2017 (14.15%), February 2018 (15.89%) and March 2018 (21.06%).
- **Prediction is possible but modest.** A gradient boosting model using only purchase-time information reaches a PR AUC of 0.273 (baseline 0.080) and catches about 69% of late orders, with a precision of 18.5%.

## Pipeline Overview

```
data/raw/*.csv
      |  pipeline/load_raw.py
      v
SQLite raw tables (unchanged)
      |  sql/02 to sql/04
      v
staging tables
      |
      v
analytics_orders
      |
      v
notebooks: analysis and model
```

1. **Extract and load:** `pipeline/load_raw.py` loads the nine CSV files into SQLite as raw tables, with no cleaning. All columns are stored as text.
2. **Transform (SQL):**
   - `01_sanity_checks.sql`: checks row counts, duplicates and missing values in the raw tables.
   - `02_stg_orders.sql`: delivered orders with delivery timing and a late flag.
   - `03_stg_items_reviews.sql`: item and freight totals per order, and the latest review per order.
   - `04_analytics_orders.sql`: final table with one row per order.
3. **Analysis and modelling:** two notebooks read the `analytics_orders` table.

Note: in the Olist data, `customer_id` changes with every order, and the real customer identifier is `customer_unique_id`.
## Data and Cleaning Decisions

The Olist dataset is not a single flat file. It is a relational dataset made of nine CSV files that are linked by shared identifiers. Each file is loaded as its own raw table, and only four of them are used to build the final analytics table.

### Source tables

| Table | Rows | Columns | Use |
|---|---|---|---|
| olist_orders_dataset | 99,441 | 8 | Base table: delivered orders, delivery timestamps |
| olist_order_items_dataset | 112,650 | 7 | Aggregated to one row per order (item count, price, freight) |
| olist_order_reviews_dataset | 99,224 | 7 | Latest review per order (review score) |
| olist_customers_dataset | 99,441 | 5 | Customer state and unique customer ID |
| olist_order_payments_dataset | 103,886 | 5 | Loaded, not used |
| olist_products_dataset | 32,951 | 9 | Loaded, not used |
| olist_sellers_dataset | 3,095 | 4 | Loaded, not used |
| olist_geolocation_dataset | 1,000,163 | 5 | Loaded, not used |
| product_category_name_translation | 71 | 2 | Loaded, not used |

In total, 1,550,922 raw rows are loaded. The tables are linked as follows: `order_id` links orders, items, reviews and payments; `customer_id` links orders to customers; `product_id` and `seller_id` link items to products and sellers.

### Row accounting

| Step | Rows | Change |
|---|---|---|
| Orders loaded | 99,441 | |
| Orders that are not delivered (cancelled, shipped, etc.) | | -2,963 |
| Delivered orders without a customer delivery date | | -8 |
| Delivered orders in `stg_orders` | 96,470 | |
| Delivered orders without items or without a review | | -646 |
| Final `analytics_orders` | 95,824 | |

Other aggregation steps:

- Order items: 112,650 rows are aggregated into 98,666 rows, one per order. No item rows are deleted.
- Order reviews: 99,224 rows are reduced to 98,673 rows. Some orders have more than one review, so only the latest review per order is kept (551 older reviews are dropped).

### Cleaning decisions

- **Raw layer is never modified.** CSV files are loaded unchanged, with every column stored as text. Casting to numbers and dates happens in SQL.
- **No duplicate orders.** Sanity checks showed 99,441 orders with 99,441 distinct order IDs. Items and reviews are reduced to one row per order before joining, so the join cannot duplicate orders. The final table has 95,824 rows and 95,824 distinct order IDs.
- **Customers.** `customer_id` changes with every order, so repeat buyers appear as different customers. The real customer is `customer_unique_id` (96,096 distinct values across 99,441 orders). Repeat customers are not treated as duplicates.
- **Scope.** Only delivered orders with a recorded delivery date are kept, because delay can only be computed for them. Orders in the final table were placed between September 2016 and August 2018.
- **Missing values.** No values are imputed. After filtering to delivered orders with items and a review, the final table has no missing values in any column.
- **Outliers are kept.** Large prices and long delays are not removed, because they may be genuine orders.
- **Final table.** `analytics_orders` has 18 columns: identifiers, purchase-time features, delivery outcome columns and the review score. Columns known only after delivery are excluded from the model features to avoid data leakage.

### Not used yet

Payments, products, sellers, geolocation and review text are not used. Possible improvements are adding seller-to-customer distance (the geolocation table has many rows per zip code and must be aggregated first), product category and size, and payment type.

## Project Structure

```
olist-elt-project/
├── data/
│   ├── raw/                 
│   └── database/            
├── sql/
│   ├── 01_sanity_checks.sql
│   ├── 02_stg_orders.sql
│   ├── 03_stg_items_reviews.sql
│   └── 04_analytics_orders.sql
├── pipeline/
│   ├── load_raw.py          # load CSV files into SQLite
│   ├── run_sql.py           # run one SQL file
│   └── run_pipeline.py      # run the whole pipeline
├── notebooks/
│   ├── 01_delay_vs_reviews.ipynb
│   └── 02_late_delivery_model.ipynb
├── models/                  # saved model, created by notebook 02 (not tracked)
├── requirements.txt
└── README.md
```

## How to Run

1. **Install Python 3.9 or newer and the dependencies:**
   ```
   pip install -r requirements.txt
   ```
2. **Download the dataset** from Kaggle: [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce). Place the nine CSV files in `data/raw/`.
3. **Run the pipeline** from the project root:
   ```
   python pipeline/run_pipeline.py
   ```
   This creates `data/database/olist.db` with the raw, staging and analytics tables.
4. **Open the notebooks** and run them in order:
   ```
   jupyter notebook
   ```
   - `notebooks/01_delay_vs_reviews.ipynb`: analysis and charts.
   - `notebooks/02_late_delivery_model.ipynb`: late delivery model.

## Model Results

Evaluated on a held-out test set of 19,165 orders (7.99% late). Features are limited to information available at purchase time: estimated delivery days, item count, product and seller counts, price, freight, customer state, purchase month, weekday and hour.

| Model | Recall | Precision | ROC AUC | PR AUC |
|---|---|---|---|---|
| Baseline (always on time) | 0.000 | 0.000 | 0.500 | 0.080 |
| Logistic Regression | 0.623 | 0.129 | 0.684 | 0.161 |
| Gradient Boosting | 0.687 | 0.185 | 0.778 | 0.273 |

The most important features are purchase month, customer state, estimated delivery days and total freight.

## Limitations

- Results show an association between late delivery and low reviews, not proof of causation.
- The train/test split is random, not by time. The data covers about two years, and the model relies strongly on purchase month, so it may not generalise to future months.
- Distance between seller and customer, carrier performance and weather are not used. Adding distance is the most promising improvement.
- Precision is low: most orders flagged as late arrive on time. The model is suited to ranking orders by risk, not to deciding on individual orders.

## Tools

Python, pandas, SQLite and SQL, scikit-learn, matplotlib, seaborn, Git and GitHub.