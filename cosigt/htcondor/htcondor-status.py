#!/usr/bin/env python3
"""
HTCondor status script for Snakemake
Returns job status in Snakemake-compatible format
"""
import sys
import subprocess
import re

def get_job_status(job_id):
    """Check job status in HTCondor"""
    
    # First try condor_q
    try:
        result = subprocess.run(
            ['condor_q', job_id, '-format', '%d\\n', 'JobStatus'],
            capture_output=True,
            text=True
        )
        
        if result.stdout.strip():
            status_code = int(result.stdout.strip())
        else:
            # Not in queue, check history
            hist_result = subprocess.run(
                ['condor_history', job_id, '-limit', '1', '-format', '%d\\n', 'JobStatus'],
                capture_output=True,
                text=True
            )
            
            if hist_result.stdout.strip():
                status_code = int(hist_result.stdout.strip())
            else:
                return "failed"
                
    except (subprocess.CalledProcessError, ValueError):
        return "failed"
    
    # Map HTCondor status codes to Snakemake status
    status_map = {
        1: "running",    # Idle (waiting to run)
        2: "running",    # Running
        3: "failed",     # Removed
        4: "success",    # Completed
        5: "failed",     # Held
        6: "running",    # Transferring
        7: "running"     # Suspended
    }
    
    return status_map.get(status_code, "failed")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: htcondor-status.py <job_id>", file=sys.stderr)
        sys.exit(1)
    
    job_id = sys.argv[1]
    status = get_job_status(job_id)
    print(status)
