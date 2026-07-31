rule exon_fc_count_unique:
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
    conda:
        "../envs/subread.yaml"
    threads: 10
    resources:
        mem_mb=lambda wildcards, attempt: attempt * 4_000,
        runtime=lambda wildcards, attempt: attempt * 35,
        tmpdir="tmp",
    params:
        fc="-Q 10 -O -f -p",
    shell:
        "featureCounts {params.fc} "
        "-T {threads} "
        "-a '{input.gtf}' "
        "-o '{output.tsv}' "
        "'{input.bam}' "
        ">> {log} 2>&1"


use rule exon_fc_count_unique as exon_fc_count_all with:
    output:
        tsv=temp(
            "tmp/feature_count/exon_fc_count_unique/{sample}.exon_fc_count_all.tsv"
        ),
        summary=temp(
            "tmp/feature_count/exon_fc_count_unique/{sample}.exon_fc_count_all.tsv.summary"
        ),
    log:
        "logs/feature_count/exon_fc_count_all/{sample}.log",
    params:
        fc="-O -f -p",


use rule exon_fc_count_unique as gene_fc_count_unique with:
    output:
        summary=temp(
            "tmp/feature_count/exon_fc_count_unique/{sample}.gene_fc_count_unique.tsv.summary"
        ),
        tsv=temp(
            "tmp/feature_count/exon_fc_count_unique/{sample}.gene_fc_count_unique.tsv"
        ),
    log:
        "logs/feature_count/gene_fc_count_unique/{sample}.log",
    params:
        fc="-M --primary -Q 10 -p",


use rule exon_fc_count_unique as gene_fc_count_all with:
    output:
        tsv=temp(
            "tmp/feature_count/exon_fc_count_unique/{sample}.gene_fc_count_all.tsv"
        ),
        summary=temp(
            "tmp/feature_count/exon_fc_count_unique/{sample}.gene_fc_count_all.tsv.summary"
        ),
    log:
        "logs/feature_count/gene_fc_count_all/{sample}.log",
    params:
        fc="-M --primary -p",


rule sed_remove_header_gene_id:
    input:
        "tmp/feature_count/exon_fc_count_unique/{sample}.{gene_exon}_fc_count_{unique_all}.tsv",
    output:
        temp(
            "tmp/feature_count/awk_remove_header_gene_id/{sample}.{gene_exon}_fc_count_{unique_all}.tsv"
        ),
    log:
        "logs/feature_count/awk_remove_header_gene_id/{sample}.{gene_exon}.{unique_all}.log",
    threads: 1
    resources:
        mem_mb=lambda wildcards, attempt: attempt * 1_000,
        runtime=lambda wildcards, attempt: attempt * 20,
        tmpdir="tmp",
    params:
        #v="-v OFS='\\t'",
        #main=lambda wildcards: f"'$1 !~ /^#/ && $1 !~ /^Geneid/ && $NF != 0 {{print \"{wildcards.sample}\",$0}}'",
        #"awk {params.v} {params.main} {input} > {output} 2> {log}"
        expr='1d',
        extra="",
    wrapper:
        "v9.8.0/utils/sed"


use rule zstd_junctions_tab as compress_feature_counts with:
    input:
        "tmp/feature_count/awk_remove_header_gene_id/{sample}.{gene_exon}_fc_count_{unique_all}.tsv",
    output:
        "results/{sample}/{sample}.{gene_exon}_fc_count_{unique_all}.tsv.zst",
    log:
        "logs/feature_count/compress_feature_counts/{sample}.{gene_exon}_{unique_all}.log",


rule make_summary_available:
    input:
        "tmp/feature_count/awk_remove_header_gene_id/{sample}.{gene_exon}_fc_count_{unique_all}.tsv.summary",
    output:
        "results/{sample}/{sample}.{gene_exon}_fc_count_{unique_all}.summary",
    log:
        "logs/make_summary_available/{sample}.{gene_exon}.{unique_all}.log",
    threads: 1
    resources:
        mem_mb=lambda wildcards, attempt: attempt * 1_000,
        runtime=lambda wildcards, attempt: attempt * 15,
        tmpdir="tmp",
    params:
        "--verbose",
    shell:
        "mv {params} {input} {output} > {log} 2>&1"
