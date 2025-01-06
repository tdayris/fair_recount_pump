import os.path
import pandas
import pathlib


def get_targets(samples: str | pathlib.Path) -> dict[str, list[str] | str]:
    """
    Provide a mapping of all expected output files
    """
    if isinstance(samples, str):
        samples: pathlib.PosixPath = pathlib.Path(samples)
    samples_df: pandas.DataFrame = pandas.read_csv(
        samples,
        sep=",",
        header=0,
        index_col=None,
    )
    samples_tpl: tuple[str] = tuple(samples.sample_id)
    stream_tpl: tuple[str] = ("1", "2", )
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
            for uniq_all in uniq_all_tpl:
                featurecount.append(
                    f"results/{sample}/{sample}.{gene_exon}_fc_count_{uniq_all}.tsv.zst"
                )

        mapping.append(f"result/{sample}/{sample}.cram")

    return {
        "junctions": junctions,
        "bamcount": bamcount,
        "fqchk": "results/seqtk_fqchk.tsv",
        "featurecount": featurecount,
        "mapping": mapping,
    }