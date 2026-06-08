# HOL 2: Data Exploration & Snowflake Intelligence

## Overview

In this hands-on lab you will:
1. Use Cortex Code (AI) to generate exploratory data analysis in a notebook
2. Create a Semantic View over your Gold layer
3. Set up a Cortex Agent
4. Launch Snowflake Intelligence for natural language queries

**Duration:** 75 minutes

**Prerequisites:** HOL 1 must be completed (Gold layer tables must exist).

---

## Timing Guide

| Step | Activity | Duration | Running Total |
|------|----------|----------|---------------|
| 1 | EDA with Cortex Code (5 prompts) | 25 min | 25 min |
| 2 | Create Semantic View (SQL) | 10 min | 35 min |
| 3 | Create Cortex Agent | 10 min | 45 min |
| 4 | Set up Snowflake Intelligence | 10 min | 55 min |
| 5 | Test SI with sample questions | 10 min | 65 min |
| 6 | Buffer / Q&A | 10 min | 75 min |

---

## Part 1: Data Exploration with Cortex Code

### Create the EDA Notebook

1. In the left sidebar, click **Notebooks**
2. Click **+ Notebook**
3. Configure:
   - **Name:** `BB_EDA`
   - **Database:** `BB_TRAINING`
   - **Schema:** `GOLD`
   - **Warehouse:** `BB_TRAINING_WH`
4. Click **Create**

### Upload the Notebook (Option A - Recommended)
If your facilitator has shared the notebook file:
1. Click **...** menu → **Import .ipynb**
2. Select `eda_notebook.ipynb`
3. Follow the instructions in each section

### Manual Entry (Option B)
If upload isn't available, follow along with the prompts below.

### How to Use Cortex Code in Notebooks

1. Click into an **empty code cell**
2. Look for the **Cortex Code icon** (sparkle/AI icon) or press the AI keyboard shortcut
3. Type your prompt in natural language
4. The AI will generate code - review it and press Enter/Accept
5. Run the cell (Shift+Enter)

### The 5 EDA Prompts

Run the setup cell first (establish session), then try each prompt:

**Prompt 1: Portfolio Distribution**
> Using the BB_TRAINING.GOLD.GOLD_CUSTOMER_360 table, create a visualization showing the distribution of total loan exposure (TOTAL_EXPOSURE) broken down by INDUSTRY and CUSTOMER_RISK_CATEGORY. Use a grouped bar chart with matplotlib.

**Prompt 2: Monthly Trends**
> Query BB_TRAINING.GOLD.GOLD_PORTFOLIO_SUMMARY and create a dual-axis chart showing monthly TOTAL_APPLICATIONS (bars) and APPROVAL_RATE (line) over time.

**Prompt 3: Delinquency Heatmap**
> Using BB_TRAINING.GOLD.GOLD_LOAN_PERFORMANCE, calculate delinquency rate by RISK_TIER and LOAN_PRODUCT. Display as a heatmap.

**Prompt 4: Size vs Risk**
> From BB_TRAINING.GOLD.GOLD_LOAN_PERFORMANCE, create a scatter plot of average LOAN_AMOUNT vs delinquency rate grouped by LOAN_PRODUCT.

**Prompt 5: Top Customers**
> Query BB_TRAINING.GOLD.GOLD_CUSTOMER_360 for top 15 customers by TOTAL_EXPOSURE. Create a horizontal bar chart colored by CUSTOMER_RISK_CATEGORY.

> **Note:** Each prompt has a fallback code cell in the notebook. If Cortex Code doesn't generate working code, just run the fallback cell instead.

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
       ▼
┌─────────────────────┐
│   Semantic View     │  ← Defines metrics, dimensions, relationships
│ BB_LENDING_SEMANTIC │
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│   Cortex Agent      │  ← Translates natural language → SQL
│ BB_LENDING_AGENT    │
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│ Snowflake           │  ← Business user interface
│ Intelligence        │     (chat with your data!)
└─────────────────────┘
```

---

## Key Concepts

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
| Agent gives wrong answers | Verify the semantic view references correct tables |
| Cortex Code not generating code | Try refreshing the page, or use the fallback cells |
| "Warehouse suspended" | Auto-resumes, just retry |
| SI not available | Check you're using Enterprise edition trial |
