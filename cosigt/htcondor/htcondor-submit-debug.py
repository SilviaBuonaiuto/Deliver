#!/usr/bin/env python3
"""
HTCondor submit script for Snakemake - DEBUG VERSION
"""
import os
import sys
import re
import subprocess
import tempfile
from snakemake.utils import read_job_properties

print("DEBUG: htcondor-submit.py called with:", sys.argv, file=sys.stderr)

# Project root directory
PROJECT_ROOT = "/lustre/home/enza/deliver/napoli/cosi/cosigt/cosigt_smk"

# Get jobscript from command line
jobscript = sys.argv[1]
print(f"DEBUG: Jobscript path: {jobscript}", file=sys.stderr)

# Check if jobscript exists
if not os.path.exists(jobscript):
    print(f"ERROR: Jobscript does not exist: {jobscript}", file=sys.stderr)
    sys.exit(1)

# Read job properties
try:
    job_properties = read_job_properties(jobscript)
    print(f"DEBUG: Job properties: {job_properties}", file=sys.stderr)
except Exception as e:
    print(f"ERROR reading job properties: {e}", file=sys.stderr)
    sys.exit(1)

# Extract job info
rule = job_properties.get("rule", "unnamed")
wildcards = job_properties.get("wildcards", {})
threads = job_properties.get("threads", 1)
resources = job_properties.get("resources", {})

# Get resource requirements
mem_mb = resources.get("mem_mb", 4000)
disk_mb = resources.get("disk_mb", 1000)
runtime = resources.get("runtime", 120)

# Create log directory
log_dir = f"{PROJECT_ROOT}/logs/htcondor"
os.makedirs(log_dir, exist_ok=True)

# Format wildcards for job name
wildcards_str = "_".join(f"{k}={v}" for k, v in wildcards.items())
job_name = f"{rule}_{wildcards_str}" if wildcards_str else rule

# Check if executable exists
executable_path = f"{PROJECT_ROOT}/config/htcondor/htcondor-jobscript.sh"
if not os.path.exists(executable_path):
    print(f"ERROR: Executable does not exist: {executable_path}", file=sys.stderr)
    sys.exit(1)

# Create HTCondor submit file
submit_content = f"""
universe = vanilla
executable = {executable_path}
arguments = {jobscript}
output = {log_dir}/{job_name}.$(Cluster).out
error = {log_dir}/{job_name}.$(Cluster).err
log = {log_dir}/{job_name}.$(Cluster).log
initialdir = {PROJECT_ROOT}
request_cpus = {threads}
request_memory = {mem_mb}M
request_disk = {disk_mb}M
getenv = True
should_transfer_files = NO
requirements = (OpSys == "LINUX") && (Arch == "X86_64")
queue 1
"""

print(f"DEBUG: Submit file content:", file=sys.stderr)
print(submit_content, file=sys.stderr)

# Write submit file
temp_dir = f"{PROJECT_ROOT}/logs/htcondor/tmp"
os.makedirs(temp_dir, exist_ok=True)

try:
    with tempfile.NamedTemporaryFile(mode='w', suffix='.sub', delete=False, dir=temp_dir) as f:
        f.write(submit_content)
        submit_file = f.name
    
    print(f"DEBUG: Submit file written to: {submit_file}", file=sys.stderr)
    
    # Submit job
    cmd = ['condor_submit', submit_file]
    print(f"DEBUG: Running command: {' '.join(cmd)}", file=sys.stderr)
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    print(f"DEBUG: Return code: {result.returncode}", file=sys.stderr)
    print(f"DEBUG: STDOUT: {result.stdout}", file=sys.stderr)
    print(f"DEBUG: STDERR: {result.stderr}", file=sys.stderr)
    
    if result.returncode != 0:
        sys.exit(1)
    
    # Parse job ID
    match = re.search(r'cluster (\d+)', result.stdout)
    if match:
        print(match.group(1))
    else:
        print("Error: Could not parse job ID", file=sys.stderr)
        sys.exit(1)
        
except Exception as e:
    print(f"ERROR: Exception occurred: {e}", file=sys.stderr)
    sys.exit(1)
finally:
    if 'submit_file' in locals():
        print(f"DEBUG: Submit file kept at: {submit_file}", file=sys.stderr)
