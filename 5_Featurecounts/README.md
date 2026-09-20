# Stage 5: gene-level quantification

This directory quantifies aligned paired-end fragments over annotated exons
with featureCounts.

## Script

### `SLAM_Seq_Script_FeatureCounts.sh`

The script validates the configured GTF annotation and featureCounts binary,
then performs two count runs:

1. every top-level BAM matching `HISAT3N_OUTPUT_DIR/*.sorted.bam`; and
2. only BAMs matching
   `*_aligned.unique.filtered.sorted.bam` (the principal Part A outputs).

Both runs count paired fragments, require both ends to map to the same
chromosome, require the configured minimum overlap (10 bases by default), use
reverse-stranded counting (`-s 2` by default), and summarize `exon` features by
`gene_id`.

Unlike the preceding per-sample stages, this is a single SLURM job. The
checked-in job requests 12 CPUs and passes that allocation to featureCounts.

## Inputs

- coordinate-sorted BAM files in `HISAT3N_OUTPUT_DIR`;
- the GTF file configured as `ANNOTATION_GTF`; and
- the executable configured as `FEATURECOUNTS_EXECUTABLE`.

Mutation-category files named `*.sorted.<category>.bam` do not match the first
search pattern and are therefore not counted by this script as written.

## Outputs

The script creates `FEATURECOUNTS_OUTPUT_DIR` and writes:

- `raw_counts_proper_orientation_filtered_and_unfiltered.txt`; and
- `raw_counts_proper_orientation_filtered.txt`.

featureCounts also normally writes a `.summary` file beside each count table.
Columns correspond to the discovered BAM inputs; check the log and summary
files for assignment rates before downstream analysis.
