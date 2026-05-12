/* =============================================================================
 * raw_censup_courses
 * -----------------------------------------------------------------------------
 * Reference DDL for the course-level Censup microdata landing table.
 *
 * Source: INEP — Censo da Educação Superior (public annual release).
 *         One CSV per census year, downloaded from the INEP portal.
 *
 * Grain: one row per course per institution per census year.
 *
 * Loading: Tableau Prep flow "Dados IES cursos". Twelve census years
 *          (2013–2024) are unioned during prep and the result is written
 *          to the warehouse in **truncate-and-load** mode. The downstream
 *          mart filters to the five most recent census years.
 *
 * Schema scope: the production load carries the *full* Censup course-level
 * schema (~150+ columns: modality, degree, CINE area, vacancies,
 * applicants, intake / enrolled / graduated counts broken down by gender,
 * age band, race, financing, school provenance, affirmative-action
 * reservation, special programs, status). The DDL below shows a
 * representative subset for documentation purposes; see vw_market_courses
 * for the complete column list consumed by the dashboard.
 * ============================================================================= */

CREATE TABLE IF NOT EXISTS warehouse_raw.raw_censup_courses (
  nu_ano_censo                STRING,    -- census year
  cod_ies                     INT64,     -- institution code
  co_curso                    INT64,     -- course code (INEP)
  no_curso                    STRING,    -- course name

  -- Classification
  tp_grau_academico           STRING,    -- bacharelado / licenciatura / tecnológico
  tp_nivel_academico          STRING,
  tp_modalidade_ensino        STRING,    -- presencial / EAD
  tp_categoria_administrativa STRING,
  tp_organizacao_academica    STRING,
  tp_rede                     STRING,
  in_gratuito                 BOOL,

  -- CINE area of knowledge
  co_cine_rotulo              STRING,
  no_cine_rotulo              STRING,
  co_cine_area_geral          STRING,
  no_cine_area_geral          STRING,
  co_cine_area_especifica     STRING,
  no_cine_area_especifica     STRING,
  co_cine_area_detalhada      STRING,
  no_cine_area_detalhada      STRING,

  -- Geography
  co_regiao                   STRING,
  no_regiao                   STRING,
  co_uf                       STRING,
  sg_uf                       STRING,
  no_uf                       STRING,
  co_municipio                STRING,
  no_municipio                STRING,
  in_capital                  BOOL,

  -- Headline metrics (full breakdowns omitted from this DDL — see mart view)
  qt_curso                    INT64,
  qt_vg_total                 INT64,
  qt_inscrito_total           INT64,
  qt_ing                      INT64,
  qt_mat                      INT64,
  qt_conc                     INT64,

  inserted_at                 TIMESTAMP
)
;
