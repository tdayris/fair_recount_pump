rule regtools_junction_extract:
    """extract list of exonic junctions"""
    input:
        bam="tmp/sort/samtools_sort/{sample}.bam",
        bai="tmp/sort/samtools_sort/{sample}.bam.bai",
        fa=branch(
            is_human,
            then=genomes.loc["homo_sapiens"]["fasta"],
            otherwise=genomes.loc["mus_musculus"]["fasta"],
        ),
        gtf=branch(
            is_human,
            then=genomes.loc["homo_sapiens"]["gtf"],
            otherwise=genomes.loc["mus_musculus"]["gtf"],
        ),
    output:
        temp("tmp/extract_jx/regtools_junction_extract/{sample}.jx_tmp"),
    log:
        "logs/extract_jx/regtools_junction_extract/{sample}.log",
    benchmark:
        "benchmark/regtools_extract_jx/regtools_junction_extract_{sample}.log",
    conda:
        "../envs/regtools.yaml"
    threads: 1
    params:
        extra="-i 20 -a 1",
    shell:
        "regtools junctions extract {params.extra} "
        "-o {output:q} {input.bam:q} "
        "> {log} 2>&1 "


use rule zstd_junctions_tab as zstd_regtools_junctions with:
    """compress newly created junctions"""
    input:
        "tmp/extract_jx/regtools_junction_extract/{sample}.jx_tmp",
    output:
        "results/{sample}/{sample}.jx_bed.zst",
    log:
        "logs/extract_jx/zstd_regtools_junctions/{sample}.log",
    benchmark:
        "benchmark/zstd/regtools_extract_junctions_{sample}.log",
