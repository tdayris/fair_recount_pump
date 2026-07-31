rule seqtk_fqchk:
    input:
        "tmp/fair_fastqc_multiqc_link_or_concat_pair_ended_input/{sample}.{stream}.fastq.gz",
    output:
        temp("tmp/fastq_check/seqtk_fqchk/{sample}.{stream}.tsv"),
    log:
        "logs/fastq_check/seqtk_fqchk/{sample}.{stream}.log",
    conda:
        "../envs/seqtk.yaml"
    threads: 1
    resources:
        mem_mb=lambda wildcards, attempt: attempt * 1_000,
        runtime=lambda wildcards, attempt: attempt * 30,
        tmpdir="tmp",
    params:
        "-q0",
    shell:
        "seqtk fqchk {params} {input} > {output} 2> {log}"


rule aggregate_seqtk_fqchk:
    input:
        expand(
            "tmp/fastq_check/seqtk_fqchk/{sample}.{stream}.tsv",
            sample=samples_tpl,
            stream=stream_tpl,
        ),
    output:
        "results/seqtk_fqchk.tsv",
    log:
        "logs/aggregate_seqtk_fqchk.log",
    conda:
        "../envs/bash.yaml"
    threads: 1
    resources:
        mem_mb=lambda wildcards, attempt: attempt * 1_000,
        runtime=lambda wildcards, attempt: attempt * 30,
        tmpdir="tmp",
    params:
        "-c",
    shell:
        "cat {input} > {output} 2> {log} "
