-- 99_run_quality_checks.sql
-- Quality checks for analytical view consistency.

-- 1) Duplicates at institution-year level
SELECT
    Cod_IES,
    NU_ANO_CENSO,
    COUNT(*) AS row_count
FROM VW_IES_AGRUPADO_TCC2
GROUP BY Cod_IES, NU_ANO_CENSO
HAVING COUNT(*) > 1;

-- 2) Coverage by year
SELECT
    NU_ANO_CENSO,
    COUNT(DISTINCT Cod_IES) AS ies_count,
    COUNT(*) AS row_count
FROM VW_IES_AGRUPADO_TCC2
GROUP BY NU_ANO_CENSO
ORDER BY NU_ANO_CENSO;

-- 3) IGC null-rate
SELECT
    NU_ANO_CENSO,
    SUM(CASE WHEN igc_continuo IS NULL THEN 1 ELSE 0 END) AS null_igc_rows,
    COUNT(*) AS total_rows,
    SUM(CASE WHEN igc_continuo IS NULL THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS null_igc_rate
FROM VW_IES_AGRUPADO_TCC2
GROUP BY NU_ANO_CENSO
ORDER BY NU_ANO_CENSO;
