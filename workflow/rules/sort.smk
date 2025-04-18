rule samtools_sort:
    input:
        "tmp/align/star_align/{sample}/Aligned.out.bam",
    output:
        temp("tmp/sort/samtools_sort/{sample}.bam"),
    threads: 8
    resources:
        mem_mb=lambda wildcards, attempt: attempt * 9_000,
        runtime=lambda wildcards, attempt: attempt * 60,
        tmpdir="tmp",
    log:
        "logs/sort/samtools_sort/{sample}.log",
    params:
        samtools="-m 64M",
        wc="-c",
    conda:
        "../envs/samtools.yaml"
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
    threads: 3
    resources:
        mem_mb=lambda wildcards, attempt: attempt * 2_000,
        runtime=lambda wildcards, attempt: attempt * 35,
        tmpdir="tmp",
    log:
        "logs/sort/samtools_index/{sample}.log",
    params:
        "",
    conda:
        "../envs/samtools.yaml"
    shell:
        "samtools index -@ 2 {input} > {log} 2>&1"


rule samtools_idxstats:
    input:
        "tmp/sort/samtools_sort/{sample}.bam",
        "tmp/sort/samtools_sort/{sample}.bam.bai",
    output:
        "results/{sample}/{sample}.idxstats",
    threads: 1
    resources:
        mem_mb=lambda wildcards, attempt: attempt * 1_000,
        runtime=lambda wildcards, attempt: attempt * 35,
        tmpdir="tmp",
    log:
        "logs/sort/samtools_idxstats/{sample}.log",
    params:
        "-c",
    conda:
        "../envs/samtools.smk"
    shell:
        "samtools idxstats {input} > {output} 2> {log} "
