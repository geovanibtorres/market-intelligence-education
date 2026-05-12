/* =============================================================================
 * raw_censup_institutions
 * -----------------------------------------------------------------------------
 * Reference DDL for the institution-level Censup microdata landing table.
 *
 * Source: INEP — Censo da Educação Superior (public annual release).
 *         One CSV per census year, downloaded from the INEP portal.
 *
 * Loading: Tableau Prep flow "Dados IES". Twelve census years (2013–2024)
 *          are unioned during prep and the result is written to the
 *          warehouse in **truncate-and-load** mode. The census year is
 *          preserved on every row through nu_ano_censo. The downstream
 *          mart filters to the five most recent census years for the
 *          default dashboard window.
 *
 * Note: column names below mirror the public Censup schema; they are part
 *       of the published government dataset and are preserved as-is.
 * ============================================================================= */

CREATE TABLE IF NOT EXISTS warehouse_raw.raw_censup_institutions (
  nu_ano_censo                STRING,    -- census year (e.g. '2024')
  cod_ies                     INT64,     -- institution code (INEP)
  nome_ies                    STRING,    -- institution legal name
  sg_ies                      STRING,    -- institution short name / acronym
  sg_uf                       STRING,    -- state (UF)
  municipio                   STRING,    -- city
  cat_administrativa          STRING,    -- public / private / community / etc.
  organizacao_academica       STRING,    -- university / college / institute
  ds_endereco_ies             STRING,
  ds_numero_endereco_ies      STRING,
  ds_complemento_endereco_ies STRING,
  no_bairro_ies               STRING,
  nu_cep_ies                  STRING,

  -- Library / portal indicators
  in_acesso_portal_capes        BOOL,
  in_acesso_outras_bases        BOOL,
  in_assina_outra_base          BOOL,
  in_repositorio_institucional  BOOL,
  in_busca_integrada            BOOL,
  in_servico_internet           BOOL,
  in_participa_rede_social      BOOL,
  in_catalogo_online            BOOL,
  qt_periodico_eletronico       INT64,
  qt_livro_eletronico           INT64,

  -- Faculty / staff totals (kept as a representative subset of the full
  -- Censup schema; the production load carries all qt_* columns)
  qt_tec_total                  INT64,
  qt_doc_exe                    INT64,
  qt_doc_ex_femi                INT64,
  qt_doc_ex_masc                INT64,
  qt_doc_ex_mest                INT64,
  qt_doc_ex_dout                INT64,

  inserted_at                 TIMESTAMP
)
;
