#!/usr/bin/env bash

# Central configuration for the eSLAM-seq pipeline.
#
# Edit this file before submitting any of the SLURM scripts. User-supplied
# paths should be absolute. Repository paths below are derived from this
# file's location, so jobs can be submitted from any working directory.

CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Project and reference data
PROJECT_DIR="/scratch/mugolini/eSLAM"
GENOME_FASTA="/scratch/mugolini/GRCz11_105_GENOME/Danio_rerio.GRCz11.105.dna.primary_assembly.fa"
ANNOTATION_GTF="/scratch/mugolini/GRCz11_105_GENOME/Danio_rerio.GRCz11.105.gtf.gz"

# Executables and auxiliary data not supplied through environment modules
HISAT3N_EXECUTABLE="/users/mugolini/hisat-3n/hisat-3n"
FEATURECOUNTS_EXECUTABLE="/users/mugolini/subread-2.0.3-Linux-x86_64/bin/featureCounts"
TRIMMOMATIC_ADAPTERS_DIR="${PROJECT_DIR}/Trimmomatic_adapters"

# Sample lists and scripts distributed with this repository
SAMPLE_FILELIST="${CONFIG_DIR}/filelist.txt"
CONTROL_FILELIST="${CONFIG_DIR}/filelist_IAA_minus.txt"
SNP_UNION_SCRIPT="${CONFIG_DIR}/3_Make_SNP_file/SNP_union.R"
SPLBAM_SCRIPT="${CONFIG_DIR}/4_Filter_Non_Nascent_Reads/Part_A/splbam.py"

# Project subdirectories
RAW_DATA_DIR="${PROJECT_DIR}/RAW_DATA_MERGED"
FASTQC_BEFORE_DIR="${PROJECT_DIR}/FastQC_Output"
TRIMMOMATIC_OUTPUT_DIR="${PROJECT_DIR}/Trimmomatic_Output"
FASTQC_AFTER_DIR="${PROJECT_DIR}/FastQC_Output_2"
HISAT3N_OUTPUT_DIR="${PROJECT_DIR}/HISAT3N_Output"
HISAT3N_INDEX="${PROJECT_DIR}/GENOME_INDEX/Genome_3n_TC/genome_3n_TC"
SNP_OUTPUT_DIR="${PROJECT_DIR}/SNP_Output"
SNP_UNION_OUTPUT="SNP_output.snp"
SNP_UNION_MIN_COVERAGE=20
FEATURECOUNTS_OUTPUT_DIR="${PROJECT_DIR}/FeatureCounts_Output"

# Analysis parameters
CONVERSION_REFERENCE_BASE="T"
CONVERSION_BASE="C"
HISAT3N_RNA_STRANDNESS="RF"
MINIMUM_BASE_QUALITY=20
TRIM_5P=0
TRIM_3P=0
SPLBAM_MEMORY="400G"

# Trimmomatic settings
TRIMMOMATIC_LEADING=3
TRIMMOMATIC_TRAILING=3
TRIMMOMATIC_SLIDINGWINDOW="4:15"
TRIMMOMATIC_MINLEN=36
TRIMMOMATIC_ADAPTER_OPTIONS="2:30:10"

# VarScan settings
VARSCAN_MIN_COVERAGE=20
VARSCAN_MIN_READS2=5
VARSCAN_MIN_AVG_QUAL=15
VARSCAN_MIN_VAR_FREQ=0.25
VARSCAN_P_VALUE=0.01

# featureCounts settings
FEATURECOUNTS_MIN_OVERLAP=10
FEATURECOUNTS_STRAND=2
FEATURECOUNTS_FEATURE_TYPE="exon"
FEATURECOUNTS_ATTRIBUTE="gene_id"

# Mutation-count groups emitted by the mismatch-analysis tooling
MUTATION_CATEGORIES=("1" "2" "3" "4" "more.4")
