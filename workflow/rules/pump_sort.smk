rule samtools_sort:
    """sort aligned reads to gain space"""
    input:
        "tmp/align/star_align/{sample}/Aligned.out.bam",
    output:
        temp("tmp/sort/samtools_sort/{sample}.bam"),
    log:
        "logs/sort/samtools_sort/{sample}.log",
    benchmark:
        "benchmark/samtools_sort_{sample}.tsv"
    conda:
        "../envs/samtools.yaml"
    threads: 8
    resources:
        mem_mb=lambda wildcards, attempt: attempt * 9_000,
        runtime=lambda wildcards, attempt: attempt * 60,
        tmpdir="tmp",
    params:
        samtools="-m 64M",
        wc="-c",
    shell:
        "samtools sort {params.samtools} "
        "-T '{resources.tmpdir}/samtools_temp_{wildcards.sample}' "
        "-@ 7  -o {output:q} {input:q} "
        "> {log:q} 2>&1 && "
        "wc {params.wc} {input:q} >> {log:q} 2>&1"


rule samtools_index:
    """index sorted reads to gain time"""
    input:
        "tmp/sort/samtools_sort/{sample}.bam",
    output:
        temp("tmp/sort/samtools_sort/{sample}.bam.bai"),
    log:
        "logs/sort/samtools_index/{sample}.log",
    benchmark:
        "benchmark/samtools_index/{sample}.tsv"
    threads: 3
    params:
        "",
    wrapper:
        "v9.14.0/bio/samtools/index"


rule samtools_idxstats:
    """create metrics on mapped reads"""
    input:
        "tmp/sort/samtools_sort/{sample}.bam",
        "tmp/sort/samtools_sort/{sample}.bam.bai",
    output:
        "results/{sample}/{sample}.idxstats",
    log:
        "logs/sort/samtools_idxstats/{sample}.log",
    benchmark:
        "benchmark/samtools_idxstats/{sample}.tsv"
    conda:
        "../envs/samtools.smk"
    threads: 1
    params:
        "-c",
    shell:
        "samtools idxstats {input:q} > {output:q} 2> {log:q} "
