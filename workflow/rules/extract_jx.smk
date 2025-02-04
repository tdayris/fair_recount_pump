rule regtools_junction_extract:
    input:
        bam="tmp/sort/samtools_sort/{sample}.bam",
        bai="tmp/sort/samtools_sort/{sample}.bam.bai",
        fa=config.get(
            "fasta",
            "/mnt/beegfs/database/bioinfo/monorail-external/hg38/fasta/genome.fa",
        ),
        gtf=config.get(
            "gtf",
            "/mnt/beegfs/database/bioinfo/monorail-external/hg38/gtf/gencode.v26.chr_patch_hapl_scaff.annotation.subset.gtf",
        ),
    output:
        temp("tmp/extract_jx/regtools_junction_extract/{sample}.jx_tmp"),
    threads: 1
    resources:
        mem_mb=lambda wildcards, attempt: attempt * 2_000,
        runtime=lambda wildcards, attempt: attempt * 45,
        tmpdir="tmp",
    log:
        "logs/extract_jx/regtools_junction_extract/{sample}.log",
    params:
        "-i 20 -a 1",
    conda:
        "../envs/regtools.yaml"
    shell:
        "regtools junctions extract {params} "
        "-o {output} {input} "
        "> {log} 2>&1 "


rule zstd_regtools_junctions:
    input:
        "tmp/extract_jx/regtools_junction_extract/{sample}.jx_tmp",
    output:
        "results/{sample}/{sample}.jx_bed.zst",
    threads: 1
    resources:
        mem_mb=lambda wildcards, attempt: attempt * 1_000,
        runtime=lambda wildcards, attempt: attempt * 45,
        tmpdir="tmp",
    log:
        "logs/extract_jx/zstd_regtools_junctions/{sample}.log",
    params:
        "-c",
    conda:
        "../envs/zstd.yaml"
    shell:
        "zstd {input} -o {output} > {log} 2>&1 "
