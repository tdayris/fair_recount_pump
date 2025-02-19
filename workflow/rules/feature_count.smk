rule exon_fc_count_unique:
    input:
        bam="tmp/sort/samtools_sort/{sample}.bam",
        bai="tmp/sort/samtools_sort/{sample}.bam.bai",
        gtf=branch(
            is_human,
            then=get_attr(lookup(query="species == 'homo_sapiens'", within=genomes), "gtf",),
            otherwise=get_attr(lookup(query="species == 'mus_musculus'", within=genomes), "gtf",),
        ),
    output:
        tsv=temp(
            "tmp/feature_count/exon_fc_count_unique/{sample}.exon_fc_count_unique.tsv"
        ),
        summary=temp(
            "tmp/feature_count/exon_fc_count_unique/{sample}.exon_fc_count_unique.tsv.summary"
        ),
    threads: 10
    resources:
        mem_mb=lambda wildcards, attempt: attempt * 4_000,
        runtime=lambda wildcards, attempt: attempt * 35,
        tmpdir="tmp",
    params:
        fc="-Q 10 -O -f -p",
    conda:
        "../envs/subread.yaml"
    log:
        "logs/feature_count/exon_fc_count_unique/{sample}.log",
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
    params:
        fc="-O -f -p",
    log:
        "logs/feature_count/exon_fc_count_all/{sample}.log",


use rule exon_fc_count_unique as gene_fc_count_unique with:
    output:
        summary=temp(
            "tmp/feature_count/exon_fc_count_unique/{sample}.gene_fc_count_unique.tsv.summary"
        ),
        tsv=temp(
            "tmp/feature_count/exon_fc_count_unique/{sample}.gene_fc_count_unique.tsv"
        ),
    params:
        fc="-M --primary -Q 10 -p",
    log:
        "logs/feature_count/gene_fc_count_unique/{sample}.log",


use rule exon_fc_count_unique as gene_fc_count_all with:
    output:
        tsv=temp(
            "tmp/feature_count/exon_fc_count_unique/{sample}.gene_fc_count_all.tsv"
        ),
        summary=temp(
            "tmp/feature_count/exon_fc_count_unique/{sample}.gene_fc_count_all.tsv.summary"
        ),
    params:
        fc="-M --primary -p",
    log:
        "logs/feature_count/gene_fc_count_all/{sample}.log",


rule awk_remove_header_gene_id:
    input:
        "tmp/feature_count/exon_fc_count_unique/{sample}.{gene_exon}_fc_count_{unique_all}.tsv",
    output:
        temp(
            "tmp/feature_count/awk_remove_header_gene_id/{sample}.{gene_exon}_fc_count_{unique_all}.tsv"
        ),
    threads: 1
    resources:
        mem_mb=lambda wildcards, attempt: attempt * 1_000,
        runtime=lambda wildcards, attempt: attempt * 20,
        tmpdir="tmp",
    log:
        "logs/feature_count/awk_remove_header_gene_id/{sample}.{gene_exon}.{unique_all}.log",
    params:
        v="-v OFS='\\t'",
        main="'$1 !~ /^#/ && $1 !~ /^Geneid/ && $NF != 0 {{print \"{wildcards.sample}\",$0}}'",
    conda:
        "../envs/awk.yaml"
    shell:
        "awk {params.v} {params.main} {input} > {output} 2> {log}"


rule compress_feature_counts:
    input:
        "tmp/feature_count/awk_remove_header_gene_id/{sample}.{gene_exon}_fc_count_{unique_all}.tsv",
    output:
        "results/{sample}/{sample}.{gene_exon}_fc_count_{unique_all}.tsv.zst",
    threads: 1
    resources:
        mem_mb=lambda wildcards, attempt: attempt * 1_000,
        runtime=lambda wildcards, attempt: attempt * 45,
        tmpdir="tmp",
    log:
        "logs/feature_count/compress_feature_counts/{sample}.{gene_exon}_{unique_all}.log",
    params:
        "-c",
    conda:
        "../envs/zstd.yaml"
    shell:
        "zstd {input} -o {output} > {log} 2>&1 "


rule make_summary_available:
    input:
        "tmp/feature_count/awk_remove_header_gene_id/{sample}.{gene_exon}_fc_count_{unique_all}.tsv.summary",
    output:
        "results/{sample}/{sample}.{gene_exon}_fc_count_{unique_all}.summary",
    threads: 1
    resources:
        mem_mb=lambda wildcards, attempt: attempt * 1_000,
        runtime=lambda wildcards, attempt: attempt * 15,
        tmpdir="tmp",
    log:
        "logs/make_summary_available/{sample}.{gene_exon}.{unique_all}.log",
    params:
        "--verbose",
    shell:
        "mv {params} {input} {output} > {log} 2>&1"
