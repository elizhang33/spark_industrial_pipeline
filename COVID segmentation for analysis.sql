CREATE OR REPLACE TABLE `taxi_analytics.yellow_trips_covid`
PARTITION BY pickup_date
CLUSTER BY pickup_location_id, dropoff_location_id AS
SELECT
  *,
  CASE
    WHEN pickup_date < '2020-03-01' THEN 'pre_covid'
    WHEN pickup_date BETWEEN '2020-03-01' AND '2020-06-30'
      THEN 'covid_shock'
    WHEN pickup_date BETWEEN '2020-07-01' AND '2021-06-30'
      THEN 'covid_restrictions'
    ELSE 'recovery'
  END AS covid_phase
FROM `taxi_analytics.yellow_trips_clean_2018_2022`;
