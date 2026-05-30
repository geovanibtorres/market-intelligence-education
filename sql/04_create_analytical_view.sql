-- 04_create_analytical_view.sql
-- Purpose: Build analytical view used by the Python modeling stage.

CREATE OR REPLACE VIEW VW_IES_AGRUPADO_TCC2 AS
SELECT
    i.Cod_IES,
    i.NU_ANO_CENSO,
    (((d.QT_SIT_TRANCADA + d.QT_SIT_DESVINCULADO + d.QT_SIT_FALECIDO)
      / NULLIF((d.QT_MAT + d.QT_SIT_TRANCADA + d.QT_SIT_DESVINCULADO + d.QT_SIT_FALECIDO), 0)) * 100) AS taxa_evasao,
    CASE WHEN d.TP_CATEGORIA_ADMINISTRATIVA IN ('4', '5', '7') AND d.TP_ORGANIZACAO_ACADEMICA = '1' THEN 1 ELSE 0 END AS cat_uni_priv,
    CASE WHEN d.TP_CATEGORIA_ADMINISTRATIVA IN ('4', '5', '7') AND d.TP_ORGANIZACAO_ACADEMICA = '2' THEN 1 ELSE 0 END AS cat_cu_priv,
    CASE WHEN d.TP_CATEGORIA_ADMINISTRATIVA IN ('4', '5', '7') THEN 1 ELSE 0 END AS cat_priv,
    d.igc_continuo,
    d.QT_MAT AS matriculas,
    d.QT_CURSO AS cursos,
    d.QT_MAT_EAD / NULLIF(d.QT_MAT, 0) AS peso_ead,
    d.QT_MAT_APOIO_SOCIAL / NULLIF(d.QT_MAT, 0) AS peso_apoio_social,
    d.QT_MAT_ATIV_EXTRACURRICULAR / NULLIF(d.QT_MAT, 0) AS peso_ativ_extracur,
    CASE WHEN qyrs.Cod_IES IS NOT NULL THEN 'manter' ELSE 'retirar' END AS amostra_anos2,
    CASE WHEN qigc.CO_IES IS NOT NULL THEN 'retirar' ELSE 'manter' END AS amostra_igc2,
    CASE
        WHEN MIN(d.QT_MAT) OVER (PARTITION BY i.Cod_IES) < 100 THEN 'retirar'
        ELSE 'manter'
    END AS amostra_final_limpa
FROM EXT_TB_IES_BR i
JOIN CURSOS_MEDIDAS_AGRUPADO_IES d
    ON d.CO_IES = i.Cod_IES
   AND d.NU_ANO_CENSO = i.NU_ANO_CENSO
LEFT JOIN SUBQUERY_INGRESSANTES_TSG2 ia
    ON ia.CO_IES = i.Cod_IES
   AND ia.NU_ANO_CENSO = i.NU_ANO_CENSO
LEFT JOIN (
    SELECT Cod_IES
    FROM EXT_TB_IES_BR
    WHERE NU_ANO_CENSO BETWEEN 2021 AND 2022
    GROUP BY Cod_IES
    HAVING COUNT(DISTINCT NU_ANO_CENSO) = 2
       AND MAX(CASE WHEN NU_ANO_CENSO = 2022 THEN 1 ELSE 0 END) = 1
) qyrs
    ON qyrs.Cod_IES = i.Cod_IES
LEFT JOIN (
    SELECT CO_IES
    FROM CURSOS_MEDIDAS_AGRUPADO_IES
    WHERE NU_ANO_CENSO IN (2021, 2022)
      AND igc_continuo IS NULL
    GROUP BY CO_IES
) qigc
    ON qigc.CO_IES = i.Cod_IES
WHERE i.NU_ANO_CENSO IN (2021, 2022);
