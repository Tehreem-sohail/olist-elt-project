"""Extract and load step of the Olist ELT pipeline.

Loads the nine raw Olist CSV files from data/raw into the SQLite database
data/database/olist.db without any cleaning or transformation. All columns
are stored as text; type casting and cleaning are performed later in SQL.

Usage:
    python pipeline/load_raw.py
"""

import sqlite3
import sys
from pathlib import Path

import pandas as pd

PROJECT_ROOT = Path(__file__).resolve().parent.parent
RAW_DIR = PROJECT_ROOT / "data" / "raw"
DB_DIR = PROJECT_ROOT / "data" / "database"
DB_PATH = DB_DIR / "olist.db"

# Fixed list of source files. Each table is named after its CSV file.
CSV_FILES = [
    "olist_customers_dataset.csv",
    "olist_geolocation_dataset.csv",
    "olist_order_items_dataset.csv",
    "olist_order_payments_dataset.csv",
    "olist_order_reviews_dataset.csv",
    "olist_orders_dataset.csv",
    "olist_products_dataset.csv",
    "olist_sellers_dataset.csv",
    "product_category_name_translation.csv",
]


def check_source_files() -> None:
    """Exit with an error message if any expected CSV file is missing."""
    missing = [name for name in CSV_FILES if not (RAW_DIR / name).exists()]
    if missing:
        print("ERROR: The following files were not found in data/raw:")
        for name in missing:
            print(f"  - {name}")
        sys.exit(1)


def load_csv_to_table(conn: sqlite3.Connection, filename: str) -> None:
    """Load one CSV file into a raw SQLite table, replacing any existing table."""
    table = Path(filename).stem
    # Reading every column as text keeps the raw data unchanged.
    df = pd.read_csv(RAW_DIR / filename, dtype=str)
    df.to_sql(table, conn, if_exists="replace", index=False, chunksize=50000)
    row_count = conn.execute(f'SELECT COUNT(*) FROM "{table}"').fetchone()[0]
    print(f"{table}: CSV rows={len(df)}, table rows={row_count}")


def main() -> None:
    """Load all raw CSV files into the SQLite database."""
    check_source_files()
    DB_DIR.mkdir(parents=True, exist_ok=True)

    conn = sqlite3.connect(DB_PATH)
    try:
        for filename in CSV_FILES:
            load_csv_to_table(conn, filename)
        conn.commit()
    finally:
        conn.close()

    print(f"Load complete. Database: {DB_PATH}")


if __name__ == "__main__":
    main()