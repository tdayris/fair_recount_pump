rule star_align:
    """align reads with star"""
    input:
        r1="tmp/fair_fastqc_multiqc_link_or_concat_pair_ended_input/{sample}.1.fastq.gz",
        r2="tmp/fair_fastqc_multiqc_link_or_concat_pair_ended_input/{sample}.2.fastq.gz",
        index=branch(
            is_human,
            then=genomes.loc["homo_sapiens"]["star_index"],
            otherwise=genomes.loc["mus_musculus"]["star_index"],
        ),
    output:
        bam=temp("tmp/align/star_align/{sample}/Aligned.out.bam"),
        junc=temp("tmp/align/star_align/{sample}/Chimeric.out.junction"),
        log_final=temp("tmp/align/star_align/{sample}/Log.final.out"),
        log=temp("tmp/align/star_align/{sample}/Log.out"),
        log_progress=temp("tmp/align/star_align/{sample}/Log.progress.out"),
        sj=temp("tmp/align/star_align/{sample}/SJ.out.tab"),
        chim_sam=temp("tmp/align/star_align/{sample}/Chimeric.out.sam"),
        unmate1=temp("tmp/align/star_align/{sample}/Unmapped.out.mate1"),
        unmate2=temp("tmp/align/star_align/{sample}/Unmapped.out.mate2"),
    log:
        "logs/align/star_align/{sample}.log",
    benchmark:
        "benchmark/star_align/{sample}.tsv"
    shadow:
        "minimal"
    conda:
        "../envs/star.yaml"
    threads: 20
    params:
        "--runMode alignReads "
        "--twopassMode None "
        "--outReadsUnmapped Fastx "
        "--outMultimapperOrder Old_2.4 "
        "--outSAMtype BAM Unsorted "
        "--outSAMmode NoQS "
        "--outSAMattributes NH MD "
        "--chimOutType Junctions SeparateSAMold "
        "--chimOutJunctionFormat 1 "
        "--chimSegmentReadGapMax 3 "
        "--chimJunctionOverhangMin 12 "
        " --chimSegmentMin 12 "
        "--genomeLoad NoSharedMemory "
        "--readFilesCommand gunzip -c ",
    shell:
        "STAR {params} "
        "--runThreadN {threads} "
        "--genomeDir {input.index:q} "
        "--readFilesIn {input.r1:q} {input.r2:q} "
        "--outTmpDir 'tmp/star_tmp_{wildcards.sample}' "
        "--outFileNamePrefix 'tmp/align/star_align/{wildcards.sample}/' "
        "> {log} 2>&1 "


rule zstd_junctions_tab:
    """compress star newly found junctions"""
    input:
        "tmp/align/star_align/{sample}/SJ.out.tab",
    output:
        "results/{sample}/{sample}.SJ.out.tab.zst",
    log:
        "logs/align/zstd_junctions_tab/{sample}.log",
    benchmark:
        "benchmark/zstd/zstd_junctions_tab_{sample}.tsv"
    conda:
        "../envs/zstd.yaml"
    threads: 10
    resources:
        mem_mb=lambda wildcards, attempt: attempt * 1_000,
        runtime=lambda wildcards, attempt: attempt * 45,
        tmpdir="tmp",
    params:
        wc="-c",
        test="-f",
        extra="--force --ultra -22"
    shell:
        "zstd {params.extra} -T{threads} {input:q} -o {output:q} >> {log} 2>&1 "


rule sort_chimeric_junctions:
    """sort star chimeric junctions"""
    input:
        "tmp/align/star_align/{sample}/Chimeric.out.junction",
    output:
        temp("tmp/align/star_align/{sample}/Chimeric.out.junction.sorted"),
    log:
        "logs/align/sort_chimeric_junctions/{sample}.log",
    benchmark:
        "benchmark/sort/sort_chimeric_junctions_{sample}.tsv"
    conda:
        "../envs/bash.yaml"
    threads: 1
    resources:
        mem_mb=lambda wildcards, input, attempt: attempt * 4_000 + input.size_mb,
        runtime=lambda wildcards, attempt: attempt * 75,
        tmpdir="tmp",
    params:
        extra="-k1,1 -k2,2n",
    shell:
        "sort {params.extra} {input:q} > {output:q} 2> {log:q}"


use rule zstd_junctions_tab as zdst_chimeric_junctions with:
    """compress star chimeric junctions"""
    input:
        "tmp/align/star_align/{sample}/Chimeric.out.junction.sorted",
    output:
        "results/{sample}/Chimeric.out.junction.sorted.zst",
    log:
        "logs/zdst_chimeric_junctions/{sample}.log",
    benchmark:
        "benchmark/zsdt/zdst_chimeric_junctions_{sample}.tsv"


use rule zstd_junctions_tab as zdst_chimeric_sam with:
    """compress stat chimeric sam why not cram seriously"""
    input:
        "tmp/align/star_align/{sample}/Chimeric.out.sam",
    output:
        "results/{sample}/{sample}.Chimeric.out.sam.zst",
    log:
        "logs/zdst_chimeric_sam/{sample}.log",
    benchmark:
        "be/zstd/zdst_chimeric_sam_{sample}.tsv"
