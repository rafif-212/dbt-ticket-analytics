"""Load the cleaned ticket data into the local DuckDB warehouse.

The Parquet files come from the Ticket-analytics-pipeline repo, pinned to one
commit so a later change there can't silently change what this project builds
on. Each file is loaded as-is into the `raw` schema; every rename, cast and
check happens in dbt.

Usage:
    python load_data.py                     # download from GitHub
    python load_data.py --source-dir PATH   # use a local copy instead
"""

import argparse
import urllib.request
from pathlib import Path

import duckdb

SOURCE_COMMIT = "944fa30b1d912a08bb2e5004a367525b58f4860b"
SOURCE_URL = (
    "https://raw.githubusercontent.com/rafif-212/Ticket-analytics-pipeline/"
    f"{SOURCE_COMMIT}/Data/Clean"
)
TABLES = ["tickets_clean", "nz_calendar", "nz_holiday_days", "daily_workload"]

PROJECT_DIR = Path(__file__).resolve().parent
DOWNLOAD_DIR = PROJECT_DIR / "data"
DATABASE = PROJECT_DIR / "ticket_analytics.duckdb"


def locate(table: str, source_dir: Path | None) -> Path:
    if source_dir is not None:
        path = source_dir / f"{table}.parquet"
        if not path.exists():
            raise SystemExit(f"Missing {path}")
        return path

    path = DOWNLOAD_DIR / f"{table}.parquet"
    if not path.exists():
        DOWNLOAD_DIR.mkdir(exist_ok=True)
        print(f"Downloading {table}.parquet")
        urllib.request.urlretrieve(f"{SOURCE_URL}/{table}.parquet", path)
    return path


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "--source-dir",
        type=Path,
        help="Folder holding the Parquet files, if not downloading them",
    )
    args = parser.parse_args()

    con = duckdb.connect(str(DATABASE))
    con.execute("create schema if not exists raw")
    for table in TABLES:
        path = locate(table, args.source_dir).as_posix().replace("'", "''")
        con.execute(
            f"create or replace table raw.{table} as select * from read_parquet('{path}')"
        )
        rows = con.execute(f"select count(*) from raw.{table}").fetchone()[0]
        print(f"raw.{table}: {rows:,} rows")
    con.close()


if __name__ == "__main__":
    main()
