rule bamcount:
    input:
        bam="tmp/sort/samtools_sort/{sample}.bam",
        bai="tmp/sort/samtools_sort/{sample}.bam.bai",
        bed="/mnt/beegfs/database/bioinfo/monorail-external/hg38/gtf/exons.bed",
        exe="/mnt/beegfs/database/bioinfo/monorail-external/bamcount"
    output:
        temp(multiext(
            "tmp/bamcount/bamcount/{sample}",
            ".alts.tsv",
            ".auc.tsv",
            ".frags.tsv",
            ".all.bw",
            ".unique.bw",
            ".jxs.tsv",
            ".all.tsv",
            ".unique.tsv",
        )),
    threads: 10
    resources:
        mem_mb=lambda wildcards, attempt: attempt * 6_000,
        runtime=lambda wildcards, attempt: attempt * 30,
        tmpdir="tmp",
    log:
        "logs/bamcount/bamcount/{sample}.log"
    params:
        extra=(
            "--coverage "
            "--no-head "
            "--require-mdz "
            " --min-unique-qual 10 "
        ),
        prefix=lambda wildcards, output: os.path.commonpath(list(map(str, output))),
    conda:
        "../envs/samtools.smk"
    shell:
        "{input.exe} {params.extra} "
        "--threads {threads} "
        "--frag-dist {params.prefix} "
        "--bigwig {params.prefix} "
        "--annotation {input.bed} {params.prefix} "
        "--auc {params.prefix} "
        "--alts {params.prefix} "
        "--junctions {params.prefix} "
        "> {log} 2>&1 "


use rule zdst_chimeric_junctions as zdst_bamcount with:
    input:
        "tmp/bamcount/bamcount/{sample}.{content}.tsv",
    output:
        "result/{sample}/{sample}.{content}.tsv.zst",
    log:
        "logs/bamcount/zdst_bamcount/{sample}.{content}.log",
