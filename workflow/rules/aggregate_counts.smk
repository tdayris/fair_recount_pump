rule extract_counts_from_fc_count_genes_unique:
    input:
        "results/{sample}/{sample}.gene_fc_count_unique.tsv.zst",
    output:
        temp("tmp/extract_counts_from_fc_count_genes_unique/{sample}.counts.tsv"),
    threads: 1
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
        cut="-f1,7",
        sd=lambda wildcards: f"'tmp/sort/samtools_sort/{sample}.bam' 'counts'"
    shell:
        "( zstd {params.zstd} {input:q} | "
        "  cut {params.cut} | "
        "  sd {params.sd} ) > {output:q} 2> {log:q}"


rule aggregate_counts:
    input:
        expand(
            "tmp/extract_counts_from_fc_count_genes_unique/{sample}.counts.tsv",
            sample=samples_tpl,
        ),
    output:
        "results/aggregated_counts.csv",
    threads: 1
    resources:
        mem_mb=lambda wildcards, attempt: min(attempt * 10000, 100000),
        runtime=lambda wildcards, attempt: min(attempt * 120, 60 * 24 * 6 - 1),
        tmpdir="tmp",
    log:
        "logs/aggregated_counts.log",
    benchmark:
        "benchmark/aggregated_counts.tsv",
    params:
        extra="--full --sorted --delimiter ',' --drop-key right  0",
    shell:
        "xan join {params.extra} --output {output:q} > {log:q} 2>&1"
