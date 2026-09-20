#!/bin/bash
#SBATCH --job-name eSLAM_FeatureCounts
#SBATCH --time 2:00:00
#SBATCH --nodes 1
#SBATCH --cpus-per-task 12
#SBATCH --output eSLAM_FeatureCounts.log

# Load Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config.sh"
ANNOTATION="${ANNOTATION_GTF}"

echo "PART 5 of eSLAM-SEQ Analysis: Quantification with FeatureCounts"

OUTDIR_HISAT="${HISAT3N_OUTPUT_DIR}"
OUTDIR_COUNTS="${FEATURECOUNTS_OUTPUT_DIR}"

mkdir -p "${OUTDIR_COUNTS}"


# Ensure the annotation GTF and featureCounts binary exist before proceeding.
if [[ ! -f "$ANNOTATION" ]]; then
    echo "ERROR: GTF Annotation file not found at ${ANNOTATION}."
    exit 1
fi

if [[ ! -x "${FEATURECOUNTS_EXECUTABLE}" ]]; then
    echo "ERROR: featureCounts executable not found or not executable at ${FEATURECOUNTS_EXECUTABLE}."
    exit 1
fi

# Load Modules
module load gcc
module load r


# Finda all coordinate-sorted BAM files in HISAT3N_Output and quantifies reads:
#   -p --countReadPairs : Quantify paired-end fragments instead of individual reads
#   -B                  : Require both ends of a pair to map to the same chromosome
#   --minOverlap 10     : Minimum required overlapping bases (10 bp)
#   -s 2                : Reversely stranded library orientation
#   -t exon -g gene_id  : Summarize exon features to gene level IDs
echo "--- Step 1: Locating all sorted .bam files (filtered and unfiltered) ---"
bamlist_all=$(find "${OUTDIR_HISAT}" -maxdepth 1 -type f -name "*.sorted.bam")

if [[ -z "$bamlist_all" ]]; then
    echo "ERROR: No .sorted.bam files found in ${OUTDIR_HISAT}."
    exit 1
fi

echo "Running featureCounts on all BAM files..."
"${FEATURECOUNTS_EXECUTABLE}" \
    -p --countReadPairs -B \
    --minOverlap "${FEATURECOUNTS_MIN_OVERLAP}" \
    -s "${FEATURECOUNTS_STRAND}" \
    -T "${SLURM_CPUS_PER_TASK}" \
    -t "${FEATURECOUNTS_FEATURE_TYPE}" \
    -g "${FEATURECOUNTS_ATTRIBUTE}" \
    -a "${ANNOTATION}" \
    -o "${OUTDIR_COUNTS}/raw_counts_proper_orientation_filtered_and_unfiltered.txt" \
    ${bamlist_all}


# Isolate only the true-conversion filtered BAM files (*_aligned.unique.filtered.sorted.bam)
echo "--- Step 2: Locating filtered .bam files only ---"
bamlist_filtered=$(find "${OUTDIR_HISAT}" -maxdepth 1 -type f -name "*_aligned.unique.filtered.sorted.bam")

if [[ -z "$bamlist_filtered" ]]; then
    echo "ERROR: No filtered .sorted.bam files found in ${OUTDIR_HISAT}."
    exit 1
fi

echo "Running featureCounts on filtered BAM files..."
"${FEATURECOUNTS_EXECUTABLE}" \
    -p --countReadPairs -B \
    --minOverlap "${FEATURECOUNTS_MIN_OVERLAP}" \
    -s "${FEATURECOUNTS_STRAND}" \
    -T "${SLURM_CPUS_PER_TASK}" \
    -t "${FEATURECOUNTS_FEATURE_TYPE}" \
    -g "${FEATURECOUNTS_ATTRIBUTE}" \
    -a "${ANNOTATION}" \
    -o "${OUTDIR_COUNTS}/raw_counts_proper_orientation_filtered.txt" \
    ${bamlist_filtered}

echo "Script finished successfully"
