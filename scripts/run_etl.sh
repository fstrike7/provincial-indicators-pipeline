#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
INFRA_DIR="${SCRIPT_DIR}/../infra"

( cd "$INFRA_DIR" && docker compose run --rm spark-jobs "$@" )