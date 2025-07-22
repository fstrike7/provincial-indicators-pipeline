# Provincial Indicators Pipeline

**Proyecto personal para demostrar ciclo completo de vida de software (SDLC) con Spring Boot, PySpark, contenedores, CI/CD y observabilidad.**

Este repo replica —en versión simplificada, reproducible y 100% localizable— el flujo que manejaba en entornos profesionales: desarrollo → build → contenedor → datos en “S3” (mock MinIO) → ETL PySpark → API REST → monitoreo con Prometheus + Grafana → integración continua con GitHub Actions.

---

## Tabla de Contenidos

- [Objetivos](#objetivos)
- [Arquitectura](#arquitectura)
- [Tecnologías](#tecnologías)
- [Estructura del repositorio](#estructura-del-repositorio)
- [Flujo de ramas](#flujo-de-ramas)
- [Requisitos locales](#requisitos-locales)
- [Configuración rápida (Quick Start)](#configuración-rápida-quick-start)
- [Servicios Docker](#servicios-docker)
- [Carga de datos raw](#carga-de-datos-raw)
- [ETL PySpark → datos procesados](#etl-pyspark--datos-procesados)
- [API REST Spring Boot](#api-rest-spring-boot)
- [Monitoreo: Prometheus + Grafana](#monitoreo-prometheus--grafana)
- [Testing](#testing)
  - [Tests en Spring Boot](#tests-en-spring-boot)
  - [Tests en PySpark](#tests-en-pyspark)

---

## Objetivos



- Construir un **servicio REST** (Spring Boot) que expone indicadores provinciales a partir de datos en un bucket estilo S3.
- Procesar datos con **PySpark ETL** para generar agregados y valores recientes.
- Simular infraestructura AWS usando **MinIO (S3 mock)** en local.
- Contenerizar todo con **Docker Compose**.
- Exponer **métricas** vía Actuator + Micrometer Prometheus, visualizar en **Grafana**.
- Configurar **CI en GitHub Actions** para validar builds y tests en PRs.
- Preparar camino a despliegues “Dev → Main” (futuro: imágenes).

---

## Arquitectura

Vista simplificada del flujo de datos y build:

```
Dataset CSV (indicadores provinciales)
         │
         ├── scripts/load_data.sh → MinIO (s3://indicadores-provincias/raw/)
         │
         ├── spark-jobs (PySpark ETL) → processed/agg + latest → MinIO
         │
         └── API Spring Boot lee de MinIO:
              • Provincias disponibles
              • Último valor por indicador/provincia
              • Agregados por año

Observabilidad:
API → /actuator/prometheus → Prometheus → Grafana dashboards
```

---

## Tecnologías

| Área           | Herramienta                  | Uso                                    |
| -------------- | ---------------------------- | -------------------------------------- |
| Backend        | **Spring Boot 3.5**, Java 21 | API REST, Actuator, métricas           |
| Datos          | **PySpark 3.5**              | ETL de CSV → agregados                 |
| Almacenamiento | **MinIO**                    | Mock S3 (bucket datos raw + processed) |
| Contenedores   | **Docker Compose**           | Orquestación local                     |
| Observabilidad | **Prometheus + Grafana**     | Métricas API                           |
| CI             | **GitHub Actions**           | Build/test en PRs                      |

---

## Estructura del repositorio

```
provincial-indicators-pipeline/
├─ api/                              # Spring Boot REST API
│  ├─ src/main/java/ar/com/faustino/provindicators/...
│  ├─ src/test/java/...              # (TODO)
│  ├─ pom.xml
│  └─ Dockerfile
├─ spark-jobs/                       # PySpark ETL jobs
│  ├─ jobs/aggregate_indicators.py
│  ├─ requirements.txt
│  ├─ run.sh
│  └─ Dockerfile
├─ infra/                            # Infra local dockerizada
│  ├─ docker-compose.yml             # MinIO, API, Prometheus, Grafana, spark-jobs
│  ├─ prometheus.yml
│  └─ grafana/
│      ├─ provisioning/datasources/datasource.yml
│      └─ dashboards/                # JSON dashboards (vacío al inicio)
├─ scripts/
│  ├─ load_data.sh                   # Sube CSV raw a MinIO
│  └─ run_etl.sh                     # Corre job spark-jobs vía compose
├─ data/
│  └─ indicadores-provinciales.csv   # Dataset original
└─ README.md                         # Este archivo
```

---

## Flujo de ramas

Flujo recomendado para simular entorno profesional:

| Rama        | Uso                    | CI                   | Deploy (futuro)           |
| ----------- | ---------------------- | -------------------- | ------------------------- |
| `feature/*` | Desarrollo puntual     | Build + test PR      | —                         |
| `develop`   | Integración continua   | Build + test         | Entorno Dev local/compose |
| `main`      | Estable / demo pública | Build + test release | Prod simulado             |

> Configurá en GitHub “branch protection rules” para que **no se pueda mergear a **``** ni **``** sin CI verde**.

---

## Requisitos locales

Para correr el proyecto se necesita:

- Docker Desktop (o Docker Engine + Compose plugin).
- Git.
- Bash (o Git Bash).
- JDK 21 si se quiere compilar la API fuera de Docker.
- AWS CLI (opcional; los scripts se apoyan en él para subir a MinIO).

---

## Configuración rápida (Quick Start)

Clonar y entrar al repo:

```bash
git clone https://github.com/fstrike7/provincial-indicators-pipeline.git
cd provincial-indicators-pipeline
```

Levantar infraestructura básica:

```bash
cd infra
docker compose up -d
```

Ver contenedores:

```bash
docker compose ps
```

Subir datos raw al bucket MinIO:

```bash
cd ..
./scripts/load_data.sh
```

(Acceso a la consola MinIO: [http://localhost:9001](http://localhost:9001) — user: `minio`, pass: `minio123`).

Reconstruir y levantar API si se editó:

```bash
cd infra
docker compose up -d --build api
```

Probar:

```bash
curl localhost:8080/health/s3
curl localhost:8080/api/provinces
```

---

## Servicios Docker

| Servicio        | Puerto Host | Descripción                                         |
| --------------- | ----------- | --------------------------------------------------- |
| `minio`         | 9000        | API S3-compatible                                   |
| `minio-console` | 9001        | UI Web MinIO                                        |
| `api`           | 8080        | API Spring Boot                                     |
| `prometheus`    | 9090        | UI Prometheus                                       |
| `grafana`       | 3000        | Dashboards                                          |
| `spark-jobs`    | (ad-hoc)    | Contenedor de ETL PySpark (se ejecuta bajo demanda) |

---

## Carga de datos raw

El dataset CSV debe residir en `data/indicadores-provinciales.csv`.

Subilo al bucket con:

```bash
./scripts/load_data.sh
```

Esto crea:

```
s3://indicadores-provincias/raw/indicadores-provinciales.csv
```

---

## ETL PySpark → datos procesados

El job PySpark se ejecuta en contenedor y:

- Descarga el CSV raw desde MinIO.
- Limpia tipos y valores.
- Filtra registros de tipo **PROVINCIA**.
- Calcula agregados por provincia/indicador/año.
- Calcula último valor por provincia/indicador.
- Escribe resultados en `processed/` (Parquet + JSON) y los sube a MinIO.

Ejecutar ETL:

```bash
./scripts/run_etl.sh
# internamente: docker compose run --rm spark-jobs
```

Ver resultados en MinIO ([http://localhost:9001](http://localhost:9001)):

```
processed/
  ├─ agg_province_indicator_year/    # parquet (part files)
  └─ latest_province_indicator.json  # json plano
```

---

## API REST Spring Boot

La API actualmente puede:

- Confirmar conectividad con MinIO: `GET /health/s3`
- Listar provincias detectadas: `GET /api/provinces`
- (En progreso) Devolver registros y agregados por provincia usando datos procesados.

### Variables de config relevantes (`application-local.yml`)

```yaml
aws:
  s3:
    endpoint: http://localhost:9000
    bucket: indicadores-provincias
    region: us-east-1
    access-key: minio
    secret-key: minio123
```

> Cuando la API corre en Docker Compose, el endpoint se inyecta como `http://minio:9000` vía environment.

---

## Monitoreo: Prometheus + Grafana

La API expone métricas Micrometer en `/actuator/prometheus`.

Prometheus scrapea:

```yaml
- job_name: api
  metrics_path: /actuator/prometheus
  static_configs:
    - targets: ["api:8080"]
```

Grafana trae la datasource provisionada automáticamente (usuario/password admin/admin por defecto). Agregaremos dashboards para:

- Requests/seg
- Latencia promedio
- Errores 4xx/5xx

---

## Testing

### Estrategia general

Inicialmente:

**Back-end (Spring Boot)**

- Tests de carga de contexto.
- Test de `HealthController`.
- Test de `IndicatorDataLoader` (usa MinIO vía Testcontainers o S3 mock).
- Test de `IndicatorQueryService` (filtrar provincias, conteo básico).

**PySpark**

- Test unitario del ETL en modo mini:
  - Generar CSV en memoria (2 provincias, 2 indicadores, 2 años).
  - Correr `run_etl()` contra carpeta local + moto (mock S3) o usando filesystem local.
  - Verificar que haya JSON de latest y agregados con filas esperadas.

---
