rule exon_fc_count_unique:
    """feature count on unique exons"""
    input:
        bam="tmp/sort/samtools_sort/{sample}.bam",
        bai="tmp/sort/samtools_sort/{sample}.bam.bai",
        gtf=branch(
            is_human,
            then=genomes.loc["homo_sapiens"]["gtf"],
            otherwise=genomes.loc["mus_musculus"]["gtf"],
        ),
    output:
        tsv=temp(
            "tmp/feature_count/exon_fc_count_unique/{sample}.exon_fc_count_unique.tsv"
        ),
        summary=temp(
            "tmp/feature_count/exon_fc_count_unique/{sample}.exon_fc_count_unique.tsv.summary"
        ),
    log:
        "logs/feature_count/exon_fc_count_unique/{sample}.log",
    benchmark:
        "benchmark/feature_count/exon_fc_count_unique_{sample}.tsv",
    conda:
        "../envs/subread.yaml"
    threads: 10
    params:
        extra="-Q 10 -O -f -p",
    shell:
        "featureCounts {params.extra} "
        "-T {threads} "
        "-a {input.gtf:q} "
        "-o {output.tsv:q} "
        "{input.bam:q} "
        ">> {log} 2>&1"


use rule exon_fc_count_unique as exon_fc_count_all with:
    """feature count on all exons"""
    output:
        tsv=temp(
            "tmp/feature_count/exon_fc_count_unique/{sample}.exon_fc_count_all.tsv"
        ),
        summary=temp(
            "tmp/feature_count/exon_fc_count_unique/{sample}.exon_fc_count_all.tsv.summary"
        ),
    log:
        "logs/feature_count/exon_fc_count_all/{sample}.log",
    benchmark:
        "benchmark/feature_count/exon_fc_count_all_{sample}.tsv"
    params:
        extra="-O -f -p",


use rule exon_fc_count_unique as gene_fc_count_unique with:
    """feature count on unique genes"""
    output:
        summary=temp(
            "tmp/feature_count/exon_fc_count_unique/{sample}.gene_fc_count_unique.tsv.summary"
        ),
        tsv=temp(
            "tmp/feature_count/exon_fc_count_unique/{sample}.gene_fc_count_unique.tsv"
        ),
    log:
        "logs/feature_count/gene_fc_count_unique/{sample}.log",
    benchmark:
        "benchmark/feature_count/gene_fc_count_unique_{sample}.tsv"
    params:
        extra="-M --primary -Q 10 -p",


use rule exon_fc_count_unique as gene_fc_count_all with:
    """feature counts on all genes"""
    output:
        tsv=temp(
            "tmp/feature_count/exon_fc_count_unique/{sample}.gene_fc_count_all.tsv"
        ),
        summary=temp(
            "tmp/feature_count/exon_fc_count_unique/{sample}.gene_fc_count_all.tsv.summary"
        ),
    log:
        "logs/feature_count/gene_fc_count_all/{sample}.log",
    benchmark:
        "benchmark/feature_count/gene_fc_count_all_{sample}.tsv"
    params:
        extra="-M --primary -p",


rule sed_remove_header_gene_id:
    """remove results header"""
    input:
        "tmp/feature_count/exon_fc_count_unique/{sample}.{gene_exon}_fc_count_{unique_all}.tsv",
    output:
        temp(
            "tmp/feature_count/awk_remove_header_gene_id/{sample}.{gene_exon}_fc_count_{unique_all}.tsv"
        ),
    log:
        "logs/feature_count/awk_remove_header_gene_id/{sample}.{gene_exon}.{unique_all}.log",
    benchmark:
        "benchmark/sed/feature_count_sed_remove_header_gene_id_{sample}.{unique_all}.tsv",
    threads: 1
    params:
        expr='1d',
        extra="",
    wrapper:
        "v9.8.0/utils/sed"


use rule zstd_junctions_tab as compress_feature_counts with:
    """compress feture count results"""
    input:
        "tmp/feature_count/awk_remove_header_gene_id/{sample}.{gene_exon}_fc_count_{unique_all}.tsv",
    output:
        "results/{sample}/{sample}.{gene_exon}_fc_count_{unique_all}.tsv.zst",
    log:
        "logs/feature_count/compress_feature_counts/{sample}.{gene_exon}_{unique_all}.log",
    benchmark:
        "benchmark/zstd/compress_feature_counts_{sample}.{gene_exon}.{unique_all}.tsv"


rule make_summary_available:
    """aggregate summaries"""
    input:
        "tmp/feature_count/awk_remove_header_gene_id/{sample}.{gene_exon}_fc_count_{unique_all}.tsv.summary",
    output:
        "results/{sample}/{sample}.{gene_exon}_fc_count_{unique_all}.summary",
    log:
        "logs/make_summary_available/{sample}.{gene_exon}.{unique_all}.log",
    benchmark:
        "benchmark/cp/make_summary_available_{sample}.{gene_exon}.{unique_all}.tsv"
    threads: 1
    params:
        "-cvrhP",
    shell:
        "rsync {params} {input} {output} > {log} 2>&1"
