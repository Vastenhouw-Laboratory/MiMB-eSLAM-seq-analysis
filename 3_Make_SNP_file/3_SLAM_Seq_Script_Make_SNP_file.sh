#!/bin/bash
#SBATCH --job-name eSLAM_Make_SNP_file
#SBATCH --time 4:00:00
#SBATCH --nodes 1
#SBATCH --cpus-per-task 4  # Requesting 4 CPUs to run the 4 samples in parallel. Adjust if using more untreated controls.
#SBATCH --output eSLAM_Make_SNP_file.%j.log

# Load Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config.sh"

echo "PART 3 of eSLAM-SEQ Analysis: SNP Identification & Union"


INDIR_RAW="${RAW_DATA_DIR}"
OUTDIR_HISAT="${HISAT3N_OUTPUT_DIR}"
OUTDIR_SNP="${SNP_OUTPUT_DIR}"
FILELIST="${CONTROL_FILELIST}"

mkdir -p "${OUTDIR_SNP}"

if [[ ! -f "$FILELIST" ]] || [[ ! -f "$GENOME_FASTA" ]]; then
    echo "ERROR: Missing filelist or reference genome."
    exit 1
fi

# Load Modules
module load gcc
module load samtools
module load varscan
module load r

# Variant Calling
echo "Starting parallel Varscan2 calls..."

# Read the filelist and run each sample in the background (&)
while IFS= read -r FILE; do
    if [[ -n "$FILE" ]]; then
        echo "Processing control sample: ${FILE}"
        (
            set -o pipefail
            samtools mpileup -f "${GENOME_FASTA}" "${OUTDIR_HISAT}/${FILE}_aligned.unique.sorted.bam" | \
                varscan pileup2snp \
                --min-coverage "${VARSCAN_MIN_COVERAGE}" \
                --min-reads2 "${VARSCAN_MIN_READS2}" \
                --min-avg-qual "${VARSCAN_MIN_AVG_QUAL}" \
                --min-var-freq "${VARSCAN_MIN_VAR_FREQ}" \
                --p-value "${VARSCAN_P_VALUE}" > "${OUTDIR_SNP}/${FILE}.varscan.snp"
        ) & 
    fi
done < "$FILELIST"

# The 'wait' command pauses the script here until all background tasks finish
wait
echo "All SNP calling finished successfully."

# R SCRIPT POST-PROCESSING
echo "Running R script to create SNP union..."

# Navigate to the SNP output directory so the R script can find the files locally
cd "${OUTDIR_SNP}" || exit 1

Rscript --vanilla "${SNP_UNION_SCRIPT}" "${CONTROL_FILELIST}" "${SNP_UNION_OUTPUT}" "${SNP_UNION_MIN_COVERAGE}"

echo "Script finished completely!"
