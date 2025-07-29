# Variables
COMPOSE=docker compose -f infra/docker-compose.yml
SPARK_JOBS=spark-jobs
DATASET=data/indicadores-provinciales.csv
S3_BUCKET=s3://indicadores-provincias
PYSPARK_CONTAINER=spark-jobs

# Objetivo por defecto
.DEFAULT_GOAL := help

help:
	@echo "Comandos disponibles:"
	@echo "  make up                → Levanta todos los servicios con Docker Compose"
	@echo "  make down              → Baja los servicios"
	@echo "  make build-api         → Reconstruye la API"
	@echo "  make load-data         → Sube CSV raw a MinIO"
	@echo "  make run-etl           → Corre el ETL de PySpark"
	@echo "  make redshift-up       → Levanta la base simulada Redshift (Postgres)"
	@echo "  make redshift-load     → Carga en Redshift simulado desde archivo S3 o resultado PySpark"
	@echo "  make all               → Ejecuta todo el pipeline: up → load → etl → redshift-load"

# Infraestructura
up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

build-api:
	$(COMPOSE) up -d --build api

# Datos
load-data:
	./scripts/load_data.sh

run-etl:
	./scripts/run_etl.sh

# Redshift (PostgreSQL simulado)
redshift-up:
	docker compose -f infra/redshift/docker-compose.yml up -d

redshift-load:
	python infra/redshift/load_to_redshift.py

# Flujo completo
all: up load-data run-etl redshift-up redshift-load
