#!/usr/bin/env python3
"""
HTCondor submit script for Snakemake
Adapted for shared Lustre filesystem
"""
import os
import sys
import re
import subprocess
import tempfile
from snakemake.utils import read_job_properties

# Project root directory
PROJECT_ROOT = "/lustre/home/enza/deliver/napoli/cosi/cosigt/cosigt_smk"

# Get jobscript from command line
jobscript = sys.argv[1]

# Read job properties
job_properties = read_job_properties(jobscript)

# Get cluster properties
cluster = job_properties.get("cluster", {})

# Extract job info
rule = job_properties.get("rule", "unnamed")
wildcards = job_properties.get("wildcards", {})
threads = job_properties.get("threads", 1)
resources = job_properties.get("resources", {})

# Get resource requirements
mem_mb = resources.get("mem_mb", 4000)
disk_mb = resources.get("disk_mb", 1000)
runtime = resources.get("runtime", 120)  # in minutes

# Create log directory with absolute path
log_dir = f"{PROJECT_ROOT}/logs/htcondor"
os.makedirs(log_dir, exist_ok=True)

# Format wildcards for job name
wildcards_str = "_".join(f"{k}={v}" for k, v in wildcards.items())
job_name = f"{rule}_{wildcards_str}" if wildcards_str else rule

# Create HTCondor submit file
submit_content = f"""
universe = vanilla
executable = {PROJECT_ROOT}/config/htcondor/htcondor-jobscript.sh
arguments = {jobscript}
output = {log_dir}/{job_name}.$(Cluster).out
error = {log_dir}/{job_name}.$(Cluster).err
log = {log_dir}/{job_name}.$(Cluster).log

# Set working directory
initialdir = {PROJECT_ROOT}

request_cpus = {threads}
request_memory = {mem_mb}M
request_disk = {disk_mb}M

# Set runtime limit
+MaxRuntime = {runtime * 60}
periodic_remove = (JobStatus == 2) && ((CurrentTime - JobStartDate) > {runtime * 60})

# Environment settings
getenv = True
environment = "PROJECT_ROOT={PROJECT_ROOT}"
should_transfer_files = NO

# Additional requirements
requirements = (OpSys == "LINUX") && (Arch == "X86_64")

# Job information for tracking
+SnakemakeRule = "{rule}"
+SnakemakeJobID = "{job_name}"

queue 1
"""

# Write submit file to shared temp location
temp_dir = f"{PROJECT_ROOT}/logs/htcondor/tmp"
os.makedirs(temp_dir, exist_ok=True)

with tempfile.NamedTemporaryFile(mode='w', suffix='.sub', delete=False, dir=temp_dir) as f:
    f.write(submit_content)
    submit_file = f.name

try:
    # Submit job and capture output AND errors
    result = subprocess.run(
        ['condor_submit', submit_file],
        capture_output=True,
        text=True
    )
    
    if result.returncode != 0:
        print(f"ERROR: condor_submit failed with return code {result.returncode}", file=sys.stderr)
        print(f"STDOUT: {result.stdout}", file=sys.stderr)
        print(f"STDERR: {result.stderr}", file=sys.stderr)
        print(f"Submit file location: {submit_file}", file=sys.stderr)
        sys.exit(1)
    
    # Extract job ID from output
    match = re.search(r'cluster (\d+)\.', result.stdout)
    if match:
        print(match.group(1))
    else:
        match = re.search(r'(\d+)\.(\d+)', result.stdout)
        if match:
            print(f"{match.group(1)}.{match.group(2)}")
        else:
            print("Error: Could not parse job ID", file=sys.stderr)
            print(f"Output was: {result.stdout}", file=sys.stderr)
            sys.exit(1)
            
finally:
    # Keep submit file for debugging
    print(f"Submit file kept at: {submit_file}", file=sys.stderr)
    # os.unlink(submit_file)  # COMMENTED FOR DEBUGGING
