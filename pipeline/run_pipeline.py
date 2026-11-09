"""Run the complete Olist ELT pipeline with a single command.

Steps, in order:
    1. Load the raw CSV files into SQLite (pipeline/load_raw.py).
    2. Run each SQL transformation file from the sql/ directory.

The pipeline stops immediately if any step fails.

Usage:
    python pipeline/run_pipeline.py
"""

import subprocess
import sys
from pathlib import Path

PIPELINE_DIR = Path(__file__).resolve().parent

# SQL files are executed in this fixed order.
SQL_FILES = [
    "01_sanity_checks.sql",
    "02_stg_orders.sql",
    "03_stg_items_reviews.sql",
    "04_analytics_orders.sql",
]


def run_step(description: str, command: list[str]) -> None:
    """Run one pipeline step and stop the pipeline if it fails."""
    print(f"\n=== {description} ===")
    result = subprocess.run(command)
    if result.returncode != 0:
        print(f"\nPipeline stopped: step failed -> {description}")
        sys.exit(result.returncode)


def main() -> None:
    """Execute the load step followed by all SQL transformation steps."""
    python = sys.executable

    run_step(
        "Load raw CSV files into SQLite",
        [python, str(PIPELINE_DIR / "load_raw.py")],
    )

    for sql_file in SQL_FILES:
        run_step(
            f"Run SQL file: {sql_file}",
            [python, str(PIPELINE_DIR / "run_sql.py"), sql_file],
        )

    print("\nPipeline completed successfully.")


if __name__ == "__main__":
    main()