rule cram_mapped_reads:
    input:
        bam="tmp/sort/samtools_sort/{sample}.bam",
        bai="tmp/sort/samtools_sort/{sample}.bam.bai",
        ref=branch(
            is_human,
            then=get_attr(lookup(query="species == 'homo_sapiens'", within=genomes), "fasta",),
            otherwise=get_attr(lookup(query="species == 'mus_musculus'", within=genomes), "fasta",),
        ),
    output:
        "results/{sample}/{sample}.cram",
    threads: 6
    resources:
        mem_mb=lambda wildcards, attempt: attempt * 3_000,
        runtime=lambda wildcards, attempt: attempt * 75,
        tmpdir="tmp",
    log:
        "logs/cram_mapped_reads/{sample}.log",
    params:
        extra="",
    wrapper:
        "v5.5.0/bio/samtools/view"
