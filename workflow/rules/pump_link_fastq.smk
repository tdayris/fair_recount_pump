rule fair_fastqc_multiqc_link_or_concat_single_ended_input:
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
    resources:
        mem_mb=lambda wildcards, attempt: 400 + attempt * 100,
        runtime=lambda wildcards, input, attempt: attempt
        * max(1, int(input.size_mb / 1024))
        * 10,
        tmpdir=tmp,
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


use rule fair_fastqc_multiqc_link_or_concat_single_ended_input as fair_fastqc_multiqc_link_or_concat_pair_ended_input with:
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
