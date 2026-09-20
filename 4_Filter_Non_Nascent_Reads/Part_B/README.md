# Stage 4B: mutation-count BAMs

This optional stage partitions the main conversion-filtered BAM into categories
based on how many retained conversions are associated with each read name.

## Script

### `4B_SLAM_Seq_Script_Filter.sh`

For each sample selected by the 28-task SLURM array, the script loops over
`MUTATION_CATEGORIES` from `config.sh` (`1`, `2`, `3`, `4`, and `more.4` by
default). For each category whose read-name table exists, it:

1. extracts matching alignments with `samtools view -N`;
2. coordinate-sorts the resulting BAM;
3. builds a BAM index; and
4. removes the unsorted intermediate BAM.

Missing category tables produce warnings and are skipped rather than failing
the entire task.

## Inputs

- `HISAT3N_OUTPUT_DIR/<sample>_aligned.unique.filtered.sorted.bam` from Part A;
- `HISAT3N_OUTPUT_DIR/mismatch_infos/<sample>.Yf.table.<category>.tab` for each
  desired category; and
- the configured sample and category lists.

The included `splbam.py` does not itself write the `Yf.table` files. Supply them
from the compatible mismatch-analysis workflow before running this stage.

## Outputs

For every available category, the script creates:

```text
HISAT3N_OUTPUT_DIR/<sample>_aligned.unique.filtered.sorted.<category>.bam
HISAT3N_OUTPUT_DIR/<sample>_aligned.unique.filtered.sorted.<category>.bam.bai
```

These category BAMs are useful for conversion-count-stratified downstream
analysis. They are not selected by Stage 5's checked-in `*.sorted.bam` search
pattern because the category follows `.sorted` in their filenames.
