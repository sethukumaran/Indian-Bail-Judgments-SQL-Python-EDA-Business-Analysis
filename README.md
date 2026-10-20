# Indian Bail Judgments — SQL + Python EDA & Business Analysis

## 1. Project overview

This project performs a senior-analyst style exploratory and business-level analysis of the supplied **Indian Bail Judgments** dataset.

The workflow intentionally starts with **EDA in Python**, then uses **SQL** for reproducible aggregation and business questions, followed by visualization and an executive interpretation of the results.

> **Important:** This is an analytical study of the supplied dataset. It is **not legal advice**, does not determine whether any individual judicial decision was legally correct, and observed associations should not be interpreted as causal effects.

## 2. Dataset snapshot

- **Rows:** 1,200
- **Columns:** 23 analytical source columns (the Python workflow creates helper date/outcome fields)
- **Date range:** 1975-08-18 to 2025-06-02
- **Courts:** 78
- **Judges:** 573
- **Regions:** 28
- **Crime types:** 12
- **Distinct case IDs:** 1,200
- **Duplicate rows:** 0
- **Duplicate case IDs:** 0
- **Missing cells:** 0

### Data-quality flags

1. `prior_cases` contains **Unknown** for 48.6% of records. This materially limits interpretation of prior-record effects.
2. Only **13** rows have `bias_flag = True`; this flag is too sparse to be treated as a reliable standalone fairness metric.
3. The dataset contains a long historical tail before 2016 (181 cases), while the bulk of observations are from 2016 onward (1019 cases). Trend comparisons therefore focus on 2016–2025.
4. Several bail-type categories have very small sample sizes (`Unknown`, `Not applicable`, `Others`) and should not drive decisions.

## 3. Business / analytical questions

- What is the overall bail grant vs rejection profile?
- How has the grant rate changed over time?
- Which crime categories show higher/lower grant rates?
- Which courts have materially different grant rates after applying a minimum sample threshold?
- How do prior-case status, bail type, accused gender, parity arguments, landmark status and cancellation cases relate to outcomes?
- Which language signals in judgment text are associated with granted vs rejected outcomes?
- What data-quality issues should be addressed before building a predictive or fairness-monitoring system?

## 4. Executive findings

### Outcome profile

The overall bail grant rate is **61.3%**, versus **38.7%** rejected.

### Time trend

Among the better-populated period **2016–2025**, the grant rate moved from **44.4%** in 2016 to **74.2%** in 2025. This is descriptive and should not be read as a causal trend in judicial behavior.

### Crime-type differentiation

Highest grant-rate categories in this dataset:

- **Cyber Crime** — 116 cases; 89.7% grant rate
- **Domestic Violence** — 72 cases; 80.6% grant rate
- **Kidnapping** — 95 cases; 72.6% grant rate

Lowest grant-rate categories:

- **Narcotics** — 134 cases; 48.5% grant rate
- **Fraud or Cheating** — 121 cases; 45.5% grant rate
- **Murder** — 89 cases; 40.4% grant rate

This is one of the strongest operational segmentation signals in the dataset, but category composition and case severity may differ substantially.

### Court-level variation

Using a **minimum threshold of 20 cases** to reduce small-sample volatility, the highest observed court grant rates were:

- **Madhya Pradesh High Court** — 52 cases; 78.8%
- **Punjab and Haryana High Court** — 130 cases; 77.7%
- **Kerala High Court** — 30 cases; 76.7%

The lowest among courts meeting that threshold were:

- **Supreme Court of India** — 47 cases; 51.1%
- **Gujarat High Court** — 48 cases; 47.9%
- **Delhi High Court** — 109 cases; 47.7%

These differences are **descriptive**, not proof of court-level bias. Court mix, offence mix, geography, procedural posture, case selection and judge assignment can all contribute.

### Prior-case status

- **No prior cases:** 80.6% grant rate
- **Unknown:** 61.7%
- **Yes:** 50.4%

The gradient is substantively large, but the high Unknown share means data completeness should be improved before using this field in a decision-support model.

### Parity argument

Cases where a parity argument was marked as used had a **77.1%** grant rate versus **55.1%** where it was not marked.

This is a strong descriptive association and suggests parity/co-accused treatment is an important analytical feature in this corpus. It should not be interpreted as “parity causes bail.”

### Gender

Female accused cases had a **69.9%** grant rate versus **60.3%** for male accused cases. Because the female sample is much smaller, this should be monitored with confidence intervals and controls for crime type, court and other case characteristics before making any fairness conclusion.

### Cancellation / landmark status

- Bail-cancellation cases: **43.1%** grant rate vs **63.3%** for non-cancellation cases.
- Landmark cases: **48.3%** grant rate vs **63.2%** for non-landmark cases.

These variables likely identify substantively different case populations, so direct comparisons should be interpreted cautiously.

### Text signals

Selected judgment terms show strong outcome associations. For example, cases containing terms such as **parity, custody, charge sheet, delay** tend to have higher grant rates, while terms such as **seriousness** and **gravity** are associated with much lower grant rates in this corpus.

These are **keyword proxies**, not semantic causal explanations. A proper NLP stage should use sentence-level context, embeddings/topic models or supervised text classification rather than simple keyword matching.

## 5. Visualizations

The repository contains these generated outputs under `outputs/`:

1. `01_outcome_distribution.png`
2. `02_annual_grant_rate.png`
3. `03_crime_type_grant_rate.png`
4. `04_court_grant_rate_min20.png`
5. `05_prior_cases_grant_rate.png`
6. `06_parity_argument_grant_rate.png`
7. `07_gender_grant_rate.png`
8. `08_text_signal_grant_rate.png`

## 6. SQL analysis

`analysis.sql` contains SQLite-compatible queries covering:

- Dataset profiling
- Outcome mix
- Annual trend
- Crime-type grant rate
- Court-level grant rate with minimum sample size
- Prior-case status
- Parity argument
- Bail type
- Gender
- Cancellation/landmark intersections
- Regional comparison
- Data-quality audit
- Text-keyword proxy analysis

## 7. Python analysis

`analysis.py` performs:

1. File ingestion
2. **EDA as the initial step**
3. Data-type and missing-value audit
4. Duplicate checks
5. Date parsing and helper features
6. Business KPI calculations
7. Segment-level outcome analysis
8. Text-signal analysis
9. Eight publication-ready PNG visualizations

# 8. Key business findings
# Bail outcomes are highly heterogeneous.
The overall grant rate is 61.3%, but it varies substantially by crime type, court, prior-case status and procedural characteristics.

# Crime type is one of the strongest segmentation dimensions.
- Cyber Crime: 89.7% grant
- Domestic Violence: 80.6%
- Kidnapping: 72.6%
- Narcotics: 48.5%
- Fraud/Cheating: 45.5%
- Murder: 40.4%
This indicates that a single overall bail-rate KPI hides substantial case-mix differences.

# Parity is a major descriptive signal.
Cases where a parity argument was recorded had a 77.1% grant rate, compared with 55.1% where parity was not recorded — a difference of roughly 22 percentage points.

This should be interpreted as an association, not as evidence that the parity argument itself caused the outcome.

# Prior criminal-case status shows a strong gradient.
- No prior cases: 80.6%
- Unknown: 61.7%
- Prior cases = Yes: 50.4%
However, the 48.6% Unknown rate is a major data-quality limitation.

# Court-level variation is material.
After requiring at least 20 cases per court:
- Madhya Pradesh High Court: 78.8%
- Punjab & Haryana High Court: 77.7%
- Kerala High Court: 76.7%
At the lower end:
- Delhi High Court: 47.7%
- Gujarat High Court: 47.9%
- Supreme Court of India: 51.1%
These differences must not be interpreted as court bias without controlling for case mix, offence type, procedural posture, judge allocation, etc.

# Temporal pattern:
For the better-populated period from 2016 onward, the grant rate generally moved upward, reaching 74.2% in 2025 versus 44.4% in 2016. The historical years before 2016 have relatively small samples, so I excluded them from the main trend visualization.

## 9. Recommended next analytical phase

For a production-grade legal analytics project, the next stage should be:

1. **Data normalization:** standardize court names, regions, crime taxonomy and bail types.
2. **Missingness strategy:** distinguish true “Unknown” from missing/not-applicable.
3. **Statistical uncertainty:** add confidence intervals and significance tests for segment comparisons.
4. **Multivariate modeling:** estimate adjusted associations while controlling for court, offence type, bail type, prior cases, procedural posture and year.
5. **Fairness analysis:** compare error rates and outcome disparities only after controlling for legitimate case-mix differences.
6. **NLP:** extract legal factors from `judgment_reason`, `legal_issues`, `facts` and `summary` using contextual NLP rather than keywords alone.
7. **Model governance:** document leakage risks, explainability, human review, and the prohibition on using a model as a substitute for judicial/legal judgment.

## 10. Conclusion

The dataset shows a **61.3% overall bail grant rate**, with substantial variation across crime type, court, prior-case status, parity arguments and textual reasoning signals. The strongest business-level takeaway is that bail outcomes are **highly heterogeneous rather than uniform**: segmentation by case characteristics reveals materially different outcome profiles.

At the same time, the analysis identifies important limitations—especially the **48.6% Unknown rate for prior-case status**, small samples in some categories, and the observational nature of the data. Therefore, the findings are best used for **descriptive legal analytics, research prioritization, data-quality improvement and dashboarding**, not as a standalone mechanism for predicting or recommending judicial outcomes.

A mature next version should combine SQL-based monitoring with controlled statistical modeling and contextual NLP, while explicitly separating **descriptive association from legal causation or fairness claims**.
