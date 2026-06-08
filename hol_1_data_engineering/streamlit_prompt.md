# HOL 1: Build a Streamlit Dashboard with Cortex Code

## Option A: Use Cortex Code (Recommended)

In Snowsight, go to **Projects** → **Streamlit** → **+ Streamlit App**.

Give it a name like `BB_Lending_Dashboard`, select the `BB_TRAINING` database, `GOLD` schema, and `BB_TRAINING_WH` warehouse.

Once the editor opens, **delete all the default code** and use Cortex Code (the AI assistant icon in the bottom-right) with this prompt:

---

### Prompt to paste into Cortex Code:

```
Build me a Streamlit dashboard for a business banking loan portfolio using data from the BB_TRAINING.GOLD schema. Use get_active_session() for the Snowflake connection.

The dashboard should have:

1. A title "Business Banking Loan Portfolio" with a subtitle

2. A row of 4 KPI metric cards showing:
   - Total Portfolio Value (sum of LOAN_AMOUNT from GOLD_LOAN_PERFORMANCE)
   - Approval Rate (from GOLD_PORTFOLIO_SUMMARY)
   - Average Payment Health Score (from GOLD_LOAN_PERFORMANCE)
   - Total Active Customers (count distinct from GOLD_CUSTOMER_360 where TOTAL_LOANS > 0)

3. Two columns side by side:
   - Left: A bar chart showing total loan exposure by INDUSTRY from GOLD_CUSTOMER_360
   - Right: A pie chart showing the distribution of CUSTOMER_RISK_CATEGORY from GOLD_CUSTOMER_360

4. A line chart showing monthly TOTAL_APPLICATIONS and TOTAL_APPROVALS over time from GOLD_PORTFOLIO_SUMMARY (aggregated by APPLICATION_MONTH)

5. A table showing the top 10 customers by TOTAL_EXPOSURE from GOLD_CUSTOMER_360, including BUSINESS_NAME, INDUSTRY, STATE, TOTAL_LOANS, TOTAL_EXPOSURE, and CUSTOMER_RISK_CATEGORY

Format large numbers as abbreviated (e.g., $1.5M, 750K). Use st.metric for the KPI cards.
Use pandas DataFrames from session.sql() queries for the data.
Do not use st.connection(), st.data_editor, or hide_index.
```

---

## Option B: Fallback Script (if Cortex Code isn't working)

If the AI-generated code doesn't work, **replace all code** in the Streamlit editor with the script below:

```python
import streamlit as st
from snowflake.snowpark.context import get_active_session
import pandas as pd

# Page config
st.set_page_config(layout="wide")
st.title("Business Banking Loan Portfolio")
st.caption("SME Lending Division - Portfolio Analytics Dashboard")

# Get Snowflake session
session = get_active_session()

# --- Helper function to format numbers ---
def format_number(num, prefix="", suffix=""):
    if num >= 1_000_000_000:
        return f"{prefix}{num/1_000_000_000:.1f}B{suffix}"
    elif num >= 1_000_000:
        return f"{prefix}{num/1_000_000:.1f}M{suffix}"
    elif num >= 1_000:
        return f"{prefix}{num/1_000:.1f}K{suffix}"
    else:
        return f"{prefix}{num:.0f}{suffix}"

# --- Load Data ---
@st.cache_data
def load_data():
    loan_perf = session.sql("SELECT * FROM BB_TRAINING.GOLD.GOLD_LOAN_PERFORMANCE").to_pandas()
    customer_360 = session.sql("SELECT * FROM BB_TRAINING.GOLD.GOLD_CUSTOMER_360").to_pandas()
    portfolio = session.sql("""
        SELECT APPLICATION_MONTH, 
               SUM(TOTAL_APPLICATIONS) as TOTAL_APPLICATIONS,
               SUM(TOTAL_APPROVALS) as TOTAL_APPROVALS,
               ROUND(SUM(TOTAL_APPROVALS) / NULLIF(SUM(TOTAL_APPLICATIONS), 0) * 100, 1) as APPROVAL_RATE
        FROM BB_TRAINING.GOLD.GOLD_PORTFOLIO_SUMMARY
        GROUP BY APPLICATION_MONTH
        ORDER BY APPLICATION_MONTH
    """).to_pandas()
    return loan_perf, customer_360, portfolio

loan_perf, customer_360, portfolio = load_data()

# --- KPI Cards ---
st.markdown("---")
col1, col2, col3, col4 = st.columns(4)

total_portfolio = loan_perf['LOAN_AMOUNT'].sum()
avg_approval = portfolio['APPROVAL_RATE'].mean()
avg_health = loan_perf['PAYMENT_HEALTH_SCORE'].mean()
active_customers = customer_360[customer_360['TOTAL_LOANS'] > 0].shape[0]

col1.metric("Total Portfolio Value", format_number(total_portfolio, prefix="$"))
col2.metric("Avg Approval Rate", f"{avg_approval:.1f}%")
col3.metric("Avg Payment Health", f"{avg_health:.0f}/100")
col4.metric("Active Customers", format_number(active_customers))

st.markdown("---")

# --- Charts Row 1: Industry Exposure + Risk Distribution ---
chart_col1, chart_col2 = st.columns(2)

with chart_col1:
    st.subheader("Loan Exposure by Industry")
    industry_data = (
        customer_360[customer_360['TOTAL_EXPOSURE'] > 0]
        .groupby('INDUSTRY')['TOTAL_EXPOSURE']
        .sum()
        .sort_values(ascending=True)
        .reset_index()
    )
    st.bar_chart(industry_data, x='INDUSTRY', y='TOTAL_EXPOSURE')

with chart_col2:
    st.subheader("Customer Risk Distribution")
    risk_data = (
        customer_360[customer_360['CUSTOMER_RISK_CATEGORY'] != 'No Loan History']
        .groupby('CUSTOMER_RISK_CATEGORY')
        .size()
        .reset_index(name='COUNT')
    )
    st.bar_chart(risk_data, x='CUSTOMER_RISK_CATEGORY', y='COUNT')

st.markdown("---")

# --- Charts Row 2: Monthly Trend ---
st.subheader("Monthly Application Trend")
portfolio['APPLICATION_MONTH'] = pd.to_datetime(portfolio['APPLICATION_MONTH'])
trend_data = portfolio[['APPLICATION_MONTH', 'TOTAL_APPLICATIONS', 'TOTAL_APPROVALS']].set_index('APPLICATION_MONTH')
st.line_chart(trend_data)

st.markdown("---")

# --- Top Customers Table ---
st.subheader("Top 10 Customers by Exposure")
top_customers = (
    customer_360[customer_360['TOTAL_EXPOSURE'] > 0]
    .nlargest(10, 'TOTAL_EXPOSURE')
    [['BUSINESS_NAME', 'INDUSTRY', 'STATE', 'TOTAL_LOANS', 'TOTAL_EXPOSURE', 'AVG_PAYMENT_HEALTH', 'CUSTOMER_RISK_CATEGORY']]
    .reset_index(drop=True)
)
top_customers['TOTAL_EXPOSURE'] = top_customers['TOTAL_EXPOSURE'].apply(lambda x: f"${x:,.0f}")
st.dataframe(top_customers, use_container_width=True)

# Footer
st.markdown("---")
st.caption("Data sourced from BB_TRAINING.GOLD layer | Built with Streamlit in Snowflake")
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Database not found" | Make sure you selected `BB_TRAINING` database when creating the app |
| "Table does not exist" | You need to complete the pipeline notebook first (HOL 1 Steps 1-4) |
| "Warehouse suspended" | Click the run button again - it auto-resumes |
| App shows no data | Check that your Gold tables have data: `SELECT COUNT(*) FROM BB_TRAINING.GOLD.GOLD_LOAN_PERFORMANCE` |
