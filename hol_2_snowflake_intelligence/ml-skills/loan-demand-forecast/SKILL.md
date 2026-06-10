---
name: loan-demand-forecast
description: Build a time-series forecast model to predict future loan application
  volumes using Snowflake ML FORECAST. Use when asked to forecast applications, predict
  demand, project future volumes, or anticipate lending pipeline capacity.
---

# Loan Demand Forecast

When the user asks to forecast loan application volume or predict future demand, build a Snowflake notebook with the following steps. Each step should be a separate cell in the notebook.

IMPORTANT:
- Always use fully qualified names for all objects: `BB_TRAINING.GOLD.<object_name>`
- All Python cells must include `from snowflake.snowpark.context import get_active_session`
- The first cell must set session context with USE DATABASE/SCHEMA/WAREHOUSE

## Step 0: Set Session Context

First cell in the notebook - sets the database, schema, and warehouse context:

```sql
USE ROLE ACCOUNTADMIN;
USE DATABASE BB_TRAINING;
USE SCHEMA GOLD;
USE WAREHOUSE BB_TRAINING_WH;
```

## Step 1: Prepare the Time Series

Create a clean monthly time series. The timestamp must be `TIMESTAMP_NTZ` and the value must be `FLOAT` - these are hard requirements for Snowflake ML FORECAST.

```sql
CREATE OR REPLACE TABLE BB_TRAINING.GOLD.FORECAST_INPUT AS
SELECT
    APPLICATION_MONTH::TIMESTAMP_NTZ AS MONTH,
    SUM(TOTAL_APPLICATIONS)::FLOAT AS TOTAL_APPLICATIONS
FROM BB_TRAINING.GOLD.GOLD_PORTFOLIO_SUMMARY
WHERE APPLICATION_MONTH IS NOT NULL
GROUP BY APPLICATION_MONTH
ORDER BY APPLICATION_MONTH;

SELECT * FROM BB_TRAINING.GOLD.FORECAST_INPUT ORDER BY MONTH;
```

## Step 2: Validate the Data

Add a validation cell that checks the data is suitable for forecasting. Training requires at least 12 rows.

```sql
SELECT
    COUNT(*) AS total_months,
    MIN(MONTH) AS earliest_month,
    MAX(MONTH) AS latest_month,
    CASE WHEN COUNT(*) >= 12 THEN 'PASS - enough data' ELSE 'WARNING - need at least 12 months' END AS data_check,
    CASE
        WHEN COUNT(*) = DATEDIFF('month', MIN(MONTH), MAX(MONTH)) + 1 THEN 'PASS - no gaps'
        ELSE 'WARNING - ' || (DATEDIFF('month', MIN(MONTH), MAX(MONTH)) + 1 - COUNT(*))::STRING || ' month(s) missing'
    END AS gap_check
FROM BB_TRAINING.GOLD.FORECAST_INPUT;
```

If either check shows a WARNING, inform the user and explain the impact on model quality.

## Step 3: Train the Forecast Model

Use Snowflake ML's native FORECAST. The input must be passed using the `TABLE()` wrapper. Always fully qualify the model name.

```sql
CREATE OR REPLACE SNOWFLAKE.ML.FORECAST BB_TRAINING.GOLD.APPLICATION_FORECAST(
    INPUT_DATA => TABLE(BB_TRAINING.GOLD.FORECAST_INPUT),
    TIMESTAMP_COLNAME => 'MONTH',
    TARGET_COLNAME => 'TOTAL_APPLICATIONS'
);
```

Tell the user: "The model has been trained. Snowflake ML automatically detected seasonality and trends in your data."

## Step 4: Generate Predictions

Forecast the next 6 months and save results. Use fully qualified model name.

```sql
CREATE OR REPLACE TABLE BB_TRAINING.GOLD.FORECAST_RESULTS AS
SELECT TS AS MONTH, FORECAST, LOWER_BOUND, UPPER_BOUND
FROM TABLE(BB_TRAINING.GOLD.APPLICATION_FORECAST!FORECAST(FORECASTING_PERIODS => 6));

-- Combine actuals + forecast for easy comparison
SELECT MONTH, TOTAL_APPLICATIONS AS VALUE, 'Actual' AS TYPE
FROM BB_TRAINING.GOLD.FORECAST_INPUT
UNION ALL
SELECT MONTH, FORECAST AS VALUE, 'Forecast' AS TYPE
FROM BB_TRAINING.GOLD.FORECAST_RESULTS
ORDER BY MONTH;
```

## Step 5: Visualize

In a Python cell, plot historical actuals and forecast together. Always include the import for `get_active_session`.

```python
from snowflake.snowpark.context import get_active_session
import matplotlib.pyplot as plt
import pandas as pd

session = get_active_session()

actuals = session.sql("SELECT MONTH, TOTAL_APPLICATIONS AS VALUE FROM BB_TRAINING.GOLD.FORECAST_INPUT ORDER BY MONTH").to_pandas()
forecast = session.sql("SELECT MONTH, FORECAST AS VALUE, LOWER_BOUND, UPPER_BOUND FROM BB_TRAINING.GOLD.FORECAST_RESULTS ORDER BY MONTH").to_pandas()

actuals['MONTH'] = pd.to_datetime(actuals['MONTH'])
forecast['MONTH'] = pd.to_datetime(forecast['MONTH'])

plt.figure(figsize=(12, 5))
plt.plot(actuals['MONTH'], actuals['VALUE'], marker='o', label='Historical', color='steelblue')
plt.plot(forecast['MONTH'], forecast['VALUE'], marker='s', linestyle='--', color='red', label='Forecast')
plt.fill_between(forecast['MONTH'], forecast['LOWER_BOUND'], forecast['UPPER_BOUND'], alpha=0.2, color='red', label='95% Prediction Interval')
plt.xlabel('Month')
plt.ylabel('Total Applications')
plt.title('Loan Application Volume - 6 Month Forecast')
plt.legend()
plt.grid(True, alpha=0.3)
plt.tight_layout()
plt.show()
```

## Step 6: Model Evaluation

Show evaluation metrics in a SQL cell, then add a Python cell that explains them in plain English.

SQL cell:
```sql
CALL BB_TRAINING.GOLD.APPLICATION_FORECAST!SHOW_EVALUATION_METRICS();
```

Then add a Python interpretation cell:
```python
from snowflake.snowpark.context import get_active_session
session = get_active_session()

metrics = session.sql("CALL BB_TRAINING.GOLD.APPLICATION_FORECAST!SHOW_EVALUATION_METRICS()").to_pandas()

print("=" * 60)
print("FORECAST MODEL EVALUATION")
print("=" * 60)
print()
for _, row in metrics.iterrows():
    metric = row.get('ERROR_METRIC', '').strip('"')
    value = row.get('METRIC_VALUE', 0)
    if metric == 'MAE':
        print(f"MAE (Mean Absolute Error): {value:.1f}")
        print(f"  → On average, the forecast is off by {value:.0f} applications per month")
    elif metric == 'MAPE':
        pct = value * 100
        print(f"\nMAPE (Mean Absolute % Error): {pct:.1f}%")
        quality = "Excellent" if pct < 10 else "Good" if pct < 25 else "Fair" if pct < 50 else "Weak"
        print(f"  → Quality rating: {quality}")
        print(f"  → Guideline: <10% Excellent, 10-25% Good, 25-50% Fair, >50% Weak")
    elif metric == 'MSE':
        print(f"\nMSE (Mean Squared Error): {value:.1f}")
        print(f"  → Penalizes large errors more heavily")

print()
print("Note: These metrics come from cross-validation on held-out historical data.")
print("They represent how well the model would have predicted periods it hadn't seen.")
```

Note: We are NOT calling EXPLAIN_FEATURE_IMPORTANCE() because we trained a single-variable forecast (timestamp + target only, no exogenous features). Feature importance only returns meaningful results when additional feature columns are included in training. For our use case, the model relies on internal time-series decomposition (trend + seasonality).

## Step 7: Summary Interpretation

Final Python cell that summarizes the forecast in plain English:

```python
from snowflake.snowpark.context import get_active_session
import pandas as pd
session = get_active_session()

forecast = session.sql("SELECT * FROM BB_TRAINING.GOLD.FORECAST_RESULTS ORDER BY MONTH").to_pandas()
actuals = session.sql("SELECT * FROM BB_TRAINING.GOLD.FORECAST_INPUT ORDER BY MONTH DESC LIMIT 3").to_pandas()

recent_avg = actuals['TOTAL_APPLICATIONS'].mean()
forecast_avg = forecast['FORECAST'].mean()
direction = "increasing" if forecast_avg > recent_avg else "decreasing" if forecast_avg < recent_avg else "stable"

print("=" * 60)
print("FORECAST SUMMARY")
print("=" * 60)
print(f"\nRecent average (last 3 months): {recent_avg:.0f} applications/month")
print(f"Forecast average (next 6 months): {forecast_avg:.0f} applications/month")
print(f"Trend: {direction} ({((forecast_avg/recent_avg - 1) * 100):+.1f}%)")
print(f"\nForecast by month:")
for _, row in forecast.iterrows():
    month_str = pd.to_datetime(row['MONTH']).strftime('%b %Y')
    print(f"  {month_str}: {row['FORECAST']:.0f} (range: {row['LOWER_BOUND']:.0f} - {row['UPPER_BOUND']:.0f})")
```
