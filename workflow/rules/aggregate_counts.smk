rule extract_counts_from_fc_count_genes_unique:
    input:
        "results/{sample}/{sample}.gene_fc_count_unique.tsv.zst",
    output:
        temp("tmp/extract_counts_from_fc_count_genes_unique/{sample}.counts.tsv"),
    threads: 3
    resources:
        mem_mb=lambda wildcards, attempt: min(attempt * 500, 1500),
        runtime=lambda wildcards, attempt: min(attempt * 15, 60),
        tmpdir="tmp",
    log:
        "logs/extract_counts_from_fc_count_genes_unique/{sample}.log"
    benchmark:
        "benchmark/extract_counts_from_fc_count_genes_unique/{sample}.tsv",
    params:
        zstd="--decompress --stdout --force --keep",
        cut="-f7",
        sd=lambda wildcards: f"'tmp/sort/samtools_sort/' ''",
    conda:
        "../envs/aggregation.yaml"
    shell:
        "( zstd {params.zstd} {input:q} | "
        "  cut {params.cut} | "
        "  sd {params.sd} ) > {output:q} 2> {log:q}"


rule extract_gene_ids_from_fc_count_genes_unique:
    input:
        expand("results/{sample}/{sample}.gene_fc_count_unique.tsv.zst", sample=samples_tpl[0],),
    output:
        temp("tmp/extract_gene_ids_from_fc_count_genes_unique.tsv"),
    threads: 1
    resources:
        mem_mb=lambda wildcards, attempt: min(attempt * 500, 1500),
        runtime=lambda wildcards, attempt: min(attempt * 15, 60),
        tmpdir="tmp",
    log:
        "logs/extract_gene_ids_from_fc_count_genes_unique.log",
    benchmark:
        "benchmark/extract_gene_ids_from_fc_count_genes_unique.tsv",
    params:
        zstd="--decompress --stdout --force --keep",
        cut="-f1",
    conda:
        "../envs/aggregation.yaml"
    shell:
        "( zstd {params.zstd} {input:q} | cut {params.cut} ) "
        "> {output:q} 2> {log:q}"


rule xan_aggregate_counts:
    input:
        "tmp/extract_gene_ids_from_fc_count_genes_unique.tsv",
        expand(
            "tmp/extract_counts_from_fc_count_genes_unique/{sample}.counts.tsv",
            sample=samples_tpl,
        ),
    output:
        "results/raw_aggregated_counts.csv",
    threads: 2
    resources:
        mem_mb=lambda wildcards, attempt: min(attempt * 10000, 100000),
        runtime=lambda wildcards, attempt: min(attempt * 120, 60 * 24 * 6 - 1),
        tmpdir="tmp",
    log:
        "logs/xan_aggregate_counts.log",
    benchmark:
        "benchmark/xan_aggregate_counts.tsv",
    params:
        cat_cols="",
        fmt="--tabs",
    conda:
        "../envs/aggregation.yaml"
    shell:
        "( xan cat cols {params.cat_cols} {input} | "
        "  xan fmt {params.fmt} )"
        "  > {output:q} 2> {log:q} "

