#!/bin/bash

# Map each chromosome to its assembly file (adjust paths)
for c in $(ls /lustre/home/enza/deliver/napoli/cosi/assemblies_a/*.fasta.gz); do 
    fasta=$(basename $c)
    id=$(echo $fasta | cut -d "." -f 1)
    echo -e "$id\t$c" >> /lustre/home/enza/deliver/napoli/cosi/asm_map.tsv
done

# Create sample mapping (adjust paths)
for s in $(ls /lustre/home/enza/deliver/napoli/cram/*.cram); do 
    cram=$(basename $s)
    id=$(echo $cram | cut -d "." -f 1)
    echo -e "$s\t$id" >> /lustre/home/enza/deliver/napoli/cosi/sample_map.tsv
done

# Download gene annotations
#/usr/bin/wget https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_47/gencode.v47.annotation.gtf.gz

# Organize input for cosigt
~/anaconda3/envs/smk7324app132/bin/python3 /lustre/home/enza/deliver/napoli/cosi/cosigt/cosigt_smk/workflow/scripts/organize.py \
    -a /lustre/home/enza/deliver/napoli/cosi/asm_map.tsv \
    -g /lustre/home/enza/silvia/reference/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna \
    -r /lustre/home/enza/deliver/napoli/cram \
    -b /lustre/home/enza/deliver/napoli/cosi/regions/roi.bed \
    -o /lustrehome/silvia/junk/cosigt_setup \
    --map /lustre/home/enza/deliver/napoli/cosi/sample_map.tsv \
    --gtf /lustre/home/enza/deliver/napoli/cosi/annotations/gencode.v47.annotation.gtf.gz \
    --proteins /lustre/home/enza/deliver/napoli/cosi/annotations/gencode.v47.pc_transcripts.fa \
    --tmp /lustre/home/enza/deliver/napoli/cosi/tmp \
    --threads 8
