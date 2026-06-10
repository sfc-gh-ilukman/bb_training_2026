---
name: loan-risk-advisor
description: Assess a loan application and provide an approve/decline/review recommendation
  based on customer profile, credit history, and portfolio benchmarks. Use when asked
  to evaluate a loan, assess risk for an application, or advise on whether to approve.
---

# Loan Risk Advisor

When a user asks you to assess a loan application or advise on whether to approve a loan, follow this structured decision framework.

## Step 1: Gather Application Details

Determine from the user's question (or ask if not provided):
- Loan amount
- Loan product type (Term Loan, Line of Credit, Equipment Finance, Commercial Property, Invoice Finance)
- Customer industry
- Credit score (if known)
- Customer state/region

## Step 2: Pull Portfolio Benchmarks

Query the semantic view to get benchmark data:
- Average credit score for the same loan product
- Average approval rate for the same industry
- Average loan size for the same product
- Delinquency rate for the same risk tier and product combination

## Step 3: Assess Against Thresholds

Apply this decision logic:

**Strong Approve (Low Risk):**
- Credit score >= 750
- Loan amount is below average for the product
- Industry delinquency rate < 15%
- Customer has existing loans with good payment health (score > 80)

**Conditional Approve (Medium Risk):**
- Credit score 650-749
- Loan amount is within 1.5x the product average
- Industry delinquency rate < 30%

**Recommend Review (High Risk):**
- Credit score 550-649
- Loan amount exceeds 1.5x product average
- Industry delinquency rate > 30%
- Customer has prior late payments

**Recommend Decline (Very High Risk):**
- Credit score < 550
- Industry + product combination has delinquency > 40%
- Customer has existing loans with payment health < 50

## Step 4: Structure the Response

Present your recommendation in this format:

1. **Recommendation:** [Approve / Conditional Approve / Review / Decline]
2. **Risk Tier:** [Low / Medium / High / Very High]
3. **Key Factors:**
   - Factor 1 (positive or negative)
   - Factor 2
   - Factor 3
4. **Portfolio Context:** How this compares to similar loans in the portfolio
5. **Conditions (if applicable):** What additional requirements or monitoring would you suggest

## Important Notes

- Always show your reasoning - never just say "approve" or "decline" without explaining why
- If information is missing, state what assumptions you're making
- Reference actual portfolio data where possible (average scores, delinquency rates)
- Be specific about numbers - "credit score of 620 is below the portfolio average of 690 for Term Loans"
