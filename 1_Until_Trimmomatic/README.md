# Stage 1: read QC and trimming

This directory prepares paired-end FASTQ reads for alignment. The SLURM array
driver selects one sample per task, runs FastQC on the raw reads, trims adapters
and low-quality sequence with Trimmomatic, and runs FastQC again.

## Scripts

### `1_SLAM_Seq_Script_Until_Trimmomatic.sh`

The stage driver:

1. sources `../config.sh`;
2. reads the sample stem at `SLURM_ARRAY_TASK_ID` from `SAMPLE_FILELIST`;
3. loads the required cluster modules;
4. calls `fastqc.sh` for the raw pair;
5. calls `trimmomatic.sh`; and
6. calls `fastqc.sh` for the trimmed pair, then uncompresses the paired trimmed
   files for Stage 2.

It is configured as a 28-task SLURM array using 48 CPUs per task. Change those
directives when the sample count or cluster limits differ.

### `fastqc.sh`

Reusable FastQC wrapper with four positional arguments:

```text
fastqc.sh INPUT_DIRECTORY OUTPUT_DIRECTORY THREADS SAMPLE_STEM
```

It checks that the input directory exists, creates the output directory, and
runs FastQC independently on `<sample>_R1.fastq.gz` and
`<sample>_R2.fastq.gz`. It is called once before and once after trimming.

### `trimmomatic.sh`

Paired-end Trimmomatic wrapper with ten positional arguments:

```text
trimmomatic.sh INPUT_DIRECTORY OUTPUT_DIRECTORY THREADS SAMPLE_STEM \
  ADAPTER_DIRECTORY LEADING TRAILING SLIDINGWINDOW MINLEN ADAPTER_OPTIONS
```

It writes surviving paired reads directly under the output directory and
unpaired reads under `Singletons/`. Adapter clipping uses
`<adapter-directory>/TruSeq3-PE.fa`; quality and adapter settings come from
`config.sh` via the driver.

## Inputs and outputs

For each sample, the expected inputs are:

```text
RAW_DATA_DIR/<sample>_R1.fastq.gz
RAW_DATA_DIR/<sample>_R2.fastq.gz
```

Outputs are FastQC reports in `FASTQC_BEFORE_DIR` and `FASTQC_AFTER_DIR`, paired
trimmed reads in `TRIMMOMATIC_OUTPUT_DIR`, and unpaired reads in its
`Singletons/` subdirectory. The driver leaves paired trimmed reads as
`<sample>_R1.fastq` and `<sample>_R2.fastq` (uncompressed).
