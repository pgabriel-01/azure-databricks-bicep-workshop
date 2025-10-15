# Databricks notebook source
# MAGIC %md
# MAGIC # NYC Taxi Data Analysis - Data Ingestion
# MAGIC 
# MAGIC This notebook demonstrates data ingestion best practices using Azure Databricks and Azure Storage.
# MAGIC 
# MAGIC ## Learning Objectives
# MAGIC - Connect to Azure Storage using secure authentication
# MAGIC - Ingest CSV data with proper schema definition
# MAGIC - Implement data quality checks
# MAGIC - Save data in Delta Lake format for ACID transactions
# MAGIC 
# MAGIC ## Prerequisites
# MAGIC - Azure Storage account with NYC taxi data
# MAGIC - Databricks workspace with proper permissions
# MAGIC - Service principal configured for storage access

# COMMAND ----------

# MAGIC %md
# MAGIC ## Setup and Configuration

# COMMAND ----------

# Import required libraries
from pyspark.sql import SparkSession
from pyspark.sql.types import *
from pyspark.sql.functions import *
import os

# Configure Spark for Delta Lake
spark.conf.set("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension")
spark.conf.set("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog")

print("Spark session configured successfully")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Storage Configuration
# MAGIC 
# MAGIC We'll use Azure Key Vault-backed secret scopes for secure credential management.

# COMMAND ----------

# Storage account configuration
STORAGE_ACCOUNT_NAME = "workshopstorageaccount"  # Replace with actual storage account name
CONTAINER_NAME = "raw-data"
MOUNT_POINT = "/mnt/workshop-data"

# Key Vault secret scope (created via Terraform)
SECRET_SCOPE = "workshop-keyvault-scope"

# Get storage credentials from Key Vault
try:
    storage_account_key = dbutils.secrets.get(scope=SECRET_SCOPE, key="storage-account-key")
    print("Retrieved storage credentials from Key Vault")
except Exception as e:
    print(f"Error retrieving credentials: {e}")
    print("Using alternative authentication method...")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Mount Azure Storage
# MAGIC 
# MAGIC Mount the storage account to make data easily accessible.

# COMMAND ----------

# Check if mount already exists
def is_mounted(mount_point):
    try:
        dbutils.fs.ls(mount_point)
        return True
    except:
        return False

# Mount storage if not already mounted
if not is_mounted(MOUNT_POINT):
    try:
        dbutils.fs.mount(
            source=f"abfss://{CONTAINER_NAME}@{STORAGE_ACCOUNT_NAME}.dfs.core.windows.net/",
            mount_point=MOUNT_POINT,
            extra_configs={
                f"fs.azure.account.key.{STORAGE_ACCOUNT_NAME}.dfs.core.windows.net": storage_account_key
            }
        )
        print(f"Successfully mounted {STORAGE_ACCOUNT_NAME}/{CONTAINER_NAME} to {MOUNT_POINT}")
    except Exception as e:
        print(f"Error mounting storage: {e}")
else:
    print(f"Storage already mounted at {MOUNT_POINT}")

# List mounted storage contents
display(dbutils.fs.ls(MOUNT_POINT))

# COMMAND ----------

# MAGIC %md
# MAGIC ## Define Data Schema
# MAGIC 
# MAGIC Define the schema for NYC taxi data to ensure data quality and performance.

# COMMAND ----------

# NYC Taxi data schema
taxi_schema = StructType([
    StructField("VendorID", IntegerType(), True),
    StructField("tpep_pickup_datetime", TimestampType(), True),
    StructField("tpep_dropoff_datetime", TimestampType(), True),
    StructField("passenger_count", IntegerType(), True),
    StructField("trip_distance", DoubleType(), True),
    StructField("RatecodeID", IntegerType(), True),
    StructField("store_and_fwd_flag", StringType(), True),
    StructField("PULocationID", IntegerType(), True),
    StructField("DOLocationID", IntegerType(), True),
    StructField("payment_type", IntegerType(), True),
    StructField("fare_amount", DoubleType(), True),
    StructField("extra", DoubleType(), True),
    StructField("mta_tax", DoubleType(), True),
    StructField("tip_amount", DoubleType(), True),
    StructField("tolls_amount", DoubleType(), True),
    StructField("improvement_surcharge", DoubleType(), True),
    StructField("total_amount", DoubleType(), True),
    StructField("congestion_surcharge", DoubleType(), True)
])

print("Schema defined for NYC taxi data")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Data Ingestion
# MAGIC 
# MAGIC Load the raw data with proper error handling and validation.

# COMMAND ----------

# Data file path (using public NYC taxi data)
data_path = f"{MOUNT_POINT}/nyc_taxi_data.csv"

# Alternative: Use public dataset URL if local file not available
public_data_url = "https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2023-01.parquet"

try:
    # Try to read from mounted storage first
    df_raw = spark.read.format("csv") \
        .option("header", "true") \
        .option("timestampFormat", "yyyy-MM-dd HH:mm:ss") \
        .schema(taxi_schema) \
        .load(data_path)
    
    print(f"Successfully loaded data from {data_path}")
    
except Exception as e:
    print(f"Warning: Could not load from mounted storage: {e}")
    print("Loading from public dataset...")
    
    # Fall back to public dataset
    df_raw = spark.read.format("parquet").load(public_data_url)
    print(f"Successfully loaded data from public dataset")

# Display basic information about the dataset
print(f"Dataset contains {df_raw.count():,} records")
print(f"Dataset has {len(df_raw.columns)} columns")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Data Quality Checks
# MAGIC 
# MAGIC Implement comprehensive data quality validations.

# COMMAND ----------

def run_data_quality_checks(df):
    """
    Run comprehensive data quality checks on the taxi dataset
    """
    checks = []
    
    # Check 1: No null pickup or dropoff times
    null_times = df.filter(
        col("tpep_pickup_datetime").isNull() | 
        col("tpep_dropoff_datetime").isNull()
    ).count()
    checks.append(("Null pickup/dropoff times", null_times, null_times == 0))
    
    # Check 2: Valid trip duration (positive and reasonable)
    invalid_duration = df.filter(
        (col("tpep_dropoff_datetime") <= col("tpep_pickup_datetime")) |
        ((col("tpep_dropoff_datetime").cast("long") - col("tpep_pickup_datetime").cast("long")) > 86400)  # > 24 hours
    ).count()
    checks.append(("Invalid trip duration", invalid_duration, invalid_duration < df.count() * 0.01))
    
    # Check 3: Reasonable passenger count
    invalid_passenger_count = df.filter(
        (col("passenger_count") < 1) | (col("passenger_count") > 10)
    ).count()
    checks.append(("Invalid passenger count", invalid_passenger_count, invalid_passenger_count < df.count() * 0.05))
    
    # Check 4: Positive trip distance
    negative_distance = df.filter(col("trip_distance") <= 0).count()
    checks.append(("Negative trip distance", negative_distance, negative_distance < df.count() * 0.01))
    
    # Check 5: Reasonable fare amount
    invalid_fare = df.filter(
        (col("fare_amount") < 0) | (col("fare_amount") > 1000)
    ).count()
    checks.append(("Invalid fare amount", invalid_fare, invalid_fare < df.count() * 0.01))
    
    return checks

# Run data quality checks
quality_checks = run_data_quality_checks(df_raw)

print("Data Quality Check Results:")
print("-" * 60)
for check_name, issue_count, passed in quality_checks:
    status = "PASS" if passed else "FAIL"
    print(f"{check_name:.<40} {issue_count:>8} issues {status}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Data Cleaning and Transformation
# MAGIC 
# MAGIC Clean the data based on quality check results.

# COMMAND ----------

# Clean the data based on quality checks
df_cleaned = df_raw.filter(
    # Remove records with null pickup/dropoff times
    col("tpep_pickup_datetime").isNotNull() & 
    col("tpep_dropoff_datetime").isNotNull() &
    
    # Valid trip duration
    (col("tpep_dropoff_datetime") > col("tpep_pickup_datetime")) &
    ((col("tpep_dropoff_datetime").cast("long") - col("tpep_pickup_datetime").cast("long")) <= 86400) &
    
    # Reasonable passenger count
    (col("passenger_count") >= 1) & (col("passenger_count") <= 8) &
    
    # Positive trip distance
    (col("trip_distance") > 0) &
    
    # Reasonable fare amount
    (col("fare_amount") >= 0) & (col("fare_amount") <= 500)
)

# Add derived columns
df_enhanced = df_cleaned.withColumn(
    "trip_duration_minutes", 
    (col("tpep_dropoff_datetime").cast("long") - col("tpep_pickup_datetime").cast("long")) / 60
).withColumn(
    "pickup_hour",
    hour(col("tpep_pickup_datetime"))
).withColumn(
    "pickup_day_of_week",
    dayofweek(col("tpep_pickup_datetime"))
).withColumn(
    "trip_speed_mph",
    when(col("trip_duration_minutes") > 0, 
         col("trip_distance") / (col("trip_duration_minutes") / 60)
    ).otherwise(0)
)

print(f"Original records: {df_raw.count():,}")
print(f"Cleaned records: {df_cleaned.count():,}")
print(f"Records removed: {df_raw.count() - df_cleaned.count():,}")
print(f"Data quality: {(df_cleaned.count() / df_raw.count() * 100):.2f}%")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Save to Delta Lake
# MAGIC 
# MAGIC Save the cleaned data in Delta Lake format for ACID transactions and performance.

# COMMAND ----------

# Define Delta table path
delta_table_path = "/tmp/delta/nyc_taxi_data"

# Write to Delta Lake with partitioning for performance
df_enhanced.write \
    .format("delta") \
    .mode("overwrite") \
    .partitionBy("pickup_day_of_week") \
    .option("mergeSchema", "true") \
    .save(delta_table_path)

print(f"Successfully saved {df_enhanced.count():,} records to Delta Lake")
print(f"Delta table location: {delta_table_path}")

# Create a Delta table for SQL access
spark.sql(f"""
    CREATE TABLE IF NOT EXISTS nyc_taxi_data
    USING DELTA
    LOCATION '{delta_table_path}'
""")

print("Delta table 'nyc_taxi_data' created successfully")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Data Validation and Summary
# MAGIC 
# MAGIC Validate the saved data and provide summary statistics.

# COMMAND ----------

# Read back from Delta to validate
df_delta = spark.read.format("delta").load(delta_table_path)

# Verify record count matches
assert df_delta.count() == df_enhanced.count(), "Record count mismatch after Delta save"

# Display summary statistics
print("Summary Statistics:")
df_delta.select(
    "trip_distance",
    "fare_amount",
    "trip_duration_minutes",
    "trip_speed_mph"
).summary().show()

# Display sample data
print("Sample Data:")
df_delta.select(
    "tpep_pickup_datetime",
    "trip_distance",
    "fare_amount",
    "trip_duration_minutes",
    "pickup_hour"
).show(10)

# COMMAND ----------

# MAGIC %md
# MAGIC ## Next Steps
# MAGIC 
# MAGIC This notebook has successfully:
# MAGIC - Connected to Azure Storage securely
# MAGIC - Defined and enforced data schema
# MAGIC - Implemented comprehensive data quality checks
# MAGIC - Cleaned and transformed the data
# MAGIC - Saved data in Delta Lake format with partitioning
# MAGIC 
# MAGIC **Next steps:**
# MAGIC 1. Run the data analysis notebook (`02_data_analysis.py`)
# MAGIC 2. Explore advanced analytics and machine learning
# MAGIC 3. Set up automated data pipelines
# MAGIC 
# MAGIC **Best Practices Demonstrated:**
# MAGIC - Schema enforcement for data quality
# MAGIC - Comprehensive data validation
# MAGIC - Secure credential management with Key Vault
# MAGIC - Delta Lake for ACID transactions
# MAGIC - Proper error handling and logging