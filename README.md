<!--
Copyright (C) 2025 Roberto Rossini <roberros@uio.no>

SPDX-License-Identifier: MIT
-->

# Nextflow workflow to run Chrom3D

[![CI](https://github.com/robomics/chrom3d-nf/actions/workflows/ci.yml/badge.svg)](https://github.com/robomics/chrom3d-nf/actions/workflows/ci.yml)

This repository hosts a Nextflow workflow to generate 3D genome structures from Hi-C data using [Chrom3D](https://github.com/Chrom3D/Chrom3D).

## Requirements

### Software requirements

- Nextflow (at least version: v25.04. Pipeline was developed using v25.04.6)
- Docker or Apptainer/Singularity

### Required input files

The workflow can be run in two ways:

1. Using a sample sheet (recommended, supports processing multiple samples at once)
2. By specifying options directly on the CLI or using a config file

#### Using a samplesheet

The samplesheet should be a TSV file with the following columns:

| sample       | hic_file                                | resolution | domains  | periphery_constraints | mask_cis     | mask_trans     |
| ------------ | --------------------------------------- | ---------- | -------- | --------------------- | ------------ | -------------- |
| sample_name  | myfile.hic                              | 50000      | tads.bed | constraints.bed       | mask_cis.bed | mask_trans.bed |
| 4DNFIZ1ZVXC8 | 4DNFIZ1ZVXC8.mcool::/resolutions/500000 | 500000     |          |                       |              |                |

- **sample**: Sample names/ids. This field will be used as prefix to in the output file names (see [below](#running-the-workflow)).
- **hic_file**: Path to a file in .hic or Cooler format.
- **resolution**: Resolution to be used for the data analysis (50-100kbp are good starting points).
- **domains** (optional) : path to a BED3+ file with a list of pre-computed domains (e.g. TADs).
  When no domains are provided, the workflow will use genomic bins as beads.
- **periphery_constraints** (optional): path to a BED3+ file with the list of domains that should be associated with the nuclear periphery (e.g. LADs).
  Optional, but highly recommended.
- **mask_cis** (optional): path to a BED3+ file with the list of regions to be masked out when processing cis interactions.
- **mask_trans** (optional): same as mask_cis, but for trans interactions.

URI syntax for multi-resolution Cooler files is supported (e.g. `myfile.mcool::/resolutions/bin_size`).

All files except the samplesheet itself can be compressed using common compression algorithms (e.g. gzip or zstd).

Furthermore, all contact matrices (as well as domain, periphery constraints, and mask files when provided) should use the same reference genome assembly.

<details>
<summary> <b>Without using a samplesheet</b> </summary>

To run the workflow without a samplesheet is not available, the following parameters are required:

- **sample**
- **hic_file**
- **resolution**

Parameters have the same meaning as the header fields outlined in the [previous section](#using-a-samplesheet).

The above parameters can be passed directly through the CLI when calling `nextflow run`:

```bash
nextflow run --sample='4DNFIZ1ZVXC8' \
             --hic_file='data/4DNFIZ1ZVXC8.mcool' \
             --resolution=500000
             ...
```

Alternatively, parameters can be written to a `config` file:

```console
user@dev:/tmp$ cat myconfig.txt

sample       = '4DNFIZ1ZVXC8'
hic_file     = 'data/4DNFIZ1ZVXC8.mcool'
resolution   = 500000
```

and the `config` file is then passed to `nextflow run`:

```bash
nextflow run -c myconfig.txt ...
```

</details>

### Optional files and parameters

In addition to the mandatory parameters, the pipeline accepts the following parameters:

#### Genome masking

- **cytoband**: path to a [cytoband](https://software.broadinstitute.org/software/igv/cytoband) file. Used to mask centromeric regions.
- **assembly_gaps**: path to a BED file with the list of assembly gaps/unmappable regions.
- **masked_chromosomes**: a comma-separated list of chromosome names to be excluded from the simulations.

Note that [NCHG](https://github.com/paulsengroup/NCHG), the tool used by the workflow to identify statistically significant interactions between the given domains,
by default uses the `MAD-max` filter to remove bins with suspiciously low marginals, so providing the cytoband and assembly_gaps files is usually not required.

- **mad_max**: cutoff used by NCHG when performing the `MAD-max` filtering.
- **bad_bin_fraction**: bad bin fraction used by NCHG to discard domains overlapping with a high fraction of bad bins.

#### NCHG cutoffs

- **fdr_cis**: adjusted p-value used by NCHG to filter significant cis interactions.
- **log_ratio_cis**: log ratio used by NCHG to filter significant cis interactions.
- **fdr_trans**: adjusted p-value used by NCHG to filter significant trans interactions.
- **log_ratio_trans**: log ratio used by NCHG to filter significant trans interactions.

#### Chrom3D options

- **chrom3d_args**: a space-separated list of additional arguments to be passed to Chrom3D.
- **ploidy**: number of sets of chromosomes to be simulated.
- **number_of_models**: number of 3D models to be generated.
- **archive_models**: boolean flag indicating whether Chrom3D model files should be packaged in a TAR archive.

By default, the workflow results are published under `results/`.
The output folder can be customized through the `-output-dir` CLI option or the `outputDir` config setting.

For a complete list of parameters supported by the workflow refer to the [nextflow.config](nextflow.config) file in the root of the workflow repository.

## Running the workflow

First, download the example datasets using script `utils/download_example_datasets.sh`.

```bash
# This will download files inside folder data/
utils/download_example_datasets.sh data/
```

Next, create a `samplesheet.tsv` file like the following (make sure you are using tabs, not spaces!)

<!-- markdownlint-disable -->
<!-- prettier-ignore-start -->

```tsv
sample	hic_file	resolution	domains	periphery_constraints	mask_cis	mask_trans
4DNFIZ1ZVXC8	data/4DNFIZ1ZVXC8.mcool	500000		data/periphery_constraints.dm6.bed.gz
```

<!-- prettier-ignore-end -->
<!-- markdownlint-enable -->

Finally, run the workflow with:

```console
user@dev:/tmp$ nextflow run https://github.com/robomics/chrom3d-nf \
                            --sample_sheet=samplesheet.tsv \
                            -output-dir data/results/ \
                            -with-apptainer  # Replace this with -with-docker to use Docker instead

 N E X T F L O W   ~  version 25.04.6

Launching `./main.nf` [golden_blackwell] DSL2 - revision: 9e4edc8e66

-- PARAMETERS
-- sample_sheet: samplesheet.tsv
-- publish_dir_mode: copy
-- cytoband: null
-- assembly_gaps: null
-- masked_chromosomes: chrY,chrM
-- chrom3d_args:
-- ploidy: 1
-- number_of_models: 5
-- archive_models: false
-- nchg_mad_max: 5
-- nchg_bad_bin_fraction: 0.1
-- nchg_fdr_cis: 0.01
-- nchg_log_ratio_cis: 1.5
-- nchg_fdr_trans: 0.01
-- nchg_log_ratio_trans: 1.5
-- plot_format: png
-- nchg_skip_plots: false
-- nchg_hic_tgt_resolution_plots: 500000
-- nchg_plot_sig_interactions_cmap_lb: null
-- nchg_plot_sig_interactions_cmap_ub: 2.0
executor >  local (71)
[9d/3884b9] SAMPLESHEET:CHECK_SYNTAX                                          [100%] 1 of 1 ✔
[26/66c459] SAMPLESHEET:CHECK_FILES                                           [100%] 1 of 1 ✔
[7d/9335cc] SAMPLESHEET:NCHG_CIS                                              [100%] 1 of 1 ✔
[ab/2ea032] SAMPLESHEET:NCHG_TRANS                                            [100%] 1 of 1 ✔
[69/2cd7d0] NCHG_CIS:GENERATE_MASK (4DNFIZ1ZVXC8_cis)                         [100%] 1 of 1 ✔
[cb/c819a7] NCHG_CIS:EXPECTED (4DNFIZ1ZVXC8_cis)                              [100%] 1 of 1 ✔
[dd/1c81b5] NCHG_CIS:DUMP_CHROM_SIZES (4DNFIZ1ZVXC8_cis)                      [100%] 1 of 1 ✔
[2d/efe2af] NCHG_CIS:PREPROCESS_DOMAINS (4DNFIZ1ZVXC8_cis)                    [100%] 1 of 1 ✔
[5c/08ca3e] NCHG_CIS:CARTESIAN_PRODUCT (4DNFIZ1ZVXC8_cis)                     [100%] 1 of 1 ✔
[86/20fad7] NCHG_CIS:GENERATE_CHROMOSOME_PAIRS (4DNFIZ1ZVXC8_cis (cis))       [100%] 1 of 1 ✔
[0a/23e4d7] NCHG_CIS:COMPUTE (4DNFIZ1ZVXC8_cis [chr3L:chr3L])                 [100%] 7 of 7 ✔
[b5/0319bb] NCHG_CIS:MERGE (4DNFIZ1ZVXC8_cis (cis))                           [100%] 1 of 1 ✔
[d8/1e72d9] NCHG_CIS:FILTER (4DNFIZ1ZVXC8_cis (cis))                          [100%] 1 of 1 ✔
[0e/659f3f] NCHG_CIS:CONCAT (4DNFIZ1ZVXC8_cis)                                [100%] 2 of 2 ✔
[79/482b36] NCHG_CIS:VIEW (4DNFIZ1ZVXC8_cis)                                  [100%] 1 of 1 ✔
[f0/66bf81] NCHG_CIS:PLOT_EXPECTED (4DNFIZ1ZVXC8_cis)                         [100%] 1 of 1 ✔
[92/b299cc] NCHG_CIS:GET_HIC_PLOT_RESOLUTION (4DNFIZ1ZVXC8_cis)               [100%] 1 of 1 ✔
[bd/a72d66] NCHG_CIS:PLOT_SIGNIFICANT (4DNFIZ1ZVXC8_cis)                      [100%] 1 of 1 ✔
[46/9125ba] NCHG_TRANS:GENERATE_MASK (4DNFIZ1ZVXC8_trans)                     [100%] 1 of 1 ✔
[0f/10f595] NCHG_TRANS:EXPECTED (4DNFIZ1ZVXC8_trans)                          [100%] 1 of 1 ✔
[09/d4d552] NCHG_TRANS:DUMP_CHROM_SIZES (4DNFIZ1ZVXC8_trans)                  [100%] 1 of 1 ✔
[b1/4ae959] NCHG_TRANS:PREPROCESS_DOMAINS (4DNFIZ1ZVXC8_trans)                [100%] 1 of 1 ✔
[da/d30774] NCHG_TRANS:CARTESIAN_PRODUCT (4DNFIZ1ZVXC8_trans)                 [100%] 1 of 1 ✔
[4e/66e3f1] NCHG_TRANS:GENERATE_CHROMOSOME_PAIRS (4DNFIZ1ZVXC8_trans (trans)) [100%] 1 of 1 ✔
[be/df47c6] NCHG_TRANS:COMPUTE (4DNFIZ1ZVXC8_trans [chr3R:chrX])              [100%] 21 of 21 ✔
[fb/3ab66b] NCHG_TRANS:MERGE (4DNFIZ1ZVXC8_trans (trans))                     [100%] 1 of 1 ✔
[f0/87356a] NCHG_TRANS:FILTER (4DNFIZ1ZVXC8_trans (trans))                    [100%] 1 of 1 ✔
[af/281160] NCHG_TRANS:CONCAT (4DNFIZ1ZVXC8_trans)                            [100%] 2 of 2 ✔
[fd/f47843] NCHG_TRANS:VIEW (4DNFIZ1ZVXC8_trans)                              [100%] 1 of 1 ✔
[e6/a661b7] NCHG_TRANS:PLOT_EXPECTED (4DNFIZ1ZVXC8_trans)                     [100%] 1 of 1 ✔
[d4/6d3be6] NCHG_TRANS:GET_HIC_PLOT_RESOLUTION (4DNFIZ1ZVXC8_trans)           [100%] 1 of 1 ✔
[a8/f9544c] NCHG_TRANS:PLOT_SIGNIFICANT (4DNFIZ1ZVXC8_trans)                  [100%] 1 of 1 ✔
[ff/f48ff3] PREPROCESSING:MERGE (4DNFIZ1ZVXC8)                                [100%] 1 of 1 ✔
[6a/3244af] PREPROCESSING:DUMP_CHROM_SIZES (4DNFIZ1ZVXC8)                     [100%] 1 of 1 ✔
[8d/f47f8e] PREPROCESSING:DUMP_BINS (4DNFIZ1ZVXC8)                            [100%] 1 of 1 ✔
[6a/c96030] PREPROCESSING:MAKE_BEAD_GTRACK (4DNFIZ1ZVXC8)                     [100%] 1 of 1 ✔
[9e/df75ad] PREPROCESSING:CHANGE_PLOIDY (4DNFIZ1ZVXC8)                        [100%] 1 of 1 ✔
[86/a66d8b] CHROM3D:GENERATE_SEEDS (4DNFIZ1ZVXC8)                             [100%] 1 of 1 ✔
[22/527a69] CHROM3D:SIMULATE (4DNFIZ1ZVXC8_3)                                 [100%] 5 of 5 ✔
Completed at: 31-Jul-2025 16:15:57
Duration    : 1m 28s
CPU hours   : 0.1
Succeeded   : 71
```

This will create a `data/results/` folder with the following files:

```txt
data/results
├── 4DNFIZ1ZVXC8
│   ├── 4DNFIZ1ZVXC8.beads.1.gtrack
│   ├── 4DNFIZ1ZVXC8.sig_interactions.tsv.gz
│   ├── models
│   │   ├── 4DNFIZ1ZVXC8_0.cmm
│   │   ├── 4DNFIZ1ZVXC8_1.cmm
│   │   ├── 4DNFIZ1ZVXC8_2.cmm
│   │   ├── 4DNFIZ1ZVXC8_3.cmm
│   │   └── 4DNFIZ1ZVXC8_4.cmm
│   └── nchg
│       ├── 4DNFIZ1ZVXC8_cis.filtered.parquet
│       ├── 4DNFIZ1ZVXC8_cis.parquet
│       ├── 4DNFIZ1ZVXC8_trans.filtered.parquet
│       ├── 4DNFIZ1ZVXC8_trans.parquet
│       ├── expected_values_4DNFIZ1ZVXC8_cis.cis.h5
│       ├── expected_values_4DNFIZ1ZVXC8_trans.trans.h5
│       └── plots
│           ├── 4DNFIZ1ZVXC8_trans.chrX.chrY.png
│           ...
├── samplesheet.nchg.cis.tsv
├── samplesheet.nchg.trans.tsv
└── samplesheet.ok.tsv

5 directories, 43 files
```

The output folder contains a copy of the original samplesheet (`samplesheet.ok.tsv`) as well as the samplesheets used to run NCHG (`samplesheet.nchg.cis.tsv` and `samplesheet.nchg.trans.tsv`).
In addition, the workflow creates one folder for each sample provided in the samplesheet.

Each sample folder (`4DNFIZ1ZVXC8/` in this case) contains the following files:

- `sample.beads.*.gtrack` - A gtrack file with the beads and constraints used to run Chrom3D.
- `sample.sig_interactions.tsv.gz` - A TSV file with the list of domains with statistically significant interactions identified using NCHG.
- `models/sample_*.cmm` - A folder containing the 3D models generated by Chrom3D.
  If `archive_models=true`, then instead of this folder the workflow will publish models inside a TAR archive named `sample.models.tar.gz`.
- `nchg/` - A folder containing intermediate files generated by NCHG (see [paulsengroup/nchg-nf](https://github.com/paulsengroup/nchg-nf) for more details).

<details>
<summary>Troubleshooting</summary>

If you get permission errors when using `-with-docker`:

- Pass option `-process.containerOptions="--user root"` to `nextflow run`

If you get an error similar to:

```txt
Cannot find revision `vx.x.x` -- Make sure that it exists in the remote repository `https://github.com/robomics/chrom3d-nf`
```

try to remove folder `~/.nextflow/assets/robomics/chrom3d-nf` before running the workflow

</details>

## Getting help

If you are having trouble running the workflow feel free to reach out by [starting a new discussion here](https://github.com/robomics/chrom3d-nf/discussions).

Bug reports and feature requests can be submitted by opening an [issue](https://github.com/robomics/chrom3d-nf/issues).
