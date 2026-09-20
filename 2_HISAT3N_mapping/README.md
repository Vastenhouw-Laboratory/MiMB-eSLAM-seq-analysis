# Stage 2: HISAT-3N alignment

This directory maps the trimmed paired-end reads to a conversion-aware genome
index and prepares high-confidence alignments for mismatch analysis.

## Script

### `2_SLAM_Seq_Script_HISAT3N_mapping.sh`

For the sample selected by `SLURM_ARRAY_TASK_ID`, the script:

1. validates the configured sample list;
2. aligns the uncompressed Stage 1 read pair with HISAT-3N using the configured
   T-to-C base change, `RF` RNA strandedness, paired-end orientation, repeat
   handling, and no discordant pairs;
3. recompresses the input FASTQ files;
4. converts SAM to BAM while retaining proper pairs, excluding unmapped and
   secondary records, and requiring the `NH` tag to equal 1;
5. repairs mate information with Picard;
6. coordinate-sorts and indexes the BAM with SAMtools and prints flagstats; and
7. removes the SAM and intermediate BAM files.

The executable, index, paths, conversion bases, and strandedness are read from
`../config.sh`. The checked-in SLURM settings request 48 CPUs for each of 28
array tasks.

## Inputs

- `TRIMMOMATIC_OUTPUT_DIR/<sample>_R1.fastq`
- `TRIMMOMATIC_OUTPUT_DIR/<sample>_R2.fastq`
- the HISAT-3N index at `HISAT3N_INDEX`
- one sample stem per line in `SAMPLE_FILELIST`

## Outputs

- `HISAT3N_OUTPUT_DIR/<sample>_aligned.unique.sorted.bam`
- `HISAT3N_OUTPUT_DIR/<sample>_aligned.unique.sorted.bam.bai`
- an alignment summary named `<sample>_summary` in
  `TRIMMOMATIC_OUTPUT_DIR`
- SLURM logs and SAMtools flagstat output

The final BAM is the input to both SNP calling and conversion filtering. It
must retain the alignment MD tags required by Stage 4's `pysam` processing.
