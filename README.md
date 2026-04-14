\# Olist E-Commerce SQL Analysis



!\[PostgreSQL](https://img.shields.io/badge/PostgreSQL-17-blue)

!\[SQL](https://img.shields.io/badge/SQL-Advanced-orange)

!\[Status](https://img.shields.io/badge/Status-Completed-green)



\## Project Overview



End-to-end SQL analysis of the \*\*Olist Brazilian E-Commerce dataset\*\* — 100K+ orders,

99K+ customers, 3K+ sellers across 25 months (Sep 2016 – Oct 2018).



Built entirely in \*\*PostgreSQL 17 + pgAdmin\*\*, this project demonstrates production-level

SQL skills including window functions, CTEs, cohort analysis, and RFM segmentation —

the exact techniques tested in FAANG data analyst interviews.



\---



\## Business Questions Answered



| # | Question | File |

|---|---|---|

| 1 | How did Olist grow over 25 months? | `02\_eda\_baseline.sql` |

| 2 | What drives revenue — products, states, payment methods? | `03\_revenue\_analysis.sql` |

| 3 | When do customers shop — peak days and hours? | `04\_order\_funnel.sql` |

| 4 | Who are Olist's most valuable customers? | `05\_customer\_analysis.sql` |

| 5 | Which sellers drive the most revenue and best ratings? | `06\_seller\_analysis.sql` |

| 6 | Which states have the worst delivery performance? | `08\_delivery\_analysis.sql` |

| 7 | Which customer segments should Olist prioritise? | `09\_rfm\_cohort.sql` |

| 8 | What are the top 10 actionable business insights? | `10\_insights\_summary.sql` |



\---



\## Dataset



\*\*Source:\*\* \[Olist Brazilian E-Commerce Dataset — Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)



| Table | Rows | Description |

|---|---|---|

| customers | 99,441 | Customer details and location |

| orders | 99,441 | Order status and timestamps |

| order\_items | 112,650 | Products, sellers, prices per order |

| order\_payments | 103,886 | Payment type and instalments |

| order\_reviews | 99,224 | Customer review scores and comments |

| products | 32,951 | Product dimensions and categories |

| sellers | 3,095 | Seller location details |

| geolocation | 1,000,163 | ZIP code coordinates |

| product\_category\_name\_translation | 71 | Portuguese to English category names |



\---



\## SQL Techniques Used



| Technique | Where Used |

|---|---|

| CTEs (WITH clause) | All analysis files |

| Window functions — RANK, DENSE\_RANK | `06\_seller\_analysis.sql`, `07\_window\_functions.sql` |

| Window functions — LAG, LEAD | `07\_window\_functions.sql`, `03\_revenue\_analysis.sql` |

| Window functions — NTILE | `07\_window\_functions.sql`, `09\_rfm\_cohort.sql` |

| PARTITION BY | `07\_window\_functions.sql` |

| Running totals + rolling averages | `03\_revenue\_analysis.sql` |

| RFM segmentation | `09\_rfm\_cohort.sql` |

| Cohort retention analysis | `09\_rfm\_cohort.sql` |

| Date arithmetic | `08\_delivery\_analysis.sql` |

| CASE WHEN segmentation | Multiple files |

| Multi-table JOINs (5+ tables) | Multiple files |

| Subqueries + nested CTEs | `07\_window\_functions.sql` |

| NULL handling with COALESCE, NULLIF | Multiple files |

| Aggregate filtering with HAVING | Multiple files |



\---



\## Project Structure

olist-ecommerce-sql-analysis/

├── README.md

├── schema/

│   └── schema.sql                    ← Database schema, all 9 tables

├── analysis/

│   ├── 01\_data\_quality.sql           ← FK validation, NULL audit

│   ├── 02\_eda\_baseline.sql           ← Business snapshot, monthly trends

│   ├── 03\_revenue\_analysis.sql       ← GMV, YoY growth, payment methods

│   ├── 04\_order\_funnel.sql           ← Order status, peak hours, categories

│   ├── 05\_customer\_analysis.sql      ← Segments, LTV, city breakdown

│   ├── 06\_seller\_analysis.sql        ← Rankings, tiers, review scores

│   ├── 07\_window\_functions.sql       ← RANK, LAG, LEAD, NTILE, PARTITION BY

│   ├── 08\_delivery\_analysis.sql      ← Late rates, state analysis, routes

│   ├── 09\_rfm\_cohort.sql             ← RFM scoring, cohort retention

│   └── 10\_insights\_summary.sql       ← 10 key business insights

└── exports/

└── (CSV snapshots of key results)

\---



\## Key Findings



\### 1. Retention crisis — 96.95% of customers never return

\- One-time buyers: 92,507 (96.95%) — avg spend R$138

\- Repeat buyers: 2,673 (2.80%) — avg spend R$248

\- Loyal buyers 3x+: 240 (0.25%) — avg spend R$422

\- \*\*Recommendation:\*\* Launch a loyalty program — loyal buyers spend 3x more



\### 2. Black Friday is the biggest revenue event

\- November 2017: R$1,010,271 — 52% MoM growth

\- Late delivery rate spiked to 14.31% that month

\- \*\*Recommendation:\*\* Begin logistics preparation 2 months before Black Friday



\### 3. São Paulo concentration risk

\- SP = 41% of all orders, 60% of all sellers, R$5.2M revenue

\- Top 3 states (SP, RJ, MG) = 65% of total revenue

\- \*\*Recommendation:\*\* Incentivise sellers in RS, BA, PR to reduce concentration



\### 4. Northeast Brazil is severely underserved

\- AL: 23.93% late rate, 24 days avg delivery

\- SP: 5.89% late rate, 8 days avg delivery — 3x faster

\- \*\*Recommendation:\*\* Open fulfilment centre in Recife or Salvador



\### 5. Health \& beauty is the crown jewel category

\- R$1.25M revenue — #1 in 17 of 27 Brazilian states

\- Lowest freight ratio (14.5%) — highest margin potential

\- \*\*Recommendation:\*\* Prioritise expanding health \& beauty seller base



\### 6. Instalment culture drives higher AOV

\- 1 instalment: R$96 avg order value

\- 10 instalments: R$415 avg order value — 4.3x more

\- \*\*Recommendation:\*\* Partner with more banks for flexible instalment options



\### 7. Platinum sellers are too concentrated

\- 18 platinum sellers generate 19% of platform revenue

\- Losing one = \~R$150K average revenue loss

\- \*\*Recommendation:\*\* Dedicated account managers for platinum sellers



\### 8. Olist over-promises and over-delivers

\- Estimated delivery: 23 days — Actual delivery: 12 days

\- Delivering 11 days earlier than promised (91.89% on time)

\- \*\*Recommendation:\*\* Market fast delivery as a competitive advantage



\### 9. Low-rated high-revenue sellers are a brand risk

\- Itaquaquecetuba seller: R$188K revenue but 3.35 rating

\- Campinas seller: R$41K revenue, 2.71 rating — critically poor

\- \*\*Recommendation:\*\* Minimum 3.5 rating threshold for active sellers



\### 10. Champions segment is the revenue backbone

\- Champions: 24.70% of customers → 47.77% of revenue

\- Champions avg spend R$275 vs R$29 for lost customers — 9.6x more

\- \*\*Recommendation:\*\* VIP program with early access and exclusive deals



\---



\## How to Reproduce



\### Prerequisites

\- PostgreSQL 17

\- pgAdmin 4

\- Olist dataset from Kaggle



\### Steps

1\. Clone this repository

2\. Run `schema/schema.sql` to create all 9 tables

3\. Download CSVs from Kaggle and load using COPY commands in schema.sql

4\. Run analysis files in order (01 through 10)



\---



\## About



\*\*Author:\*\* Soham Mukherjee

\*\*Tools:\*\* PostgreSQL 17, pgAdmin 4

\*\*Dataset:\*\* Olist Brazilian E-Commerce (Kaggle)

\*\*Project Type:\*\* Portfolio — Data Analyst



\*Part of an ongoing DS/ML portfolio. Project 1: Churn Prediction MLOps.\*

