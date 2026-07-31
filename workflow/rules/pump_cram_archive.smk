rule cram_mapped_reads:
    """compress mapped reads to save disk space"""
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
    benchmark:
        "benchmark/samtools_view/cram_mapped_reads_{sample}.log",
    threads: 6
    params:
        extra="--with-header",
    wrapper:
        "v9.14.0/bio/samtools/view"


rule crai_mapped_reads:
    """index mapped reads to access them faster"""
    input:
        "results/{sample}/{sample}.cram",
    output:
        "results/{sample}/{sample}.cram.crai",
    log:
        "logs/crai_mapped_reads/{sample}.log",
    benchmark:
        "benchmark/samtools_index/{sample}.tsv"
    threads: 4
    params:
        extra="",
    wrapper:
        "v9.14.0/bio/samtools/index"

    
        
