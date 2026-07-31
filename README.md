# fair_recount_pump

Run Recount-pump with snakemake workflow interface and conda deployment

This pipeline runs the outdated recount s5 pipeline without the strange name scheme,
without command line errors, with reduced memory reservation, with reduced time
requirements.

## Run pipeline

1. Copy `config/samples.csv` file and adapt it to your data.

```sh
rsync -cvrhP '/mnt/beegfs01/pipelines_old_centos7/fair_recount_pump/config/samples.csv' .
```

2. Copy `config/config.yaml` file and adapt it to your project and pipeline localisation.

```sh
rsync -cvrhP '/mnt/beegfs01/pipelines_old_centos7/fair_recount_pump/config/config.yaml' .
```

3. Run Snakemake command:

```sh
snakemake   --profile '/mnt/beegfs01/pipelines_old_centos7/fair_recount_pump/profiles/slurm-flamingo' \
            --workflow-profile '/mnt/beegfs01/pipelines_old_centos7/fair_recount_pump/profiles/workflow-slurm-flamingo/config.yaml' \
            -s '/mnt/beegfs01/pipelines_old_centos7/fair_recount_pump/workflow/Snakefile' \
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

## How to:

### One sample with multiple fastq files:

Use quotes and separate your re-sequencing steps by a comma:

```csv
sample,upstream_file,downstream_file,species,build,release
Resequenced1,'/path/to/reads.1.R1.fq.gz,/path/to/reads.2.R1.fq.gz','/path/to/reads.1.R2.fq.gz,/path/to/reads.2.R2.fq.gz',homo_sapiens,GRCh38,105
```
