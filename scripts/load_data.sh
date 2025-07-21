#!/usr/bin/env bash
set -euo pipefail

MINIO_ENDPOINT="http://localhost:9000"
BUCKET="indicadores-provincias"
ACCESS_KEY="minio"
SECRET_KEY="minio123"
REGION="us-east-1"
DATA_CSV="$(cd "$(dirname "$0")/.." && pwd)/data/indicadores-provinciales.csv"

if [[ ! -f "$DATA_CSV" ]]; then
  echo "No se encontró el CSV en $DATA_CSV" >&2
  exit 1
fi

# Export credenciales (formato AWS)
export AWS_ACCESS_KEY_ID="$ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="$SECRET_KEY"
export AWS_DEFAULT_REGION="$REGION"

# Crear bucket si no existe
if ! aws --endpoint-url "$MINIO_ENDPOINT" s3 ls "s3://$BUCKET" >/dev/null 2>&1; then
  echo "Creando bucket $BUCKET ..."
  aws --endpoint-url "$MINIO_ENDPOINT" s3 mb "s3://$BUCKET"
fi

echo "Subiendo CSV..."
aws --endpoint-url "$MINIO_ENDPOINT" s3 cp "$DATA_CSV" "s3://$BUCKET/raw/indicadores-provinciales.csv"

echo "Listo. Objetos en bucket:"
aws --endpoint-url "$MINIO_ENDPOINT" s3 ls "s3://$BUCKET/raw/"