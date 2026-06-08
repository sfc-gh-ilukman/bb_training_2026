-- ============================================================================
-- BB TRAINING: HANDS-ON LAB SETUP
-- ============================================================================
-- This script creates all required infrastructure and synthetic data for both
-- HOL 1 (Data Engineering & Analytics) and HOL 2 (Exploration & Intelligence)
--
-- Business Scenario: SME Business Lending Portfolio
-- A mid-sized bank's business lending division tracking loan applications,
-- customer profiles, repayment transactions, and risk assessments across
-- Australian SMEs.
--
-- INSTRUCTIONS: Run this entire script in a SQL Worksheet in Snowsight.
-- Estimated time: ~2 minutes
-- ============================================================================

-- ============================================================================
-- STEP 1: CREATE DATABASE, SCHEMAS, AND WAREHOUSE
-- ============================================================================

USE ROLE ACCOUNTADMIN;

-- Enable cross-region inference (required for Cortex Agents / Snowflake Intelligence
-- on AP-Southeast-2 Sydney trial accounts - models run in US regions)
ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';

-- Grant CORTEX_USER database role to ACCOUNTADMIN (ensures AI features work)
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE ACCOUNTADMIN;

-- Create the training database
CREATE OR REPLACE DATABASE BB_TRAINING
    COMMENT = 'Business Banking Training - Hands-on Lab Data';

-- Create schemas for the data pipeline layers
CREATE OR REPLACE SCHEMA BB_TRAINING.RAW
    COMMENT = 'Raw landing zone - synthetic business lending data';

CREATE OR REPLACE SCHEMA BB_TRAINING.SILVER
    COMMENT = 'Cleaned and validated data layer';

CREATE OR REPLACE SCHEMA BB_TRAINING.GOLD
    COMMENT = 'Business-ready aggregated tables';

-- Create a warehouse for the training
CREATE OR REPLACE WAREHOUSE BB_TRAINING_WH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = FALSE
    COMMENT = 'Warehouse for BB Training HOL';

-- Use our new warehouse
USE WAREHOUSE BB_TRAINING_WH;
USE DATABASE BB_TRAINING;
USE SCHEMA RAW;

-- ============================================================================
-- STEP 2: CREATE RAW_CUSTOMERS (~500 rows)
-- Business customer profiles
-- ============================================================================

CREATE OR REPLACE TABLE RAW.RAW_CUSTOMERS (
    customer_id         VARCHAR(20),
    business_name       VARCHAR(200),
    abn                 VARCHAR(20),
    industry            VARCHAR(50),
    state               VARCHAR(10),
    annual_revenue      NUMBER(15,2),
    employees           INT,
    years_in_business   INT,
    registration_date   DATE,
    created_at          TIMESTAMP_NTZ
);

-- Generate 500 business customers with realistic distributions
INSERT INTO RAW.RAW_CUSTOMERS
WITH
industries AS (
    SELECT column1 AS industry, column2 AS weight FROM VALUES
    ('Agriculture', 12), ('Retail', 18), ('Manufacturing', 14),
    ('Healthcare', 10), ('Technology', 15), ('Construction', 16),
    ('Hospitality', 8), ('Professional Services', 7)
),
states AS (
    SELECT column1 AS state, column2 AS weight FROM VALUES
    ('NSW', 32), ('VIC', 26), ('QLD', 20), ('WA', 10),
    ('SA', 7), ('TAS', 2), ('NT', 1), ('ACT', 2)
),
seq AS (
    SELECT SEQ4() + 1 AS n FROM TABLE(GENERATOR(ROWCOUNT => 500))
),
base AS (
    SELECT
        n,
        'CUST-' || LPAD(n::VARCHAR, 5, '0') AS customer_id,
        -- Pick industry based on weighted distribution
        CASE
            WHEN MOD(n * 7 + 13, 100) < 12 THEN 'Agriculture'
            WHEN MOD(n * 7 + 13, 100) < 30 THEN 'Retail'
            WHEN MOD(n * 7 + 13, 100) < 44 THEN 'Manufacturing'
            WHEN MOD(n * 7 + 13, 100) < 54 THEN 'Healthcare'
            WHEN MOD(n * 7 + 13, 100) < 69 THEN 'Technology'
            WHEN MOD(n * 7 + 13, 100) < 85 THEN 'Construction'
            WHEN MOD(n * 7 + 13, 100) < 93 THEN 'Hospitality'
            ELSE 'Professional Services'
        END AS industry,
        -- Pick state based on population distribution
        CASE
            WHEN MOD(n * 3 + 7, 100) < 32 THEN 'NSW'
            WHEN MOD(n * 3 + 7, 100) < 58 THEN 'VIC'
            WHEN MOD(n * 3 + 7, 100) < 78 THEN 'QLD'
            WHEN MOD(n * 3 + 7, 100) < 88 THEN 'WA'
            WHEN MOD(n * 3 + 7, 100) < 95 THEN 'SA'
            WHEN MOD(n * 3 + 7, 100) < 97 THEN 'TAS'
            WHEN MOD(n * 3 + 7, 100) < 98 THEN 'NT'
            ELSE 'ACT'
        END AS state,
        -- Revenue varies by industry
        CASE
            WHEN industry = 'Technology' THEN UNIFORM(500000, 15000000, RANDOM())
            WHEN industry = 'Manufacturing' THEN UNIFORM(1000000, 25000000, RANDOM())
            WHEN industry = 'Construction' THEN UNIFORM(800000, 20000000, RANDOM())
            WHEN industry = 'Healthcare' THEN UNIFORM(400000, 8000000, RANDOM())
            WHEN industry = 'Retail' THEN UNIFORM(200000, 5000000, RANDOM())
            WHEN industry = 'Agriculture' THEN UNIFORM(300000, 10000000, RANDOM())
            WHEN industry = 'Hospitality' THEN UNIFORM(150000, 3000000, RANDOM())
            ELSE UNIFORM(200000, 6000000, RANDOM())
        END AS annual_revenue,
        -- Employees correlate with revenue
        GREATEST(1, (annual_revenue / UNIFORM(80000, 200000, RANDOM()))::INT) AS employees,
        UNIFORM(1, 35, RANDOM()) AS years_in_business,
        DATEADD('day', -UNIFORM(365, 3650, RANDOM()), '2024-01-01'::DATE) AS registration_date
    FROM seq
)
SELECT
    customer_id,
    -- Generate realistic business names
    CASE MOD(n, 10)
        WHEN 0 THEN industry || ' Solutions Pty Ltd'
        WHEN 1 THEN state || ' ' || industry || ' Group'
        WHEN 2 THEN 'Aus ' || industry || ' Services ' || LPAD(MOD(n, 100)::VARCHAR, 2, '0')
        WHEN 3 THEN industry || ' Partners ' || state
        WHEN 4 THEN 'Pacific ' || industry || ' Co'
        WHEN 5 THEN industry || ' Direct ' || LPAD(MOD(n, 50)::VARCHAR, 2, '0')
        WHEN 6 THEN state || ' Commercial ' || industry
        WHEN 7 THEN 'National ' || industry || ' Holdings'
        WHEN 8 THEN industry || ' Enterprises Australia'
        ELSE 'First ' || industry || ' Corp'
    END AS business_name,
    -- Generate ABN (11 digits)
    LPAD(MOD(n * 123456789, 99999999999)::VARCHAR, 11, '0') AS abn,
    industry,
    state,
    annual_revenue::NUMBER(15,2),
    employees,
    years_in_business,
    registration_date,
    DATEADD('second', -UNIFORM(0, 86400*30, RANDOM()), registration_date::TIMESTAMP_NTZ) AS created_at
FROM base;

-- ============================================================================
-- STEP 3: CREATE RAW_LOAN_APPLICATIONS (~2000 rows)
-- Loan applications with temporal patterns
-- ============================================================================

CREATE OR REPLACE TABLE RAW.RAW_LOAN_APPLICATIONS (
    application_id      VARCHAR(20),
    customer_id         VARCHAR(20),
    application_date    DATE,
    loan_amount         NUMBER(15,2),
    loan_product        VARCHAR(50),
    loan_term_months    INT,
    interest_rate       NUMBER(5,2),
    purpose             VARCHAR(100),
    status              VARCHAR(20),
    decision_date       DATE,
    created_at          TIMESTAMP_NTZ
);

INSERT INTO RAW.RAW_LOAN_APPLICATIONS
WITH
date_range AS (
    -- Generate dates from 2021-01-01 to 2024-06-30 (3.5 years)
    SELECT DATEADD('day', SEQ4(), '2021-01-01'::DATE) AS app_date
    FROM TABLE(GENERATOR(ROWCOUNT => 1278))
),
seq AS (
    SELECT SEQ4() + 1 AS n FROM TABLE(GENERATOR(ROWCOUNT => 2000))
),
base AS (
    SELECT
        n,
        'APP-' || LPAD(n::VARCHAR, 6, '0') AS application_id,
        -- Assign to existing customers (some customers have multiple applications)
        'CUST-' || LPAD(UNIFORM(1, 500, RANDOM())::VARCHAR, 5, '0') AS customer_id,
        -- Application date with seasonal patterns:
        -- More apps in Q1 (new financial year), fewer in Dec
        DATEADD('day',
            CASE
                -- Seasonal boost: Q1 (Jul-Sep) gets more weight
                WHEN MOD(n, 4) = 0 THEN UNIFORM(181, 272, RANDOM()) + (UNIFORM(0, 3, RANDOM()) * 365)
                -- COVID dip: March-April 2020 mapped to 2021 for our range
                WHEN MOD(n, 20) = 0 THEN UNIFORM(59, 120, RANDOM())
                ELSE UNIFORM(0, 1277, RANDOM())
            END,
            '2021-01-01'::DATE
        ) AS application_date,
        -- Loan product distribution
        CASE
            WHEN MOD(n * 11 + 3, 100) < 30 THEN 'Term Loan'
            WHEN MOD(n * 11 + 3, 100) < 50 THEN 'Line of Credit'
            WHEN MOD(n * 11 + 3, 100) < 70 THEN 'Equipment Finance'
            WHEN MOD(n * 11 + 3, 100) < 88 THEN 'Commercial Property'
            ELSE 'Invoice Finance'
        END AS loan_product,
        -- Loan amount varies by product
        CASE
            WHEN loan_product = 'Commercial Property' THEN UNIFORM(500000, 5000000, RANDOM())
            WHEN loan_product = 'Equipment Finance' THEN UNIFORM(50000, 500000, RANDOM())
            WHEN loan_product = 'Term Loan' THEN UNIFORM(100000, 2000000, RANDOM())
            WHEN loan_product = 'Line of Credit' THEN UNIFORM(50000, 1000000, RANDOM())
            ELSE UNIFORM(20000, 300000, RANDOM())
        END AS loan_amount,
        -- Term varies by product
        CASE
            WHEN loan_product = 'Commercial Property' THEN UNIFORM(60, 300, RANDOM())
            WHEN loan_product = 'Equipment Finance' THEN UNIFORM(24, 60, RANDOM())
            WHEN loan_product = 'Term Loan' THEN UNIFORM(12, 60, RANDOM())
            WHEN loan_product = 'Line of Credit' THEN UNIFORM(12, 36, RANDOM())
            ELSE UNIFORM(3, 12, RANDOM())
        END AS loan_term_months,
        -- Interest rate (higher for riskier products)
        CASE
            WHEN loan_product = 'Commercial Property' THEN UNIFORM(450, 650, RANDOM()) / 100.0
            WHEN loan_product = 'Equipment Finance' THEN UNIFORM(550, 850, RANDOM()) / 100.0
            WHEN loan_product = 'Term Loan' THEN UNIFORM(500, 900, RANDOM()) / 100.0
            WHEN loan_product = 'Line of Credit' THEN UNIFORM(600, 1100, RANDOM()) / 100.0
            ELSE UNIFORM(400, 800, RANDOM()) / 100.0
        END AS interest_rate,
        -- Purpose
        CASE MOD(n, 8)
            WHEN 0 THEN 'Business Expansion'
            WHEN 1 THEN 'Working Capital'
            WHEN 2 THEN 'Equipment Purchase'
            WHEN 3 THEN 'Property Acquisition'
            WHEN 4 THEN 'Debt Refinancing'
            WHEN 5 THEN 'Inventory Management'
            WHEN 6 THEN 'Renovation/Fitout'
            ELSE 'Cash Flow Management'
        END AS purpose,
        -- Status with realistic approval rates (~65% approved)
        CASE
            WHEN MOD(n * 17 + 5, 100) < 65 THEN 'Approved'
            WHEN MOD(n * 17 + 5, 100) < 85 THEN 'Declined'
            WHEN MOD(n * 17 + 5, 100) < 93 THEN 'Pending'
            ELSE 'Withdrawn'
        END AS status
    FROM seq
)
SELECT
    application_id,
    customer_id,
    LEAST(application_date, '2024-06-30'::DATE) AS application_date,
    loan_amount::NUMBER(15,2),
    loan_product,
    loan_term_months,
    interest_rate::NUMBER(5,2),
    purpose,
    status,
    -- Decision date: 1-14 days after application (NULL for Pending)
    CASE
        WHEN status IN ('Approved', 'Declined') THEN DATEADD('day', UNIFORM(1, 14, RANDOM()), application_date)
        WHEN status = 'Withdrawn' THEN DATEADD('day', UNIFORM(1, 7, RANDOM()), application_date)
        ELSE NULL
    END AS decision_date,
    application_date::TIMESTAMP_NTZ AS created_at
FROM base;

-- ============================================================================
-- STEP 4: CREATE RAW_TRANSACTIONS (~15000 rows)
-- Loan repayments and disbursements
-- ============================================================================

CREATE OR REPLACE TABLE RAW.RAW_TRANSACTIONS (
    transaction_id      VARCHAR(20),
    loan_id             VARCHAR(20),
    customer_id         VARCHAR(20),
    transaction_date    DATE,
    amount              NUMBER(15,2),
    transaction_type    VARCHAR(20),
    status              VARCHAR(20),
    payment_method      VARCHAR(30),
    created_at          TIMESTAMP_NTZ
);

INSERT INTO RAW.RAW_TRANSACTIONS
WITH
-- Get approved loans to generate transactions against
approved_loans AS (
    SELECT
        application_id AS loan_id,
        customer_id,
        loan_amount,
        loan_term_months,
        decision_date,
        loan_product,
        ROW_NUMBER() OVER (ORDER BY application_id) AS rn
    FROM RAW.RAW_LOAN_APPLICATIONS
    WHERE status = 'Approved' AND decision_date IS NOT NULL
),
seq AS (
    SELECT SEQ4() + 1 AS n FROM TABLE(GENERATOR(ROWCOUNT => 15000))
),
base AS (
    SELECT
        n,
        'TXN-' || LPAD(n::VARCHAR, 7, '0') AS transaction_id,
        -- Map to approved loans (cycling through them)
        al.loan_id,
        al.customer_id,
        al.decision_date,
        al.loan_amount,
        al.loan_term_months,
        al.loan_product,
        -- Transaction type distribution
        CASE
            WHEN MOD(n, 100) < 5 THEN 'Disbursement'
            WHEN MOD(n, 100) < 75 THEN 'Repayment'
            WHEN MOD(n, 100) < 88 THEN 'Interest'
            WHEN MOD(n, 100) < 95 THEN 'Fee'
            ELSE 'Late Fee'
        END AS transaction_type,
        -- Transaction date: after the loan decision date
        DATEADD('day',
            LEAST(UNIFORM(1, 900, RANDOM()), al.loan_term_months * 30),
            al.decision_date
        ) AS transaction_date
    FROM seq
    JOIN approved_loans al ON al.rn = MOD(n - 1, (SELECT COUNT(*) FROM approved_loans)) + 1
)
SELECT
    transaction_id,
    loan_id,
    customer_id,
    LEAST(transaction_date, '2024-06-30'::DATE) AS transaction_date,
    -- Amount varies by type
    CASE
        WHEN transaction_type = 'Disbursement' THEN loan_amount
        WHEN transaction_type = 'Repayment' THEN ROUND(loan_amount / loan_term_months * UNIFORM(80, 120, RANDOM()) / 100.0, 2)
        WHEN transaction_type = 'Interest' THEN ROUND(loan_amount * 0.005 * UNIFORM(80, 120, RANDOM()) / 100.0, 2)
        WHEN transaction_type = 'Fee' THEN UNIFORM(50, 500, RANDOM())::NUMBER(15,2)
        ELSE UNIFORM(100, 1000, RANDOM())::NUMBER(15,2)  -- Late Fee
    END AS amount,
    transaction_type,
    -- Status: mostly completed, some failures
    CASE
        WHEN MOD(n * 13, 100) < 92 THEN 'Completed'
        WHEN MOD(n * 13, 100) < 97 THEN 'Failed'
        ELSE 'Pending'
    END AS status,
    -- Payment method
    CASE MOD(n * 7, 5)
        WHEN 0 THEN 'Direct Debit'
        WHEN 1 THEN 'Bank Transfer'
        WHEN 2 THEN 'BPAY'
        WHEN 3 THEN 'Direct Debit'
        ELSE 'Manual Payment'
    END AS payment_method,
    transaction_date::TIMESTAMP_NTZ AS created_at
FROM base;

-- ============================================================================
-- STEP 5: CREATE RAW_RISK_ASSESSMENTS (~2000 rows)
-- Credit risk scoring for each application
-- ============================================================================

CREATE OR REPLACE TABLE RAW.RAW_RISK_ASSESSMENTS (
    assessment_id       VARCHAR(20),
    application_id      VARCHAR(20),
    assessment_date     DATE,
    credit_score        INT,
    risk_tier           VARCHAR(20),
    debt_service_ratio  NUMBER(5,2),
    collateral_value    NUMBER(15,2),
    assessor_id         VARCHAR(10),
    model_version       VARCHAR(10),
    created_at          TIMESTAMP_NTZ
);

INSERT INTO RAW.RAW_RISK_ASSESSMENTS
WITH
apps AS (
    SELECT
        application_id,
        application_date,
        customer_id,
        loan_amount,
        ROW_NUMBER() OVER (ORDER BY application_id) AS rn
    FROM RAW.RAW_LOAN_APPLICATIONS
),
customers AS (
    SELECT customer_id, industry, annual_revenue
    FROM RAW.RAW_CUSTOMERS
),
base AS (
    SELECT
        a.rn AS n,
        'RISK-' || LPAD(a.rn::VARCHAR, 6, '0') AS assessment_id,
        a.application_id,
        a.application_date,
        a.loan_amount,
        c.industry,
        c.annual_revenue,
        -- Credit score influenced by industry
        CASE
            WHEN c.industry = 'Technology' THEN UNIFORM(620, 850, RANDOM())
            WHEN c.industry = 'Healthcare' THEN UNIFORM(650, 880, RANDOM())
            WHEN c.industry = 'Professional Services' THEN UNIFORM(640, 860, RANDOM())
            WHEN c.industry = 'Manufacturing' THEN UNIFORM(580, 820, RANDOM())
            WHEN c.industry = 'Construction' THEN UNIFORM(550, 790, RANDOM())
            WHEN c.industry = 'Retail' THEN UNIFORM(530, 780, RANDOM())
            WHEN c.industry = 'Agriculture' THEN UNIFORM(540, 800, RANDOM())
            ELSE UNIFORM(480, 720, RANDOM())  -- Hospitality (higher risk)
        END AS credit_score,
        -- Debt service ratio
        ROUND(a.loan_amount / NULLIF(c.annual_revenue, 0) * UNIFORM(80, 200, RANDOM()) / 100.0, 2) AS debt_service_ratio,
        -- Collateral (varies by loan size)
        ROUND(a.loan_amount * UNIFORM(50, 150, RANDOM()) / 100.0, 2) AS collateral_value,
        -- Assessor
        'ASR-' || LPAD(UNIFORM(1, 15, RANDOM())::VARCHAR, 3, '0') AS assessor_id,
        -- Model version: v1.0 before 2022-07, v2.0 after (shows improvement)
        CASE
            WHEN a.application_date < '2022-07-01' THEN 'v1.0'
            WHEN a.application_date < '2023-06-01' THEN 'v2.0'
            ELSE 'v3.0'
        END AS model_version
    FROM apps a
    LEFT JOIN customers c ON a.customer_id = c.customer_id
)
SELECT
    assessment_id,
    application_id,
    -- Assessment happens 0-3 days after application
    DATEADD('day', UNIFORM(0, 3, RANDOM()), application_date) AS assessment_date,
    credit_score,
    -- Risk tier based on credit score
    CASE
        WHEN credit_score >= 750 THEN 'Low'
        WHEN credit_score >= 650 THEN 'Medium'
        WHEN credit_score >= 550 THEN 'High'
        ELSE 'Very High'
    END AS risk_tier,
    LEAST(debt_service_ratio, 5.00) AS debt_service_ratio,
    collateral_value,
    assessor_id,
    model_version,
    assessment_date::TIMESTAMP_NTZ AS created_at
FROM base;

-- ============================================================================
-- STEP 6: VERIFY SETUP
-- ============================================================================

-- Run this to confirm everything was created correctly
SELECT '1. RAW_CUSTOMERS' AS table_name, COUNT(*) AS row_count FROM BB_TRAINING.RAW.RAW_CUSTOMERS
UNION ALL
SELECT '2. RAW_LOAN_APPLICATIONS', COUNT(*) FROM BB_TRAINING.RAW.RAW_LOAN_APPLICATIONS
UNION ALL
SELECT '3. RAW_TRANSACTIONS', COUNT(*) FROM BB_TRAINING.RAW.RAW_TRANSACTIONS
UNION ALL
SELECT '4. RAW_RISK_ASSESSMENTS', COUNT(*) FROM BB_TRAINING.RAW.RAW_RISK_ASSESSMENTS
ORDER BY table_name;

-- Expected output:
-- +--------------------------+-----------+
-- | TABLE_NAME               | ROW_COUNT |
-- +--------------------------+-----------+
-- | 1. RAW_CUSTOMERS         |       500 |
-- | 2. RAW_LOAN_APPLICATIONS |      2000 |
-- | 3. RAW_TRANSACTIONS      |     15000 |
-- | 4. RAW_RISK_ASSESSMENTS  |      2000 |
-- +--------------------------+-----------+

-- Quick data preview
SELECT * FROM BB_TRAINING.RAW.RAW_CUSTOMERS LIMIT 5;
SELECT * FROM BB_TRAINING.RAW.RAW_LOAN_APPLICATIONS LIMIT 5;
SELECT * FROM BB_TRAINING.RAW.RAW_TRANSACTIONS LIMIT 5;
SELECT * FROM BB_TRAINING.RAW.RAW_RISK_ASSESSMENTS LIMIT 5;

-- ============================================================================
-- SETUP COMPLETE! You're ready for the Hands-On Labs.
-- ============================================================================

