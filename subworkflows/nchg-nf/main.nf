#!/usr/bin/env nextflow
// Copyright (C) 2024 Roberto Rossini <roberros@uio.no>
//
// SPDX-License-Identifier: MIT

nextflow.enable.dsl=2
nextflow.preview.output=1

include { SAMPLESHEET } from './subworkflows/samplesheet'
include { NCHG } from './subworkflows/nchg'


workflow {
    main:
        log.info("-- PARAMETERS")
        log.info("")
        if (params.sample_sheet) {
            log.info("-- sample_sheet: ${params.sample_sheet}")
        } else {
            log.info("-- sample: ${params.sample}")
            log.info("-- hic_file: ${params.hic_file}")
            log.info("-- resolution: ${params.resolution}")
            log.info("-- domains: ${params.domains}")
            log.info("-- mask: ${params.mask}")
        }
        log.info("-- publish_dir_mode: ${params.publish_dir_mode}")
        log.info("-- cytoband: ${params.cytoband}")
        log.info("-- assembly_gaps: ${params.assembly_gaps}")

        log.info("-- mad_max: ${params.mad_max}")
        log.info("-- bad_bin_fraction: ${params.bad_bin_fraction}")

        log.info("-- fdr_cis: ${params.fdr_cis}")
        log.info("-- log_ratio_cis: ${params.log_ratio_cis}")
        log.info("-- fdr_trans: ${params.fdr_trans}")
        log.info("-- log_ratio_trans: ${params.log_ratio_trans}")

        log.info("-- use_cis_interactions: ${params.use_cis_interactions}")
        log.info("-- use_trans_interactions: ${params.use_trans_interactions}")

        log.info("-- plot_format: ${params.plot_format}")
        log.info("-- hic_tgt_resolution_plots: ${params.hic_tgt_resolution_plots}")
        log.info("-- plot_sig_interactions_cmap_lb: ${params.plot_sig_interactions_cmap_lb}")
        log.info("-- plot_sig_interactions_cmap_ub: ${params.plot_sig_interactions_cmap_ub}")
        log.info("-- skip_expected_plots: ${params.skip_expected_plots}")
        log.info("-- skip_sign_interaction_plots: ${params.skip_sign_interaction_plots}")

        log.info("")

        SAMPLESHEET(
            params.sample_sheet,
            params.sample,
            params.hic_file,
            params.resolution,
            params.domains,
            params.mask
        )

        NCHG(
            SAMPLESHEET.out.sample_sheet,
            params.mad_max,
            params.bad_bin_fraction,
            params.cytoband,
            params.assembly_gaps
        )

    publish:
        sample_sheet = SAMPLESHEET.out.sample_sheet
        expected = NCHG.out.expected
        parquets = NCHG.out.parquets
        plots = NCHG.out.plots
        tsv = NCHG.out.tsv

}

output {
    // TODO use named outputs
    sample_sheet {
        path '.'
        mode params.publish_dir_mode
    }
    expected {
        path { "${it[0]}/" }
        mode params.publish_dir_mode
    }
    parquets {
        path { "${it[0]}/" }
        mode params.publish_dir_mode
    }
    plots {
        path { "${it[0]}/plots/" }
        mode params.publish_dir_mode
    }
    tsv {
        path { "${it[0]}/" }
        mode params.publish_dir_mode
    }
}
