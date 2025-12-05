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
set -euo 'pipefail'
shopt -s nullglob

# Logging details
echo "Working at:"
hostname
date

# Dealing with temporary directories
BIGR_TMP="${PWD}/tmp"
TMP="${BIGR_TMP}"
TEMP="${BIGR_TMP}"
TMPDIR="${BIGR_TMP}"
TEMPDIR="${BIGR_TMP}"
_JAVA_OPTIONS=" -Djava.io.tmpdir=\"${BIGR_TMP}\" "

export BIGR_TMP
export _JAVA_OPTIONS TMP TEMP TMPDIR TEMP
echo -e "Temporary directory: ${TMP}"

# Conda environment
source "/home/t_dayris/conda_envs/miniconda3/etc/profile.d/conda.sh"
source "/home/t_dayris/conda_envs/miniconda3/etc/profile.d/mamba.sh"
conda activate --no-stack \
    "/mnt/beegfs02/pipelines/unofficial-snakemake-wrappers/shared_install/snakemake_v8.16.0"

snakemake --version
echo "Conda activated"

# Run pipeline
snakemake \
  --cores 20 \
  --jobs 30 \
  --local-cores 2 \
  --keep-going \
  --rerun-triggers 'mtime' \
  --executor 'slurm-gustave-roussy' \
  --benchmark-extended \
  --rerun-incomplete \
  --printshellcmds \
  --restart-times 3 \
  --show-failed-logs \
  --jobname '{name}.{jobid}.slurm.snakejob.sh' \
  --conda-prefix '/mnt/beegfs02/pipelines/unofficial-snakemake-wrappers/shared_install/' \
  --apptainer-prefix '/mnt/beegfs02/pipelines/unofficial-snakemake-wrappers/singularity/' \
  --shadow-prefix "${BIGR_TMP}" \
  --software-deployment-method 'conda' \
  --conda-frontend 'conda' \
  --use-envmodules \
  -s '/path/to/workflow/Snakefile' \
  --configfile '/path/to/config/config.yaml'

