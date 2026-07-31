# coding: utf-8

"""This script searches for zsdt tables and concatenates them"""

import argparse
import collections.abc
import io
import os
import pathlib
import polars
import pretty_errors
import rich_argparse
import sklearn.preprocessing
import session_info
import zstandard

from loguru import logger


def load_zstd_featurecount(
    path: pathlib.Path, enumeration: str = "", keep_gene_names: bool = False
) -> polars.DataFrame:
    """
    Load a zdst table, keep the counts column and rename it with sample name.
    """
    logger.info(f"{enumeration} Loading {str(path.resolve())}")
    schema: dict[str, polars.PolarsDataType] = {
        "Geneid": polars.Utf8,
        "Chr": polars.Utf8,
        "Start": polars.UInt32,
        "End": polars.UInt32,
        "Strand": polars.Categorical,
        "Length": polars.UInt32,
        str(path): polars.UInt32,
    }
    extensions: set[str] = {
        ".exon_fc_count_all.tsv.zst",
        ".exon_fc_count_unique.tsv.zst",
        ".gene_fc_count_all.tsv.zst",
        ".gene_fc_count_unique.tsv.zst",
    }
    suffix: str = ""
    for s in extensions:
        if path.endswith(s):
            suffix = s
            break
    else:
        raise ValueError(
            "Could not find proper file extention for " f"{path} among {extensions}"
        )

    sample_name: str = str(path.name)[: -len(suffix)]
    abs_path: str = str(path.resolve())

    # Load the table
    with open(abs_path, "rb") as compressed_file_stream:
        with zstandard.ZstdDecompressor().stream_reader(
            compressed_file_stream
        ) as uncompressed_stream:
            table_stream = io.TextIOWrapper(uncompressed_stream)
            df: polars.DataFrame = polars.read_csv(
                uncompressed_stream,
                separator="\t",
                schema=schema,
                low_memory=True,
            )

    # Compute zscore
    df = df.with_columns(
        zscore=(
            (polars.col(str(path)).cast(polars.Float64) - polars.col(str(path)).mean())
            / polars.col(str(path)).std()
        )
    )

    # Select index and that column, renaming the integer column
    if keep_gene_names:
        df = df.select(
            polars.col(list(schema.keys())[0]).alias("Gene"),
            polars.col("zscore").alias(sample_name),
        )
    else:
        df = df.select(polars.col("zscore").alias(sample_name))

    logger.debug(df.head())
    return df


def load_zstd_bamcount(
    path: pathlib.Path,
    enumeration: str = "",
    keep_gene_names: bool = False,
    suffix: str = ".all.tsv.zst",
) -> polars.DataFrame:
    """
    Load a zdst table, keep the counts column and rename it with sample name.
    """
    logger.info(f"{enumeration} Loading {str(path.resolve())}")
    extensions: set[str] = {
        ".all.tsv.zst",
        ".alts.tsv.zst",
        ".auc.tsv.zst",
        ".frags.tsv.zst",
        ".jx_bed.tsv.zst",
        ".jxs.tsv.zst",
        ".unique.tsv.zst",
    }
    suffix: str = ""
    for s in extensions:
        if str(path.name).endswith(s):
            suffix = s
            break
    else:
        raise ValueError(
            "Could not find proper file extension for" f" {path} among {extension}"
        )
    sample_name: str = str(path.name)[: -len(suffix)]
    abs_path: str = str(path.resolve())

    schema: dict[str, polars.PolarsDataType] = {
        "Gene": polars.Utf8,
        "Column1": polars.UInt32,
        "Length": polars.UInt32,
        "Column3": polars.UInt32,
    }

    # Load the table
    with open(abs_path, "rb") as compressed_file_stream:
        with zstandard.ZstdDecompressor().stream_reader(
            compressed_file_stream
        ) as uncompressed_stream:
            table_stream = io.TextIOWrapper(uncompressed_stream)
            df: polars.DataFrame = polars.read_csv(
                uncompressed_stream,
                separator="\t",
                schema=schema,
                low_memory=True,
                has_header=False,
            )

    # Compute zscore
    scaler = sklearn.preprocessing.StandardScaler()
    df = df.with_columns(
        polars.Series("zscore", scaler.fit_transform(df[["Column3"]].to_numpy())[:, 0])
    )
    print(df)

    col = "Column1"
    # Check raw stats in Polars
    print("Polars stats:")
    print(df.select(
        polars.col(col).mean().alias("mean"),
        polars.col(col).std().alias("std"),
        polars.col(col).n_unique().alias("n_unique"),
    ))

    # Prepare for sklearn
    X = df[[col]].to_numpy()  # shape (n_samples, 1)
    print("\nNumPy shape:", X.shape)
    print("NumPy mean, std:", X.mean(), X.std(ddof=1))

    # Scale
    X_scaled = ( polars.col(col) - polars.col(col).mean() ) / polars.col(col).std()

    print("\nScaled first 10 values:")
    print(X_scaled.head(20))

    print("\nScaler params:")
    print("mean_:", scaler.mean_)
    print("scale_:", scaler.scale_)
    

    # Select index and that column, renaming the integer column
    if keep_gene_names:
        df = df.select(
            polars.col(list(schema.keys())[0]), polars.col("zscore").alias(sample_name)
        )
    else:
        df = df.select(polars.col("zscore").alias(sample_name))

    logger.debug(df.head())
    return df


def search_zstd_tables(
    path: pathlib.Path,
    source_programm: str = "feature_count",
) -> collections.abc.Generator[pathlib.Path, None, None]:
    """Recursively search zsdt tables and yeidls them"""
    logger.debug(f"Searching {source_programm} tables into {str(path.resolve())}")
    extensions: dict[str, str] = {
        "feature_count": tuple([".gene_fc_count_all.tsv.zst"]),
        "bamcount": tuple([".all.tsv.zst"]),
        "feature_count_exon_all": tuple([".exon_fc_count_all.tsv.zst"]),
        "feature_count_exon_unique": tuple([".exon_fc_count_unique.tsv.zst"]),
        "feature_count_gene_all": tuple([".gene_fc_count_all.tsv.zst"]),
        "feature_count_gene_unique": tuple([".gene_fc_count_unique.tsv.zst"]),
        "bamcount_all": tuple([".all.tsv.zst"]),
        "bamcount_alts": tuple([".alts.tsv.zst"]),
        "bamcount_auc": tuple([".auc.tsv.zst"]),
        "bamcount_frags": tuple([".frags.tsv.zst"]),
        "bamcount_jx_bed": tuple([".jx_bed.tsv.zst"]),
        "bamcount_jxs": tuple([".jxs.tsv.zst"]),
        "bamcount_unique": tuple([".unique.tsv.zst"]),
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
        "-i",
        "--input_directory",
        help="Path to input directory",
        default=os.getcwd(),
        type=str,
    )
    parser.add_argument(
        "-o",
        "--output_table",
        help="Path to gzipped output table",
        default=f"{os.getcwd()}/Counts.csv.gz",
        type=str,
    )
    parser.add_argument(
        "-s",
        "--source",
        help="Source programm used to produce tables",
        default="bamcount_all",
        choices={
            "feature_count_exon_all",
            "feature_count_exon_unique",
            "feature_count_gene_all",
            "feature_count_gene_unique",
            "bamcount_all",
            "bamcount_alts",
            "bamcount_auc",
            "bamcount_frags",
            "bamcount_jx_bed",
            "bamcount_jxs",
            "bamcount_unique",
        },
        type=str,
    )
    parser.add_argument(
        "-f",
        "--force",
        help="Overwrite existing result file",
        action="store_true",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        help="Increase verbosity",
        action="store_true",
    )
    args = parser.parse_args()
    logger.info("Command line parsed")
    # Check existing output table
    output_table: str = str(pathlib.Path(args.output_table))
    if not args.force and pathlib.Path(args.output_table).exists():
        raise FileExistsError(
            f"{output_table} already exists. " "Remove it, or use `-f|--force` argument"
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
    dfs: list[polars.DataFrame] = [
        load_zstd_bamcount(
            paths[0],
            enumeration=f"1/{len(paths)}",
            keep_gene_names=True,
        )
    ]
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
