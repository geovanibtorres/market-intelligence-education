# How To Run (Simple, Outside Corporate Environment)

This runbook is designed to work with local public MEC downloads only.

## 1) Prerequisites

- Python 3.11+
- Local folder with MEC files (example used below):
  `C:\Users\xxxx`

## 2) Install dependencies

```bash
pip install -r requirements.txt
```

## 3) Consolidate public MEC files

From the repository root, run:

```bash
python python/consolidate_mec_public_data.py \
  --source-root "C:\Users\xxxx" \
  --output-root data
```

Notes:
- The script excludes private/non-public files using a filename rule.
- It auto-detects separator (`;` or `,`) and handles duplicate year files by selecting the best candidate.
- It also consolidates IGC sources (CSV/XLS/XLSX) when file names include `igc` or `historico_indices_consulta_publica_avancada_ies`.

## 4) Check outputs

Expected outputs:

- `data/manifest_mec_sources.csv`
- `data/manifest_igc_sources.csv`
- `data/bronze/cursos/year=YYYY/data.parquet`
- `data/bronze/ies/year=YYYY/data.parquet`
- `data/bronze/igc/snapshot=*/data.parquet`
- `data/silver/cursos_all_years.parquet`
- `data/silver/ies_all_years.parquet`
- `data/silver/igc_all_years.parquet`

## 5) Next step options

- Option A: Load `silver` parquet files into DuckDB or SQLite for local SQL analysis.
- Option B: Keep this as bronze/silver and plug into modeling directly with pandas.
