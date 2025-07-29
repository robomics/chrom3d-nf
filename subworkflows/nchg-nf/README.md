<!--
Copyright (C) 2024 Roberto Rossini <roberros@uio.no>

SPDX-License-Identifier: MIT
-->

# Nextflow workflow to run NCHG

[![CI](https://github.com/paulsengroup/nchg-nf/actions/workflows/ci.yml/badge.svg)](https://github.com/paulsengroup/nchg-nf/actions/workflows/ci.yml)

This repository hosts a Nextflow workflow to identify statistically significant interactions from Hi-C data using [NCHG](https://github.com/paulsengroup/NCHG).

## Requirements

### Software requirements

- Nextflow (at least version: v25.04. Pipeline was developed using v25.04.6)
- Docker or Singularity/Apptainer

### Required input files

The workflow can be run in two ways:

1. Using a sample sheet (recommended, supports processing multiple samples at once)
2. By specifying options directly on the CLI or using a config

#### Using a samplesheet

The samplesheet should be a TSV file with the following columns:

| sample       | hic_file                               | resolution | domains                  | mask              |
| ------------ | -------------------------------------- | ---------- | ------------------------ | ----------------- |
| sample_name  | myfile.hic                             | 50000      | tads.bed                 | mask.bed          |
| 4DNFI74YHN5W | 4DNFI74YHN5W.mcool::/resolutions/50000 | 50000      | 4DNFI74YHN5W_domains.bed | assembly_gaps.bed |

- **sample**: Sample names/ids. This field will be used as prefix to in the output file names (see [below](#running-the-workflow)).
- **hic_file**: Path to a file in .hic or Cooler format.
- **resolution**: Resolution to be used for the data analysis (50-100kbp are good starting points).
- **domains** (optional) : path to a BED3+ file with a list of pre-computed domains (e.g. TADs).
  When provided, NCHG will aggregate interactions between all possible pairs of domains, and compute their statistical significance.
- **mask** (optional): path to a BED3+ file with the list of regions to be masked out.

URI syntax for multi-resolution Cooler files is supported (e.g. `myfile.mcool::/resolutions/bin_size`).

Furthermore, all contact matrices (as well as domain and mask files when provided) should use the same reference genome assembly.

<details>
<summary> <b>Without using a samplesheet</b> </summary>

To run the workflow without a samplesheet is not available, the following parameters are required:

- **sample**
- **hic_file**
- **resolution**

Parameters have the same meaning as the header fields outlined in the [previous section](#using-a-samplesheet).

The above parameters can be passed directly through the CLI when calling `nextflow run`:

```bash
nextflow run --sample='4DNFI74YHN5W' \
             --hic_file='data/4DNFI74YHN5W.mcool' \
             --resolution=50000
             ...
```

Alternatively, parameters can be written to a `config` file:

```console
user@dev:/tmp$ cat myconfig.txt

sample       = '4DNFI74YHN5W'
hic_file     = 'data/4DNFI74YHN5W.mcool'
resolution   = 50000
```

and the `config` file is then passed to `nextflow run`:

```bash
nextflow run -c myconfig.txt ...
```

</details>

### Optional files and parameters

In addition to the mandatory parameters, the pipeline accepts the following parameters:

- **cytoband**: path to a [cytoband](https://software.broadinstitute.org/software/igv/cytoband) file. Used to mask centromeric regions.
- **assembly_gaps**: path to a BED file with the list of assembly gaps/unmappable regions.

Note that NCHG by default uses the `MAD-max` filter to remove bins with suspiciously low marginals, so providing the above files is usually not requirerd.

- **mad_max**: cutoff used by NCHG when performing the `MAD-max` filtering.
- **bad_bin_fraction**: bad bin fraction used by NCHG to discard domains overlapping with a high fraction of bad bins.
- **fdr_cis**: adjusted pvalue used by NCHG to filter significant cis interactions.
- **log_ratio_cis**: log ratio used by NCHG to filter significant cis interactions.
- **fdr_trans**: adjusted pvalue used by NCHG to filter significant trans interactions.
- **log_ratio_trans**: log ratio used by NCHG to filter significant trans interactions.
- **use_cis_interactions**: use interactions from the cis portion of the Hi-C matrix.
- **use_trans_interactions**: use interactions from the trans portion of the Hi-C matrix.

By default, the workflow results are published under `result/`. The output folder can be customized through the **outdir** parameter.

For a complete list of parameters supported by the workflow refer to the workflow main [config](nextflow.config) file.

## Running the workflow

First, download the example datasets using script `utils/download_example_datasets.sh`.

```bash
# This will download files inside folder data/
utils/download_example_datasets.sh data/
```

Next, create a `samplesheet.tsv` file like the following (make sure you are using tabs, not spaces!)

<!-- prettier-ignore-start -->

```tsv
sample   hic_file      resolution    domains    mask
example  data/4DNFI74YHN5W.mcool   50000    
```

<!-- prettier-ignore-end -->

Finally, run the workflow with:

```console
user@dev:/tmp$ nextflow run --max_cpus=8 \
                            --max_memory=16.GB \
                            --max_time=2.h \
                            --sample_sheet=samplesheet.tsv \
                            https://github.com/paulsengroup/nchg-nf \
                            -output-dir data/results/ \
                            -with-singularity  # Replace this with -with-docker to use Docker instead

 N E X T F L O W   ~  version 25.04.2

Launching `./main.nf` [fabulous_turing] DSL2 - revision: fd37ba43c4

-- PARAMETERS
-- sample_sheet: samplesheet.tsv
-- publish_dir_mode: copy
-- cytoband: null
-- assembly_gaps: null
-- mad_max: 5
-- bad_bin_fraction: 0.1
-- fdr_cis: 0.01
-- log_ratio_cis: 1.5
-- fdr_trans: 0.01
-- log_ratio_trans: 1.5
-- use_cis_interactions: true
-- use_trans_interactions: true
-- plot_format: png
-- hic_tgt_resolution_plots: 500000
-- plot_sig_interactions_cmap_lb: null
-- plot_sig_interactions_cmap_ub: 2.0
-- skip_expected_plots: false
-- skip_sign_interaction_plots: false
executor >  local (250)
[84/789e27] SAMPLESHEET:CHECK_SYNTAX                         [100%] 1 of 1 ✔
[02/3ff9e7] SAMPLESHEET:CHECK_FILES                          [100%] 1 of 1 ✔
[91/d0e6c6] NCHG:GENERATE_MASK (example)                     [100%] 1 of 1 ✔
[ab/0ff3f5] NCHG:EXPECTED (example)                          [100%] 1 of 1 ✔
[6a/191e76] NCHG:DUMP_CHROM_SIZES (example)                  [100%] 1 of 1 ✔
[7c/2e8a9b] NCHG:PREPROCESS_DOMAINS (example)                [100%] 1 of 1 ✔
[f6/9ac15e] NCHG:CARTESIAN_PRODUCT (example)                 [100%] 1 of 1 ✔
[7c/c281cf] NCHG:GENERATE_CHROMOSOME_PAIRS (example (trans)) [100%] 2 of 2 ✔
[ed/bf4af9] NCHG:COMPUTE (example [chr9:chr15])              [100%] 231 of 231 ✔
[fd/f05b4e] NCHG:MERGE (example (cis))                       [100%] 2 of 2 ✔
[0e/057edf] NCHG:FILTER (example (cis))                      [100%] 2 of 2 ✔
[27/b64f64] NCHG:CONCAT (example)                            [100%] 2 of 2 ✔
[37/ca3c33] NCHG:VIEW (example)                              [100%] 1 of 1 ✔
[62/bc9193] NCHG:PLOT_EXPECTED (example)                     [100%] 1 of 1 ✔
[46/eceb87] NCHG:GET_HIC_PLOT_RESOLUTION (example)           [100%] 1 of 1 ✔
[3f/decbec] NCHG:PLOT_SIGNIFICANT (example)                  [100%] 1 of 1 ✔
```

This will create a `data/results/` folder with the following files:

```txt
data/results
└── example
    ├── example.filtered.parquet
    ├── example.filtered.tsv.gz
    ├── example.parquet
    ├── expected_values_example.h5
    └── plots
        ├── example.chr1.chr1.png
        ├── example.chr1.chr2.png
        ├── example.chr1.chr3.png
        ...
        ├── example_cis.png
        └── example_trans.png

3 directories, 220 files
```

- `example.parquet` - Parquet file with the output of `NCHG compute` (i.e., all genomic interactions before p-value correction).
- `example.filtered.{parquet,tsv.gz}` - Parquet and TSV files with the statistically significant interactions detected by NCHG.
- `expected_values_example.h5` - HDF5 file with the expected values computed by NCHG.
- `plots/example.*.*.png` - Plots showing the log ratio computed by NCHG for each chromosome pair analyzed.
- `plots/example_{cis,trans}.png` - Plots showing the expected value profile computed by NCHG.

<details>
<summary>Troubleshooting</summary>

If you get permission errors when using `-with-docker`:

- Pass option `-process.containerOptions="--user root"` to `nextflow run`

If you get an error similar to:

```txt
Cannot find revision `v0.0.1` -- Make sure that it exists in the remote repository `https://github.com/paulsengroup/nchg-nf`
```

try to remove folder `~/.nextflow/assets/paulsengroup/nchg-nf` before running the workflow

</details>

## Getting help

If you are having trouble running the workflow feel free to reach out by [starting a new discussion here](https://github.com/paulsengroup/nchg-nf/discussions).

Bug reports and feature requests can be submitted by opening an [issue](https://github.com/paulsengroup/nchg-nf/issues).
