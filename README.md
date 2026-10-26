# Food Delivery Analytics (MySQL)

End-to-end SQL analytics project on a food-delivery business: relational schema design, a synthetic Indian-market data generator, and window-function / CTE queries answering real business questions (revenue trends, margins, retention, referrals).

**Stack:** MySQL 8.0 · Python 3 (data generation) · optional Power BI / Tableau for dashboards

> **Data & attribution:** All data is **synthetic**, produced by `generator/generate_dataset.py`. The 4-table layout (customers / orders / order_item / product) is inspired by the open-source [johorodnyk/food-dataset](https://github.com/johorodnyk/food-dataset) (BSD-3-Clause). Schema details, columns, data and queries here are my own.

## Schema
See [`docs/er_diagram.md`](docs/er_diagram.md) and [`docs/data_dictionary.md`](docs/data_dictionary.md).

| Table | Rows | Grain |
|---|---|---|
| customers | 600 | one per customer (self-referencing `referred_by`) |
| product | 30 | one per menu item |
| orders | 4,000 | one per order (Jan 2025 - Sep 2026) |
| order_item | 11,977 | one per order line |

## How to run
Requires MySQL 8.0.16+ (window functions, CHECK constraints).
```bash
git clone <your-repo-url> && cd india-food-analytics
mysql --local-infile=1 -u root -p < sql/01_schema_mysql.sql
mysql --local-infile=1 -u root -p < sql/02_load_mysql.sql   # run from repo root
mysql -u root -p < sql/03_analysis_mysql.sql
```
If `LOAD DATA LOCAL` is blocked: `SET GLOBAL local_infile = 1;` as admin.
Regenerate data (optional): `python generator/generate_dataset.py`

## Repository layout
```
data/        4 CSVs
sql/         01 schema · 02 load · 03 analysis queries
generator/   synthetic data generator (seeded, reproducible)
docs/        ER diagram, data dictionary
images/      dashboard / result screenshots
```

## SQL techniques used
CTEs · window functions (`LAG`, `DENSE_RANK`, moving average via `ROWS BETWEEN`, `SUM() OVER ()`) · self-join/self-reference · conditional aggregation · cohort analysis with `TIMESTAMPDIFF` · `CASE` bucketing · `LOAD DATA` with `NULLIF` cleaning · indexing & FK constraints.

## Key findings (from the generated dataset)
| Metric | Result |
|---|---|
| Total revenue | ₹20.12 lakh across 4,000 orders; **AOV ≈ ₹503** |
| Top products by revenue | Butter Chicken (₹1.57 L), Chicken Biryani (₹1.47 L), Saoji Chicken (₹1.39 L) |
| Highest margin items | Fresh Lime Soda (80%), Butter Roti and Filter Coffee (73%) vs ~50% for main-course curries |
| Top category | Main Course (₹5.23 L), then Rice and Starters |
| Payment mix | UPI 54.7%, COD 19.9%, Card 19.0%, Wallet 6.4% |
| Demand pattern | Weekends carry 36% of orders (vs 28.6% if uniform); revenue peaks in Oct-Nov and grows over time as the customer base grows |
| Busiest city | Bengaluru (588 orders), then Delhi (500); Mumbai has the highest AOV among the top 3 (₹513) |
| Ratings | Avg 4.01; 64.5% of orders rated 4-5; 14.4% unrated |

**Limitations (be honest in interviews):** the data is synthetic, so some real-world effects are absent by design. Repeat-customer rate (92.5%) is higher than a real platform's, and referred vs organic customers order at the same rate (about 6.6 orders each) because the generator doesn't model a referral effect.

## Possible extensions
- Power BI / Tableau dashboard (add screenshots to `images/`)
- Churn query (no order in last 60 days), RFM segmentation
- `EXPLAIN` before/after index optimisation write-up
- Stored procedure for monthly KPI snapshot

