# Variable Notes (Core Modeling Set)

## Dependent Variable

- `taxa_evasao`: evasion rate proxy at institution-year level

## Key Explanatory Variables

- `igc_continuo`: institution quality index
- `peso_ead`: share of distance-learning enrollment
- `peso_apoio_social`: share of students with social support
- `peso_ativ_extracur`: share of students in extracurricular activities
- `cat_uni_priv`: private university flag
- `cat_cu_priv`: private university center flag

## Sample Filters Seen in Final Modeling Notebook

- years restricted to 2021-2022 (or 2022 in baseline variant)
- private institutions focus (`cat_priv = 1`)
- non-null IGC
- minimum enrollment threshold (`matriculas > 100`)
