// Copyright (C) 2024 Roberto Rossini <roberros@uio.no>
//
// SPDX-License-Identifier: MIT

Path strip_resolution_from_cooler_uri(uri) {
    file(uri.replaceFirst(/::\/resolutions\/\d+$/, ""), checkIfExists: true)
}

// Workaround for optional input files: https://github.com/nextflow-io/nextflow/issues/1694
List<Path> make_optional_input(path) {
    if (path?.trim()) {
        return [file(path)]
    }
    return []
}

Tuple<Path> parse_sample_sheet_row(row) {
    def Path hic_fname = strip_resolution_from_cooler_uri(row.hic_file)
    def List<Path> files = [hic_fname]

    def List<Path> domains = make_optional_input(row.domains)
    def List<Path> mask = make_optional_input(row.mask)

    tuple(row.sample,
          files,
          domains,
          mask)
}


workflow SAMPLESHEET {

    take:
        sample_sheet
        sample
        hic_file
        resolution
        domains
        mask

    main:
        if (sample_sheet) {
            if(sample) log.warn("'sample' parameter is ignored when 'sample_sheet' is defined")
            if(hic_file) log.warn("'hic_file' parameter is ignored when 'sample_sheet' is defined")
            if(mask) log.warn("'mask' parameter is ignored when 'sample_sheet' is defined")
            if(resolution) log.warn("'resolution' parameter is ignored when 'sample_sheet' is defined")

            CHECK_SYNTAX(file(sample_sheet, checkIfExists: true))
        } else {
            if(!sample || !hic_file || !resolution) {
                log.error("The following parameters are required when 'sample_sheet' is undefined! Required parameters: sample, hic_file, resolution")
            }

            GENERATE(
                sample,
                hic_file,
                resolution,
                domains ? domains : "",
                mask ? mask : ""
            )

            CHECK_SYNTAX(GENERATE.out.tsv)
        }

        CHECK_SYNTAX.out.tsv.set { sample_sheet }

        sample_sheet
            .splitCsv(sep: "\t", header: true)
            .map {
                   def row = parse_sample_sheet_row(it)
                   // Concatenate path to coolers and optional files
                   row[1] + row[2] + row[3]
            }
            .flatten()
            .unique()
            .filter { !!it }
            .set { files_from_sample_sheet }

        CHECK_FILES(
            sample_sheet,
            files_from_sample_sheet.collect()
        )

    emit:
        sample_sheet = CHECK_FILES.out.tsv

}

process GENERATE {
    label 'duration_very_short'

    cpus 1

    input:
        val sample
        val hic_file
        val resolution
        val domains
        val mask

    output:
        path "sample_sheet.tsv", emit: tsv

    script:
        """
        for param in '$sample' '$hic_file' '$resolution'; do
            if [[ "\$param" == 'null' ]]; then
                2>&1 echo 'Parameters sample, hic_file, and resolution are required when no samplesheet is provided!'
                2>&1 echo "sample='$sample'; hic_file='$hic_file'; resolution='$resolution'"
                exit 1
            fi
        done

        printf 'sample\\thic_file\\tresolution\\tdomains\\tmask\\n' > sample_sheet.tsv
        printf '%s\\t%s\\t%s\\t%s\\t%s\\n' '$sample' \\
                                 '$hic_file' \\
                                 '$resolution' \\
                                 '$domains' \\
                                 '$mask' >> sample_sheet.tsv
        """
}

process CHECK_SYNTAX {
    label 'duration_very_short'

    cpus 1

    input:
        path sample_sheet

    output:
        path "${sample_sheet}", includeInputs: true, emit: tsv

    script:
        """
        nchg_nf_parse_samplesheet.py --detached '$sample_sheet' > /dev/null
        """
}

process CHECK_FILES {
    label 'duration_very_short'

    cpus 1

    input:
        path sample_sheet
        path files

    output:
        path "*.ok", emit: tsv

    script:
        """
        nchg_nf_parse_samplesheet.py '$sample_sheet' > '$sample_sheet'.ok
        """
}
