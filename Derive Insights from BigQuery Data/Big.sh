#!/bin/bash

# ============================================================
# 🚀 BIGQUERY COVID-19 ANALYSIS - ALL 10 TASKS
# ============================================================

# ---------- COLORS ----------
GREEN="\033[1;32m"
CYAN="\033[1;36m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
WHITE="\033[1;37m"
RESET="\033[0m"

# ---------- HEADER ----------
clear
echo -e "${CYAN}"
echo "============================================================"
echo "        🚀 BIGQUERY COVID-19 DATA ANALYSIS"
echo "============================================================"
echo -e "${RESET}"

# ---------- CHECK BQ ----------
if ! command -v bq &> /dev/null
then
    echo -e "${RED}❌ bq CLI is not installed.${RESET}"
    exit 1
fi

echo -e "${GREEN}✅ BigQuery CLI detected.${RESET}"

# ============================================================
# TASK 1
# ============================================================

echo -e "\n${YELLOW}▶ TASK 1: Total Confirmed Cases${RESET}"

bq query --use_legacy_sql=false '
SELECT
  SUM(cumulative_confirmed) AS total_cases_worldwide
FROM
  `bigquery-public-data.covid19_open_data.covid19_open_data`
WHERE
  date = "2020-05-15";
'

# ============================================================
# TASK 2
# ============================================================

echo -e "\n${YELLOW}▶ TASK 2: Worst Affected Areas${RESET}"

bq query --use_legacy_sql=false '
SELECT
  COUNT(*) AS count_of_states
FROM (
  SELECT
    subregion1_name,
    SUM(cumulative_deceased) AS total_deaths
  FROM
    `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE
    country_name = "United States of America"
    AND date = "2020-05-15"
    AND subregion1_name IS NOT NULL
  GROUP BY
    subregion1_name
  HAVING
    SUM(cumulative_deceased) > 250
);
'

# ============================================================
# TASK 3
# ============================================================

echo -e "\n${YELLOW}▶ TASK 3: Identify Hotspots${RESET}"

bq query --use_legacy_sql=false '
SELECT
  subregion1_name AS state,
  SUM(cumulative_confirmed) AS total_confirmed_cases
FROM
  `bigquery-public-data.covid19_open_data.covid19_open_data`
WHERE
  country_name = "United States of America"
  AND date = "2020-05-15"
  AND subregion1_name IS NOT NULL
GROUP BY
  subregion1_name
HAVING
  total_confirmed_cases > 1500
ORDER BY
  total_confirmed_cases DESC;
'

# ============================================================
# TASK 4
# ============================================================

echo -e "\n${YELLOW}▶ TASK 4: Fatality Ratio${RESET}"

bq query --use_legacy_sql=false '
SELECT
  SUM(cumulative_confirmed) AS total_confirmed_cases,
  SUM(cumulative_deceased) AS total_deaths,
  (SUM(cumulative_deceased) / SUM(cumulative_confirmed)) * 100
    AS case_fatality_ratio
FROM
  `bigquery-public-data.covid19_open_data.covid19_open_data`
WHERE
  country_name = "Italy"
  AND date BETWEEN "2020-05-01" AND "2020-05-31";
'

# ============================================================
# TASK 5
# ============================================================

echo -e "\n${YELLOW}▶ TASK 5: Identify Specific Day${RESET}"

bq query --use_legacy_sql=false '
SELECT
  date
FROM (
  SELECT
    date,
    SUM(cumulative_deceased) AS total_deaths
  FROM
    `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE
    country_name = "Italy"
  GROUP BY
    date
)
WHERE
  total_deaths > 10000
ORDER BY
  date ASC
LIMIT 1;
'

# ============================================================
# TASK 6
# ============================================================

echo -e "\n${YELLOW}▶ TASK 6: Days With Zero Net New Cases${RESET}"

bq query --use_legacy_sql=false '
WITH india_cases_by_date AS (
  SELECT
    date,
    SUM(cumulative_confirmed) AS cases
  FROM
    `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE
    country_name = "India"
    AND date BETWEEN "2020-02-21" AND "2020-03-12"
  GROUP BY
    date
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
'

# ============================================================
# TASK 7
# ============================================================

echo -e "\n${YELLOW}▶ TASK 7: Doubling Rate${RESET}"

bq query --use_legacy_sql=false '
WITH us_cases_by_date AS (
  SELECT
    date,
    SUM(cumulative_confirmed) AS cases
  FROM
    `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE
    country_name = "United States of America"
    AND date BETWEEN "2020-03-22" AND "2020-04-20"
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
'

# ============================================================
# TASK 8
# ============================================================

echo -e "\n${YELLOW}▶ TASK 8: Recovery Rate${RESET}"

bq query --use_legacy_sql=false '
WITH country_data AS (
  SELECT
    country_name AS country,
    SUM(cumulative_recovered) AS recovered_cases,
    SUM(cumulative_confirmed) AS confirmed_cases
  FROM
    `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE
    date = "2020-05-10"
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
'

# ============================================================
# TASK 9
# ============================================================

echo -e "\n${YELLOW}▶ TASK 9: CDGR - Cumulative Daily Growth Rate${RESET}"

bq query --use_legacy_sql=false '
WITH france_cases AS (
  SELECT
    date,
    SUM(cumulative_confirmed) AS total_cases
  FROM
    `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE
    country_name = "France"
    AND date IN ("2020-01-24", "2020-05-15")
  GROUP BY
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
'

# ============================================================
# TASK 10
# ============================================================

echo -e "\n${YELLOW}▶ TASK 10: Data Studio / Looker Studio Data${RESET}"

bq query --use_legacy_sql=false '
SELECT
  date,
  SUM(cumulative_confirmed) AS country_cases,
  SUM(cumulative_deceased) AS country_deaths
FROM
  `bigquery-public-data.covid19_open_data.covid19_open_data`
WHERE
  country_name = "United States of America"
  AND date BETWEEN "2020-03-19" AND "2020-04-29"
GROUP BY
  date
ORDER BY
  date;
'

# ============================================================
# COMPLETE
# ============================================================

echo -e "\n${GREEN}"
echo "============================================================"
echo "              ✅ ALL 10 TASKS COMPLETED"
echo "============================================================"
echo -e "${RESET}"
