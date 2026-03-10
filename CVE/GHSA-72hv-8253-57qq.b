#!/bin/bash

set -euo pipefail
. /.functions

ARTIFACT_IDS=(
	com.fasterxml.jackson.core:jackson-core@ZOOKEEPER_LIB_DIR
	com.fasterxml.jackson.core:jackson-databind@ZOOKEEPER_LIB_DIR
)

set_or_default BASE_DIR "/app"
set_or_default HOME_DIR "${BASE_DIR}/zookeeper"
set_or_default ZOOKEEPER_LIB_DIR "${HOME_DIR}/lib"

export ZOOKEEPER_LIB_DIR
exec fix-jars "GHSA-72hv-8253-57qq" "2.21.1" "${ARTIFACT_IDS[@]}"
