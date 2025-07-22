from pyspark.sql import SparkSession

def test_spark_session():
    spark = SparkSession.builder.master("local[1]").appName("test").getOrCreate()
    df = spark.createDataFrame([(1, "A")], ["id", "name"])
    assert df.count() == 1
    spark.stop()