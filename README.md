# Higher-Education Market Intelligence Model

This project is a sanitized, portfolio-ready implementation of a market intelligence analytics model for the Brazilian higher education sector.

It combines public datasets (Census microdata and regulatory information) with an abstracted commercial overlay to support strategic questions such as:

- Which institutions exist in the market and how they evolve over time
- Which institutions belong to larger educational groups or holdings
- Market whitespace and expansion opportunities
- Course-level growth and cross-sell potential

This repository focuses on architecture, data modeling and analytical reasoning. All proprietary information (clients, contracts, identifiers, internal classifications) has been fully anonymized.


## Key Highlights

- Multi-source integration (public + internal overlay)
- Time-aware modeling (5-year rolling window + historical access)
- Data isolation between public and commercial layers
- Scalable data pipeline pattern using Tableau Prep
- Dashboard-ready analytical views with data blending strategy

---

## 1. Business Problem (abstracted)

A commercial team selling into Brazilian higher-education institutions
needs a single market view that combines:

- **Public market structure.** Every institution (IES — Instituição de
  Ensino Superior) registered with the Ministry of Education, with its
  regulatory metadata, address, academic indicators, faculty/staff
  demographics and quality index (IGC).
- **Public course offering.** Every course offered by every institution,
  with modality (presencial / EAD), area of knowledge, degree level and
  enrollment counts, year by year for the last five censuses.
- **Internal commercial overlay.** For each institution: is it an
  **active**, **inactive** or **non-customer** of the vendor; which
  internal account executive owns it; and which commercial cluster it
  belongs to (driven by group size, holding structure and enrollment).

The analytical questions to answer are:

- **Whitespace analysis.** Which large institutions are not yet customers?
- **Renewal risk.** Which inactive institutions used to be customers and
  are still operating in the market?
- **Group view.** When an institution is part of a larger group or
  holding, what is the consolidated commercial picture?
- **Course-level cross-sell.** Within an existing customer institution,
  which courses or modalities are growing and represent expansion
  opportunities?

---

## 2. Data Sources

### 2.1 Public sources (preserved as-is conceptually)

- **Censup Microdata** (Censo da Educação Superior — INEP).  
  Annual public release. Two file families per year are used:
  - **Institution-level microdata** — one row per IES per census year,
    with regulatory metadata, address, faculty/staff counts and library
    indicators.
  - **Course-level microdata** — one row per course per IES per census
    year, with modality, degree level, area of knowledge, enrollment and
    graduation counts.
  Twelve census years of microdata are loaded in staging (2013–2024).
  The mart layer filters to the five most recent years for the default
  dashboard view; the remaining history stays available for ad-hoc
  analyses. The census year is preserved on every row through the
  `nu_ano_censo` column.

- **e-MEC Public Consultation Portal** (Consulta Pública Avançada).  
  A spreadsheet exported from the public regulatory portal listing every
  institution currently registered with the Ministry of Education,
  including regulatory situation, accreditation type and academic
  organization. This is **not** part of the Censup microdata; it is
  refreshed on an ad-hoc cadence whenever the portal export changes.

- **INEP IGC indicator** (Índice Geral de Cursos).  
  An annual spreadsheet released by INEP with the IGC value and band per
  institution. Eleven editions are loaded (2013–2023, with the year
  matching the census year for downstream joining).

### 2.2 Internal overlay sources (sanitized)

- **Vendor customer & contract list.** Internal CRM/ERP extract of every
  institution that has had a contract with the vendor, with status
  (active / inactive / under renewal). In production this contains the
  real CNPJ and contract codes; in this portfolio it is reduced to a
  neutral `customer_status` enum on a synthetic key.
- **Group / holding cluster definitions.** Internal commercial
  classification used to group institutions that share a controlling
  entity. In production these clusters carry real group names and revenue
  bands; here they are exposed only as opaque labels (`CLUSTER_GROUP_A`,
  `CLUSTER_HOLDING_2`, etc.).
- **Account executive assignment.** Internal sales-rep ownership of each
  group. Sanitized to neutral role handles.

### 2.3 Loading pattern

All sources are landed via three independent **Tableau Prep** flows,
one per analytical domain. Each flow is a declarative pipeline of
`LoadCsv` / `LoadExcel` → unions → (optional join with the customer
overlay) → `WriteToDatabase`. The three flows write to three single
flat tables in the warehouse:

| Flow                       | Inputs                                                                 | Output table                              |
|----------------------------|------------------------------------------------------------------------|-------------------------------------------|
| Institution flow           | 12 years of Censup institution microdata + e-MEC public export + internal customer-base spreadsheet | `raw_censup_institutions` (+ overlay) |
| Course flow                | 12 years of Censup course-level microdata                              | `raw_censup_courses`                      |
| IGC flow                   | 11 years of INEP IGC indicator spreadsheets                            | `raw_inep_igc`                            |

Key operational properties:

- **Write mode: truncate-and-load.** Each scheduled run rebuilds the
  destination table from scratch, so the warehouse is always a pure
  function of the inputs at run time. There is no incremental state to
  reconcile, which keeps the pipeline cheap to reason about.
- **Domain isolation.** A schema change in IGC (e.g. INEP renaming a
  column) is one flow to fix. The institution and course flows are
  unaffected.
- **Editable spreadsheet inputs.** The e-MEC export and the internal
  customer-base file are owned by non-engineering teams. Tableau Prep
  validates schema and types before publishing, so the warehouse only
  sees clean rows. This mirrors the same Excel-→-prep-→-warehouse
  pattern used for the quota and rep-contract feeds in the
  [sales-rep allocation portfolio](../sales-rep-allocation-portfolio/README.md).
- **Long history retained, short window exposed.** The institution and
  course flows carry **12 years** of Censup history (2013–2024). The
  mart layer filters to the **5 most recent census years** for the
  default dashboard, but the full history stays available in staging
  for ad-hoc analyses, retroactive cohort studies and back-testing of
  cluster definitions.

---

## 3. Architecture

The platform follows the same **layered, source-isolated** pattern used
across the other portfolios in this collection.

```
 ┌────────────┐   ┌────────────┐   ┌────────────┐   ┌──────────────┐
 │  raw_*     │ → │  stg_*     │ → │  sup_*     │ → │  vw_/dash_*  │
 │ (landings) │   │ (5y union) │   │ (overlays) │   │   (mart)     │
 └────────────┘   └────────────┘   └────────────┘   └──────────────┘
```

### Layer responsibilities

| Layer       | Prefix       | Purpose                                                                 |
|-------------|--------------|-------------------------------------------------------------------------|
| Raw         | `raw_`       | Per-file landings of public datasets and internal extracts.             |
| Staging     | `stg_`       | Tableau-Prep-produced 5-year unions, schema-conformed.                  |
| Support     | `sup_`       | Quality index, group cluster, holding cluster, IGC by year.             |
| Integration | `int_`       | Vendor-customer-status overlay (sanitized).                             |
| Mart        | `vw_`/`dash_`| Final dashboard surfaces: market institutions and market courses views. |

---

## 4. Modeling Patterns

### 4.1 Public-vs-internal isolation

Every public-data column lives in `stg_higher_ed_*` files. Every
internal-overlay column lives in `int_*` or `sup_*` files. The mart layer
joins them. This means:

- Refreshing public data (a new Censup year) is a `stg_*` change only.
- Refreshing the customer overlay does not touch the public data layer.
- A reviewer can audit exactly which fields come from public sources and
  which come from internal commercial decisions.

### 4.2 Year-aware joins

Most analytical questions are time-aware:

- IGC (Índice Geral de Cursos) is published once per year and is joined
  to the institution row using both `cod_ies` and `ano_igc =
  nu_ano_censo`. This is what allows the dashboard to show IGC trend by
  year on the same surface as the institution metadata.
- The five-year filter on `nu_ano_censo` is enforced in the mart layer,
  not at staging, so that ad-hoc analyses can still go back further.

### 4.3 CNPJ as the join key for the commercial overlay

The internal customer status is joined to the public IES list by a
**normalized CNPJ** (digits only). The normalization happens at join
time using `REGEXP_REPLACE(company_tax_id, r'[^0-9]', '')` to be robust
against formatting differences between the two sides. In this portfolio
the CNPJ values are synthetic; the join logic is preserved exactly.

### 4.4 Two-source dashboard with data blending

The downstream dashboard consumes **two views**:

- [vw_market_institutions](sql/marts/vw_market_institutions.sql) — one row
  per institution per census year.
- [vw_market_courses](sql/marts/vw_market_courses.sql) — one row per
  course per institution per census year.

The two are joined inside Tableau using **data blending** on
`(cod_ies, nu_ano_censo)` rather than a SQL join. This is a deliberate
choice:

- Different grain. The institution view is one-row-per-IES-per-year; the
  course view is much wider. A SQL join would explode the institution
  metrics.
- Different refresh cost. Course-level numbers are heavy; the dashboard
  only needs them when a user drills in. Blending lets the institution
  view stay cheap and only pull course numbers on demand.
- Self-service flexibility. Analysts can swap or extend the secondary
  source without touching the primary mart.

---

## 5. Mart Surfaces

### 5.1 [vw_market_institutions](sql/marts/vw_market_institutions.sql)

Primary dashboard source. One row per IES per census year, with:

- Public regulatory metadata (situation, accreditation, academic
  organization, address, contact, legal representative).
- Public Censup metrics (faculty counts by degree / age / race, library
  indicators, course-portal indicators).
- IGC indicator (continuous + band) for the same census year.
- Anonymized commercial overlay: account executive, group cluster,
  holding cluster, and a vendor-customer status flag (`ACTIVE` /
  `INACTIVE` / `NEVER`).

### 5.2 [vw_market_courses](sql/marts/vw_market_courses.sql)

Secondary dashboard source. One row per course per IES per census year,
with modality, degree level, area of knowledge and enrollment counts.

### 5.3 Data-blending contract

Both views expose `cod_ies` and `nu_ano_censo` as the blending keys. Any
new mart that wants to participate in the dashboard must expose the same
pair.

---

## 6. Why the Solution Scales

- **Public/internal split.** A new Censup year is a single `stg_*`
  change. A new commercial cluster is a single `sup_*` change. Neither
  cascades into the other.
- **Single CNPJ normalization rule.** The `REGEXP_REPLACE` is in exactly
  one place per join site, which means CNPJ-formatting drift on either
  side never silently breaks the customer overlay.
- **Pluggable customer overlay.** The vendor-customer status is one
  table at a known grain. Replacing the source (e.g. CRM migration) only
  needs to publish the same shape; no downstream change is required.
- **Auditability.** Any number on the dashboard can be traced back
  through `dash_/vw_ → int_/sup_ → stg_ → raw_` to either a public
  microdata file or a sanitized internal overlay row.

---

## 7. Repository Layout

```
market-intelligence-portfolio/
├── README.md
├── .gitignore
└── sql/
    ├── raw/
    │   ├── raw_censup_institutions.sql
    │   ├── raw_censup_courses.sql
    │   ├── raw_inep_igc.sql
    │   └── raw_emec_public.sql
    ├── staging/
    │   ├── stg_higher_ed_institutions.sql
    │   └── stg_higher_ed_courses.sql
    ├── support/
    │   ├── sup_institution_quality_index.sql
    │   ├── sup_group_cluster.sql
    │   └── sup_holding_cluster.sql
    ├── integration/
    │   └── int_vendor_customer_status.sql
    └── marts/
        ├── vw_market_institutions.sql
        └── vw_market_courses.sql
```

---

## 8. What Was Sanitized

For full transparency, the following transformations were applied versus
the production model:

| Production concept                          | Portfolio replacement                       |
|---------------------------------------------|---------------------------------------------|
| Real CNPJ values                            | Synthetic 14-digit strings                  |
| Real group / holding names                  | `CLUSTER_GROUP_A`, `CLUSTER_HOLDING_2`, ... |
| Real account executive names                | `Account Exec — Region X`                   |
| Real vendor customer-status values          | `ACTIVE` / `INACTIVE` / `NEVER` enum        |
| Vendor brand name on customer-status field  | Neutral `vendor_customer_status` column     |
| Internal CRM / contract table names         | `int_vendor_customer_status`                |
| Real schema (e.g. `dbhed`)                  | `warehouse_raw` / `warehouse_curated`       |

The public-data column names (Censup, e-MEC) are preserved because they
come from openly published government datasets and are part of the
modeling vocabulary the project is meant to demonstrate.
