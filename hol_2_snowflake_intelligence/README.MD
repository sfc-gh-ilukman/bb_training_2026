# HOL 2: Predictive Analytics & Snowflake Intelligence

## Overview

In this hands-on lab you will:
1. Build ML models using Cortex Code prompts and Snowflake ML (native classification)
2. Create a Semantic View over your Gold layer
3. Set up a Cortex Agent
4. Launch Snowflake Intelligence for natural language queries

**Duration:** 75 minutes

**Prerequisites:** HOL 1 must be completed (Gold layer tables must exist).

---

## Part 1: Predictive Analytics with Snowflake ML

### Create the ML Notebook

1. In the left sidebar, click **Notebooks**
2. Click **+ Notebook**
3. Configure:
   - **Name:** `BB_ML`
   - **Database:** `BB_TRAINING`
   - **Schema:** `GOLD`
   - **Warehouse:** `BB_TRAINING_WH`
4. Click **Create**

### Upload the Notebook (Option A - Recommended)
If your facilitator has shared the notebook file:
1. Click **...** menu → **Import .ipynb**
2. Select `ml_notebook.ipynb`
3. Follow the instructions in each section

### How to Use Cortex Code in Notebooks

1. Click into an **empty code cell**
2. Look for the **Cortex Code icon** (sparkle/AI icon) or press the AI keyboard shortcut
3. Type your prompt in natural language
4. The AI will generate code - review it and press Enter/Accept
5. Run the cell (Shift+Enter)

### The ML Workflow (5 Steps)

The notebook guides you through a standard ML workflow using prompts:

| Step | What You're Doing | ML Concept |
|------|-------------------|------------|
| 1 | Prepare training data | Feature engineering, target definition |
| 2 | Train a model | Snowflake ML Classification |
| 3 | Evaluate performance | Accuracy, precision, recall, feature importance |
| 4 | Make predictions | Scoring the portfolio |
| 5 | Bonus: second model | Multiclass classification (customer risk) |

**Business question:** Can we predict which loans will have late payments using information available at approval time?

---

## Part 2: Snowflake Intelligence

### Step 2a: Create the Semantic View

1. Go to **Worksheets** → **+ SQL Worksheet**
2. Paste the contents of `create_semantic_view.sql`
3. Click **Run All**
4. You should see the semantic view description in the results

### Step 2b-2d: Set Up Agent and SI

Follow the detailed instructions in **`si_hol.md`** which covers:
- Creating a Cortex Agent
- Configuring it with the semantic view
- Launching Snowflake Intelligence
- Testing with sample questions

---

## What You Built

```
Gold Layer Tables
       │
       ├──────────────────────────────┐
       │                              │
       ▼                              ▼
┌─────────────────────┐    ┌─────────────────────┐
│   ML Models         │    │   Semantic View     │
│ loan_default_model  │    │ BB_LENDING_SEMANTIC │
│ customer_risk_model │    └─────────┬───────────┘
└─────────────────────┘              │
                                     ▼
                          ┌─────────────────────┐
                          │   Cortex Agent      │
                          │ BB_LENDING_AGENT    │
                          └─────────┬───────────┘
                                    │
                                    ▼
                          ┌─────────────────────┐
                          │ Snowflake           │
                          │ Intelligence        │
                          └─────────────────────┘
```

---

## Key Concepts

- **Snowflake ML Classification** - Native model training without Python packages or data export
- **Cortex Code** - AI assistant that generates code from natural language prompts
- **Semantic Views** - Business-friendly definitions over your data model
- **Cortex Agents** - AI agents that understand your data and answer questions
- **Snowflake Intelligence** - Chat interface for business users to query data

---

## Sample Questions to Ask SI

Once Snowflake Intelligence is running, try these:

| Category | Question |
|----------|----------|
| KPI | "What is the total portfolio value?" |
| Trend | "Show monthly applications for the last year" |
| Segment | "Which industry has the highest approval rate?" |
| Risk | "How many high-risk customers have exposure over $1M?" |
| Comparison | "Compare delinquency rates between Term Loans and Lines of Credit" |

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Can't find AI & ML section | Use ACCOUNTADMIN role |
| Semantic view creation fails | Check Gold tables exist first |
| ML model training fails | Ensure ML_TRAINING_DATA table was created in Step 1 |
| Agent gives wrong answers | Verify the semantic view references correct tables |
| Cortex Code not generating code | Try refreshing the page |
| "Warehouse suspended" | Auto-resumes, just retry |
| SI not available | Check you're using Enterprise edition trial |
