rule link_or_concat_single_ended_input:
    """access single ended input files"""
    output:
        temp(
            "tmp/fair_fastqc_multiqc_link_or_concat_single_ended_input/{sample}.fastq.gz"
        ),
    log:
        "logs/fair_fastqc_multiqc_link_or_concat_single_ended_input/{sample}.log",
    benchmark:
        "benchmark/fair_fastqc_multiqc_link_or_concat_single_ended_input/{sample}.tsv"
    conda:
        "../envs/python.yaml"
    threads: 1
    params:
        in_files=collect(
            "{sample.upstream_file}",
            sample=lookup(
                query="sample_id == '{sample}' & downstream_file != downstream_file",
                within=samples,
            ),
        ),
    script:
        "../scripts/link_or_concat.py"


use rule link_or_concat_single_ended_input as link_or_concat_pair_ended_input with:
    """access pair ended input files"""
    output:
        temp(
            "tmp/fair_fastqc_multiqc_link_or_concat_pair_ended_input/{sample}.{stream}.fastq.gz"
        ),
    log:
        "logs/fair_fastqc_multiqc_link_or_concat_pair_ended_input/{sample}.{stream}.log",
    benchmark:
        "benchmark/fair_fastqc_multiqc_link_or_concat_pair_ended_input/{sample}.{stream}.tsv"
    params:
        in_files=branch(
            evaluate("{stream} == '1'"),
            then=collect(
                "{sample.upstream_file}",
                sample=lookup(
                    query="sample_id == '{sample}' & downstream_file == downstream_file",
                    within=samples,
                ),
            ),
            otherwise=collect(
                "{sample.downstream_file}",
                sample=lookup(
                    query="sample_id == '{sample}' & downstream_file == downstream_file",
                    within=samples,
                ),
            ),
        ),
