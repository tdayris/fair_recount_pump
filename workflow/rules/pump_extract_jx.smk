rule regtools_junction_extract:
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
    conda:
        "../envs/regtools.yaml"
    threads: 1
    resources:
        mem_mb=lambda wildcards, attempt: attempt * 2_000,
        runtime=lambda wildcards, attempt: attempt * 45,
        tmpdir="tmp",
    params:
        "-i 20 -a 1",
    shell:
        "regtools junctions extract {params} "
        "-o {output} {input.bam} "
        "> {log} 2>&1 "


use rule zstd_junctions_tab as zstd_regtools_junctions with:
    input:
        "tmp/extract_jx/regtools_junction_extract/{sample}.jx_tmp",
    output:
        "results/{sample}/{sample}.jx_bed.zst",
    log:
        "logs/extract_jx/zstd_regtools_junctions/{sample}.log",
