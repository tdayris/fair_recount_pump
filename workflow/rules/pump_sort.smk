rule samtools_sort:
    input:
        "tmp/align/star_align/{sample}/Aligned.out.bam",
    output:
        temp("tmp/sort/samtools_sort/{sample}.bam"),
    log:
        "logs/sort/samtools_sort/{sample}.log",
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
        "-T {resources.tmpdir}/samtools_temp_{wildcards.sample} "
        "-@ 7  -o {output} {input} "
        "> {log} 2>&1 && "
        "wc {params.wc} {input} >> {log} 2>&1"


rule samtools_index:
    input:
        "tmp/sort/samtools_sort/{sample}.bam",
    output:
        temp("tmp/sort/samtools_sort/{sample}.bam.bai"),
    log:
        "logs/sort/samtools_index/{sample}.log",
    threads: 3
    resources:
        mem_mb=lambda wildcards, attempt: attempt * 2_000,
        runtime=lambda wildcards, attempt: attempt * 35,
        tmpdir="tmp",
    params:
        "",
    wrapper:
        "v9.14.0/bio/samtools/index"


rule samtools_idxstats:
    input:
        "tmp/sort/samtools_sort/{sample}.bam",
        "tmp/sort/samtools_sort/{sample}.bam.bai",
    output:
        "results/{sample}/{sample}.idxstats",
    log:
        "logs/sort/samtools_idxstats/{sample}.log",
    conda:
        "../envs/samtools.smk"
    threads: 1
    resources:
        mem_mb=lambda wildcards, attempt: attempt * 1_000,
        runtime=lambda wildcards, attempt: attempt * 35,
        tmpdir="tmp",
    params:
        "-c",
    shell:
        "samtools idxstats {input} > {output} 2> {log} "
