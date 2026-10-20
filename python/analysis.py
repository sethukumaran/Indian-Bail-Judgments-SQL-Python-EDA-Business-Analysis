"""
Indian Bail Judgments — EDA and Business Analysis

"""

import argparse, os, re
import pandas as pd
import matplotlib.pyplot as plt

parser = argparse.ArgumentParser()
parser.add_argument("--input", default="Indian-Bail-Judgments new.csv")
parser.add_argument("--output-dir", default="outputs")
args = parser.parse_args()

os.makedirs(args.output_dir, exist_ok=True)
df = pd.read_csv(args.input)

# ---------------- EDA FIRST ----------------
print("=== DATASET SHAPE ===")
print(df.shape)
print("\n=== DATA TYPES ===")
print(df.dtypes)
print("\n=== MISSING VALUES ===")
print(df.isna().sum().sort_values(ascending=False))
print("\n=== DUPLICATES ===")
print("duplicate rows:", df.duplicated().sum())
print("duplicate case_id:", df["case_id"].duplicated().sum())

df["date_dt"] = pd.to_datetime(df["date"], errors="coerce")
df["year"] = df["date_dt"].dt.year
df["granted"] = (df["bail_outcome"] == "Granted").astype(int)

print("\n=== DATE RANGE ===")
print(df["date_dt"].min(), "to", df["date_dt"].max())
print("\n=== CATEGORICAL CARDINALITY ===")
for c in df.select_dtypes(include="object").columns:
    print(c, df[c].nunique())

print("\n=== OUTCOME ===")
print(df["bail_outcome"].value_counts())
print("\n=== KEY CROSSTABS ===")
for c in ["bail_type", "accused_gender", "prior_cases", "crime_type",
          "bail_cancellation_case", "landmark_case", "parity_argument_used",
          "bias_flag"]:
    x = pd.crosstab(df[c], df["bail_outcome"])
    x["grant_rate_pct"] = x.get("Granted", 0) / x.sum(axis=1) * 100
    print("\n", c)
    print(x.sort_values("grant_rate_pct", ascending=False))

# ---------------- BUSINESS OUTPUTS ----------------
def rate_table(col):
    x = df.groupby(col).agg(cases=("case_id","size"), granted=("granted","sum")).reset_index()
    x["grant_rate_pct"] = x["granted"] / x["cases"] * 100
    return x

crime = rate_table("crime_type").sort_values("grant_rate_pct", ascending=False)
court = rate_table("court")
court20 = court[court.cases >= 20].sort_values("grant_rate_pct", ascending=False)
year = df.groupby("year").agg(cases=("case_id","size"), granted=("granted","sum")).reset_index()
year["grant_rate_pct"] = year.granted / year.cases * 100
recent = year[year.year >= 2016]

print("\n=== EXECUTIVE KPIs ===")
print("Cases:", len(df))
print("Grant rate:", round(df.granted.mean()*100, 2), "%")
print("Rejection rate:", round((1-df.granted.mean())*100, 2), "%")
print("Prior-case Unknown:", round(df.prior_cases.eq("Unknown").mean()*100, 2), "%")

print("\n=== TOP CRIME TYPES BY GRANT RATE ===")
print(crime[["crime_type","cases","grant_rate_pct"]].to_string(index=False))
print("\n=== COURTS WITH >=20 CASES ===")
print(court20[["court","cases","grant_rate_pct"]].to_string(index=False))

# ---------------- CHARTS ----------------
def save(fig, name):
    fig.tight_layout()
    fig.savefig(os.path.join(args.output_dir, name), dpi=180)
    plt.close(fig)

counts = df.bail_outcome.value_counts().reindex(["Granted","Rejected"])
fig, ax = plt.subplots(figsize=(10,6))
counts.plot(kind="bar", ax=ax)
ax.set_title("Bail Outcome Distribution"); ax.set_xlabel("Outcome"); ax.set_ylabel("Cases")
save(fig, "01_outcome_distribution.png")

fig, ax = plt.subplots(figsize=(10,6))
ax.plot(recent.year, recent.grant_rate_pct, marker="o")
ax.set_title("Annual Bail Grant Rate (2016–2025)")
ax.set_xlabel("Year"); ax.set_ylabel("Grant rate (%)"); ax.set_ylim(0,100)
save(fig, "02_annual_grant_rate.png")

tmp = crime.sort_values("grant_rate_pct")
fig, ax = plt.subplots(figsize=(10,6))
ax.barh(tmp.crime_type, tmp.grant_rate_pct)
ax.set_title("Bail Grant Rate by Crime Type"); ax.set_xlabel("Grant rate (%)"); ax.set_xlim(0,100)
save(fig, "03_crime_type_grant_rate.png")

tmp = court20.sort_values("grant_rate_pct")
fig, ax = plt.subplots(figsize=(10,8))
ax.barh(tmp.court, tmp.grant_rate_pct)
ax.set_title("Court-Level Grant Rate (Courts with ≥20 Cases)")
ax.set_xlabel("Grant rate (%)"); ax.set_xlim(0,100)
save(fig, "04_court_grant_rate_min20.png")

for col, fname, title in [
    ("prior_cases","05_prior_cases_grant_rate.png","Grant Rate by Prior Case Status"),
    ("parity_argument_used","06_parity_argument_grant_rate.png","Grant Rate by Parity Argument"),
    ("accused_gender","07_gender_grant_rate.png","Bail Grant Rate by Accused Gender"),
]:
    tmp = rate_table(col).sort_values("grant_rate_pct")
    fig, ax = plt.subplots(figsize=(10,6))
    ax.barh(tmp[col].astype(str), tmp.grant_rate_pct)
    ax.set_title(title); ax.set_xlabel("Grant rate (%)"); ax.set_xlim(0,100)
    save(fig, fname)

text = (df.judgment_reason.fillna("") + " " + df.legal_issues.fillna("") + " " + df.summary.fillna("")).str.lower()
terms = ["parity","custody","antecedent","charge sheet","investigation","recovery",
         "evidence","delay","co-accused","clean antecedent","seriousness","gravity"]
rows = []
for term in terms:
    m = text.str.contains(re.escape(term), regex=True, na=False)
    rows.append((term, m.sum(), df.loc[m,"granted"].mean()*100))
t = pd.DataFrame(rows, columns=["keyword","cases","grant_rate_pct"]).sort_values("grant_rate_pct")
fig, ax = plt.subplots(figsize=(10,7))
ax.barh(t.keyword, t.grant_rate_pct)
ax.set_title("Grant Rate for Cases Containing Selected Judgment Terms")
ax.set_xlabel("Grant rate (%)"); ax.set_xlim(0,100)
save(fig, "08_text_signal_grant_rate.png")
