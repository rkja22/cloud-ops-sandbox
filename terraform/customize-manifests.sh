#!/usr/bin/env bash

# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This script compiles manifest files with the image tags and places them in
# /release/...

set -euo pipefail
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
[[ -n "${DEBUG:-}" ]] && set -x

log() { echo "$1" >&2; }

# The tag of the image we should take
TAG="latest"
REPO_PREFIX="gcr.io/stackdriver-sandbox-230822/sandbox"
OUT_DIR="${OUT_DIR:-${SCRIPTDIR}/../release}"

read_manifests() {
    local dir
    dir="$1"

    while IFS= read -d $'\0' -r file; do
        cat "${file}"
        echo "---"
    done < <(find "${dir}" -name '*.yaml' -type f -print0)
}

mk_kubernetes_manifests() {
    out_manifest="$(read_manifests "${SCRIPTDIR}/../kubernetes-manifests")"

    # replace "image" repo, tag for each service
    for dir in ../src/*/
    do
        svcname="$(basename "${dir}")"
        image="$REPO_PREFIX/$svcname:$TAG"

        pattern="^(\s*)image:\s.*$svcname(.*)(\s*)"
        replace="\1image: $image\3"
        out_manifest="$(sed -r "s|$pattern|$replace|" <(echo "${out_manifest}") )"
    done
    echo "${out_manifest}"
}

main() {
    mkdir -p "${OUT_DIR}"
    local k8s_manifests_file 

    k8s_manifests_file="${OUT_DIR}/kubernetes-manifests.yaml"
    mk_kubernetes_manifests > "${k8s_manifests_file}"
    log "Written ${k8s_manifests_file}"
}

main