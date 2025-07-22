#!/usr/bin/env python3
import os
import sys
import argparse
import tempfile
import boto3
import pandas as pd
from pathlib import Path
from pyspark.sql import SparkSession, functions as F, Window
from pyspark.sql.types import (StructType, StructField, IntegerType, StringType, DoubleType)

# ------------------------------------------------------------------
# Args
# ------------------------------------------------------------------

def get_args():
    p = argparse.ArgumentParser()
    p.add_argument("--endpoint", default=os.getenv("MINIO_ENDPOINT", "http://minio:9000"))
    p.add_argument("--access-key", default=os.getenv("MINIO_ACCESS_KEY", "minio"))
    p.add_argument("--secret-key", default=os.getenv("MINIO_SECRET_KEY", "minio123"))
    p.add_argument("--bucket", default=os.getenv("MINIO_BUCKET", "indicadores-provincias"))
    p.add_argument("--raw-key", default=os.getenv("RAW_KEY", "raw/indicadores-provinciales.csv"))
    p.add_argument("--processed-prefix", default=os.getenv("PROCESSED_PREFIX", "processed"))
    return p.parse_args()


def download_raw_csv(s3, bucket, key, dest_path):
    print(f"[ETL] Descargando s3://{bucket}/{key} -> {dest_path}")
    s3.download_file(bucket, key, dest_path)
    return dest_path


def build_spark():
    return (SparkSession.builder
            .appName("provincial-indicators-etl")
            .master("local[*]")
            .getOrCreate())


SCHEMA = StructType([
    StructField("sector_id", IntegerType(), True),
    StructField("sector_nombre", StringType(), True),
    StructField("variable_id", IntegerType(), True),
    StructField("actividad_producto_nombre", StringType(), True),
    StructField("indicador", StringType(), True),
    StructField("unidad_de_medida", StringType(), True),
    StructField("fuente", StringType(), True),
    StructField("frecuencia_nombre", StringType(), True),
    StructField("cobertura_nombre", StringType(), True),
    StructField("alcance_tipo", StringType(), True),
    StructField("alcance_id", IntegerType(), True),
    StructField("alcance_nombre", StringType(), True),
    StructField("indice_tiempo", StringType(), True),
    StructField("valor", StringType(), True),
])

def transform(df):
    """Pure transform: recibe DF raw con columnas originales y retorna (agg_df, latest_df)."""
    from pyspark.sql import functions as F
    from pyspark.sql.types import DoubleType
    from pyspark.sql.window import Window

    # normalize
    df = df.withColumn("valor_clean", F.regexp_replace(F.col("valor"), ",", "."))
    df = df.withColumn("valor_d", F.col("valor_clean").cast(DoubleType()))
    # parse fecha + año
    df = df.withColumn("fecha", F.to_date("indice_tiempo", "yyyy-MM-dd"))
    df = df.withColumn("anio", F.year("fecha"))
    # provincias solamente
    dfp = df.filter(F.upper(F.col("alcance_tipo")) == F.lit("PROVINCIA"))

    agg = (dfp.groupBy("alcance_nombre", "indicador", "anio")
              .agg(F.avg("valor_d").alias("avg_valor"),
                   F.min("valor_d").alias("min_valor"),
                   F.max("valor_d").alias("max_valor"),
                   F.count("valor_d").alias("n")))

    w = Window.partitionBy("alcance_nombre", "indicador").orderBy(F.col("fecha").desc())
    latest = (dfp.withColumn("rn", F.row_number().over(w))
                 .filter(F.col("rn") == 1)
                 .select("alcance_nombre", "indicador", "fecha", F.col("valor_d").alias("valor")))

    return agg, latest

def run_etl(spark, csv_path, processed_prefix, s3, bucket):
    print(f"[ETL] Leyendo CSV {csv_path}")
    df = spark.read.csv(csv_path, header=True, schema=SCHEMA, encoding="ISO-8859-1")

    agg, latest = transform(df)

    tmpdir = Path(tempfile.mkdtemp(prefix="provind-etl-"))
    agg_dir = tmpdir / "agg_province_indicator_year"
    latest_json = tmpdir / "latest_province_indicator.json"

    print(f"[ETL] Escribiendo Parquet agg en {agg_dir}")
    (agg.write.mode("overwrite").parquet(str(agg_dir)))

    print(f"[ETL] Escribiendo latest JSON en {latest_json}")
    latest.toPandas().to_json(latest_json, orient="records", force_ascii=False)

    # Subir a MinIO ---------------------------------------------------
    # Subir el directorio Parquet como objetos part-*
    prefix_agg = f"{processed_prefix}/agg_province_indicator_year/"
    for file in agg_dir.glob("**/*"):
        if file.is_file():
            rel = file.relative_to(agg_dir)
            key = prefix_agg + str(rel).replace("\\", "/")
            print(f"[ETL] Subiendo {file} -> s3://{bucket}/{key}")
            s3.upload_file(str(file), bucket, key)

    # Subir latest json
    key_latest = f"{processed_prefix}/latest_province_indicator.json"
    print(f"[ETL] Subiendo {latest_json} -> s3://{bucket}/{key_latest}")
    s3.upload_file(str(latest_json), bucket, key_latest)

    print("[ETL] Completo.")


def main():
    args = get_args()

    s3 = boto3.client(
        "s3",
        endpoint_url=args.endpoint,
        aws_access_key_id=args.access_key,
        aws_secret_access_key=args.secret_key,
        region_name="us-east-1",
    )

    # Descargar raw a tmp
    tmp_csv = Path(tempfile.mkdtemp(prefix="provind-raw-")) / "raw.csv"
    download_raw_csv(s3, args.bucket, args.raw_key, str(tmp_csv))

    spark = build_spark()
    try:
        run_etl(spark, str(tmp_csv), args.processed_prefix, s3, args.bucket)
    finally:
        spark.stop()


if __name__ == "__main__":
    sys.exit(main())