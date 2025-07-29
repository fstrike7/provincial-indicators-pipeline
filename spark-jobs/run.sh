#!/usr/bin/env bash
set -euo pipefail

# env vars
python /opt/jobs/aggregate_indicators.py \
  --endpoint "${MINIO_ENDPOINT:-http://minio:9000}" \
  --access-key "${MINIO_ACCESS_KEY:-minio}" \
  --secret-key "${MINIO_SECRET_KEY:-minio123}" \
  --bucket "${MINIO_BUCKET:-indicadores-provincias}" \
  --raw-key "${RAW_KEY:-raw/indicadores-provinciales.csv}" \
  --processed-prefix "${PROCESSED_PREFIX:-processed}" "$@"