# eSLAM-seq analysis pipeline

This repository contains a five-stage, SLURM-oriented workflow for processing
paired-end **eSLAM-seq** data. The workflow trims and quality-checks reads,
aligns them with HISAT-3N, identifies genomic SNPs in untreated controls,
retains read pairs carrying high-confidence T-to-C conversions (nascent RNA),
and produces gene-level count matrices with featureCounts.

The repository provides orchestration and analysis scripts, not the sequencing
data, reference genome, genome index, annotation, software binaries, or
Trimmomatic adapter FASTA files.

## Workflow overview

| Stage | Directory | Purpose | Principal output |
| --- | --- | --- | --- |
| 1 | [`1_Until_Trimmomatic/`](1_Until_Trimmomatic/) | Run FastQC before and after paired-end adapter/quality trimming. | Trimmed paired FASTQ files |
| 2 | [`2_HISAT3N_mapping/`](2_HISAT3N_mapping/) | Align reads in T-to-C conversion-aware mode and retain unique, properly paired alignments. | Sorted, indexed BAM files |
| 3 | [`3_Make_SNP_file/`](3_Make_SNP_file/) | Call SNPs in untreated controls and form a union of sites to exclude. | `SNP_output.snp` and SNP Venn diagrams |
| 4A | [`4_Filter_Non_Nascent_Reads/Part_A/`](4_Filter_Non_Nascent_Reads/Part_A/) | Detect quality-filtered conversions, subtract SNP sites, and retain converted read pairs. | Conversion-filtered BAM and mismatch tables |
| 4B | [`4_Filter_Non_Nascent_Reads/Part_B/`](4_Filter_Non_Nascent_Reads/Part_B/) | Split converted reads into mutation-count categories. | One sorted/indexed BAM per category |
| 5 | [`5_Featurecounts/`](5_Featurecounts/) | Count paired fragments over annotated exons. | Gene-level count tables |

Stage 4 also contains an optional plotting script; see
[`4_Filter_Non_Nascent_Reads/README.md`](4_Filter_Non_Nascent_Reads/README.md).

## Requirements

The submission scripts assume a cluster with SLURM and an environment-modules
installation. They load or invoke:

- FastQC, Trimmomatic, HISAT-3N, SAMtools, Picard, VarScan 2, Python, R, and
  featureCounts (Subread);
- Python packages `numpy`, `pandas`, `pysam`, `tabulate`, `joblib`, and `tqdm`;
- R packages `data.table`, `ggVennDiagram`, and `ggvenn` for SNP processing,
  plus `ggplot2`, `plyr`, `purrr`, `data.table`, and `wesanderson` for the
  optional mismatch plots;
- a reference FASTA (with the associated files expected by SAMtools), a
  HISAT-3N index, a GTF annotation, and `TruSeq3-PE.fa` from Trimmomatic.

The alignment BAMs must contain MD tags because `splbam.py` asks `pysam` for
reference bases while inspecting aligned pairs.

## Configuration and input naming

1. Edit [`config.sh`](config.sh). Replace the example absolute paths for the
   project directory, reference FASTA, GTF, HISAT-3N executable/index, and
   featureCounts executable. Analysis thresholds are centralized in the same
   file.
2. Put gzipped paired reads in `RAW_DATA_DIR`. For a sample named `sample`, the
   files must be named `sample_R1.fastq.gz` and `sample_R2.fastq.gz`.
3. Put one sample stem per line in [`filelist.txt`](filelist.txt). Put
   untreated-control sample stems used for SNP detection in
   [`filelist_IAA_minus.txt`](filelist_IAA_minus.txt).
4. Adjust every `#SBATCH --array` range to the number of entries in the relevant
   list. The checked-in sample list has 28 entries and the array scripts are
   configured for `1-28`.
5. Adjust `#SBATCH --cpus-per-task` to the number of untreated-control samples in 
   stage 3.
Blank lines should be avoided in sample lists.

## Running the pipeline

Submit stages in order from the repository checkout:

```bash
sbatch 1_Until_Trimmomatic/1_SLAM_Seq_Script_Until_Trimmomatic.sh
sbatch 2_HISAT3N_mapping/2_SLAM_Seq_Script_HISAT3N_mapping.sh
sbatch 3_Make_SNP_file/3_SLAM_Seq_Script_Make_SNP_file.sh
sbatch 4_Filter_Non_Nascent_Reads/Part_A/4A_SLAM_Seq_Script_Filter.sh
sbatch 4_Filter_Non_Nascent_Reads/Part_B/4B_SLAM_Seq_Script_Filter.sh
sbatch 5_Featurecounts/SLAM_Seq_Script_FeatureCounts.sh
```

Wait for every job (including every array task) in one stage to complete before
starting the next. These scripts do not declare SLURM dependencies themselves.
Review the `.log` files and output counts at each stage before continuing.

### Important behavior

- Stage 1 uncompresses its paired trimmed outputs. Stage 2 consumes those
  `.fastq` files and compresses them again after alignment.
- Stage 2 removes its SAM and intermediate BAM files after producing the final
  coordinate-sorted BAM and index.
- Stage 4 assumes reverse-forward (`RF-FIRSTSTRAND`) paired-end libraries. Its
  conversion logic reports antisense A-to-G observations as T-to-C events.
- Stage 5 counts every top-level `*.sorted.bam` once, then separately counts
  only the main `*_aligned.unique.filtered.sorted.bam` files. Mutation-category
  BAM names end in `.sorted.<category>.bam`, so they are not selected by the
  first `*.sorted.bam` pattern.
- The scripts overwrite or remove some intermediate files. Preserve inputs and
  results elsewhere if they must remain immutable.

## Repository files

- `config.sh`: shared paths and analysis parameters sourced by all five stages.
- `filelist.txt`: sample stems used by the 28-task array stages.
- `filelist_IAA_minus.txt`: four untreated controls used to construct the SNP
  exclusion set.
- Each workflow directory has its own README with script arguments, inputs,
  outputs, and implementation notes.

## Scope

This is a research workflow whose checked-in defaults reflect the original
zebrafish analysis and cluster layout. Validate parameters, library strandedness,
resource requests, reference versions, and biological assumptions for a new
experiment before using its results.
