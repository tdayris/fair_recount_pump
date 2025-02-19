#!/usr/bin/bash

# Slurm parameters
#SBATCH --job-name='Fair_recount_pump'
#SBATCH --output='logs/slurm/%x_%j_%u.out'
#SBATCH --error=logs/slurm/%x_%j_%u.err'
#SBATCH --mem='2G'
#SBATCH --cpus-per-task='2'
#SBATCH --time='1-00:00:00'
#SBATCH --partition='mediumq'
#SBATCH --comment='Snakemake launcher for Fair Recount Pump'


# Ensure bash works properly or stops
set -eiop 'pipefail'
shopt -s nullglob

# Logging details
hostname
date

# Conda environment
source "/mnt/beegfs/pipelines/unofficial-snakemake-wrappers/shared_install/snakemake_v8.16.0/etc/profile.d/conda.sh"
source "/mnt/beegfs/pipelines/unofficial-snakemake-wrappers/shared_install/snakemake_v8.16.0/etc/profile.d/mamba.sh"
conda activate "/mnt/beegfs/pipelines/unofficial-snakemake-wrappers/shared_install/snakemake_v8.16.0"

# Run pipeline
snakemake \\
  --cores 30 \\
  --jobs 50 \\
  --local-cores 2 \\
  --keep-going \\
  --rerun-triggers 'mtime' \\
  --executor slurm-gustave-roussy \\
  --benchmark-extended \\
  --rerun-incomplete \\
  --printshellcmds \\
  --restart-times 3 \\
  --show-failed-logs \\
  --jobname '{name}.{jobid}.slurm.snakejob.sh' \\
  --conda-prefix '' \\
  --apptainer-prefix '' \\
  --shadow-prefix ''
