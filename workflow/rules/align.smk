rule star_align:
    input:
        r1="tmp/fair_fastqc_multiqc_link_or_concat_pair_ended_input/{sample}.1.fastq.gz",
        r2="tmp/fair_fastqc_multiqc_link_or_concat_pair_ended_input/{sample}.2.fastq.gz",
        index=config.get(
            "star_index",
            "/mnt/beegfs/database/bioinfo/monorail-external/hg38/star_idx",
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
    threads: 20
    resources:
        mem_mb=lambda wildcards, attempt: attempt * 10_000 + 36_000,
        runtime=lambda wildcards, attempt: attempt * 75,
        tmpdir="tmp",
    log:
        "logs/align/star_align/{sample}.log",
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
    conda:
        "../envs/star.yaml"
    shell:
        "STAR {params} "
        "--runThreadN {threads} "
        "--genomeDir {input.index} "
        "--readFilesIn {input.r1} {input.r2} "
        "--outTmpDir '{resources.tmpdir}/star_tmp_{wildcards.sample}' "
        "> {log} 2>&1 && "
        "cat {output.log_final} >> {log} 2>&1 "


rule zstd_junctions_tab:
    input:
        "tmp/align/star_align/{sample}/SJ.out.tab",
    output:
        "results/{sample}/{sample}.SJ.out.tab.zst",
    threads: 1
    resources:
        mem_mb=lambda wildcards, attempt: attempt * 1_000,
        runtime=lambda wildcards, attempt: attempt * 45,
        tmpdir="tmp",
    log:
        "logs/align/zstd_junctions_tab/{sample}.log",
    params:
        wc="-c",
        test="-f",
    conda:
        "../envs/zstd.yaml"
    shell:
        "test {params.test} {input} > {log} 2>&1 && "
        "zstd {input} -o {output} >> {log} 2>&1 && "
        "wc {params.wc} {output} >> {log} 2>&1"


rule sort_chimeric_junctions:
    input:
        "tmp/align/star_align/{sample}/Chimeric.out.junction",
    output:
        temp("tmp/align/star_align/{sample}/Chimeric.out.junction.sorted"),
    threads: 1
    resources:
        mem_mb=lambda wildcards, input, attempt: attempt * 4_000 + input.size_mb,
        runtime=lambda wildcards, attempt: attempt * 75,
        tmpdir="tmp",
    log:
        "logs/align/sort_chimeric_junctions/{sample}.log",
    params:
        "-k1,1 -k2,2n",
    conda:
        "../envs/bash.yaml"
    shell:
        "sort {params} {input} > {output} 2> {log}"


rule zdst_chimeric_junctions:
    input:
        "tmp/align/star_align/{sample}/Chimeric.out.junction.sorted",
    output:
        "results/{sample}/Chimeric.out.junction.sorted.zst",
    threads: 1
    resources:
        mem_mb=lambda wildcards, attempt: attempt * 1_000,
        runtime=lambda wildcards, attempt: attempt * 45,
        tmpdir="tmp",
    log:
        "logs/zdst_chimeric_junctions/{sample}.log",
    params:
        "-c",
    conda:
        "../envs/zstd.yaml"
    shell:
        "zstd {input} -o {output} > {log} 2>&1 && "
        "wc {params} >> {log} 2>&1 "


rule zdst_chimeric_sam:
    input:
        "tmp/align/star_align/{sample}/Chimeric.out.sam",
    output:
        "results/{sample}/{sample}.Chimeric.out.sam.zst",
    threads: 1
    resources:
        mem_mb=lambda wildcards, attempt: attempt * 1_000,
        runtime=lambda wildcards, attempt: attempt * 45,
        tmpdir="tmp",
    log:
        "logs/zdst_chimeric_sam/{sample}.log",
    params:
        wc="-c",
        test="-s",
    conda:
        "../envs/zstd.yaml"
    shell:
        "test -s {input} > {log} 2>&1"
        "zstd {input} -o {output} >> {log} 2>&1 && "
        "wc {params} >> {log} 2>&1 "
