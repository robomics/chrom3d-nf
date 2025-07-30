<!--
Copyright (C) 2025 Roberto Rossini <roberros@uio.no>

SPDX-License-Identifier: MIT
-->

# README

The nchg subworkflow was downloaded from [github.com/paulsengroup/nchg-nf](https://github.com/paulsengroup/nchg-nf).
The code was downloaded on July 29, 2025 (commit eea28ca35c392ff2b8f0e1ebea5fc365d07b85b4).

The following changes have been made before checking in the code:

- Copy the LICENSE file
- Move subworkflow scripts under the main workflow's bin/ folder
- Update withName matchers in the nextflow.config to match `NCHG_{CIS,TRANS}:.*`
