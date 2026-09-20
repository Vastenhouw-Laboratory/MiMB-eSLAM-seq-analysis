#!/bin/bash
#SBATCH --job-name eSLAM_HISAT3N_mapping
#SBATCH --time 12:00:00
#SBATCH --nodes 1
#SBATCH --cpus-per-task 48
#SBATCH --output eSLAM_HISAT3N_mapping.%A_%a.log
#SBATCH --array 1-28

# Load Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config.sh"

echo "PART 2 of eSLAM-SEQ Analysis: HISAT-3N Mapping"

INDIR_RAW="${RAW_DATA_DIR}"
OUTDIR_TRIMMOMATIC="${TRIMMOMATIC_OUTPUT_DIR}"
OUTDIR_HISAT="${HISAT3N_OUTPUT_DIR}"
INDEX_HISAT3N="${HISAT3N_INDEX}"
FILELIST="${SAMPLE_FILELIST}"

# Create output folder if it doesn't already exist
mkdir -p "${OUTDIR_HISAT}"

if [[ ! -f "$FILELIST" ]]; then
    echo "ERROR: filelist.txt not found in ${INDIR_RAW}."
    exit 1
fi

FILE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "${FILELIST}")
echo "Running alignment analysis on sample: ${FILE}"


# Load Modules
module load gcc
module load python
module load samtools
module load picard


# Align uncompressed paired-end FASTQ reads. 
# Key options:
#   --base-change T,C : Configures nucleotide conversion tracking for eSLAM-seq.
#   --rna-strandness RF / --fr : Handles stranded paired-end library configuration.
#   --no-discordant : Excludes pairs that don't map with expected orientation/distance.

echo "Mapping started"
"${HISAT3N_EXECUTABLE}" --base-change "${CONVERSION_REFERENCE_BASE},${CONVERSION_BASE}" --repeat -p "${SLURM_CPUS_PER_TASK}" \
  --rna-strandness "${HISAT3N_RNA_STRANDNESS}" --fr --no-discordant \
  --summary-file "${OUTDIR_TRIMMOMATIC}/${FILE}_summary" \
  -x "${INDEX_HISAT3N}" \
  -1 "${OUTDIR_TRIMMOMATIC}/${FILE}_R1.fastq" \
  -2 "${OUTDIR_TRIMMOMATIC}/${FILE}_R2.fastq" \
  -S "${OUTDIR_HISAT}/${FILE}_aligned.sam"

echo "Mapping completed successfully"


# Re-compresses FASTQ input files after mapping to minimize storage usage.
echo "Re-zipping fastq files"
gzip "${OUTDIR_TRIMMOMATIC}/${FILE}_R1.fastq"
gzip "${OUTDIR_TRIMMOMATIC}/${FILE}_R2.fastq"


# Convert SAM to BAM format while filtering for high-confidence alignments:
#   -f 0x2     : Read mapped in proper pair
#   -F 0x4     : Read unmapped (excluded)
#   -F 0x100   : Secondary alignment (excluded)
#   [NH] == 1  : Keeps only uniquely mapped reads (Number of Hits = 1)

echo "Keeping only uniquely mapped pairs"
samtools view -h -b -f 0x2 -F 0x4 -F 0x100 --threads "${SLURM_CPUS_PER_TASK}" \
  --input-fmt-option 'filter=[NH] == 1' \
  "${OUTDIR_HISAT}/${FILE}_aligned.sam" > "${OUTDIR_HISAT}/${FILE}_aligned.unique.bam"

# Remove initial uncompressed SAM file to free disk space
rm -f "${OUTDIR_HISAT}/${FILE}_aligned.sam"


# Picard FixMateInformation updates mate-pair tags and syncs mate information
# after filtering reads, ensuring downstream tools process pairs correctly.

echo "Fixmate"
picard FixMateInformation \
  --INPUT "${OUTDIR_HISAT}/${FILE}_aligned.unique.bam" \
  --OUTPUT "${OUTDIR_HISAT}/${FILE}_aligned.unique.fixmate.bam" \
  --IGNORE_MISSING_MATES FALSE


# Sort the final BAM file by genomic coordinate, index, and generate mapping summary metrics.
echo "Sorting file by coordinate"
samtools sort --threads "${SLURM_CPUS_PER_TASK}" \
  -o "${OUTDIR_HISAT}/${FILE}_aligned.unique.sorted.bam" \
  "${OUTDIR_HISAT}/${FILE}_aligned.unique.fixmate.bam"

samtools index -@ "${SLURM_CPUS_PER_TASK}" "${OUTDIR_HISAT}/${FILE}_aligned.unique.sorted.bam"
samtools flagstats -@ "${SLURM_CPUS_PER_TASK}" "${OUTDIR_HISAT}/${FILE}_aligned.unique.sorted.bam"


# Delete temporary un-sorted BAM files to avoid unnecessary storage clutter.
rm -f "${OUTDIR_HISAT}/${FILE}_aligned.unique.bam"
rm -f "${OUTDIR_HISAT}/${FILE}_aligned.unique.fixmate.bam"

echo "Script finished successfully"
