rule seqtk_fqchk:
    input:
        "tmp/fair_fastqc_multiqc_link_or_concat_pair_ended_input/{sample}.{stream}.fastq.gz",
    output:
        temp("tmp/fastq_check/seqtk_fqchk/{sample}.{stream}.tsv"),
    threads: 1
    resources:
        mem_mb=lambda wildcards, attempt: attempt * 1_000,
        runtime=lambda wildcards, attempt: attempt * 30,
        tmpdir="tmp",
    log:
        "logs/fastq_check/seqtk_fqchk/{sample}.{stream}.log",
    params:
        "-q0",
    conda:
        "../envs/seqtk.yaml"
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
    threads: 1
    resources:
        mem_mb=lambda wildcards, attempt: attempt * 1_000,
        runtime=lambda wildcards, attempt: attempt * 30,
        tmpdir="tmp",
    log:
        "logs/aggregate_seqtk_fqchk.log",
    params:
        "-c",
    conda:
        "../envs/bash.yaml"
    shell:
        "cat {input} > {output} 2> {log} && "
        "wc {params} {output} >> {log} 2>&1 "
