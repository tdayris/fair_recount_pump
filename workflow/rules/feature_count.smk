rule exon_fc_count_unique:
    input:
        bam="tmp/sort/samtools_sort/{sample}.bam",
        bai="tmp/sort/samtools_sort/{sample}.bam.bai",
        gtf=config.get(
            "gtf",
            "/mnt/beegfs/database/bioinfo/Index_DB/Fasta/Ensembl/GRCh38.99/GRCh38.99.homo_sapiens.gtf",
        ),
    output:
        tsv=temp(
            "tmp/feature_count/exon_fc_count_unique/{sample}.exon_fc_count_unique.tsv"
        ),
        summary="results/{sample}/{sample}.exon_fc_count_unique.summary",
    threads: 10
    resources:
        mem_mb=lambda wildcards, attempt: attempt * 4_000,
        runtime=lambda wildcards, attempt: attempt * 35,
        tmpdir="tmp",
    params:
        fc="-Q 10 -O -f -p",
        mv="-v",
    conda:
        "../envs/feature_count.yaml"
    log:
        "logs/feature_count/exon_fc_count_unique/{sample}.log",
    shell:
        "featureCounts {params.fc} "
        "-T {threads} "
        "-a {input.gtf} "
        "-o {output.tsv} "
        "{input.bam} "
        "> {log} 2>&1 && "
        "mv {params.mv} "
        "{output.tsv}.summary "
        "{output.summary} "
        ">> {log} 2>&1 && "


use rule exon_fc_count_unique as exon_fc_count_all with:
    output:
        tsv=temp(
            "tmp/feature_count/exon_fc_count_unique/{sample}.exon_fc_count_all.tsv"
        ),
        summary="results/{sample}/{sample}.exon_fc_count_all.summary",
    params:
        fc="-O -f -p",
        mv="-v",
    log:
        "logs/feature_count/exon_fc_count_all/{sample}.log",


use rule exon_fc_count_unique as gene_fc_count_unique with:
    output:
        tsv=temp(
            "tmp/feature_count/exon_fc_count_unique/{sample}.gene_fc_count_unique.tsv"
        ),
        summary="results/{sample}/{sample}.gene_fc_count_unique.summary",
    params:
        fc="-M --primary -Q 10 -p",
        mv="-v",
    log:
        "logs/feature_count/gene_fc_count_unique/{sample}.log",


use rule exon_fc_count_unique as gene_fc_count_all with:
    output:
        tsv=temp(
            "tmp/feature_count/exon_fc_count_unique/{sample}.gene_fc_count_all.tsv"
        ),
        summary="results/{sample}/{sample}.gene_fc_count_all.summary",
    params:
        fc="-M --primary -p",
        mv="-v",
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
        "logs/feature_count/compress_feature_counts/{sample}.{gene_exon}.{unique_all}.log",
    params:
        "-c",
    conda:
        "../envs/zstd.yaml"
    shell:
        "zstd {input} -o {output} > {log} 2>&1 && "
        "wc {params} {input} >> {log} 2>&1"
