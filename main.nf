#!/usr/bin/env nextflow
// Copyright (C) 2024 Roberto Rossini <roberros@uio.no>
//
// SPDX-License-Identifier: MIT

nextflow.enable.dsl=2

params.publish_dir = params.outdir

NCHG_PARAMS = [
    publish_dir: "${params.outdir}/nchg/",
    publish_dir_mode: params.publish_dir_mode,
    use_cis_interactions: true,
    use_trans_interactions: true,
    zstd_compression_lvl: params.zstd_compression_lvl,
    fdr_cis: params.nchg_fdr_cis,
    fdr_trans: params.nchg_fdr_trans,
    log_ratio_cis: params.nchg_log_ratio_cis,
    log_ratio_trans: params.nchg_log_ratio_trans,
    plot_format: params.plot_format,
    hic_tgt_resolution_plots: 500000,
    plot_sig_interactions_cmap_lb: null,
    plot_sig_interactions_cmap_ub: 2.0,
    skip_expected_plots: params.nchg_skip_plots,
    skip_sign_interaction_plots: params.nchg_skip_plots,
]

NCHG_CIS_PARAMS = NCHG_PARAMS.clone()
NCHG_CIS_PARAMS["use_trans_interactions"] = false

NCHG_TRANS_PARAMS = NCHG_PARAMS.clone()
NCHG_TRANS_PARAMS["use_cis_interactions"] = false

PREPROCESSING_PARAMS = [
    publish_dir: params.outdir,
    publish_dir_mode: params.publish_dir_mode,
]

CHROM3D_PARAMS = [
    publish_dir: "${params.outdir}/chrom3d/",
    publish_dir_mode: params.publish_dir_mode,
    archive_models: params.archive_models,
]

include { SAMPLESHEET } from './subworkflows/samplesheet.nf'
include { NCHG as NCHG_CIS } from './subworkflows/nchg.nf' params(NCHG_CIS_PARAMS)
include { NCHG as NCHG_TRANS } from './subworkflows/nchg.nf' params(NCHG_TRANS_PARAMS)
include { PREPROCESSING } from './subworkflows/preprocessing.nf' params(PREPROCESSING_PARAMS)
include { CHROM3D } from './subworkflows/chrom3d.nf' params(CHROM3D_PARAMS)


workflow {

    log.info("-- PARAMETERS")
    log.info("")
    if (params.sample_sheet) {
        log.info("-- sample_sheet: ${params.sample_sheet}")
    } else {
        log.info("-- sample: ${params.sample}")
        log.info("-- hic_file: ${params.hic_file}")
        log.info("-- resolution: ${params.resolution}")
        log.info("-- beads: ${params.beads}")
        log.info("-- lads: ${params.lads}")
        log.info("-- mask: ${params.mask}")
    }
    log.info("-- outdir: ${params.outdir}")
    log.info("-- publish_dir_mode: ${params.publish_dir_mode}")

    log.info("-- cytoband: ${params.cytoband}")
    log.info("-- assembly_gaps: ${params.assembly_gaps}")
    log.info("-- masked_chromosomes: ${params.masked_chromosomes}")

    log.info("-- chrom3d_args: ${params.chrom3d_args}")
    log.info("-- ploidy: ${params.ploidy}")
    log.info("-- number_of_models: ${params.number_of_models}")
    log.info("-- archive_models: ${params.archive_models}")

    log.info("-- nchg_mad_max: ${params.nchg_mad_max}")
    log.info("-- nchg_bad_bin_fraction: ${params.nchg_bad_bin_fraction}")
    log.info("-- nchg_fdr_cis: ${params.nchg_fdr_cis}")
    log.info("-- nchg_log_ratio_cis: ${params.nchg_log_ratio_cis}")
    log.info("-- nchg_fdr_trans: ${params.nchg_fdr_trans}")
    log.info("-- nchg_log_ratio_trans: ${params.nchg_log_ratio_trans}")

    log.info("-- plot_format: ${params.plot_format}")
    log.info("-- nchg_skip_plots: ${params.nchg_skip_plots}")

    log.info("")

    SAMPLESHEET(
        params.sample_sheet,
        params.sample,
        params.hic_file,
        params.resolution,
        params.beads,
        params.mask
    )

    SAMPLESHEET.out.tsv.set { sample_sheet }
    SAMPLESHEET.out.nchg_cis.set { nchg_cis_sample_sheet }
    SAMPLESHEET.out.nchg_trans.set { nchg_trans_sample_sheet }

    NCHG_CIS(
        nchg_cis_sample_sheet,
        params.nchg_mad_max,
        params.nchg_bad_bin_fraction,
        params.cytoband,
        params.assembly_gaps
    )

    NCHG_TRANS(
        nchg_trans_sample_sheet,
        params.nchg_mad_max,
        params.nchg_bad_bin_fraction,
        params.cytoband,
        params.assembly_gaps
    )

    NCHG_CIS.out.tsv
        .map {
            sample = it[0] - ~/_cis$/
            tuple(sample, it[1])
        }
        .set { nchg_sig_interactions_cis }

    NCHG_TRANS.out.tsv
        .map {
            sample = it[0] - ~/_trans$/
            tuple(sample, it[1])
        }
        .set { nchg_sig_interactions_trans }

    PREPROCESSING(
        sample_sheet,
        nchg_sig_interactions_cis,
        nchg_sig_interactions_trans,
        params.ploidy,
        params.masked_chromosomes
    )

    CHROM3D(
        PREPROCESSING.out.gtrack,
        params.chrom3d_args,
        params.number_of_models
    )

}
