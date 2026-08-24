# Derive Insights from BigQuery Data [GSP787](https://www.skills.google/course_templates/623/labs/629091)
<blockquote style="background-color: #1e1e2e; color: #cdd6f4; border-left: 5px solid #89b4fa; border-radius: 8px; padding: 1.2em; font-family: sans-serif; font-size: 14px; line-height: 1.6; box-shadow: 0 4px 6px rgba(0,0,0,0.3);">
  <div style="color: #89b4fa; font-weight: bold; font-size: 16px; margin-bottom: 8px;">
    ℹ️ DISCLAIMER
  </div>
  <strong style="color: #f9e2af;">Educational Purpose Only:</strong> This script and guide are provided for educational purposes to help you understand lab services and boost your career. Please review the script before use to familiarize yourself with Google Cloud services.
  <br><br>
  <strong style="color: #f9e2af;">Terms Compliance:</strong> Always ensure compliance with Qwiklabs' terms of service and YouTube's community guidelines. The goal is to enhance your learning experience — not to circumvent it.
</blockquote>


# Task 1. Total confirmed cases
```
SELECT
  SUM(cumulative_confirmed) AS total_cases_worldwide
FROM
  `bigquery-public-data.covid19_open_data.covid19_open_data`
WHERE
  date = '2020-05-15';
```
# Task 2. Worst affected areas
```
SELECT
  COUNT(*) AS count_of_states
FROM (
  SELECT
    subregion1_name,
    SUM(cumulative_deceased) AS total_deaths
  FROM
    `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE
    country_name = 'United States of America'
    AND date = '2020-05-15'
    AND subregion1_name IS NOT NULL
  GROUP BY
    subregion1_name
  HAVING
    SUM(cumulative_deceased) > 250
);
```
# Task 3. Identify hotspots
```
SELECT
  subregion1_name AS state,
  SUM(cumulative_confirmed) AS total_confirmed_cases
FROM
  `bigquery-public-data.covid19_open_data.covid19_open_data`
WHERE
  country_name = 'United States of America'
  AND date = '2020-05-15'
  AND subregion1_name IS NOT NULL
GROUP BY
  subregion1_name
HAVING
  total_confirmed_cases > 1500
ORDER BY
  total_confirmed_cases DESC;
```
# Task 4. Fatality ratio
```
SELECT
  SUM(cumulative_confirmed) AS total_confirmed_cases,
  SUM(cumulative_deceased) AS total_deaths,
  (SUM(cumulative_deceased) / SUM(cumulative_confirmed)) * 100 AS case_fatality_ratio
FROM
  `bigquery-public-data.covid19_open_data.covid19_open_data`
WHERE
  country_name = 'Italy'
  AND date BETWEEN '2020-05-01' AND '2020-05-31'; 
# Task 5. Identify a specific day

SELECT
  date
FROM (
  SELECT
    date,
    SUM(cumulative_deceased) AS total_deaths
  FROM
    `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE
    country_name = 'Italy'
  GROUP BY
    date
)
WHERE
  total_deaths > 10000
ORDER BY
  date ASC
LIMIT 1;
```
# Task 6. Find days with zero net new cases
```
WITH india_cases_by_date AS (
  SELECT
    date,
    SUM(cumulative_confirmed) AS cases
  FROM
    `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE
    country_name = 'India'
    AND date BETWEEN '2020-02-21' AND '2020-03-12'
  GROUP BY
    date
  ORDER BY
    date ASC
),

india_previous_day_comparison AS (
  SELECT
    date,
    cases,
    LAG(cases) OVER (ORDER BY date) AS previous_day,
    cases - LAG(cases) OVER (ORDER BY date) AS net_new_cases
  FROM
    india_cases_by_date
)

SELECT
  COUNT(*) AS days_with_zero_net_new_cases
FROM
  india_previous_day_comparison
WHERE
  net_new_cases = 0;
```
# Task 7. Doubling rate
```
WITH us_cases_by_date AS (
  SELECT
    date,
    SUM(cumulative_confirmed) AS cases
  FROM
    `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE
    country_name = 'United States of America'
    AND date BETWEEN '2020-03-22' AND '2020-04-20'
  GROUP BY
    date
),

us_previous_day_comparison AS (
  SELECT
    date,
    cases,
    LAG(cases) OVER (ORDER BY date) AS previous_day
  FROM
    us_cases_by_date
)

SELECT
  date AS Date,
  cases AS Confirmed_Cases_On_Day,
  previous_day AS Confirmed_Cases_Previous_Day,
  ((cases - previous_day) / previous_day) * 100
    AS Percentage_Increase_In_Cases
FROM
  us_previous_day_comparison
WHERE
  ((cases - previous_day) / previous_day) * 100 > 20
ORDER BY
  date;
```
# Task 8. Recovery rate
```
WITH country_data AS (
  SELECT
    country_name AS country,
    SUM(cumulative_recovered) AS recovered_cases,
    SUM(cumulative_confirmed) AS confirmed_cases
  FROM
    `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE
    date = '2020-05-10'
  GROUP BY
    country_name
)

SELECT
  country,
  recovered_cases,
  confirmed_cases,
  (recovered_cases / confirmed_cases) * 100 AS recovery_rate
FROM
  country_data
WHERE
  confirmed_cases > 50000
ORDER BY
  recovery_rate DESC
LIMIT 20;
```
# Task 9. CDGR - Cumulative daily growth rate
```
WITH france_cases AS (
  SELECT
    date,
    SUM(cumulative_confirmed) AS total_cases
  FROM
    `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE
    country_name = 'France'
    AND date IN ('2020-01-24', '2020-05-15')
  GROUP BY
    date
  ORDER BY
    date
),

summary AS (
  SELECT
    total_cases AS first_day_cases,
    LEAD(total_cases) OVER (ORDER BY date) AS last_day_cases,
    DATE_DIFF(
      LEAD(date) OVER (ORDER BY date),
      date,
      DAY
    ) AS days_diff
  FROM
    france_cases
  LIMIT 1
)

SELECT
  first_day_cases,
  last_day_cases,
  days_diff,
  POW(
    (last_day_cases / first_day_cases),
    (1 / days_diff)
  ) - 1 AS cdgr
FROM
  summary;
```
# Task 10. Create a Data Studio report
```
SELECT
  date,
  SUM(cumulative_confirmed) AS country_cases,
  SUM(cumulative_deceased) AS country_deaths
FROM
  `bigquery-public-data.covid19_open_data.covid19_open_data`
WHERE
  country_name = 'United States of America'
  AND date BETWEEN '2020-03-19' AND '2020-04-29'
GROUP BY
  date
ORDER BY
  date;
```
