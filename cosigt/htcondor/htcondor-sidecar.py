#!/usr/bin/env python3
"""
HTCondor sidecar for monitoring job status
"""
import subprocess
import time
import sys
import os

# Set project root
PROJECT_ROOT = "/lustre/home/enza/deliver/napoli/cosi/cosigt/cosigt_smk"

def monitor_jobs():
    """Monitor running HTCondor jobs"""
    user = os.environ.get('USER')
    cmd = f"condor_q {user} -format '%d\\n' ClusterId"
    
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        job_count = len(result.stdout.strip().split('\n')) if result.stdout.strip() else 0
        print(f"Active jobs: {job_count}")
    except Exception as e:
        print(f"Error monitoring jobs: {e}", file=sys.stderr)

if __name__ == "__main__":
    monitor_jobs()
