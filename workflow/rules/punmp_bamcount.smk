rule get_bamcount:
    """acquire software to count reads"""
    output:
        "bamcount",
    log:
        "logs/get_bamcount.log",
    benchmark:
        "benchmark/aria2/get_bamcount.tsv"
    threads: 1
    resources:
        mem_mb=lambda wildcards, attempt: attempt * 1_000,
        runtime=lambda wildcards, attempt: attempt * 15,
        tmpdir="tmp",
    params:
        url="https://github.com/ChristopherWilks/bamcount/releases/download/0.4.0/bamcount_static",
        extra="",
    wrapper:
        "v6.2.0/utils/aria2c"


rule bamcount:
    """count reads with an old software"""
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
    benchmark:
        "benchmark/bamcount/{sample}.tsv"
    conda:
        "../envs/samtools.yaml"
    threads: 10
    params:
        extra=str(
            "--coverage --no-head --require-mdz --min-unique-qual 10"
        ),
        prefix=lambda wildcards, output: os.path.commonprefix(list(map(str, output)))[
            :-1
        ],
    shell:
        "chmod u+x {input.exe:q} && "
        "{input.exe:q} "
        "{input.bam:q} "
        "{params.extra} "
        "--threads {threads} "
        "--frag-dist {params.prefix:q} "
        "--bigwig {params.prefix:q} "
        "--annotation {input.bed:q} {params.prefix:q} "
        "--auc {params.prefix:q} "
        "--alts {params.prefix:q} "
        "--junctions {params.prefix:q} "
        "> {log:q} 2>&1 "


use rule zdst_chimeric_junctions as zdst_bamcount with:
    """compress bamcount results"""
    input:
        "tmp/bamcount/bamcount/{sample}.{content}.tsv",
    output:
        "results/{sample}/{sample}.{content}.tsv.zst",
    log:
        "logs/bamcount/zdst_bamcount/{sample}.{content}.log",
