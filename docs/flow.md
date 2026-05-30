# Technical Flow

## 1) Aggregation Layer

`CURSOS_MEDIDAS_AGRUPADO_IES` aggregates course-level census metrics to institution-year level.

Inputs:
- course-level table (`EXT_TB_IES_CURSOS_BR` in the original project)
- IGC table (`EXT_TB_IES_IGC_BR`)

Outputs:
- volumes (courses, seats, enrolled, entrants, graduates)
- modality splits (onsite, distance)
- support counts for evasion and student support indicators

## 2) Support Layer

`SUBQUERY_CURSOS_POLOS`
- computes number of municipalities (proxy for poles) by institution-year

`SUBQUERY_INGRESSANTES_TSG2`
- computes lagged entrants by degree group
- supports graduation success rate variable (TSG)

## 3) Analytical View

`VW_IES_AGRUPADO_TCC2`
- combines institution profile + aggregate outcomes + engineered ratios
- includes sample quality flags (`amostra_*`) and model predictors

## 4) Validation Layer

Checks ensure:
- expected panel-year coverage
- IGC linkage completeness
- duplicates at institution-year level

## 5) Modeling Layer (Python)

Dataset extraction from the analytical view, followed by:
- robust linear modeling
- panel FE/RE modeling
- random forest benchmark

Results are exported to `outputs/model_comparison.csv`.
