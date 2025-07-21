docker run --rm -it \
  -v $(pwd)/data:/data \
  --network=provincial-indicators_provincial-net \
  minio/mc:latest \
  /bin/sh -c "mc alias set local http://minio:9000 minio minio123 --api S3v4 && \
             mc mb --ignore-existing local/indicadores-provincias && \
             mc cp /data/indicadores-provinciales.csv local/indicadores-provincias/raw/"