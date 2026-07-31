# coding: utf-8

"""This script searches for zsdt tables and concatenates them"""

import argparse
import collections.abc
import multiprocessing
import os
import pathlib
import polars
import pretty_errors
import rich_argparse
import session_info
import xopen

from loguru import logger


def load_zstd_table(path: pathlib.Path, enumeration: str = "") -> polars.DataFrame:
    """
    Load a zdst table, keep the counts column (the one with the highest counts)
    and rename it with sample name.
    """
    logger.info(f"{enumeration} Loading {str(path.resolve())}")
    sample_name: str = str(path.name)[: -len(".zdst")]
    abs_path: str = str(path.resolve())

    # Get header names and prepare best casting type
    with xopen.xopen(abs_path, "rt") as f:
        header_line = f.readline()
    header = header_line.strip().split("\t")

    index_col: str = header[0]
    int_cols: list[str] = header[1:]

    schema: dict[str, polars.PolarsDataType] = {index_col: polars.Utf8}
    for col in int_cols:
        schema[col] = polars.UInt32

    # Load the table
    with xopen.xopen(abs_path, "rt") as f:
        df = polars.read_csv(f, schema=schema, low_memory=True)

    # Find counts column
    sums: dict[str, int] = df.select(polars.col(int_cols).sum()).row(0, named=True)
    max_sum: int = max(sums.values())
    max_col: str = max_cols[0]
    logger.debug(f"Keeping {max_col} from {sample_name}")

    # Select index and that column, renaming the integer column
    return df.select(polars.col(index_col), polars.col(max_col).alias(sample_name))


def load_parallel(paths: list[pahtlib.Path], cores: int = 1) -> list[polars.DataFrame]:
    """Load multiple files in parallel"""
    ctx = mp.get_context("spawn")
    with ctx.Pool(processes=cores) as pool:
        return pool.map(load_zstd_table, paths)


def search_zstd_tables(
    path: pathlib.Path,
) -> collections.abc.Generator[pathlib.Path, None, None]:
    """Recursively search zsdt tables and yeidls them"""
    logger.debug(f"Searching tables into {str(path.resolve())}")
    for child in path.iterdir():
        if child.is_directory():
            yield from search_zstd_tables(child)
        elif child.is_file() and str(child.name).endswith("_fc_count_all.tsv.zst"):
            yield child


def main() -> None:
    parser = argparse.ArgumentParser(
        formatter_class=rich_argparse.ArgumentDefaultsRichHelpFormatter,
        description=__doc__,
    )

    parser.add_argument(
        "input_directory",
        help="Path to input directory",
        default=os.getcwd(),
        type=str,
    )
    parser.add_argument(
        "output_table",
        help="Path to gzipped output table",
        default=f"{os.getcwd()}/Counts.csv.gz",
        type=str,
    )
    args = parser.parse_args()
    # List of zstd-compressed CSV files
    paths: list[pathlib.Path] = list(
        search_zstd_tables(path=pathlib.Path(args.input_directory))
    )
    logger.debug(f"Found {len(dfs)} tables to process.")

    # Load all tables, it should take roughly 140Mb per table.
    dfs: list[polars.DataFrame] = load_parallel(paths=paths)
    logger.debug("Data loaded")

    # Merge side-by-side (same row count, same order, different column names)
    # Since all tables are build with same genome assembly and same tool
    merged: polars.DataFrame = polars.concat(dfs, how="horizontal")
    logger.info("Data merged")

    # Save gzipped results
    output_table: str = str(pathlib.Path(args.output_table))
    merged.write_csv(
        output_table,
        compression="gzip",
        compression_level=9,
    )
    logger.info(f"Table saved at {output_table}")
    session_info.show()
    logger.info("Process over.")


if __name__ == "__main__":
    main()
