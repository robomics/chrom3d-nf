#!/usr/bin/env bash

# Copyright (C) 2025 Roberto Rossini <roberros@uio.no>
# SPDX-License-Identifier: MIT

set -e
set -u
set -o pipefail


url='https://zenodo.org/records/16635955/files/chrom3d_nf_test_data.tar.zst?download=1'

checksums=(
  'cd26693cead7abd4b6177cf1db255b6111db82fdc08f2f875ef985b359bccf3d  4DNFIZ1ZVXC8.mcool'
  'ea23151c1e7fb552300bd74d1497f1a210858a43f30bdb78be55343b80ffcba4  cytoBand.dm6.txt.gz'
  '3887751d2034eeca830e0da506329bf8549ff395ca62b7bd7bf4793281883091  gap.dm6.txt.gz'
  '5425d27ce8a7bcc9f01a04f2818e38b05f235d88a96bccc52c1f13475e323570  periphery_constraints.dm6.bed.gz'
)


if [ $# -ne 1 ]; then
  1>&2 echo "Usage:   $0 path_to_output_folder/"
  1>&2 echo "Example: $0 data/"
  exit 1
fi

ok=true
for bin in curl sha256sum zstd tar; do
  if ! command -v "$bin" 1> /dev/null 2> /dev/null; then
    1>&2 echo "Unable to find $bin in your PATH"
    ok=false
  fi
done

if [ "$ok" != 'true' ]; then
  exit 1
fi

outdir="$1"
mkdir -p "$outdir"

# shellcheck disable=SC2064
trap "cd '$PWD'" EXIT

cd "$outdir"

if sha256sum -c <(printf '%s\n' "${checksums[@]}"); then
  1>&2 echo "### SUCCESS: all files are already available under folder \"$outdir\""
  exit 0
fi

1>&2 echo "### Downloading test datasets from \"$url\""
curl -L "$url" | zstd -dc | tar -xf - --strip-components=2

if ! sha256sum -c <(printf '%s\n' "${checksums[@]}"); then
  1>&2 echo '### ERROR: one or more files failed to validate, please review the output above'
  exit 1
fi

1>&2 echo "### SUCCESS: all files have successfully been downloaded inside folder \"$outdir\""
