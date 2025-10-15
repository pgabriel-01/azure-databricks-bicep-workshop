# Databricks notebook source
# MAGIC %md
# MAGIC # NYC Taxi Data Analysis - Advanced Analytics
# MAGIC 
# MAGIC This notebook demonstrates advanced analytics and machine learning on taxi data using Azure Databricks.
# MAGIC 
# MAGIC ## Learning Objectives
# MAGIC - Perform exploratory data analysis
# MAGIC - Create visualizations and insights
# MAGIC - Build predictive models
# MAGIC - Implement MLflow for experiment tracking
# MAGIC 
# MAGIC ## Prerequisites
# MAGIC - Completed data ingestion notebook (`01_data_ingestion.py`)
# MAGIC - Delta table `nyc_taxi_data` available

# COMMAND ----------

# MAGIC %md
# MAGIC ## Setup and Data Loading

# COMMAND ----------

# Import required libraries
from pyspark.sql.functions import *
from pyspark.sql.types import *
import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd
import numpy as np

# MLlib imports
from pyspark.ml.feature import VectorAssembler, StandardScaler
from pyspark.ml.regression import LinearRegression, RandomForestRegressor
from pyspark.ml.evaluation import RegressionEvaluator
from pyspark.ml import Pipeline
from pyspark.ml.tuning import CrossValidator, ParamGridBuilder

# MLflow for experiment tracking
import mlflow
import mlflow.spark

print("Libraries imported successfully")

# COMMAND ----------

# Load the Delta table
df = spark.read.format("delta").table("nyc_taxi_data")

print(f"Loaded {df.count():,} records from Delta table")
print(f"Data covers period: {df.agg(min('tpep_pickup_datetime')).collect()[0][0]} to {df.agg(max('tpep_pickup_datetime')).collect()[0][0]}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Exploratory Data Analysis

# COMMAND ----------

# Basic statistics
print("Dataset Summary:")
df.select(
    "trip_distance",
    "fare_amount", 
    "trip_duration_minutes",
    "trip_speed_mph",
    "passenger_count"
).summary().show()

# COMMAND ----------

# Trip patterns by hour
hourly_trips = df.groupBy("pickup_hour") \
    .agg(
        count("*").alias("trip_count"),
        avg("fare_amount").alias("avg_fare"),
        avg("trip_distance").alias("avg_distance"),
        avg("trip_duration_minutes").alias("avg_duration")
    ) \
    .orderBy("pickup_hour")

print("Trip Patterns by Hour:")
hourly_trips.show(24)

# COMMAND ----------

# Day of week patterns
dow_trips = df.groupBy("pickup_day_of_week") \
    .agg(
        count("*").alias("trip_count"),
        avg("fare_amount").alias("avg_fare"),
        avg("trip_distance").alias("avg_distance")
    ) \
    .withColumn("day_name", 
        when(col("pickup_day_of_week") == 1, "Sunday")
        .when(col("pickup_day_of_week") == 2, "Monday")
        .when(col("pickup_day_of_week") == 3, "Tuesday")
        .when(col("pickup_day_of_week") == 4, "Wednesday")
        .when(col("pickup_day_of_week") == 5, "Thursday")
        .when(col("pickup_day_of_week") == 6, "Friday")
        .when(col("pickup_day_of_week") == 7, "Saturday")
    ) \
    .orderBy("pickup_day_of_week")

print("Trip Patterns by Day of Week:")
dow_trips.show()

# COMMAND ----------

# MAGIC %md
# MAGIC ## Data Visualization
# MAGIC 
# MAGIC Create visualizations to understand data patterns.

# COMMAND ----------

# Convert to Pandas for visualization (sample for performance)
sample_size = 10000
df_sample = df.sample(fraction=sample_size/df.count(), seed=42).toPandas()

print(f"Using sample of {len(df_sample):,} records for visualization")

# COMMAND ----------

# Fare amount distribution
plt.figure(figsize=(12, 8))

plt.subplot(2, 2, 1)
plt.hist(df_sample['fare_amount'], bins=50, alpha=0.7, color='blue')
plt.title('Fare Amount Distribution')
plt.xlabel('Fare Amount ($)')
plt.ylabel('Frequency')

plt.subplot(2, 2, 2)
plt.hist(df_sample['trip_distance'], bins=50, alpha=0.7, color='green')
plt.title('Trip Distance Distribution')
plt.xlabel('Distance (miles)')
plt.ylabel('Frequency')

plt.subplot(2, 2, 3)
plt.hist(df_sample['trip_duration_minutes'], bins=50, alpha=0.7, color='orange')
plt.title('Trip Duration Distribution')
plt.xlabel('Duration (minutes)')
plt.ylabel('Frequency')

plt.subplot(2, 2, 4)
plt.scatter(df_sample['trip_distance'], df_sample['fare_amount'], alpha=0.5, s=1)
plt.title('Distance vs Fare Amount')
plt.xlabel('Distance (miles)')
plt.ylabel('Fare Amount ($)')

plt.tight_layout()
plt.show()

# COMMAND ----------

# Time-based patterns
hourly_data = df.groupBy("pickup_hour").count().toPandas()
dow_data = df.groupBy("pickup_day_of_week").count().toPandas()

plt.figure(figsize=(15, 5))

plt.subplot(1, 2, 1)
plt.plot(hourly_data['pickup_hour'], hourly_data['count'], marker='o')
plt.title('Trip Count by Hour of Day')
plt.xlabel('Hour')
plt.ylabel('Number of Trips')
plt.grid(True)

plt.subplot(1, 2, 2)
plt.bar(dow_data['pickup_day_of_week'], dow_data['count'])
plt.title('Trip Count by Day of Week')
plt.xlabel('Day of Week (1=Sunday)')
plt.ylabel('Number of Trips')
plt.grid(True)

plt.tight_layout()
plt.show()

# COMMAND ----------

# MAGIC %md
# MAGIC ## Feature Engineering for Machine Learning

# COMMAND ----------

# Prepare features for modeling
ml_df = df.select(
    "trip_distance",
    "passenger_count", 
    "pickup_hour",
    "pickup_day_of_week",
    "trip_duration_minutes",
    "PULocationID",
    "DOLocationID",
    "fare_amount"  # Target variable
).filter(
    # Remove outliers for better model performance
    (col("fare_amount") > 0) & (col("fare_amount") < 100) &
    (col("trip_distance") > 0) & (col("trip_distance") < 50) &
    (col("trip_duration_minutes") > 1) & (col("trip_duration_minutes") < 120)
)

# Add derived features
ml_df = ml_df.withColumn("is_weekend", 
    when((col("pickup_day_of_week") == 1) | (col("pickup_day_of_week") == 7), 1).otherwise(0)
).withColumn("is_rush_hour",
    when((col("pickup_hour").between(7, 9)) | (col("pickup_hour").between(17, 19)), 1).otherwise(0)
).withColumn("trip_speed_mph",
    col("trip_distance") / (col("trip_duration_minutes") / 60)
)

print(f"ML dataset prepared with {ml_df.count():,} records")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Machine Learning Model Development

# COMMAND ----------

# Start MLflow experiment
mlflow.set_experiment("/Shared/workshop/taxi_fare_prediction")

# Feature columns for ML
feature_cols = [
    "trip_distance",
    "passenger_count",
    "pickup_hour", 
    "pickup_day_of_week",
    "trip_duration_minutes",
    "is_weekend",
    "is_rush_hour",
    "trip_speed_mph"
]

# Create feature vector
assembler = VectorAssembler(inputCols=feature_cols, outputCol="features")
scaler = StandardScaler(inputCol="features", outputCol="scaledFeatures")

# Split data
train_df, test_df = ml_df.randomSplit([0.8, 0.2], seed=42)

print(f"Training set: {train_df.count():,} records")
print(f"Test set: {test_df.count():,} records")

# COMMAND ----------

# MAGIC %md
# MAGIC ### Linear Regression Model

# COMMAND ----------

with mlflow.start_run(run_name="linear_regression"):
    # Create pipeline
    lr = LinearRegression(featuresCol="scaledFeatures", labelCol="fare_amount")
    pipeline = Pipeline(stages=[assembler, scaler, lr])
    
    # Train model
    lr_model = pipeline.fit(train_df)
    
    # Make predictions
    lr_predictions = lr_model.transform(test_df)
    
    # Evaluate model
    evaluator = RegressionEvaluator(labelCol="fare_amount", predictionCol="prediction")
    
    rmse = evaluator.evaluate(lr_predictions, {evaluator.metricName: "rmse"})
    r2 = evaluator.evaluate(lr_predictions, {evaluator.metricName: "r2"})
    mae = evaluator.evaluate(lr_predictions, {evaluator.metricName: "mae"})
    
    # Log metrics
    mlflow.log_metric("rmse", rmse)
    mlflow.log_metric("r2", r2)
    mlflow.log_metric("mae", mae)
    
    # Log model
    mlflow.spark.log_model(lr_model, "linear_regression_model")
    
    print("Linear Regression Results:")
    print(f"   RMSE: {rmse:.3f}")
    print(f"   R²: {r2:.3f}")
    print(f"   MAE: {mae:.3f}")

# COMMAND ----------

# MAGIC %md
# MAGIC ### Random Forest Model

# COMMAND ----------

with mlflow.start_run(run_name="random_forest"):
    # Create Random Forest pipeline
    rf = RandomForestRegressor(featuresCol="scaledFeatures", labelCol="fare_amount", numTrees=50)
    rf_pipeline = Pipeline(stages=[assembler, scaler, rf])
    
    # Train model
    rf_model = rf_pipeline.fit(train_df)
    
    # Make predictions
    rf_predictions = rf_model.transform(test_df)
    
    # Evaluate model
    rf_rmse = evaluator.evaluate(rf_predictions, {evaluator.metricName: "rmse"})
    rf_r2 = evaluator.evaluate(rf_predictions, {evaluator.metricName: "r2"})
    rf_mae = evaluator.evaluate(rf_predictions, {evaluator.metricName: "mae"})
    
    # Log metrics
    mlflow.log_metric("rmse", rf_rmse)
    mlflow.log_metric("r2", rf_r2)
    mlflow.log_metric("mae", rf_mae)
    
    # Log model
    mlflow.spark.log_model(rf_model, "random_forest_model")
    
    print("Random Forest Results:")
    print(f"   RMSE: {rf_rmse:.3f}")
    print(f"   R²: {rf_r2:.3f}")
    print(f"   MAE: {rf_mae:.3f}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Model Comparison and Feature Importance

# COMMAND ----------

# Compare model performance
print("Model Comparison:")
print("-" * 50)
print(f"Linear Regression - RMSE: {rmse:.3f}, R²: {r2:.3f}")
print(f"Random Forest     - RMSE: {rf_rmse:.3f}, R²: {rf_r2:.3f}")

if rf_rmse < rmse:
    print("Random Forest performs better!")
    best_model = rf_model
    best_predictions = rf_predictions
else:
    print("Linear Regression performs better!")
    best_model = lr_model
    best_predictions = lr_predictions

# COMMAND ----------

# Feature importance (for Random Forest)
if rf_rmse < rmse:
    feature_importance = rf_model.stages[-1].featureImportances.toArray()
    feature_importance_df = pd.DataFrame({
        'feature': feature_cols,
        'importance': feature_importance
    }).sort_values('importance', ascending=False)
    
    print("Feature Importance (Random Forest):")
    print(feature_importance_df)
    
    # Plot feature importance
    plt.figure(figsize=(10, 6))
    plt.barh(feature_importance_df['feature'], feature_importance_df['importance'])
    plt.title('Feature Importance - Random Forest')
    plt.xlabel('Importance')
    plt.gca().invert_yaxis()
    plt.tight_layout()
    plt.show()

# COMMAND ----------

# MAGIC %md
# MAGIC ## Model Validation and Business Insights

# COMMAND ----------

# Prediction vs Actual analysis
pred_sample = best_predictions.sample(0.01).toPandas()

plt.figure(figsize=(12, 5))

plt.subplot(1, 2, 1)
plt.scatter(pred_sample['fare_amount'], pred_sample['prediction'], alpha=0.5)
plt.plot([pred_sample['fare_amount'].min(), pred_sample['fare_amount'].max()], 
         [pred_sample['fare_amount'].min(), pred_sample['fare_amount'].max()], 'r--')
plt.xlabel('Actual Fare')
plt.ylabel('Predicted Fare')
plt.title('Predicted vs Actual Fare')

plt.subplot(1, 2, 2)
residuals = pred_sample['fare_amount'] - pred_sample['prediction']
plt.hist(residuals, bins=50, alpha=0.7)
plt.xlabel('Residuals (Actual - Predicted)')
plt.ylabel('Frequency')
plt.title('Residual Distribution')

plt.tight_layout()
plt.show()

# COMMAND ----------

# Business insights
print("Business Insights:")
print("-" * 50)

# Average fare by hour
hourly_revenue = df.groupBy("pickup_hour") \
    .agg(
        avg("fare_amount").alias("avg_fare"),
        count("*").alias("trip_count"),
        (avg("fare_amount") * count("*")).alias("total_revenue")
    ) \
    .orderBy(desc("total_revenue"))

print("Top Revenue Hours:")
hourly_revenue.show(5)

# Peak demand times
print("Peak demand insights:")
peak_hours = df.groupBy("pickup_hour").count().orderBy(desc("count")).take(3)
for i, row in enumerate(peak_hours):
    print(f"   {i+1}. Hour {row['pickup_hour']:02d}:00 - {row['count']:,} trips")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Summary and Recommendations
# MAGIC 
# MAGIC ### Key Findings:
# MAGIC 1. **Model Performance**: Best model achieved R² of {best_r2:.3f}
# MAGIC 2. **Key Predictors**: Trip distance and duration are primary fare drivers
# MAGIC 3. **Peak Hours**: Rush hours and late night show highest demand
# MAGIC 4. **Revenue Optimization**: Focus on high-demand, high-fare time periods
# MAGIC 
# MAGIC ### Recommendations:
# MAGIC 1. **Dynamic Pricing**: Implement surge pricing during peak hours
# MAGIC 2. **Driver Allocation**: Position drivers in high-demand areas
# MAGIC 3. **Route Optimization**: Use trip duration predictions for better routing
# MAGIC 4. **Demand Forecasting**: Deploy model for real-time fare estimation
# MAGIC 
# MAGIC ### Next Steps:
# MAGIC 1. Deploy model to production using MLflow
# MAGIC 2. Implement real-time scoring pipeline
# MAGIC 3. Set up model monitoring and retraining
# MAGIC 4. A/B test dynamic pricing strategies