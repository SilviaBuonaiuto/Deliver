# Cosigt workflow on Recas

## Install snakemake and cosigt
```
conda create \
    -n smk7324app132 \
    bioconda::snakemake=7.32.4 \
    conda-forge::apptainer=1.3.2 \
    conda-forge::cookiecutter=2.6.0 \
    conda-forge::gdown
```
Clone cosigt directory from github
```
git clone https://github.com/davidebolo1993/cosigt.git
```

## Configure workflow on HTcondor
### 1. Create the HTCondor Profile Directory
```
mkdir -p ~/.config/snakemake/htcondor
cd ~/.config/snakemake/htcondor
```

### 2. Create the Main Configuration File
[config.yaml](https://github.com/SilviaBuonaiuto/Deliver/blob/main/cosigt/htcondor/config.yaml)
### 3. Create htcondor-submit.py (Job Submission Script)
[htcondor-submit.py](https://github.com/SilviaBuonaiuto/Deliver/blob/main/cosigt/htcondor/htcondor-submit.py)
### 4. Create htcondor-status.py (Job Status Checking)
[htcondor-status.py](https://github.com/SilviaBuonaiuto/Deliver/blob/main/cosigt/htcondor/htcondor-status.py)
### 5. Create htcondor-jobscript.sh (Job Wrapper)
[htcondor-jobscript.sh](https://github.com/SilviaBuonaiuto/Deliver/blob/main/cosigt/htcondor/htcondor-jobscript.sh)
### 6. Create htcondor-sidecar.py (Job Monitoring)
[htcondor-sidecar.py](https://github.com/SilviaBuonaiuto/Deliver/blob/main/cosigt/htcondor/htcondor-sidecar.py)

## Required files

### 1. Reference Genome (fasta) 
### 2. Alignments (our sequences aligned on reference genome in .bam and .cram)
### 3. Genome assemblies
```
# Create folder to store assemblies files
mkdir assemblies_a

# Download chromosome-specific pangenome graphs
wget https://s3-us-west-2.amazonaws.com/human-pangenomics/pangenomes/freeze/freeze1/pggb/chroms/chr10.hprc-v1.0-pggb.gfa.gz
wget https://s3-us-west-2.amazonaws.com/human-pangenomics/pangenomes/freeze/freeze1/pggb/chroms/chr17.hprc-v1.0-pggb.gfa.gz
# Download AGC (Assembly Graph Container)
wget https://zenodo.org/record/5826274/files/HPRC-yr1.agc?download=1 -O HPRC-yr1.agc 
```
Extract fasta sequences for desired chromosomes from pangenome graphs (all HPRC year 1 samples) 
```
#
WORK_DIR="/lustre/home/enza/deliver/napoli/cosi/assemblies_a"
for chr in chr10 chr17; do
        zgrep "^P" "${WORK_DIR}/${chr}.hprc-v1.0-pggb.gfa.gz" | cut -f2 | sort -u > "${WORK_DIR}/${chr}.all_ids.txt"

        # Extract FASTA sequences
        cat "${WORK_DIR}/${chr}.all_ids.txt" | while read f; do
        ~/anaconda3/envs/smk7324app132/bin/agc getctg /lustre/home/enza/deliver/napoli/cosi/assemblies_a/HPRC-yr1.agc $f | \
        /lustrehome/silvia/bin/htslib-1.15/bgzip >> "${WORK_DIR}/${chr}.fasta.gz"
done
samtools faidx "${WORK_DIR}/${chr}.fasta.gz"
done

```

### 4. Region of interest

Create bed file containing regions of interest
```
# Create folder to store regions of interest
mkdir regions

# Write bed file roi.bed
chr10   31318495        31529814        ZEB1
chr17   31094927        31382116        NF1
```

### 5. Annotation files
```
# Download gene annotations for the regions of interest
wget https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_47/gencode.v47.annotation.gtf.gz

# Download Protein-coding transcript sequences
wget https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_47/gencode.v47.pc_transcripts.fa.gz

# Unzip protein-coding transcript sequences fasta file
bgzip -d gencode.v47.pc_transcripts.fa.gz

# Index protein-coding transcript sequences fasta file
samtools faidx gencode.v47.pc_transcripts.fa
```

## Configure workflow
Once all the files are available, configure the pipeline using a dedicated setup script and run it on the cluster


## Notes
Understand why this is the output directory and change it /lustrehome/silvia/junk/cosigt_setup/
For now I manually moved it in /lustre/home/enza/deliver/napoli/cosi/