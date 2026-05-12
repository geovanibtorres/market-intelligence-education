/* =============================================================================
 * raw_emec_public
 * -----------------------------------------------------------------------------
 * Reference DDL for the e-MEC public consultation landing table.
 *
 * Source: e-MEC — Consulta Pública Avançada
 *         (public regulatory portal of the Ministry of Education).
 *         Spreadsheet exported from the portal on an ad-hoc cadence.
 *
 * Loading: Tableau Prep flow "Dados IES" (joined inside the institution
 *          flow). The export is normalized into the schema below and
 *          joined to the most recent Censup year in
 *          stg_higher_ed_institutions.sql to enrich regulatory metadata.
 *          Write mode: **truncate-and-load**.
 * ============================================================================= */

CREATE TABLE IF NOT EXISTS warehouse_raw.raw_emec_public (
  cod_ies                     INT64,
  nome_ies                    STRING,
  sigla_ies                   STRING,
  cod_mantenedora             INT64,
  razao_social                STRING,
  company_tax_id              STRING,    -- CNPJ as published; sanitized in this portfolio
  data_criacao_ies            DATE,
  tipo_credenciamento         STRING,
  categoria                   STRING,
  cat_administrativa          STRING,
  natureza_juridica           STRING,
  organizacao_academica       STRING,
  situacao_ies                STRING,    -- regulatory situation
  sinalizacoes_vigentes       STRING,    -- active regulatory flags
  telefone                    STRING,
  sitio                       STRING,
  email                       STRING,
  representante_legal         STRING,
  reitor_dirigente_principal  STRING,
  inserted_at                 TIMESTAMP
)
;
