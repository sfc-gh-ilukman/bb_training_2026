---
name: early-warning-scan
description: Proactively scan the loan portfolio for at-risk loans showing signs of
  deterioration and suggest intervention actions. Use when asked to find problem loans,
  identify risk, flag concerns, run an early warning scan, or check for loans to worry about.
---

# Early Warning Scan

When a user asks you to identify at-risk loans, flag problems, or scan for early warning signs, follow this structured detection and triage framework.

## Step 1: Define Warning Signals

Scan the portfolio for loans matching these criteria:

**Critical (Immediate Action):**
- Payment health score < 30
- Late payment count >= 5
- Repayment ratio < 10% (barely paying back)

**Warning (Close Monitoring):**
- Payment health score between 30-50
- Late payment count 3-4
- Repayment ratio < 30%

**Watch (Early Signs):**
- Payment health score between 50-65
- Late payment count 1-2
- High-risk tier with above-average loan amount

## Step 2: Identify At-Risk Loans

Query the loan performance data to find loans matching the warning signals above. For each flagged loan, capture:
- Application ID
- Customer name and industry
- Loan amount and product
- Current payment health score
- Number of late payments
- Repayment ratio
- Risk tier

## Step 3: Group by Severity

Organize the flagged loans into the three tiers (Critical / Warning / Watch) and provide a count for each:
- "X loans in Critical, Y loans in Warning, Z loans in Watch"

Show the top 5-10 most concerning loans with their details.

## Step 4: Pattern Analysis

Look for patterns across the flagged loans:
- Are they concentrated in one industry? (e.g., "7 of 10 critical loans are in Hospitality")
- Are they concentrated in one product type?
- Is there a credit score range that's overrepresented?
- Are they mostly recent loans or older ones?

This pattern analysis helps identify systemic vs. isolated issues.

## Step 5: Suggest Interventions

For each severity tier, recommend actions:

**Critical:**
- Immediate outreach to customer
- Review collateral position
- Consider restructuring options
- Escalate to credit committee

**Warning:**
- Schedule customer check-in call
- Increase monitoring frequency
- Review against original risk assessment
- Consider early intervention offers (payment plan adjustments)

**Watch:**
- Flag for next portfolio review
- Monitor for escalation to Warning
- No immediate action needed but track closely

## Step 6: Structure the Output

Present as:

### Early Warning Scan Results

**Summary:** [X] loans flagged across [Y] customers

| Severity | Count | Total Exposure | Top Industry |
|----------|-------|----------------|--------------|
| Critical | | | |
| Warning  | | | |
| Watch    | | | |

**Critical Loans (Top 5):**
(table with details)

**Patterns Detected:**
- [Pattern 1]
- [Pattern 2]

**Recommended Actions:**
1. [Most urgent action]
2. [Second action]
3. [Third action]

## Important Notes

- Always quantify the exposure at risk (dollar amounts)
- Compare flagged loans to total portfolio size for context ("12 loans flagged out of 1,300 = 0.9% of portfolio")
- Don't alarm unnecessarily - distinguish between "normal portfolio noise" and "genuine concern"
- If very few loans are flagged, say so positively: "Portfolio is largely healthy with minimal early warning signals"
