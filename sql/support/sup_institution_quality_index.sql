/* =============================================================================
 * sup_institution_quality_index
 * -----------------------------------------------------------------------------
 * IGC (Índice Geral de Cursos) per institution per year, sourced from the
 * public INEP indicator release.
 *
 * Production loading: Tableau Prep flow "Dados IES IGC" — unions eleven
 * yearly IGC spreadsheets (2013–2023) into a single flat table and
 * writes it to the warehouse in **truncate-and-load** mode.
 *
 * Grain: (cod_ies, ano_igc).
 *
 * Used by vw_market_institutions to attach the IGC indicator to the
 * matching census year (ano_igc = nu_ano_censo).
 * ============================================================================= */

SELECT
  cod_ies,
  ano_igc,
  igc_continuo,                  -- numeric IGC value
  igc_faixa                      -- IGC band (1..5)
FROM warehouse_raw.raw_inep_igc
;
