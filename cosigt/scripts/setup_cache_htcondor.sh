#!/bin/bash

echo "Setting up Singularity/Apptainer cache for HTCondor"
echo "Time: $(date)"
echo "========================================"

# Your Lustre directories
LUSTRE_BASE="/lustre/home/enza/deliver/napoli/cosi"
WORKING_DIR="$LUSTRE_BASE/cosigt/cosigt_smk"

# Set up cache directories in Lustre
CACHE_DIR="$LUSTRE_BASE/singularity_cache"
TMP_DIR="$LUSTRE_BASE/singularity_tmp"

# Create directories
echo "Creating cache directories..."
mkdir -p "$CACHE_DIR" "$TMP_DIR"

if [ -d "$CACHE_DIR" ] && [ -d "$TMP_DIR" ]; then
    echo "✓ Cache directories created successfully:"
    echo "  Cache: $CACHE_DIR"
    echo "  Temp: $TMP_DIR"
else
    echo "✗ ERROR: Failed to create cache directories"
    exit 1
fi

# Backup the original cosigt_smk.sh
echo ""
echo "Backing up original cosigt_smk.sh..."
cp "$WORKING_DIR/cosigt_smk.sh" "$WORKING_DIR/cosigt_smk.sh.backup.$(date +%Y%m%d_%H%M%S)"

# Create new version with cache exports AND HTCondor profile
echo ""
echo "Creating HTCondor-enabled cosigt_smk.sh..."
cat > "$WORKING_DIR/cosigt_smk_htcondor.sh" << INNEREOF
#!/bin/bash
# Modified for HTCondor with Lustre cache directories

# CRITICAL: Set ALL cache directories BEFORE running snakemake
export SINGULARITY_CACHEDIR="$CACHE_DIR"
export SINGULARITY_TMPDIR="$TMP_DIR"
export APPTAINER_CACHEDIR="$CACHE_DIR"
export APPTAINER_TMPDIR="$TMP_DIR"
export SINGULARITY_LOCALCACHEDIR="$CACHE_DIR"
export APPTAINER_LOCALCACHEDIR="$CACHE_DIR"

# Disable any default paths
unset SINGULARITY_PULLFOLDER
unset APPTAINER_PULLFOLDER

echo "Using Singularity/Apptainer cache at: \$APPTAINER_CACHEDIR"

# Run with HTCondor profile instead of local execution
SINGULARITY_TMPDIR=$TMP_DIR snakemake \
    --use-singularity \
    --singularity-args "-B /lustre/home/enza,/lustrehome/silvia -e" \
    --profile config/htcondor \
    --jobs 100 \
    --rerun-triggers=mtime \
    --rerun-incomplete \
    cosigt
INNEREOF

chmod +x "$WORKING_DIR/cosigt_smk_htcondor.sh"
echo "✓ Created cosigt_smk_htcondor.sh"

echo ""
echo "==========================================="
echo "✓ SETUP COMPLETE!"
echo "==========================================="
echo ""
echo "Cache directories created at:"
echo "  $CACHE_DIR"
echo "  $TMP_DIR"
echo ""
echo "TO RUN COSIGT with HTCondor:"
echo "   cd $WORKING_DIR"
echo "   ./cosigt_smk_htcondor.sh"
echo ""
echo "The pipeline will now submit jobs to HTCondor instead of running locally."
echo "==========================================="
