module fair_fastqc_multiqc:
    snakefile:
        github(
            "tdayris/fair_fastqc_multiqc",
            path="workflow/Snakefile",
            tag="2.5.1",
        )
    config:
        {
            **config,
            "load_fair_genome_indexer": False,
        }


use rule * from fair_fastqc_multiqc
