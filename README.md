# fair_recount_pump
 Run Recount-pump with snakemake workflow interface and conda deployment

This pipeline runs the outdated recount s5 pipeline without the strange name scheme,
without command line errors, with reduced memory reservation, with reduced time
requirements.

## Run pipeline

1. Copy `config/samples.csv` file and adapt it to your data.
2. Copy `config/config.yaml` file and adapt it to your project and pipeline localisation.
3. Run Snakemake command:

```sh
snakemake   --cores 20   \
            --jobs 30   \
            --local-cores 2   \
            --keep-going   \
            --rerun-triggers 'mtime'   \
            --executor 'slurm-gustave-roussy'   \
            --benchmark-extended   \
            --rerun-incomplete   \
            --printshellcmds   \
            --restart-times 0   \
            --show-failed-logs   \
            --jobname '{name}.{jobid}.slurm.snakejob.sh'   \
            --software-deployment-method 'conda'   \
            --conda-prefix '/mnt/beegfs02/pipelines/unofficial-snakemake-wrappers/shared_install/'   \
            --apptainer-prefix '/mnt/beegfs02/pipelines/unofficial-snakemake-wrappers/singularity/'   \
            --shadow-prefix '/path/to/tmp'   \
            --use-envmodules   \
            -s /path/to/workflow/Snakefile   \
            --configfile '/path/to/config/config.yaml'

```


## `config/samples.csv`

A simple CSV file with the following columns:

1. `sample_id`: unique sample name
1. `upstream_file`: path to upstream read file (R1 fastq). Must be gz-compressed.
1. `downstream_file`: path to downstream read file (R2 fastq). Must be gz-compressed.
1. `species`: The species name, according to Ensembl standards.
1. `build`: The corresponding genome build, according to Ensembl standards.
1. `release`: The corresponding genome release, according to Ensembl standards.

## `config/config.yaml`

A simple yaml file with the following parameters:
1. `bamcount: "/mnt/beegfs02/database/bioinfo/monorail-external/bamcount/"`
1. `samples: "/path/to/your_samples.csv"`
1. `genomes: "/path/to/pipeline/config/genomes.csv"`


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

