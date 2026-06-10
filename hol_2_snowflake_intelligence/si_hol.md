# Snowflake Intelligence Setup Guide

## Overview

In this section, you'll set up **Snowflake Intelligence** - a natural language interface that lets business users ask questions about data in plain English. 

You'll complete three steps:
1. Create a Semantic View (already done via SQL)
2. Create a Cortex Agent
3. Set up Snowflake Intelligence

**Estimated time: 30 minutes**

---

## Step 1: Verify Your Semantic View

You should have already run `create_semantic_view.sql`. Let's verify it exists.

Open a **SQL Worksheet** and run:

```sql
USE ROLE ACCOUNTADMIN;
SHOW SEMANTIC VIEWS IN SCHEMA BB_TRAINING.GOLD;
```

You should see `BB_LENDING_SEMANTIC_VIEW` in the results.

If it's not there, go back and run `create_semantic_view.sql` from the `hol_2_exploration_intelligence` folder.

---

## Step 2: Create a Cortex Agent

### 2a. Navigate to Cortex Agents

1. In the **left sidebar** of Snowsight, click on **AI & ML**
2. Under AI & ML, click on **Cortex Agents**
3. Click the **+ Agent** button in the top-right corner

### 2b. Configure the Agent

You'll see the Agent creation screen with several fields:

| Field | What to enter |
|-------|--------------|
| **Name** | `BB_LENDING_AGENT` |
| **Database** | `BB_TRAINING` |
| **Schema** | `GOLD` |
| **Warehouse** | `BB_TRAINING_WH` |

**Agent Description** (paste into the Description field):

```
Business Banking SME Lending Portfolio Analyst. This agent answers questions about loan applications, customer risk profiles, repayment performance, and portfolio trends for the bank's small and medium enterprise lending division across Australia. It covers data from 2021-2024 including 500 business customers, 2000 loan applications, and 15000 transactions.
```

### 2c. Add the Semantic View as a Data Source

1. In the **Data Sources** section, click **+ Add Cortex Analyst tool**
2. Select the semantic view: `BB_TRAINING` → `GOLD` → `BB_LENDING_SEMANTIC_VIEW`
3. Click **Add**

**Semantic View Description** (paste into the tool description field that appears after adding):

```
This semantic view contains three Gold layer tables for SME business lending analysis:
- GOLD_LOAN_PERFORMANCE: Per-loan metrics including loan amount, repayment ratio, payment health score, late payment counts, and risk tier. One row per approved loan.
- GOLD_CUSTOMER_360: One row per business customer with aggregated loan portfolio metrics, industry, state, revenue band, and risk categorization.
- GOLD_PORTFOLIO_SUMMARY: Monthly aggregates of applications, approvals, and approval rates sliced by industry, state, and loan product.

Key dimensions: industry, state, loan product, risk tier, revenue band, customer risk category, application month.
Key metrics: total portfolio value, approval rate, delinquency rate, average loan size, payment health score, total exposure.
```

### 2d. Add Orchestration Instructions

In the **Orchestration Instructions** section, paste:

```
When answering a user question:
1. Determine if the question is about individual loans, customers, or portfolio-level trends.
2. For loan-level questions (delinquency, repayment, loan size) use GOLD_LOAN_PERFORMANCE.
3. For customer-level questions (who are the top customers, risk categories, exposure) use GOLD_CUSTOMER_360.
4. For time-series and trend questions (monthly applications, approval rates over time) use GOLD_PORTFOLIO_SUMMARY.
5. For cross-cutting questions (delinquency by industry) join LOAN_PERFORMANCE to CUSTOMER_360 via CUSTOMER_ID.
6. Always use the semantic view tool to generate and execute SQL. Do not guess or make up numbers.
7. If the question is ambiguous, ask the user to clarify which segment or time period they mean.
8. Based on  your experience as a principal business banking analyst create key insights  and recommendations
```

### 2e. Add Response Instructions

In the **Response Instructions** section, paste:

```
When presenting results:
- Lead with the key finding or number before showing details
- Format currency values in AUD with abbreviations: use $1.5M not $1,500,000; use $750K not $750,000
- Always include the sample size or record count for context (e.g., "across 1,300 approved loans")
- For percentage metrics, round to 1 decimal place
- When showing rankings or top-N lists, include the relevant dimension values (industry, state, product)
- If showing trends, mention the direction (increasing, decreasing, stable) and the time range covered
- When discussing risk, reference both the risk tier AND the payment health score for completeness
- Keep responses concise - aim for 2-4 sentences of insight plus any supporting data table
- Based on  your  experience as a principal business banking analyst create key insights  and  recommendations
```

### 2f. Save the Agent

1. Click **Create** (or **Save**) in the top-right corner
2. The agent will be created and you'll see a confirmation

### 2g. Test the Agent

On the agent page, you'll see a **chat interface**. Test it with these questions:

1. `What is the total portfolio value?`
2. `Which industries have the highest delinquency rate?`
3. `Show me the top 5 high-risk customers by loan exposure`

Verify the agent returns sensible results before proceeding.

---

## Step 3: Set Up Snowflake Intelligence

### 3a. Navigate to Snowflake Intelligence

1. In the **left sidebar** of Snowsight, click on **AI & ML**
2. Click on **Snowflake Intelligence**
3. Click the **+ Intelligence** button

### 3b. Configure the Intelligence Instance

| Field | What to enter |
|-------|--------------|
| **Name** | `BB Lending Intelligence` |
| **Description** | `Ask questions about business banking loan portfolio in natural language` |
| **Warehouse** | `BB_TRAINING_WH` |

### 3c. Add Your Agent

1. In the **Agent** section, select the agent you just created: `BB_LENDING_AGENT`
2. The agent's data sources (your semantic view) will be automatically included

### 3d. Save and Launch

1. Click **Create** to finalize the setup
2. You'll be taken to the Snowflake Intelligence chat interface

---

## Step 4: Test Snowflake Intelligence

Now try asking questions in natural language! Here are some good test questions:

### Basic Questions (these map directly to metrics)
- "What is the total value of our loan portfolio?"
- "How many active customers do we have?"
- "What is our average approval rate?"

### Analytical Questions (these require grouping by dimensions)
- "Which industry has the highest delinquency rate?"
- "Show me the monthly trend of loan applications over the last year"
- "What is the average loan size by product type?"

### Business Questions (these filter and rank)
- "Who are our top 10 customers by total exposure?"
- "What is the approval rate by state?"
- "Show me customers with high exposure but poor payment health (below 50)"

### Challenge Questions (try these!)
- "Compare approval rates between NSW and VIC - Why does one state perform better than the other"
- "What is the delinquency rate for each risk tier?"
- "Which loan product has the best repayment performance?"

### Skill-Powered Questions (invoke the agent's reasoning frameworks)

These prompts trigger the agent skills you've added. The agent will follow a structured multi-step analysis rather than just returning a single query result.

**Loan Risk Advisor:**
- "A hospitality business with a credit score of 580 wants a $400K equipment finance loan. Should we approve it?"
- "Assess this application: $1.2M commercial property loan, construction industry, NSW, credit score 690"
- "Would you recommend approving a $200K line of credit for a retail business with 3 years in operation?"

**Portfolio Health Check:**
- "Run a health check on our portfolio"
- "Give me an executive summary of how the lending portfolio is performing"
- "How's the portfolio doing? Any concerns?"

**Early Warning Scan:**
- "Are there any loans I should be worried about?"
- "Run an early warning scan - flag any deteriorating loans"
- "Which loans are showing signs of distress? What should we do about them?"

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Can't find "AI & ML" in sidebar | Make sure you're using the ACCOUNTADMIN role (top-left dropdown) |
| Semantic view not showing | Verify it exists: `SHOW SEMANTIC VIEWS IN SCHEMA BB_TRAINING.GOLD;` |
| Agent gives wrong answers | Check that the semantic view references the correct Gold tables |
| "Warehouse suspended" error | The warehouse auto-resumes; just retry the question |
| Agent says "I don't know" | Rephrase with more specific column/table references from the semantic view |

---

## Summary

You've now set up a complete Snowflake Intelligence stack:

```
Gold Layer Tables → Semantic View → Cortex Agent → Snowflake Intelligence
```

This allows business users to:
- Ask questions in plain English
- Get instant answers with SQL transparency
- Explore data without writing code
- Share insights through a collaborative interface

### What makes this powerful:
1. **No SQL required** - Business users can self-serve
2. **Governed** - All answers come from your curated Gold layer
3. **Transparent** - Users can see the SQL generated behind each answer
4. **Scalable** - Add more semantic views as your data grows

---

## Congratulations! 

You've completed both Hands-On Labs! Here's what you built today:

| HOL 1 | HOL 2 |
|-------|-------|
| Raw → Silver → Gold pipeline | Data exploration with Cortex Code |
| Snowpark Python transformations | Semantic View creation |
| Data quality profiling | Cortex Agent setup |
| Streamlit dashboard | Snowflake Intelligence |
