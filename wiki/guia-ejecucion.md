# Guía de Ejecución Local del Proyecto

Este documento detalla cómo ejecutar cada parte del proyecto `provincial-indicators-pipeline` en entorno local utilizando `make` y Docker.

## Requisitos Previos

- Docker y Docker Compose instalados
- Python 3.10+ y entorno virtual (`.env`) creado si se usa fuera de contenedores
- Acceso a AWS CLI configurado (si se usan servicios externos)

## Pasos de Ejecución

### 1. Preparar entorno
```bash
make prepare
```
Crea el entorno virtual `.env` e instala las dependencias de Python necesarias.

### 2. Ejecutar PySpark Job
```bash
make run-spark
```
Ejecuta el script principal de PySpark y genera un CSV intermedio en MinIO (`http://localhost:9000/provincial-bucket` por defecto).

### 3. Levantar MinIO
```bash
make up-minio
```
Levanta un servicio local de almacenamiento compatible con S3.

### 4. Levantar Redshift simulado
```bash
make up-redshift
```
Inicia un contenedor PostgreSQL configurado para simular Redshift.

### 5. Cargar datos a Redshift simulado
```bash
make run-redshift-loader
```
Lee desde MinIO o desde un archivo intermedio y carga los datos a Redshift local.

### 6. Ver estructura de directorios
```bash
make tree
```
Muestra una estructura limpia del proyecto para facilitar navegación.

## Observaciones

- Todos los contenedores usan imágenes públicas o configuraciones locales mockeadas para evitar costos.
- La configuración de MinIO puede modificarse en el archivo `docker-compose.override.yml` si se desea usar otro bucket o puerto.
- El archivo de resultados de PySpark debe encontrarse en el bucket configurado antes de ejecutar el paso de carga en Redshift.

