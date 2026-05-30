# Consolidation Strategies (Public Data)

## Strategy 1: Bronze/Silver Parquet (Recommended)

Use `python/consolidate_mec_public_data.py`.

Pros:
- reproducible outside corporate systems
- portable files (Parquet)
- easy to query with pandas/DuckDB

Cons:
- requires local preprocessing step

## Strategy 2: DuckDB-First Local Warehouse

Load MEC CSV directly into DuckDB tables and build views there.

Pros:
- SQL-first local workflow
- no server needed
- very fast for analytics

Cons:
- requires SQL adaptation from MySQL syntax

## Strategy 3: Notebook-Only Direct CSV Reads

Read yearly CSV files directly in notebooks/scripts and transform in memory.

Pros:
- fastest to start
- low setup overhead

Cons:
- weaker governance/reproducibility
- repeated logic across notebooks

## Practical Recommendation

- Start with Strategy 1 for stable base layers.
- Use DuckDB on top of parquet when you want local SQL speed.
- Keep notebook-only mode for quick exploration, not for the final productionized flow.
