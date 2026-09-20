# Stage 4: nascent-read filtering

Stage 4 uses high-confidence nucleotide conversions to separate metabolically
labelled (nascent) RNA reads from unlabelled reads. It first creates mismatch
metadata and a conversion-filtered BAM, then optionally partitions that BAM by
the number of conversions in each read name.

## Subdirectories

- [`Part_A/`](Part_A/) detects conversions, excludes known SNP positions, and
  creates the main filtered BAM.
- [`Part_B/`](Part_B/) creates BAMs for the configured mutation-count groups.

Run Part A for all samples before Part B.

## Plotting script

### `FIGURE_ED3D_plot_mismatches_paper.R`

This optional, study-specific R script merges the `*.mismatches.tab.gz` and
`*.mismatches-used.tab.gz` tables produced by `splbam.py`, derives mismatch
rates and standard errors, parses the original experiment's genotype/stage/IAA
naming scheme, and creates separate first- and second-read boxplots:

- `ED3D_First_mismatch_plot.pdf`
- `ED3D_Second_mismatch_plot.pdf`

Before running it, update its hard-coded `loc` value. The checked-in value is
`./PART_A/mismatch_infos/`, while the pipeline normally writes mismatch tables
to `HISAT3N_OUTPUT_DIR/mismatch_infos`; directory name casing also matters on
Linux. The stage and treatment assignments are tailored to sample names such
as `WT_A1` through `WT_D4` and should be revised for other experiments.

Run the plotting script manually after Part A:

```bash
Rscript 4_Filter_Non_Nascent_Reads/FIGURE_ED3D_plot_mismatches_paper.R
```
