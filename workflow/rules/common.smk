import csv
import os.path
import pandas


configfile: "config/config.yaml"


# Load and check samples properties table
def load_table(path: str) -> pandas.DataFrame:
    """
    Load a table in memory, automatically inferring column separators

    Parameters:
    path (str): Path to the table to be loaded

    Return
    (pandas.DataFrame): The loaded table
    """
    with open(path, "r") as table_stream:
        dialect: csv.Dialect = csv.Sniffer().sniff(table_stream.readline())
        table_stream.seek(0)

    # Load table
    table: pandas.DataFrame = pandas.read_csv(
        path,
        sep=dialect.delimiter,
        header=0,
        index_col=None,
        comment="#",
        dtype=str,
    )

    # Remove empty lines
    table = table.where(table.notnull(), None)

    return table

def used_genomes(
    genomes: pandas.DataFrame, samples: pandas.DataFrame | None = None
) -> tuple[str]:
    """
    Reduce the number of genomes to download to the strict minimum
    """
    if samples is None:
        return genomes

    return genomes.loc[
        genomes.species.isin(samples.species.tolist())
        & genomes.build.isin(samples.build.tolist())
        & genomes.release.isin(samples.release.tolist())
    ]

def load_genomes(
    path: str | None = None, samples: pandas.DataFrame | None = None
) -> pandas.DataFrame:
    """
    Load genome file, build it if genome file is missing and samples is not None.

    Parameters:
    path    (str)               : Path to genome file
    samples (pandas.DataFrame)  : Loaded samples
    """
    if path is not None:
        genomes: pandas.DataFrame = load_table(path)

        if samples is not None:
            genomes = used_genomes(genomes, samples)
        return genomes

    elif samples is not None:
        return samples[["species", "build", "release"]].drop_duplicates(
            ignore_index=True
        )

    raise ValueError(
        "Provide either a path to a genome file, or a loaded samples table"
    )


# Load and check samples properties tables
try:
    if (samples is None) or samples.empty():
        sample_table_path: str = config.get("samples", "config/samples.csv")
        samples: pandas.DataFrame = load_table(sample_table_path)
except NameError:
    sample_table_path: str = config.get("samples", "config/samples.csv")
    samples: pandas.DataFrame = load_table(sample_table_path)


# Load and check genomes properties table
genomes_table_path: str = config.get("genomes", "config/genomes.csv")
try:
    if (genomes is None) or genomes.empty:
        genomes: pandas.DataFrame = load_genomes(genomes_table_path, samples)
except NameError:
    genomes: pandas.DataFrame = load_genomes(genomes_table_path, samples)


def lookup_config(
    dpath: str, default: str | None = None, config: dict[str, Any] = config
) -> str:
    """
    Run lookup function with default parameters in order to search a key in configuration and return a default value
    """
    value: str | None = default

    try:
        value = lookup(dpath=dpath, within=config)
    except LookupError:
        value = default
    except WorkflowError:
        value = default

    return value


def lookup_genomes(
    wildcards: snakemake.io.Wildcards,
    key: str,
    default: str | list[str] | None = None,
    genomes: pandas.DataFrame = genomes,
    query: str = "species == '{wildcards.species}' & build == '{wildcards.build}' & release == '{wildcards.release}'",
) -> str:
    """
    Run lookup function with default parameters in order to search user-provided sequence/annotation files
    """
    query: str = query.format(wildcards=wildcards)
    query_result: str | float = getattr(
        lookup(query=query, within=genomes), key, default
    )
    if (query_result != query_result) or (query_result is None) or (query_result == ""):
        # Then the result of the query is nan
        return default
    return query_result


def get_sample_species(wildcards: snakemake.io.Wildcards, samples: pandas.DataFrame = samples,) -> str:
    """Return the species related to a given sample"""
    return samples.loc[str(wildcards.sample)].to_dict()["species"]


def is_human(wildcards: snakemake.io.Wildcards, samples: pandas.DataFrame = samples,) -> bool:
    """Return true if a sample belongs to homo_sapiens species"""
    return str(get_sample_species(wildcards, samples)).lower() == "homo_sapiens"


samples_tpl: tuple[str] = tuple(samples.sample_id)
stream_tpl: tuple[str] = (
    "1",
    "2",
)
bamcount_content_tpl: tuple[str] = (
    "alts",
    "auc",
    "frags",
    "all",
    "unique",
    "jxs",
    "all",
    "unique",
)
gene_exon_tpl: tuple[str, ...] = (
    "gene",
    "exon",
)
unique_all_tpl: tuple[str, ...] = (
    "unique",
    "all",
)

junctions: list[str] = []
bamcount: list[str] = []
featurecount: list[str] = []
mapping: list[str] = []
for sample in samples_tpl:
    junctions.append(f"results/{sample}/{sample}.SJ.out.tab.zst")
    junctions.append(f"results/{sample}/{sample}.Chimeric.out.sam.zst")
    junctions.append(f"results/{sample}/{sample}.jx_bed.zst")

    for content in bamcount_content_tpl:
        bamcount.append(f"results/{sample}/{sample}.{content}.tsv.zst")

    for gene_exon in gene_exon_tpl:
        for unique_all in unique_all_tpl:
            featurecount.append(
                f"results/{sample}/{sample}.{gene_exon}_fc_count_{unique_all}.tsv.zst"
            )

    mapping.append(f"results/{sample}/{sample}.cram")

expected_results: dict[str, list[str]] = {
    "junctions": junctions,
    "bamcount": bamcount,
    "fqchk": ["results/seqtk_fqchk.tsv"],
    "featurecount": featurecount,
    "mapping": mapping,
}


wildcard_constraints:
    sample=r"|".join(samples_tpl),
    stream=r"|".join(stream_tpl),
    content=r"|".join(bamcount_content_tpl),
    unique_all=r"|".join(unique_all_tpl),
    gene_exon=r"|".join(gene_exon_tpl),


def get_targets():
    return expected_results
