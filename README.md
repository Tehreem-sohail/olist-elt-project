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

## Project Structure

```
olist-elt-project/
├── data/
│   ├── raw/                 # Olist CSV files (not tracked in Git)
│   └── database/            # olist.db, created by the pipeline (not tracked)
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