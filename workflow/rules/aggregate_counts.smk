rule aggregate_bamcounts:
    """aggregate bamcounts for future cbioportal upload"""
    input:
       counts=expand(
            "results/{sample}/{sample}.{content}.tsv.zst",
            sample=samples_tpl,
            allow_missing=True,
        ),
        script_path=workflow.source_path("../scripts/merge_zdst_read_counts.py"),
    output:
        "results/bamcount.{content}.tsv.gz",
    threads: 6
    params:
        extra="-s 'bamcount'",
    conda:
        "../envs/aggregation.yaml"
    shell:
        "python3 {input.script_path:q} "
        "{params.extra} -i {params.input_dir:q} "
        "-o {params.output[0]:q} > {log:q} 2>&1 "


use rule aggregate_bamcounts as aggregate_featurecounts with:
    """aggregate featurecount for future cbioportal upload"""
    input:
       counts=expand(
            "results/{sample}/{sample}.{gene_exon}_fc_count_{unique_all}.tsv.zst",
            sample=samples_tpl,
            allow_missing=True,
        ),
        script_path=workflow.source_path("../scripts/merge_zdst_read_counts.py"),
    output:
        "results/bamcount.{gene_exon}.{unique_all}.tsv.gz",
    params:
        extra="-s 'featurecount'",
        
