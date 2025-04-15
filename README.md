# fair_recount_pump
 Run Recount-pump with snakemake workflow interface and conda deployment

This pipeline runs the outdated recount s5 pipeline without the strange name scheme,
without command line errors, with reduced memory reservation, with reduced time
requirements.

## Run pipeline

1. Create `config/samples.csv` file
2. Create `config/config.yaml` with optional configuration (or let it empty to run all defaults)
3. Run Snakemake command:

```sh
snakemake   --cores 30   \
            --jobs 50   \
            --local-cores 2   \
            --rerun-triggers 'mtime'   \
            --executor slurm-gustave-roussy   \
            --benchmark-extended   \
            --rerun-incomplete   \
            --printshellcmds   \
            --restart-times 0   \
            --show-failed-logs   \
            --jobname '{name}.{jobid}.slurm.snakejob.sh'   \
            --software-deployment-method 'conda'   \
            --conda-prefix '/mnt/beegfs02/pipelines/unofficial-snakemake-wrappers/shared_install/'   \
            --apptainer-prefix '/mnt/beegfs02/pipelines/unofficial-snakemake-wrappers/singularity/'   \
            --shadow-prefix '/mnt/beegfs02/userdata/t_dayris/test/monorail_external/tmp'   \
            --use-envmodules   \
            -s /path/to/workflow/Snakefile
```


## `config/samples.csv`

A simple CSV file with the following columns:

1. `sample_id`: unique sample name
1. `upstream_file`: path to upstream read file (R1 fastq). Must be gz-compressed.
1. `downstream_file`: path to downstream read file (R2 fastq). Must be gz-compressed.
1. `species`: The species name, according to Ensembl standards.
1. `build`: The corresponding genome build, according to Ensembl standards.
1. `release`: The corresponding genome release, according to Ensembl standards.

## `config/genomes.csv`

A simple CSV file with the following columns:

1. `species`: The species name, according to Ensembl standards
1. `build`: The corresponding Ensembl genome build
1. `release`: The corresponding Ensemnbl genome build
1. `star_index`: The genome indexed with STAR (obtained from recount themselves)
1. `salmon_index`: The genome indexed with Salmon (obtained from recount themselves)
1. `gtf`: The GTF annotation (obtained from recount themselves)
1. `fasta`: The genome sequences (obtained from recount themselves)
1. `bed`: The genomic intervals (obtained from recount themselves)
