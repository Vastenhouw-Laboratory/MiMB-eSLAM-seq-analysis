# Stage 3: SNP exclusion set

This directory identifies genomic variants in untreated controls so that
pre-existing SNPs are not mistaken for metabolic-label conversions.

## Scripts

### `3_SLAM_Seq_Script_Make_SNP_file.sh`

This single SLURM job reads the control stems from `CONTROL_FILELIST`. For each
non-empty line it starts a background pipeline of `samtools mpileup` and
`varscan pileup2snp`, using the thresholds in `config.sh`. All controls run in
parallel; after `wait`, the script changes to `SNP_OUTPUT_DIR` and runs
`SNP_union.R`.

The default job requests four CPUs because the supplied control list contains
four samples. Background process failures are not explicitly aggregated after
`wait`, so inspect the log and each `.varscan.snp` output before trusting the
union.

### `SNP_union.R`

The R script accepts:

```text
SNP_union.R CONTROL_FILELIST OUTPUT_FILE MINIMUM_COVERAGE
```

It requires exactly four control names. It loads the corresponding
`<sample>.varscan.snp` files from the current working directory, applies a
second total-depth filter (`Reads1 + Reads2`), and converts VarScan's 1-based
positions to the zero-based `chromosome:position` format expected by
`splbam.py`. It writes the unique union under a `Location` column and creates
`venn_diagrams_SNP.pdf` to visualize overlap among the four controls.

## Inputs and outputs

Inputs are the reference FASTA, the four control BAMs from Stage 2, and
`filelist_IAA_minus.txt` (or the configured replacement). Outputs in
`SNP_OUTPUT_DIR` are:

- one `<sample>.varscan.snp` call table per control;
- `SNP_output.snp` by default, containing the union used by Stage 4; and
- `venn_diagrams_SNP.pdf`.

Both VarScan's calling coverage threshold and the R union coverage threshold
are configurable and are distinct settings.
