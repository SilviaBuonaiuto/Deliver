#!/bin/bash
# HTCondor job script wrapper for Snakemake with cache configuration

# Set project root
export PROJECT_ROOT="/lustre/home/enza/deliver/napoli/cosi/cosigt/cosigt_smk"

# CRITICAL: Set cache directories for Singularity/Apptainer
export SINGULARITY_CACHEDIR="/lustre/home/enza/deliver/napoli/cosi/singularity_cache"
export SINGULARITY_TMPDIR="/lustre/home/enza/deliver/napoli/cosi/singularity_tmp"
export APPTAINER_CACHEDIR="/lustre/home/enza/deliver/napoli/cosi/singularity_cache"
export APPTAINER_TMPDIR="/lustre/home/enza/deliver/napoli/cosi/singularity_tmp"
export SINGULARITY_LOCALCACHEDIR="/lustre/home/enza/deliver/napoli/cosi/singularity_cache"
export APPTAINER_LOCALCACHEDIR="/lustre/home/enza/deliver/napoli/cosi/singularity_cache"

# Source user bashrc if it exists
if [ -f "$HOME/.bashrc" ]; then
    source $HOME/.bashrc
fi

# CRITICAL: Activate conda environment on compute nodes
# Try to find conda - check common locations
if [ -f "$HOME/anaconda3/bin/conda" ]; then
    eval "$($HOME/anaconda3/bin/conda shell.bash hook)"
elif [ -f "/lustrehome/silvia/anaconda3/bin/conda" ]; then
    eval "$(/lustrehome/silvia/anaconda3/bin/conda shell.bash hook)"
else
    echo "ERROR: Cannot find conda installation" >&2
    exit 1
fi

# Activate the environment
conda activate smk7324app132

# Verify conda environment is activated
echo "Conda environment: $CONDA_DEFAULT_ENV"
which python
which snakemake

# Ensure we're in the project directory
cd $PROJECT_ROOT || {
    echo "Error: Cannot change to project directory $PROJECT_ROOT" >&2
    exit 1
}

# Debug information
echo "Running on host: $(hostname)"
echo "Current directory: $(pwd)"
echo "Singularity cache: $SINGULARITY_CACHEDIR"
echo "Job started at: $(date)"

# Run the actual snakemake jobscript
exec bash "$@"
