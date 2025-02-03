import os.path
import pandas


configfile: "config/config.yaml"


samples: pandas.DataFrame = pandas.read_csv(
    config.get("samples", "config/samples.csv"),
    sep=",",
    header=0,
    index_col=None,
)
samples_tpl: tuple[str] = tuple(samples.sample_id)
stream_tpl: tuple[str] = (
    "1",
    "2",
)
bamcount_content_tpl: tuple[str] = (
    ".alts",
    ".auc",
    ".frags",
    ".all",
    ".unique",
    ".jxs",
    ".all",
    ".unique",
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
        bamcount.append(f"result/{sample}/{sample}.{content}.tsv.zst")

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
    samples=r"|".join(samples_tpl),
    stream=r"|".join(stream_tpl),
    content=r"|".join(bamcount_content_tpl),
    unique_all=r"|".join(unique_all_tpl),
    gene_exon=r"|".join(gene_exon),


def get_targets():
    return expected_results
