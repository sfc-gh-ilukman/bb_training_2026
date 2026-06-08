-- ============================================================================
-- CREATE SEMANTIC VIEW FOR SNOWFLAKE INTELLIGENCE
-- ============================================================================
-- This script creates a semantic view from the Gold layer tables.
-- Run this in a SQL Worksheet in Snowsight.
-- 
-- Prerequisites: HOL 1 Gold tables must exist.
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE BB_TRAINING;
USE SCHEMA GOLD;
USE WAREHOUSE BB_TRAINING_WH;

-- Create the semantic view
CREATE OR REPLACE SEMANTIC VIEW BB_TRAINING.GOLD.BB_LENDING_SEMANTIC_VIEW

  TABLES (
    LOAN_PERFORMANCE AS BB_TRAINING.GOLD.GOLD_LOAN_PERFORMANCE
      PRIMARY KEY (APPLICATION_ID)
      COMMENT = 'Per-loan metrics showing repayment health, payment scores, and delinquency indicators',
    CUSTOMER_360 AS BB_TRAINING.GOLD.GOLD_CUSTOMER_360
      PRIMARY KEY (CUSTOMER_ID)
      COMMENT = 'Complete customer view with one row per business customer including all loan portfolio metrics',
    PORTFOLIO_SUMMARY AS BB_TRAINING.GOLD.GOLD_PORTFOLIO_SUMMARY
      COMMENT = 'Monthly portfolio-level aggregates by industry, state, and loan product'
  )

  RELATIONSHIPS (
    LOAN_PERFORMANCE (CUSTOMER_ID) REFERENCES CUSTOMER_360 (CUSTOMER_ID)
  )

  DIMENSIONS (
    CUSTOMER_360.CUSTOMER_ID AS CUSTOMER_360.CUSTOMER_ID
      COMMENT = 'Unique customer identifier for counting and grouping',
    CUSTOMER_360.INDUSTRY AS CUSTOMER_360.INDUSTRY
      COMMENT = 'Business industry sector (Agriculture, Retail, Manufacturing, Healthcare, Technology, Construction, Hospitality, Professional Services)',
    CUSTOMER_360.STATE AS CUSTOMER_360.STATE
      COMMENT = 'Australian state or territory (NSW, VIC, QLD, WA, SA, TAS, NT, ACT)',
    CUSTOMER_360.REVENUE_BAND AS CUSTOMER_360.REVENUE_BAND
      COMMENT = 'Revenue classification (Micro < $500K, Small < $2M, Medium < $10M, Large >= $10M)',
    CUSTOMER_360.EMPLOYEE_BAND AS CUSTOMER_360.EMPLOYEE_BAND
      COMMENT = 'Employee count band (1-4, 5-19, 20-99, 100+)',
    CUSTOMER_360.CUSTOMER_RISK_CATEGORY AS CUSTOMER_360.CUSTOMER_RISK_CATEGORY
      COMMENT = 'Overall customer risk category (Low Risk, Medium Risk, High Risk, No Loan History)',
    CUSTOMER_360.BUSINESS_NAME AS CUSTOMER_360.BUSINESS_NAME
      COMMENT = 'Registered business name',

    LOAN_PERFORMANCE.APPLICATION_ID AS LOAN_PERFORMANCE.APPLICATION_ID
      COMMENT = 'Unique loan application identifier for counting loans',
    LOAN_PERFORMANCE.CUSTOMER_ID AS LOAN_PERFORMANCE.CUSTOMER_ID
      COMMENT = 'Customer who holds the loan - use for joining to CUSTOMER_360',
    LOAN_PERFORMANCE.LOAN_PRODUCT AS LOAN_PERFORMANCE.LOAN_PRODUCT
      COMMENT = 'Type of loan product (Term Loan, Line of Credit, Equipment Finance, Commercial Property, Invoice Finance)',
    LOAN_PERFORMANCE.RISK_TIER AS LOAN_PERFORMANCE.RISK_TIER
      COMMENT = 'Risk tier at time of application (Low, Medium, High, Very High)',
    LOAN_PERFORMANCE.APPLICATION_DATE AS LOAN_PERFORMANCE.APPLICATION_DATE
      COMMENT = 'Date the loan application was submitted',

    PORTFOLIO_SUMMARY.APPLICATION_MONTH AS PORTFOLIO_SUMMARY.APPLICATION_MONTH
      COMMENT = 'Month of loan applications (first day of month)',
    PORTFOLIO_SUMMARY.INDUSTRY AS PORTFOLIO_SUMMARY.INDUSTRY
      COMMENT = 'Customer industry sector for portfolio aggregation',
    PORTFOLIO_SUMMARY.STATE AS PORTFOLIO_SUMMARY.STATE
      COMMENT = 'Australian state for portfolio aggregation',
    PORTFOLIO_SUMMARY.LOAN_PRODUCT AS PORTFOLIO_SUMMARY.LOAN_PRODUCT
      COMMENT = 'Loan product type for portfolio aggregation'
  )

  METRICS (
    -- Loan-level metrics
    LOAN_PERFORMANCE.TOTAL_PORTFOLIO_VALUE AS
      SUM(LOAN_PERFORMANCE.LOAN_AMOUNT)
      COMMENT = 'Total value of all loans in portfolio (AUD)',

    LOAN_PERFORMANCE.AVG_LOAN_SIZE AS
      AVG(LOAN_PERFORMANCE.LOAN_AMOUNT)
      COMMENT = 'Average loan amount in AUD',

    LOAN_PERFORMANCE.TOTAL_LOANS AS
      COUNT(LOAN_PERFORMANCE.APPLICATION_ID)
      COMMENT = 'Total number of loans in the portfolio',

    LOAN_PERFORMANCE.OVERALL_DELINQUENCY_RATE AS
      SUM(CASE WHEN LOAN_PERFORMANCE.LATE_PAYMENT_COUNT > 0 THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(LOAN_PERFORMANCE.APPLICATION_ID), 0)
      COMMENT = 'Percentage of loans with at least one late payment',

    LOAN_PERFORMANCE.AVG_PAYMENT_HEALTH AS
      AVG(LOAN_PERFORMANCE.PAYMENT_HEALTH_SCORE)
      COMMENT = 'Average payment health score across all loans (0-100)',

    LOAN_PERFORMANCE.AVG_REPAYMENT_RATIO AS
      AVG(LOAN_PERFORMANCE.REPAYMENT_RATIO)
      COMMENT = 'Average repayment ratio percentage - higher means more repaid',

    -- Customer-level metrics
    CUSTOMER_360.TOTAL_ACTIVE_CUSTOMERS AS
      COUNT(DISTINCT CASE WHEN CUSTOMER_360.TOTAL_LOANS > 0 THEN CUSTOMER_360.CUSTOMER_ID END)
      COMMENT = 'Number of customers with at least one active loan',

    CUSTOMER_360.TOTAL_EXPOSURE AS
      SUM(CUSTOMER_360.TOTAL_EXPOSURE)
      COMMENT = 'Total loan exposure across all customers (AUD)',

    CUSTOMER_360.AVG_CUSTOMER_HEALTH AS
      AVG(CUSTOMER_360.AVG_PAYMENT_HEALTH)
      COMMENT = 'Average payment health across all customers (0-100)',

    -- Portfolio-level metrics
    PORTFOLIO_SUMMARY.TOTAL_APPLICATIONS AS
      SUM(PORTFOLIO_SUMMARY.TOTAL_APPLICATIONS)
      COMMENT = 'Total number of loan applications',

    PORTFOLIO_SUMMARY.TOTAL_APPROVALS AS
      SUM(PORTFOLIO_SUMMARY.TOTAL_APPROVALS)
      COMMENT = 'Total number of approved loan applications',

    PORTFOLIO_SUMMARY.AVG_APPROVAL_RATE AS
      AVG(PORTFOLIO_SUMMARY.APPROVAL_RATE)
      COMMENT = 'Average loan approval rate percentage',

    PORTFOLIO_SUMMARY.TOTAL_LOAN_VOLUME AS
      SUM(PORTFOLIO_SUMMARY.TOTAL_LOAN_AMOUNT)
      COMMENT = 'Total dollar value of all loan applications (AUD)'
  )

  COMMENT = 'Business Banking SME Lending Portfolio - Semantic View for Snowflake Intelligence'

  AI_VERIFIED_QUERIES (
    total_portfolio_value AS (
      QUESTION 'What is the total portfolio value?'
      SQL 'SELECT SUM(LOAN_AMOUNT) AS TOTAL_PORTFOLIO_VALUE FROM BB_TRAINING.GOLD.GOLD_LOAN_PERFORMANCE'
    ),

    approval_rate_by_industry AS (
      QUESTION 'What is the approval rate by industry?'
      SQL 'SELECT INDUSTRY, ROUND(SUM(TOTAL_APPROVALS) / NULLIF(SUM(TOTAL_APPLICATIONS), 0) * 100, 1) AS APPROVAL_RATE FROM BB_TRAINING.GOLD.GOLD_PORTFOLIO_SUMMARY GROUP BY INDUSTRY ORDER BY APPROVAL_RATE DESC'
    ),

    high_risk_customers AS (
      QUESTION 'Which customers are high risk with the most exposure?'
      SQL 'SELECT BUSINESS_NAME, INDUSTRY, STATE, TOTAL_EXPOSURE, AVG_PAYMENT_HEALTH FROM BB_TRAINING.GOLD.GOLD_CUSTOMER_360 WHERE CUSTOMER_RISK_CATEGORY = ''High Risk'' ORDER BY TOTAL_EXPOSURE DESC LIMIT 10'
    ),

    monthly_application_trend AS (
      QUESTION 'How have monthly loan applications trended over the last 12 months?'
      SQL 'SELECT APPLICATION_MONTH, SUM(TOTAL_APPLICATIONS) AS APPLICATIONS, SUM(TOTAL_APPROVALS) AS APPROVALS, ROUND(SUM(TOTAL_APPROVALS) / NULLIF(SUM(TOTAL_APPLICATIONS), 0) * 100, 1) AS APPROVAL_RATE FROM BB_TRAINING.GOLD.GOLD_PORTFOLIO_SUMMARY GROUP BY APPLICATION_MONTH ORDER BY APPLICATION_MONTH DESC LIMIT 12'
    ),

    delinquency_by_product AS (
      QUESTION 'What is the delinquency rate by loan product?'
      SQL 'SELECT LOAN_PRODUCT, COUNT(*) AS TOTAL_LOANS, SUM(CASE WHEN LATE_PAYMENT_COUNT > 0 THEN 1 ELSE 0 END) AS DELINQUENT_LOANS, ROUND(SUM(CASE WHEN LATE_PAYMENT_COUNT > 0 THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS DELINQUENCY_RATE FROM BB_TRAINING.GOLD.GOLD_LOAN_PERFORMANCE GROUP BY LOAN_PRODUCT ORDER BY DELINQUENCY_RATE DESC'
    ),

    delinquency_by_industry AS (
      QUESTION 'Which industry has the highest delinquency rate?'
      SQL 'SELECT c.INDUSTRY, COUNT(*) AS TOTAL_LOANS, SUM(CASE WHEN l.LATE_PAYMENT_COUNT > 0 THEN 1 ELSE 0 END) AS DELINQUENT_LOANS, ROUND(SUM(CASE WHEN l.LATE_PAYMENT_COUNT > 0 THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS DELINQUENCY_RATE FROM BB_TRAINING.GOLD.GOLD_LOAN_PERFORMANCE l JOIN BB_TRAINING.GOLD.GOLD_CUSTOMER_360 c ON l.CUSTOMER_ID = c.CUSTOMER_ID GROUP BY c.INDUSTRY ORDER BY DELINQUENCY_RATE DESC'
    ),

    top_customers_by_exposure AS (
      QUESTION 'Who are the top 10 customers by total exposure?'
      SQL 'SELECT BUSINESS_NAME, INDUSTRY, STATE, TOTAL_EXPOSURE, TOTAL_LOANS, AVG_PAYMENT_HEALTH, CUSTOMER_RISK_CATEGORY FROM BB_TRAINING.GOLD.GOLD_CUSTOMER_360 WHERE TOTAL_EXPOSURE > 0 ORDER BY TOTAL_EXPOSURE DESC LIMIT 10'
    ),

    approval_rate_by_state AS (
      QUESTION 'What is the approval rate by state?'
      SQL 'SELECT STATE, SUM(TOTAL_APPLICATIONS) AS TOTAL_APPLICATIONS, SUM(TOTAL_APPROVALS) AS TOTAL_APPROVALS, ROUND(SUM(TOTAL_APPROVALS) / NULLIF(SUM(TOTAL_APPLICATIONS), 0) * 100, 1) AS APPROVAL_RATE FROM BB_TRAINING.GOLD.GOLD_PORTFOLIO_SUMMARY GROUP BY STATE ORDER BY APPROVAL_RATE DESC'
    )
  );

-- Verify the semantic view was created
DESCRIBE SEMANTIC VIEW BB_TRAINING.GOLD.BB_LENDING_SEMANTIC_VIEW;

-- Test: Show all columns
SHOW COLUMNS IN VIEW BB_TRAINING.GOLD.BB_LENDING_SEMANTIC_VIEW;

-- ============================================================================
-- SEMANTIC VIEW CREATED SUCCESSFULLY!
-- Continue to the SI HOL guide for next steps.
-- ============================================================================
