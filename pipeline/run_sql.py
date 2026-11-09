"""Run a SQL file from the sql/ directory against the SQLite database.

Every statement in the file is executed in order. Statements that return
rows (for example SELECT queries) have their results printed.

Usage:
    python pipeline/run_sql.py 01_sanity_checks.sql
"""

import sqlite3
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
SQL_DIR = PROJECT_ROOT / "sql"
DB_PATH = PROJECT_ROOT / "data" / "database" / "olist.db"


def split_statements(sql_text: str) -> list[str]:
    """Split SQL text into complete statements."""
    statements = []
    buffer = ""
    for line in sql_text.splitlines(keepends=True):
        buffer += line
        if sqlite3.complete_statement(buffer):
            statements.append(buffer.strip())
            buffer = ""
    if buffer.strip():
        statements.append(buffer.strip())
    return statements


def run_sql_file(conn: sqlite3.Connection, sql_path: Path) -> None:
    """Execute all statements in a SQL file and print any returned rows."""
    sql_text = sql_path.read_text(encoding="utf-8")
    statements = split_statements(sql_text)
    print(f"File: {sql_path.name} | Statements found: {len(statements)}")

    for number, statement in enumerate(statements, start=1):
        cursor = conn.execute(statement)
        if cursor.description is not None:
            rows = cursor.fetchall()
            columns = [column[0] for column in cursor.description]
            print(f"\nStatement {number}: {len(rows)} row(s)")
            print(" | ".join(columns))
            print("-" * 60)
            for row in rows:
                print(" | ".join(str(value) for value in row))
        else:
            print(f"\nStatement {number}: executed (no result set)")
    conn.commit()


def main() -> None:
    """Parse the command line argument and run the requested SQL file."""
    if len(sys.argv) != 2:
        print("Usage: python pipeline/run_sql.py <sql_file_name>")
        sys.exit(1)

    sql_path = (SQL_DIR / sys.argv[1]).resolve()
    if sql_path.parent != SQL_DIR.resolve() or not sql_path.is_file():
        print(f"ERROR: SQL file not found in the sql directory: {sys.argv[1]}")
        sys.exit(1)

    if not DB_PATH.exists():
        print("ERROR: Database not found. Run pipeline/load_raw.py first.")
        sys.exit(1)

    conn = sqlite3.connect(DB_PATH)
    try:
        run_sql_file(conn, sql_path)
    finally:
        conn.close()


if __name__ == "__main__":
    main()