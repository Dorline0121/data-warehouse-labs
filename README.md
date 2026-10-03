# Data Warehouse Labs — Dimensional Modeling & Slowly Changing Dimensions

Labs 3 and 4 of the **Advanced Dimensional Modeling** course (Data Warehouse) — ECE Paris, ING4 Data & Artificial Intelligence.

**Author:** Dorline TIAKO OKASSIE
**Stack:** MySQL 8 · phpMyAdmin (WampServer) · SQL (DDL, aggregations, window functions)

---

## 📌 The problem

Operational databases (sales systems, school management systems, TV platforms…) are built to **record** transactions, not to **analyze** them. Answering questions such as *"Which restaurants are the most profitable each month?"* or *"How did a teacher's specialty affect teaching hours over the years?"* on a normalized transactional schema requires slow, complex queries.

These labs address two classic data warehousing problems:

1. **Modeling** — how to restructure business data into **facts** (what we measure) and **dimensions** (how we analyze it), using star, snowflake and galaxy (fact constellation) schemas.
2. **History** — how to handle descriptive attributes that change over time (a student who moves, a teacher who changes specialty, a renamed course) without corrupting historical analysis: **Slowly Changing Dimensions (SCD)**.

## 🎯 Objectives

- Identify the **fact**, the **grain**, the **measures** and the **dimensions** from a business scenario.
- Design **star**, **snowflake** and **galaxy** schemas, and know when each one fits.
- Turn an operational (OLTP) model into a decision-support model.
- Write SQL queries that compute key indicators: totals, averages, rankings (Top-N), month-over-month progression.
- Implement **SCD Type 1, 2 and 3** in SQL and measure their impact on fact tables.

## 🧩 Lab 3 — Star, Snowflake and Galaxy Schemas

| # | Business case | Fact & grain | Solution |
|---|---|---|---|
| 1 | Disposable tableware sales | Sale — product × outlet × month | Star schema: Time, Product, Location dimensions; measures `quantity_sold`, `unit_revenue` |
| 2 | Fast-food chain sales | Sale — food item × restaurant × day | Star schema → snowflake (Day→Week→Month→Year, Restaurant→City→Country, Food→Type→Category) → **galaxy** schema with a second fact table `Fact_Orders` (restaurant × day) |
| 3 | University teaching & results | Grades + teaching load | **Galaxy** schema: `Fact_Grades` and `Fact_TeacherLoad` share `Dim_Course`; star and snowflake versions; SQL for average grade, teaching hours, discharge hours |
| 4 | Exam success factors | Exam taken (anonymous student) | Star and snowflake schemas; pass/fail stored as 0/1 so successes are counted with `SUM(is_passed)` |
| 5 | BreeFox interactive TV | Viewer action | Star schema (Date, Household, Broadcast); queries for cumulative viewing time, Top 10 program types, monthly report with `LAG()` |

**Key design decisions**
- **Separate fact table when the grain differs** (Ex. 2): the number of orders is measured per restaurant × day, so storing it in the item-level sales table would count each order several times.
- **Merging two sources with the same grain** (Ex. 3): `Teach` and `Responsible` both describe teacher × course × year, so they become one fact table with two measures. MySQL has no `FULL OUTER JOIN`, so it is emulated with `LEFT JOIN … UNION ALL`.
- **Additive vs non-additive measures** (Ex. 1): a unit price is never summed; revenue is computed as `SUM(quantity × unit_revenue)`.

## 🕒 Lab 4 — Slowly Changing Dimensions

| Scenario | Change | SCD type applied |
|---|---|---|
| Student moves from Paris to Lyon | Address | Type 1 (overwrite), Type 2 (new version), Type 3 (previous-value column) |
| Teacher changes specialty to AI | Specialty | Type 1 and Type 2 |
| Impact on `Fact_Grades` | — | ETL lookup of the surrogate key valid on the exam date |
| Address / specialty / course name | Choice of type | Type 3 / Type 2 / Type 1 |

**Type 2 implementation:** surrogate key `sk_*`, validity period `date_start` / `date_end`, flag `is_current`. The old row is closed and a new version is inserted in a single transaction.

## 📊 Results

On the sample data loaded by the script:

- **Lab 3, Ex. 3:** average grades per course and date are computed correctly, and a teacher who is responsible for a course without teaching it still appears with 0 teaching hours and 6 discharge hours.
- **Lab 3, Ex. 5:** the monthly report shows information requests going 1 → 2 → 1 (+100 %, −50 %) with a running total.
- **Lab 4:** with SCD Type 2, Alice's 2022 grade stays attached to **Paris** and her 2023 grade to **Lyon**. With Type 1, every grade moves to Lyon, which rewrites history and distorts any analysis by city.

**Takeaways**
- The **grain** drives every other design decision.
- Star schemas favor query speed and simplicity; snowflake schemas reduce redundancy; galaxy schemas link several business processes through shared dimensions.
- Fact tables must reference the **surrogate key**, never the natural key, to keep history consistent.

## 🗂️ Repository structure

```
.
├── README.md
├── sql/
│   └── lab3_lab4_mysql.sql   ← all schemas, sample data and queries (MySQL 8)
└── docs/
    └── report.pdf            ← full lab report (schemas, explanations, answers)
```

## ▶️ How to run

1. Start **WampServer** (MySQL 8 or later; window functions such as `LAG()` are required).
2. Open **phpMyAdmin** → go back to the server home page (no database selected) → **Import** tab.
3. Select `sql/lab3_lab4_mysql.sql` and click **Import**.

The script creates one database per exercise so table names never collide:

`lab3_ex1`, `lab3_ex2`, `lab3_ex2_snowflake`, `lab3_ex3`, `lab3_ex3_snowflake`, `lab3_ex4`, `lab3_ex4_snowflake`, `lab3_ex5`, `lab4_ex1_type1`, `lab4_ex1_type2`, `lab4_ex1_type3`, `lab4_ex2_type1`, `lab4_ex2_type2`

> ⚠️ The script starts each section with `DROP DATABASE IF EXISTS`, so re-running it resets those databases.

## 📚 Context

Lab statements and course slides belong to the course provider and are not included in this repository; the exercises are summarized above in my own words.
