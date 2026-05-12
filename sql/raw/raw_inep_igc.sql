/* =============================================================================
 * raw_inep_igc
 * -----------------------------------------------------------------------------
 * Reference DDL for the INEP IGC indicator landing table.
 *
 * Source: INEP — Índice Geral de Cursos (public annual release).
 *         One spreadsheet per IGC edition, downloaded from the INEP portal.
 *
 * Loading: Tableau Prep flow "Dados IES IGC". Eleven IGC editions
 *          (2013–2023) are unioned during prep and the result is written
 *          to the warehouse in **truncate-and-load** mode.
 *
 * Grain: one row per institution per IGC year.
 *        ano_igc lines up with nu_ano_censo so the mart can join on
 *        (cod_ies, ano_igc = nu_ano_censo) without any year remapping.
 * ============================================================================= */

CREATE TABLE IF NOT EXISTS warehouse_raw.raw_inep_igc (
  cod_ies                     INT64,
  ano_igc                     STRING,    -- IGC edition year (matches nu_ano_censo)
  igc_continuo                FLOAT64,   -- continuous IGC value
  igc_faixa                   INT64,     -- IGC band (1..5)
  inserted_at                 TIMESTAMP
)
;
