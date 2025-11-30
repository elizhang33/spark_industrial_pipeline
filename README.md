# spark_industrial_pipeline
# NYC Taxi COVID Mobility Analytics with Spark, Dataproc, and BigQuery

## Overview

This project builds an end-to-end **cloud data engineering pipeline** using:

- **NYC TLC Yellow Taxi trip data (2018–2022)** from the BigQuery public datasets
- **Google Cloud BigQuery** as the data warehouse
- **Dataproc Spark Connect** for scalable Spark processing
- **Python / PySpark** for transformations and analytics
- **Matplotlib + scikit-learn** for visualization and ML
- Optional **Power BI / Tableau** dashboards for business-facing analytics

The main goal is to analyze **mobility and revenue patterns before, during, and after COVID-19** and to demonstrate production-style data engineering skills aligned with roles like **Data Engineer**.

---

## Architecture

**High-level flow:**

1. **Raw Source:**  
   `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_*`

2. **Data Cleaning & Feature Engineering (BigQuery + Spark):**
   - Filter invalid trips (distance, amount, timestamps, passenger counts)
   - Add `trip_duration_min`, `pickup_date`, `pickup_hour`, `pickup_dow`, etc.
   - Add `covid_phase` labels:
     - `pre_covid`
     - `covid_shock`
     - `covid_restrictions`
     - `recovery`

3. **Analytical Tables (Spark → BigQuery):**
   - `nyc_taxi_analytics.yellow_trips_covid` – cleaned, enriched trip table
   - `nyc_taxi_analytics.daily_stats` – daily metrics by COVID phase
   - (Optional) `nyc_taxi_analytics.hourly_stats`, `zone_daily_stats`

4. **Analytics & ML (Python):**
   - Visualizations (daily trips over time by phase, avg fares)
   - Demand forecasting model
   - Anomaly detection for unusual days

5. **BI & Dashboards:**
   - Connect Power BI / Tableau to `daily_stats` and `zone_daily_stats`
   - Build management dashboards

---

## Technologies

- **Google Cloud:**
  - BigQuery
  - Dataproc Spark Connect
  - GCS (staging bucket for Spark ↔ BigQuery)
- **Data Processing:**
  - PySpark (Spark DataFrame API)
  - Spark BigQuery Connector
- **Analytics & ML:**
  - Python (pandas, matplotlib)
  - scikit-learn (RandomForestRegressor, IsolationForest)
- **BI:**
  - Power BI Desktop
  - Tableau Desktop

---

## Data Sources

- **NYC TLC Yellow Taxi Trips** (2018–2022)  
  BigQuery public dataset:  
  `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_*`

- **Taxi Zone Geometry (optional for zone analysis)**  
  `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`

---

## Pipeline Steps

### 1. Create Cleaned & Enriched Table in BigQuery

SQL (run in BigQuery):

```sql
CREATE OR REPLACE TABLE `YOUR_PROJECT.nyc_taxi_analytics.yellow_trips_clean_2018_2022`
PARTITION BY DATE(pickup_datetime)
CLUSTER BY pickup_location_id, dropoff_location_id AS
SELECT
  vendor_id,
  pickup_datetime,
  dropoff_datetime,
  TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, MINUTE) AS trip_duration_min,
  passenger_count,
  trip_distance,
  rate_code,
  store_and_fwd_flag,
  payment_type,
  fare_amount,
  extra,
  mta_tax,
  tip_amount,
  tolls_amount,
  imp_surcharge,
  total_amount,
  pickup_location_id,
  dropoff_location_id,
  data_file_year,
  data_file_month,
  EXTRACT(DATE FROM pickup_datetime) AS pickup_date,
  EXTRACT(YEAR FROM pickup_datetime) AS pickup_year,
  EXTRACT(MONTH FROM pickup_datetime) AS pickup_month,
  EXTRACT(DAYOFWEEK FROM pickup_datetime) AS pickup_dow,
  EXTRACT(HOUR FROM pickup_datetime) AS pickup_hour
FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_*`
WHERE
  pickup_datetime BETWEEN '2018-01-01' AND '2022-12-31'
  AND trip_distance > 0 AND trip_distance < 200
  AND total_amount > 0 AND total_amount < 1000
  AND passenger_count BETWEEN 1 AND 6
  AND dropoff_datetime > pickup_datetime;
