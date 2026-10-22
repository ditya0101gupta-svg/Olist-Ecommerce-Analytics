# Olist E-Commerce Intelligence — Streamlit

A one-page, interactive Olist dashboard with business KPIs, sales charts, and four exploratory statistical hypothesis tests.

## Run locally

```bash
pip install -r requirements.txt
streamlit run app.py
```

The app reads pre-aggregated `orders.csv.gz` and `items.csv.gz` (included). It does not require the original large raw files to run.

## Rebuild processed data

Place the original Olist CSV files in `raw/`, then run `python build_data.py`. Raw files are not included in the deployment package.

## Tests

- Spearman: delivery time vs review score
- Mann–Whitney U: order value for repeat vs one-time customers
- Chi-square: delay status vs customer state
- Kruskal–Wallis: order value vs primary payment method

These are exploratory, observational tests, not causal inference. Group membership and sample sizes change with filters. Delays are evaluated at calendar-date resolution.

## Deployment

Push the contents of this folder to a GitHub repository. In Streamlit Community Cloud, select the repo, branch and `app.py` as entrypoint, then deploy. No Power BI Service account is needed.
