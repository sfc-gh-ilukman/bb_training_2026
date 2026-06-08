# Business Banking Training: Hands-On Labs

## Snowflake Training for CBA Business Banking

Welcome! This repository contains materials for two hands-on labs covering data engineering, analytics, data exploration, and Snowflake Intelligence.

---

## Prerequisites

Before the session, you need:

1. **A Snowflake Trial Account** - Sign up at [signup.snowflake.com](https://signup.snowflake.com/)
   - Choose **Enterprise Edition**
   - Choose **AWS** as cloud provider
   - Choose **Asia Pacific (Sydney)** as region
2. **A modern web browser** (Chrome or Edge recommended)
3. **That's it!** Everything runs inside Snowsight - no local tools needed.

---

## Session Structure

| Session | Topic | Duration |
|---------|-------|----------|
| **HOL 1** | Data Engineering & Analytics | 75 min |
| *Break* | | 10 min |
| **HOL 2** | Data Exploration & Snowflake Intelligence | 75 min |

---

## Getting Started

### Step 1: Run the Setup Script (do this first!)

1. Log into your Snowflake trial account at [app.snowflake.com](https://app.snowflake.com)
2. Click **Worksheets** in the left sidebar → **+ SQL Worksheet**
3. Copy the entire contents of `00_setup/setup.sql` into the worksheet
4. Click **Run All** (or Ctrl+Shift+Enter / Cmd+Shift+Enter)
5. Verify you see the row count table at the bottom:
   - RAW_CUSTOMERS: 500
   - RAW_LOAN_APPLICATIONS: 2,000
   - RAW_TRANSACTIONS: 15,000
   - RAW_RISK_ASSESSMENTS: 2,000

### Step 2: HOL 1 - Data Engineering & Analytics

Follow the instructions in `hol_1_data_engineering/README.md`

### Step 3: HOL 2 - Exploration & Intelligence

Follow the instructions in `hol_2_exploration_intelligence/README.md`

---

## File Structure

```
bb_training/
├── README.md                              ← You are here
├── 00_setup/
│   └── setup.sql                          ← Run this first! Creates everything.
├── hol_1_data_engineering/
│   ├── README.md                          ← HOL 1 step-by-step guide
│   ├── pipeline_notebook.ipynb            ← Snowpark pipeline (raw → silver → gold)
│   └── streamlit_prompt.md                ← Prompt + fallback for Streamlit dashboard
├── hol_2_exploration_intelligence/
│   ├── README.md                          ← HOL 2 step-by-step guide
│   ├── eda_notebook.ipynb                 ← 5 EDA prompts for Cortex Code
│   ├── semantic_model.yaml                ← Semantic model definition (reference)
│   ├── create_semantic_view.sql           ← SQL to create semantic view
│   └── si_hol.md                          ← Snowflake Intelligence setup guide
```

---

## Business Scenario

**SME Business Lending Portfolio**

You're a data team at a mid-sized bank's Business Banking division. Your lending portfolio serves Australian small and medium enterprises across 8 industry sectors and all states/territories.

Your data includes:
- **500** business customers
- **2,000** loan applications (2021-2024)
- **15,000** repayment transactions
- **2,000** credit risk assessments

Your job: build a data pipeline, create analytics dashboards, explore the data, and set up a natural language interface for business users.

---

## Data Dictionary

### RAW_CUSTOMERS (500 rows)
Business customer profiles for SMEs in the lending portfolio.

| Column | Type | Description |
|--------|------|-------------|
| `CUSTOMER_ID` | VARCHAR(20) | Unique customer identifier (e.g., CUST-00001) |
| `BUSINESS_NAME` | VARCHAR(200) | Registered business name |
| `ABN` | VARCHAR(20) | Australian Business Number (11 digits) |
| `INDUSTRY` | VARCHAR(50) | Industry sector: Agriculture, Retail, Manufacturing, Healthcare, Technology, Construction, Hospitality, Professional Services |
| `STATE` | VARCHAR(10) | Australian state/territory: NSW, VIC, QLD, WA, SA, TAS, NT, ACT |
| `ANNUAL_REVENUE` | NUMBER(15,2) | Annual revenue in AUD (ranges from $150K to $25M depending on industry) |
| `EMPLOYEES` | INT | Number of employees (1 to 300+) |
| `YEARS_IN_BUSINESS` | INT | How long the business has been operating (1-35 years) |
| `REGISTRATION_DATE` | DATE | Date the customer was registered in the system |
| `CREATED_AT` | TIMESTAMP_NTZ | Record creation timestamp |

### RAW_LOAN_APPLICATIONS (2,000 rows)
Loan applications submitted between 2021-2024 with seasonal patterns (Q1 spike, Dec dip).

| Column | Type | Description |
|--------|------|-------------|
| `APPLICATION_ID` | VARCHAR(20) | Unique application identifier (e.g., APP-000001) |
| `CUSTOMER_ID` | VARCHAR(20) | FK to RAW_CUSTOMERS - the applicant |
| `APPLICATION_DATE` | DATE | Date the application was submitted |
| `LOAN_AMOUNT` | NUMBER(15,2) | Requested loan amount in AUD ($20K - $5M depending on product) |
| `LOAN_PRODUCT` | VARCHAR(50) | Product type: Term Loan, Line of Credit, Equipment Finance, Commercial Property, Invoice Finance |
| `LOAN_TERM_MONTHS` | INT | Loan duration in months (3-300 depending on product) |
| `INTEREST_RATE` | NUMBER(5,2) | Annual interest rate percentage (4.0% - 11.0%) |
| `PURPOSE` | VARCHAR(100) | Loan purpose: Business Expansion, Working Capital, Equipment Purchase, Property Acquisition, Debt Refinancing, Inventory Management, Renovation/Fitout, Cash Flow Management |
| `STATUS` | VARCHAR(20) | Application status: Approved (~65%), Declined (~20%), Pending (~8%), Withdrawn (~7%) |
| `DECISION_DATE` | DATE | Date of approval/decline decision (NULL for Pending) |
| `CREATED_AT` | TIMESTAMP_NTZ | Record creation timestamp |

### RAW_TRANSACTIONS (15,000 rows)
Repayment and disbursement transactions for approved loans. Includes patterns of increasing late fees in Hospitality sector.

| Column | Type | Description |
|--------|------|-------------|
| `TRANSACTION_ID` | VARCHAR(20) | Unique transaction identifier (e.g., TXN-0000001) |
| `LOAN_ID` | VARCHAR(20) | FK to RAW_LOAN_APPLICATIONS (APPLICATION_ID) for approved loans |
| `CUSTOMER_ID` | VARCHAR(20) | FK to RAW_CUSTOMERS |
| `TRANSACTION_DATE` | DATE | Date the transaction occurred |
| `AMOUNT` | NUMBER(15,2) | Transaction amount in AUD |
| `TRANSACTION_TYPE` | VARCHAR(20) | Type: Disbursement (5%), Repayment (70%), Interest (13%), Fee (7%), Late Fee (5%) |
| `STATUS` | VARCHAR(20) | Transaction status: Completed (92%), Failed (5%), Pending (3%) |
| `PAYMENT_METHOD` | VARCHAR(30) | Method: Direct Debit, Bank Transfer, BPAY, Manual Payment |
| `CREATED_AT` | TIMESTAMP_NTZ | Record creation timestamp |

### RAW_RISK_ASSESSMENTS (2,000 rows)
Credit risk scoring for each loan application. Model version improves over time (v1.0 → v2.0 → v3.0).

| Column | Type | Description |
|--------|------|-------------|
| `ASSESSMENT_ID` | VARCHAR(20) | Unique assessment identifier (e.g., RISK-000001) |
| `APPLICATION_ID` | VARCHAR(20) | FK to RAW_LOAN_APPLICATIONS - one assessment per application |
| `ASSESSMENT_DATE` | DATE | Date the risk assessment was performed (0-3 days after application) |
| `CREDIT_SCORE` | INT | Credit score (480-880, varies by industry - Technology/Healthcare score higher, Hospitality lower) |
| `RISK_TIER` | VARCHAR(20) | Risk classification: Low (score >= 750), Medium (650-749), High (550-649), Very High (< 550) |
| `DEBT_SERVICE_RATIO` | NUMBER(5,2) | Ratio of loan to revenue (capped at 5.0) |
| `COLLATERAL_VALUE` | NUMBER(15,2) | Value of collateral offered (50-150% of loan amount) |
| `ASSESSOR_ID` | VARCHAR(10) | ID of the credit assessor (15 assessors) |
| `MODEL_VERSION` | VARCHAR(10) | Risk model version: v1.0 (before Jul 2022), v2.0 (Jul 2022 - Jun 2023), v3.0 (after Jun 2023) |
| `CREATED_AT` | TIMESTAMP_NTZ | Record creation timestamp |

### Key Relationships

```
RAW_CUSTOMERS (1) ──────< (many) RAW_LOAN_APPLICATIONS
                                        │
RAW_LOAN_APPLICATIONS (1) ──── (1) RAW_RISK_ASSESSMENTS
                                        │
RAW_LOAN_APPLICATIONS (1) ──< (many) RAW_TRANSACTIONS
(only Approved loans)
```

### Embedded Data Patterns (for you to discover!)

| Pattern | Where | What to look for |
|---------|-------|------------------|
| Seasonal volume | Loan Applications | More applications in Q1 (Jul-Sep), fewer in December |
| Industry risk | Risk Assessments | Technology/Healthcare have higher credit scores; Hospitality lowest |
| Model improvement | Risk Assessments | v3.0 model has better score distribution than v1.0 |
| Late payment sectors | Transactions | Hospitality sector has proportionally more Late Fee transactions |
| Revenue correlation | Customers | Manufacturing/Construction have highest revenues; Hospitality lowest |

---

## Troubleshooting

### Common Issues

| Problem | Solution |
|---------|----------|
| "Object does not exist" error | Make sure you ran setup.sql completely |
| Warehouse suspended | It auto-resumes. Just re-run your query. |
| "Insufficient privileges" | Use ACCOUNTADMIN role (dropdown in top-left) |
| Notebook won't run | Select a Python kernel (top-right of notebook) |
| Streamlit app errors | Check that Gold tables exist from HOL 1 |

### Getting Help

- Raise your hand (in-room)
- Use the chat (virtual attendees)
- Check that you're using the **ACCOUNTADMIN** role
- Check that you're using the **BB_TRAINING_WH** warehouse

---

## Credits

Built for CBA Business Banking Training | Snowflake 2025
