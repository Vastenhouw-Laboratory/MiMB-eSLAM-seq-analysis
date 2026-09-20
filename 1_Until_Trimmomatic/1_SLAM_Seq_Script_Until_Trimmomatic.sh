#!/bin/bash
#SBATCH --job-name eSLAM_until_Trimmomatic
#SBATCH --time 12:00:00
#SBATCH --nodes 1
#SBATCH --cpus-per-task 48
#SBATCH --output eSLAM_until_Trimmomatic.%A_%a.log
#SBATCH --array 1-28

echo "PART 1 of eSLAM-SEQ Analysis"
echo "This script will perform pre-filtering (before mapping)"
echo "The raw .fastq.gz files need to be saved in the INDIR_RAW directory"
echo "The fw and rv files must have the same name and end with _R1.fastq.gz and sample_R2.fastq.gz"
echo "Prepare a filelist.txt file in INDIR_RAW with all the file names (without the _R1.fastq.gz, _R2.fastq.gz)"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config.sh"

FILE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "${SAMPLE_FILELIST}")
echo "Running analysis on $FILE"

module load gcc
module load fastqc
module load trimmomatic
module load python
module load samtools
module load picard

echo "Version of FastQC used:"
fastqc --version
echo "Version of Trimmomatic used:"
trimmomatic -version

echo "FastQC 1 started"
bash "${SCRIPT_DIR}/fastqc.sh" "${RAW_DATA_DIR}" "${FASTQC_BEFORE_DIR}" "${SLURM_CPUS_PER_TASK}" "${FILE}"
echo "Trimmomatic started"
bash "${SCRIPT_DIR}/trimmomatic.sh" "${RAW_DATA_DIR}" "${TRIMMOMATIC_OUTPUT_DIR}" "${SLURM_CPUS_PER_TASK}" "${FILE}" "${TRIMMOMATIC_ADAPTERS_DIR}" \
  "${TRIMMOMATIC_LEADING}" "${TRIMMOMATIC_TRAILING}" "${TRIMMOMATIC_SLIDINGWINDOW}" \
  "${TRIMMOMATIC_MINLEN}" "${TRIMMOMATIC_ADAPTER_OPTIONS}"
echo "FastQC 2 started"
bash "${SCRIPT_DIR}/fastqc.sh" "${TRIMMOMATIC_OUTPUT_DIR}" "${FASTQC_AFTER_DIR}" "${SLURM_CPUS_PER_TASK}" "${FILE}"

echo "unzip fastq.gz files (Trimmomatic output)"
gunzip "${TRIMMOMATIC_OUTPUT_DIR}/${FILE}_R1.fastq.gz"
gunzip "${TRIMMOMATIC_OUTPUT_DIR}/${FILE}_R2.fastq.gz"

echo "Script finished"
