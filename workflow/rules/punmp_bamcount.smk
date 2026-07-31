rule get_bamcount:
    output:
        "bamcount",
    log:
        "logs/get_bamcount.log",
    threads: 1
    resources:
        mem_mb=lambda wildcards, attempt: attempt * 1_000,
        runtime=lambda wildcards, attempt: attempt * 15,
        tmpdir="tmp",
    params:
        extra="-q 'https://github.com/ChristopherWilks/bamcount/releases/download/0.4.0/bamcount_static'",
    wrapper:
        "v6.2.0/utils/aria2c"


rule bamcount:
    input:
        bam="tmp/sort/samtools_sort/{sample}.bam",
        bai="tmp/sort/samtools_sort/{sample}.bam.bai",
        bed=branch(
            is_human,
            then=genomes.loc["homo_sapiens"]["bed"],
            otherwise=genomes.loc["mus_musculus"]["bed"],
        ),
        exe=config.get("bamcount", "bamcount"),
    output:
        temp(
            multiext(
                "tmp/bamcount/bamcount/{sample}",
                ".alts.tsv",
                ".auc.tsv",
                ".frags.tsv",
                ".all.bw",
                ".unique.bw",
                ".jxs.tsv",
                ".all.tsv",
                ".unique.tsv",
            )
        ),
    log:
        "logs/bamcount/bamcount/{sample}.log",
    conda:
        "../envs/samtools.yaml"
    threads: 10
    resources:
        mem_mb=lambda wildcards, attempt: attempt * 6_000,
        runtime=lambda wildcards, attempt: attempt * 30,
        tmpdir="tmp",
    params:
        extra=("--coverage " "--no-head " "--require-mdz " " --min-unique-qual 10 "),
        prefix=lambda wildcards, output: os.path.commonprefix(list(map(str, output)))[
            :-1
        ],
    shell:
        "chmod u+x {input.exe} && "
        "{input.exe} "
        "{input.bam} "
        "{params.extra} "
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
        "results/{sample}/{sample}.{content}.tsv.zst",
    log:
        "logs/bamcount/zdst_bamcount/{sample}.{content}.log",
