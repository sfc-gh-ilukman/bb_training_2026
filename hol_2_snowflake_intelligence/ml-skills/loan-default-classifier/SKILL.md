---
name: loan-default-classifier
description: Build a classification model to predict which loans will default using
  only features available at approval time. Use when asked to predict defaults, build
  a risk model, classify loans, or identify which loans will have late payments.
---

# Loan Default Classifier

When the user asks to predict loan defaults or build a risk classification model, build a Snowflake notebook with the following steps. Each step should be a separate cell in the notebook.

IMPORTANT:
- Always use fully qualified names for all objects: `BB_TRAINING.GOLD.<object_name>`
- All Python cells must include `from snowflake.snowpark.context import get_active_session`
- The first cell must set session context with USE DATABASE/SCHEMA/WAREHOUSE
- Do NOT include APPLICATION_ID or any identifier columns as features - they are not predictive

## Step 0: Set Session Context

First cell in the notebook:

```sql
USE ROLE ACCOUNTADMIN;
USE DATABASE BB_TRAINING;
USE SCHEMA GOLD;
USE WAREHOUSE BB_TRAINING_WH;
```

## Step 1: Build Training Data from Silver Tables

The critical ML concept: features come from application-time data (Silver loan applications), the target comes from transaction outcomes (Silver transactions). We join them but only keep features known at the point of loan approval.

```sql
CREATE OR REPLACE TABLE BB_TRAINING.GOLD.ML_DEFAULT_TRAINING AS
WITH loan_outcomes AS (
    SELECT
        LOAN_ID,
        1 AS IS_DEFAULT
    FROM BB_TRAINING.SILVER.SILVER_TRANSACTIONS
    WHERE TRANSACTION_TYPE = 'Late Fee'
    GROUP BY LOAN_ID
)
SELECT
    a.LOAN_AMOUNT,
    a.LOAN_TERM_MONTHS,
    a.INTEREST_RATE,
    a.CREDIT_SCORE,
    a.RISK_TIER,
    a.LOAN_PRODUCT,
    COALESCE(o.IS_DEFAULT, 0) AS IS_DEFAULT
FROM BB_TRAINING.SILVER.SILVER_LOAN_APPLICATIONS a
LEFT JOIN loan_outcomes o
    ON a.APPLICATION_ID = o.LOAN_ID
WHERE a.STATUS = 'Approved'
  AND a.CREDIT_SCORE IS NOT NULL
  AND a.RISK_TIER IS NOT NULL;
```

Explain to the user: "We're using 6 features available at approval time (loan amount, term, interest rate, credit score, risk tier, product type) to predict whether the loan will eventually have late payments. APPLICATION_ID is excluded because identifiers are not predictive features."

## Step 2: Validate Training Data

Check class balance and row count. Classification needs sufficient examples of both classes.

```sql
SELECT
    IS_DEFAULT,
    COUNT(*) AS COUNT,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS PERCENTAGE
FROM BB_TRAINING.GOLD.ML_DEFAULT_TRAINING
GROUP BY IS_DEFAULT;

SELECT
    COUNT(*) AS total_rows,
    CASE WHEN COUNT(*) >= 100 THEN 'PASS - sufficient data' ELSE 'WARNING - very small dataset' END AS data_check,
    CASE WHEN MIN(cnt) >= 10 THEN 'PASS - both classes represented'
         ELSE 'WARNING - severe class imbalance' END AS balance_check
FROM (SELECT IS_DEFAULT, COUNT(*) AS cnt FROM BB_TRAINING.GOLD.ML_DEFAULT_TRAINING GROUP BY IS_DEFAULT);
```

If the class balance is heavily skewed (e.g., 95%/5%), note this to the user: "The classes are imbalanced. The model may struggle to detect the minority class. In production, you'd consider oversampling or adjusting class weights."

## Step 3: Train the Model

Use `SYSTEM$REFERENCE` to pass the training table. Fully qualify the model name.

```sql
CREATE OR REPLACE SNOWFLAKE.ML.CLASSIFICATION BB_TRAINING.GOLD.LOAN_DEFAULT_MODEL(
    INPUT_DATA => SYSTEM$REFERENCE('TABLE', 'BB_TRAINING.GOLD.ML_DEFAULT_TRAINING'),
    TARGET_COLNAME => 'IS_DEFAULT'
);
```

Tell the user: "Model trained. Snowflake ML automatically handled:
- Train/test split for evaluation
- Feature encoding for categorical columns (RISK_TIER, LOAN_PRODUCT)
- Hyperparameter tuning
- Algorithm selection (ensemble of methods)"

## Step 4: Evaluate Model Performance

SQL cell for metrics:
```sql
CALL BB_TRAINING.GOLD.LOAN_DEFAULT_MODEL!SHOW_EVALUATION_METRICS();
```

Then a Python cell to interpret:
```python
from snowflake.snowpark.context import get_active_session
session = get_active_session()

metrics = session.sql("CALL BB_TRAINING.GOLD.LOAN_DEFAULT_MODEL!SHOW_EVALUATION_METRICS()").to_pandas()

print("=" * 60)
print("CLASSIFICATION MODEL EVALUATION")
print("=" * 60)
print()
for _, row in metrics.iterrows():
    metric = row.get('METRIC', row.get('ERROR_METRIC', ''))
    value = row.get('VALUE', row.get('METRIC_VALUE', 0))
    if 'accuracy' in str(metric).lower():
        print(f"Accuracy: {float(value)*100:.1f}%")
        print(f"  → {float(value)*100:.0f} out of 100 predictions are correct")
    elif 'precision' in str(metric).lower():
        print(f"Precision: {float(value)*100:.1f}%")
        print(f"  → When the model says 'default', how often is it right?")
    elif 'recall' in str(metric).lower():
        print(f"Recall: {float(value)*100:.1f}%")
        print(f"  → Of all actual defaults, how many did the model catch?")
    elif 'f1' in str(metric).lower():
        print(f"F1 Score: {float(value)*100:.1f}%")
        print(f"  → Balanced measure of precision and recall")
    elif 'auc' in str(metric).lower():
        auc_val = float(value)
        quality = "Excellent" if auc_val > 0.9 else "Good" if auc_val > 0.8 else "Fair" if auc_val > 0.7 else "Weak" if auc_val > 0.5 else "No better than random"
        print(f"AUC: {auc_val:.3f} ({quality})")
        print(f"  → Guideline: >0.9 Excellent, 0.8-0.9 Good, 0.7-0.8 Fair, <0.7 Weak")

print()
print("For lending risk: Recall matters most (catching actual defaults)")
print("is more important than Precision (avoiding false alarms).")
```

## Step 5: Feature Importance

SQL cell:
```sql
CALL BB_TRAINING.GOLD.LOAN_DEFAULT_MODEL!SHOW_FEATURE_IMPORTANCE();
```

Python interpretation cell:
```python
from snowflake.snowpark.context import get_active_session
session = get_active_session()

importance = session.sql("CALL BB_TRAINING.GOLD.LOAN_DEFAULT_MODEL!SHOW_FEATURE_IMPORTANCE()").to_pandas()

print("=" * 60)
print("FEATURE IMPORTANCE - What drives default predictions?")
print("=" * 60)
print()
if len(importance) == 0:
    print("No feature importance data available.")
else:
    importance = importance.sort_values(by=importance.columns[2], ascending=False)
    for i, row in importance.iterrows():
        feature = row.iloc[1]
        score = row.iloc[2]
        bar = "█" * int(float(score) * 50)
        print(f"  {feature:<20} {bar} ({float(score):.3f})")

    top_feature = importance.iloc[0, 1]
    print(f"\nKey insight: {top_feature} is the strongest predictor of loan defaults.")
    print("This aligns with banking intuition - credit assessment scores")
    print("are designed to predict exactly this outcome.")
```

## Step 6: Score Predictions on the Portfolio

Generate predictions. The PREDICT method takes OBJECT_CONSTRUCT with keys matching training column names exactly. Use fully qualified model name.

```sql
CREATE OR REPLACE TABLE BB_TRAINING.GOLD.ML_DEFAULT_PREDICTIONS AS
SELECT
    a.APPLICATION_ID,
    a.LOAN_AMOUNT,
    a.LOAN_PRODUCT,
    a.RISK_TIER,
    a.CREDIT_SCORE,
    BB_TRAINING.GOLD.LOAN_DEFAULT_MODEL!PREDICT(
        OBJECT_CONSTRUCT(
            'LOAN_AMOUNT', a.LOAN_AMOUNT,
            'LOAN_TERM_MONTHS', a.LOAN_TERM_MONTHS,
            'INTEREST_RATE', a.INTEREST_RATE,
            'CREDIT_SCORE', a.CREDIT_SCORE,
            'RISK_TIER', a.RISK_TIER,
            'LOAN_PRODUCT', a.LOAN_PRODUCT
        )
    ) AS PREDICTION
FROM BB_TRAINING.SILVER.SILVER_LOAN_APPLICATIONS a
WHERE a.STATUS = 'Approved'
  AND a.CREDIT_SCORE IS NOT NULL
  AND a.RISK_TIER IS NOT NULL;
```

Show highest-risk loans:
```sql
SELECT
    APPLICATION_ID,
    LOAN_PRODUCT,
    LOAN_AMOUNT,
    RISK_TIER,
    CREDIT_SCORE,
    PREDICTION:"class"::STRING AS PREDICTED_CLASS,
    ROUND(PREDICTION:"probability"::VARIANT:"1"::FLOAT * 100, 1) AS DEFAULT_PROBABILITY_PCT
FROM BB_TRAINING.GOLD.ML_DEFAULT_PREDICTIONS
ORDER BY DEFAULT_PROBABILITY_PCT DESC
LIMIT 20;
```

## Step 7: Summary Interpretation

Final Python cell:
```python
from snowflake.snowpark.context import get_active_session
session = get_active_session()

results = session.sql("""
    SELECT
        COUNT(*) AS total_loans,
        SUM(CASE WHEN PREDICTION:'class'::STRING = '1' THEN 1 ELSE 0 END) AS predicted_defaults,
        ROUND(SUM(CASE WHEN PREDICTION:'class'::STRING = '1' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS default_pct
    FROM BB_TRAINING.GOLD.ML_DEFAULT_PREDICTIONS
""").to_pandas()

by_product = session.sql("""
    SELECT LOAN_PRODUCT, COUNT(*) AS flagged
    FROM BB_TRAINING.GOLD.ML_DEFAULT_PREDICTIONS
    WHERE PREDICTION:'class'::STRING = '1'
    GROUP BY LOAN_PRODUCT
    ORDER BY flagged DESC
""").to_pandas()

print("=" * 60)
print("PREDICTION SUMMARY")
print("=" * 60)
print(f"\nTotal loans scored: {results['TOTAL_LOANS'].iloc[0]:,.0f}")
print(f"Predicted to default: {results['PREDICTED_DEFAULTS'].iloc[0]:,.0f} ({results['DEFAULT_PCT'].iloc[0]:.1f}%)")
print(f"\nHighest-risk loan products:")
for _, row in by_product.iterrows():
    print(f"  {row['LOAN_PRODUCT']}: {row['FLAGGED']} loans flagged")
print(f"\nNext steps in production:")
print(f"  - Flag new applications for manual review when probability > 50%")
print(f"  - Retrain monthly on actual outcomes")
print(f"  - Monitor for prediction drift over time")
```
