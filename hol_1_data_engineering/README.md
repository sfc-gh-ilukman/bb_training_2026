# HOL 1: Data Engineering & Analytics

## Overview

In this hands-on lab you will:
1. Build a data transformation pipeline (Raw → Silver → Gold) using Snowpark Python
2. Perform data quality profiling
3. Create a Streamlit dashboard to visualize the results

**Duration:** 75 minutes

---

## Timing Guide

| Step | Activity | Duration | Running Total |
|------|----------|----------|---------------|
| 1 | Run setup.sql + verify | 10 min | 10 min |
| 2 | Pipeline: Raw → Silver (3 tables) | 20 min | 30 min |
| 3 | Data quality profiling | 10 min | 40 min |
| 4 | Pipeline: Silver → Gold (3 tables) | 15 min | 55 min |
| 5 | Streamlit dashboard | 15 min | 70 min |
| 6 | Buffer / Q&A | 5 min | 75 min |

---

## Step 1: Run the Setup Script (if not done already)

> Skip this if you already ran setup.sql in the main session.

1. Go to **Worksheets** → **+ SQL Worksheet**
2. Paste the contents of `../00_setup/setup.sql`
3. Click **Run All**
4. Verify you see all 4 tables with correct row counts

---

## Step 2: Create the Pipeline Notebook

1. In the left sidebar, click **Notebooks**
2. Click **+ Notebook**
3. Configure:
   - **Name:** `BB_Pipeline`
   - **Database:** `BB_TRAINING`
   - **Schema:** `RAW`
   - **Warehouse:** `BB_TRAINING_WH`
4. Click **Create**

### Upload the Notebook (Option A - Recommended)
If your facilitator has shared the notebook file:
1. In the notebook, click the **...** menu → **Import .ipynb**
2. Select `pipeline_notebook.ipynb`
3. Run cells top-to-bottom

### Manual Entry (Option B)
If uploading isn't available, create cells manually by copying from `pipeline_notebook.ipynb`. The notebook contains:
- Cell 1-2: Connection + verification
- Cell 3-5: Silver layer transformations
- Cell 6-7: Data quality profiling
- Cell 8-10: Gold layer aggregations
- Cell 11: Final verification

### Running the Notebook

Run each cell **in order** from top to bottom:
- Click into a cell → Press **Shift+Enter** (or click the Play button)
- Wait for each cell to complete before running the next one
- Green check = success, Red X = error

---

## Step 3: Create the Streamlit Dashboard

After your Gold layer tables are created, you'll build a dashboard.

1. In the left sidebar, click **Projects** → **Streamlit**
2. Click **+ Streamlit App**
3. Configure:
   - **Name:** `BB_Lending_Dashboard`
   - **Database:** `BB_TRAINING`
   - **Schema:** `GOLD`
   - **Warehouse:** `BB_TRAINING_WH`
4. Click **Create**

### Using Cortex Code (Try this first!)

1. Delete all the default code in the editor
2. Open Cortex Code (AI assistant icon at the bottom-right, or press the shortcut)
3. Paste the prompt from `streamlit_prompt.md` (the section under "Option A")
4. Review the generated code and click **Run**

### Fallback Script

If Cortex Code doesn't generate working code:
1. Delete all code in the editor
2. Copy the complete script from `streamlit_prompt.md` (the section under "Option B")
3. Paste it into the editor
4. Click **Run**

You should see a dashboard with KPI cards, charts, and a customer table.

---

## What You Built

```
RAW Layer (4 tables)          SILVER Layer (3 tables)         GOLD Layer (3 tables)
┌──────────────────┐    ┌──────────────────────┐    ┌─────────────────────────┐
│ RAW_CUSTOMERS    │───▶│ SILVER_CUSTOMERS     │───▶│ GOLD_CUSTOMER_360       │
│ RAW_APPLICATIONS │───▶│ SILVER_APPLICATIONS  │───▶│ GOLD_LOAN_PERFORMANCE   │
│ RAW_TRANSACTIONS │───▶│ SILVER_TRANSACTIONS  │───▶│ GOLD_PORTFOLIO_SUMMARY  │
│ RAW_RISK_ASSESS  │    └──────────────────────┘    └─────────────────────────┘
└──────────────────┘         ▲ Cleaned              ▲ Aggregated
                             │ Validated             │ Business-ready
                             │ Enriched              │ Analytics-optimized
```

---

## Key Concepts

- **Medallion Architecture** - Raw → Silver → Gold pattern for progressive data refinement
- **Snowpark Python** - DataFrame API for serverless data transformations
- **Idempotent Pipelines** - `write.mode('overwrite')` makes re-runs safe
- **Data Quality** - Always profile between transformation layers
- **Streamlit in Snowflake** - Build dashboards without leaving Snowsight

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Session not found" | Make sure you're running in a Snowsight Notebook |
| "Table does not exist" | Run cells in order - earlier cells create the tables |
| Slow performance | This is normal on XS warehouse. Wait 10-20 seconds per cell. |
| "get_active_session not defined" | You're not in a Snowsight notebook. This only works in Snowsight. |
| Streamlit shows no data | Verify Gold tables exist: `SELECT COUNT(*) FROM BB_TRAINING.GOLD.GOLD_LOAN_PERFORMANCE` |
