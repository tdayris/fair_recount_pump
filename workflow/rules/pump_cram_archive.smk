rule cram_mapped_reads:
    input:
        bam="tmp/sort/samtools_sort/{sample}.bam",
        bai="tmp/sort/samtools_sort/{sample}.bam.bai",
        ref=branch(
            is_human,
            then=genomes.loc["homo_sapiens"]["fasta"],
            otherwise=genomes.loc["mus_musculus"]["fasta"],
        ),
    output:
        "results/{sample}/{sample}.cram",
    log:
        "logs/cram_mapped_reads/{sample}.log",
    threads: 6
    resources:
        mem_mb=lambda wildcards, attempt: attempt * 3_000,
        runtime=lambda wildcards, attempt: attempt * 75,
        tmpdir="tmp",
    params:
        extra="",
    wrapper:
        "v9.14.0/bio/samtools/view"
