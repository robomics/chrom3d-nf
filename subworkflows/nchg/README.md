<!--
Copyright (C) 2025 Roberto Rossini <roberros@uio.no>

SPDX-License-Identifier: MIT
-->

# README

The nchg subworkflow was downloaded from [github.com/paulsengroup/nchg-nf](https://github.com/paulsengroup/nchg-nf).
The code was downloaded on July 30, 2025 (commit d31f6c1125e4c86c1d7ba32ccec13ec80f873e60).

The following changes have been made before checking in the code:

- Copy the LICENSE file
- Move subworkflow scripts under the main workflow's bin/ folder
- Update withName matchers in the nextflow.config to match `NCHG_{CIS,TRANS}:.*`
