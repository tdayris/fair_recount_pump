# coding: utf-8

"""This script searches for zsdt tables and concatenates them"""

import argparse
import collections.abc
import io
import multiprocessing
import os
import pathlib
import polars
import pretty_errors
import rich_argparse
import session_info
import zstandard

from loguru import logger

def load_zstd_table(path: pathlib.Path, enumeration: str = "", schema: dict[str, polars.PolarsDataType], keep_gene_names: bool = False, suffix: str = ".all.tsv.zst") -> polars.DataFrame:
    """
    Load a zdst table, keep the counts column (the one with the highest counts)
    and rename it with sample name.
    """
    logger.info(f"{enumeration} Loading {str(path.resolve())}")
    sample_name: str = str(path.name)[: -len(suffix)]
    abs_path: str = str(path.resolve())

    # Load the table
    with open(abs_path, "rb") as compressed_file_stream:
        with zstandard.ZstdDecompressor().stream_reader(compressed_file_stream) as uncompressed_stream:
            table_stream = io.TextIOWrapper(uncompressed_stream)
            df: polars.DataFrame = polars.read_csv(
                uncompressed_stream,
                separator="\t",
                schema=schema, 
                low_memory=True, 
                has_header=False,
            )

    # Find counts column
    sums: dict[str, int] = df.select(polars.col(list(schema.keys())[1:]).sum()).row(0, named=True)
    max_col: str = max(sums.keys(), key=sums.get)
    logger.debug(f"Keeping {max_col} from {sample_name}")

    # Select index and that column, renaming the integer column
    if keep_gene_names:
        df = df.select(polars.col(list(schema.keys())[0]), polars.col(max_col).alias(sample_name))
    else:
        df = df.select(polars.col(max_col).alias(sample_name))

    logger.debug(df.head())
    return df


def load_parallel(paths: list[pathlib.Path], cores: int = 1) -> list[polars.DataFrame]:
    """Load multiple files in parallel"""
    load_function = {
        "bamcount": load_zstd_bamcount,
        "feature_count": load_zstd_featurecount,
    }
    ctx = multiprocessing.get_context("spawn")
    with ctx.Pool(processes=cores) as pool:
        nb_path: int = len(paths)
        enum_paths = [(p, f"{i+1}/{nb_path}") for i, p in enumerate(paths)]
        return pool.starmap(load_zstd_bamcount, enum_paths)


def search_zstd_tables(
    path: pathlib.Path,
    source_programm: str = "feature_count",
) -> collections.abc.Generator[pathlib.Path, None, None]:
    """Recursively search zsdt tables and yeidls them"""
    logger.debug(f"Searching {source_programm} tables into {str(path.resolve())}")
    extensions: dict[str, str] = {
        "feature_count": tuple([".gene_fc_count_all.tsv.zst"]),
        "bamcount": tuple([".all.tsv.zst"]),
    }
    for child in path.iterdir():
        if child.is_dir():
            yield from search_zstd_tables(child, source_programm)
        elif child.is_file() and str(child.name).endswith(extensions[source_programm]):
            yield child


def main() -> None:
    parser = argparse.ArgumentParser(
        formatter_class=rich_argparse.ArgumentDefaultsRichHelpFormatter,
        description=__doc__,
    )

    parser.add_argument(
        "-i", "--input_directory",
        help="Path to input directory",
        default=os.getcwd(),
        type=str,
    )
    parser.add_argument(
        "-o", "--output_table",
        help="Path to gzipped output table",
        default=f"{os.getcwd()}/Counts.csv.gz",
        type=str,
    )
    parser.add_argument(
        "-s", "--source",
        help="Source programm used to produce tables",
        default="bamcount",
        choices={"feature_count", "bamcount"},
        type=str,
    )
    parser.add_argument(
        "-t", "--threads",
        help="Maximum number of threads used",
        default=multiprocessing.cpu_count(),
        type=int,
    )
    parser.add_argument(
        "-f", "--force",
        help="Overwrite existing result file",
        action="store_true",
    )
    parser.add_argument(
        "-v", "--verbose",
        help="Increase verbosity",
        action="store_true",
    )
    args = parser.parse_args()
    logger.info("Command line parsed")
    # Check existing output table
    output_table: str = str(pathlib.Path(args.output_table))
    if not args.force and pathlib.Path(args.output_table).exists():
        raise FileExistsError(
            f"{output_table} already exists. "
            "Remove it, or use `-f|--force` argument"
        )

    # List of zstd-compressed CSV files
    logger.info(f"Looking for {args.source} tables in {args.input_directory}")
    paths: list[pathlib.Path] = list(
        search_zstd_tables(
            path=pathlib.Path(args.input_directory),
            source_programm=args.source,
        ),
    )
    logger.debug(f"Found {len(paths)} tables to process.")

    # Load all tables, it should take roughly 140Mb per table.
    dfs: list[polars.DataFrame] = [load_zstd_bamcount(paths[0], enumeration=f"1/{len(paths)}", keep_gene_names=True,)]
    #dfs: list[polars.DataFrame] = load_parallel(paths=paths, cores=args.threads)
    dfs: list[polars.DataFrame] = dfs + [load_zstd_bamcount(p, "") for p in paths[1:]]
    logger.debug("Data loaded")

    # Merge side-by-side (same row count, same order, different column names)
    # Since all tables are build with same genome assembly and same tool
    merged: polars.DataFrame = polars.concat(dfs, how="horizontal")
    logger.info("Data merged")

    # Save gzipped results
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
