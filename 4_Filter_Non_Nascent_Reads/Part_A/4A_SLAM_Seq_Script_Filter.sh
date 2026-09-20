#!/bin/bash
#SBATCH --job-name eSLAM_Filter_1
#SBATCH --time 24:00:00
#SBATCH --nodes 1
#SBATCH --cpus-per-task 48
#SBATCH --mem 400G
#SBATCH --output eSLAM_Filter_1.%A_%a.log
#SBATCH --array 1-28

# Load Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../config.sh"

echo "PART 4 (A) of SLAM-SEQ Analysis: BAM Filtering"
echo "This script filters BAM files based on detected T->C mutations (via pulseR)."

INDIR_RAW="${RAW_DATA_DIR}"
OUTDIR_HISAT="${HISAT3N_OUTPUT_DIR}"
OUTDIR_MISMATCH="${OUTDIR_HISAT}/mismatch_infos"
SNP_FILE="${SNP_OUTPUT_DIR}/${SNP_UNION_OUTPUT}"
FILELIST="${SAMPLE_FILELIST}"

mkdir -p "${OUTDIR_MISMATCH}"


# Ensure all required inputs, lists, and scripts exist before running.

if [[ ! -f "$FILELIST" ]]; then
    echo "ERROR: filelist.txt not found at ${FILELIST}."
    exit 1
fi

if [[ ! -f "$SNP_FILE" ]]; then
    echo "ERROR: SNP file not found at ${SNP_FILE}. Did step 3 finish successfully?"
    exit 1
fi

if [[ ! -f "$SPLBAM_SCRIPT" ]]; then
    echo "ERROR: splbam.py not found at ${SPLBAM_SCRIPT}."
    exit 1
fi

FILE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "${FILELIST}")
BAM_INPUT="${OUTDIR_HISAT}/${FILE}_aligned.unique.sorted.bam"

if [[ ! -f "$BAM_INPUT" ]]; then
    echo "ERROR: Input BAM not found for ${FILE} at ${BAM_INPUT}"
    exit 1
fi

echo "Processing sample: ${FILE}"

# Load Modules
module load gcc
module load python
module load samtools


# Identifie true conversions, subtracting known SNPs to avoid false positives.
echo "Start splbam.py"
python "${SPLBAM_SCRIPT}" \
    --subtract "${SNP_FILE}" \
    --ref-base "${CONVERSION_REFERENCE_BASE}" \
    --base-change "${CONVERSION_BASE}" \
    --base-qual "${MINIMUM_BASE_QUALITY}" \
    --trim5p "${TRIM_5P}" \
    --trim3p "${TRIM_3P}" \
    --overwrite \
    --num-cpus "${SLURM_CPUS_PER_TASK}" \
    --mem "${SPLBAM_MEMORY}" \
    "${BAM_INPUT}" \
    "${OUTDIR_MISMATCH}/" \
    "${FILE}"

# BAM FILTERING
# Filter the original BAM file using the list of reads with true conversions
echo "Filtering BAM file using the true conversions list"
samtools view -h -b --threads "${SLURM_CPUS_PER_TASK}" \
    -N "${OUTDIR_MISMATCH}/${FILE}.trueconversions_list.tab" \
    "${BAM_INPUT}" > "${OUTDIR_HISAT}/${FILE}_aligned.unique.filtered.bam"

# Sort and index the filtered BAM
echo "Sort and index filtered BAM file"
samtools sort --threads "${SLURM_CPUS_PER_TASK}" \
    -o "${OUTDIR_HISAT}/${FILE}_aligned.unique.filtered.sorted.bam" \
    "${OUTDIR_HISAT}/${FILE}_aligned.unique.filtered.bam"

samtools index -@ "${SLURM_CPUS_PER_TASK}" "${OUTDIR_HISAT}/${FILE}_aligned.unique.filtered.sorted.bam"

# Cleanup
rm -f "${OUTDIR_HISAT}/${FILE}_aligned.unique.filtered.bam"

echo "Script finished successfully"
