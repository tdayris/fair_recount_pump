rule seqtk_fqchk:
    """create fastq quality metrics"""
    input:
        "tmp/fair_fastqc_multiqc_link_or_concat_pair_ended_input/{sample}.{stream}.fastq.gz",
    output:
        temp("tmp/fastq_check/seqtk_fqchk/{sample}.{stream}.tsv"),
    log:
        "logs/fastq_check/seqtk_fqchk/{sample}.{stream}.log",
    benchmark:
        "benchmark/seqtk_fastq_check/seqtk_fqchk_{sample}.{stream}.tsv",
    conda:
        "../envs/seqtk.yaml"
    threads: 1
    params:
        extra="-q0",
    shell:
        "seqtk fqchk {params.extra} {input:q} > {output:q} 2> {log:q}"


rule aggregate_seqtk_fqchk:
    """aggregate metrics in a single file"""
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
    benchmark:
        "benchmark/cat/aggregate_seqtk_fqchk.tsv",
    conda:
        "../envs/bash.yaml"
    threads: 1
    shell:
        "cat {input:q} > {output:q} 2> {log} "
