import pytest
from pyspark.sql import SparkSession
from pyspark.sql import Row
from jobs import aggregate_indicators as aggmod

@pytest.fixture(scope="session")
def spark():
    spark = (SparkSession.builder
             .master("local[2]")
             .appName("provindicators-test")
             .getOrCreate())
    yield spark
    spark.stop()

def test_transform_agg_and_latest(spark):
    data = [
        Row(
            sector_id=1,
            sector_nombre="Indicadores Provinciales",
            variable_id=10,
            actividad_producto_nombre="Actividad X",
            indicador="Tasa",
            unidad_de_medida="por 1000",
            fuente="TEST",
            frecuencia_nombre="Anual",
            cobertura_nombre="Nacional",
            alcance_tipo="PROVINCIA",
            alcance_id=101,
            alcance_nombre="BUENOS AIRES",
            indice_tiempo="2023-01-01",
            valor="10.5",
        ),
        Row(
            sector_id=1,
            sector_nombre="Indicadores Provinciales",
            variable_id=10,
            actividad_producto_nombre="Actividad X",
            indicador="Tasa",
            unidad_de_medida="por 1000",
            fuente="TEST",
            frecuencia_nombre="Anual",
            cobertura_nombre="Nacional",
            alcance_tipo="PROVINCIA",
            alcance_id=101,
            alcance_nombre="BUENOS AIRES",
            indice_tiempo="2024-01-01",
            valor="11.0",
        ),
        Row(
            sector_id=1,
            sector_nombre="Indicadores Provinciales",
            variable_id=20,
            actividad_producto_nombre="Actividad Y",
            indicador="Índice",
            unidad_de_medida="%",
            fuente="TEST",
            frecuencia_nombre="Anual",
            cobertura_nombre="Nacional",
            alcance_tipo="PAIS",
            alcance_id=200,
            alcance_nombre="Argentina",
            indice_tiempo="2024-01-01",
            valor="99.9",
        ),
    ]

    df = spark.createDataFrame(data)

    agg_df, latest_df = aggmod.transform(df)

    # Agg debe contener sólo PROVINCIA (1 provincia, 1 indicador, 2 años)
    rows = agg_df.take(5)
    assert len(rows) == 2  # 2023 y 2024
    years = sorted([r.anio for r in rows])
    assert years == [2023, 2024]

    # Latest debe elegir 2024-01-01 para BUENOS AIRES/Tasa
    latest_rows = latest_df.collect()
    assert len(latest_rows) == 1
    r0 = latest_rows[0]
    assert r0.alcance_nombre == "BUENOS AIRES"
    assert r0.indicador == "Tasa"
    # valor 11.0
    assert pytest.approx(r0.valor, rel=1e-6) == 11.0
