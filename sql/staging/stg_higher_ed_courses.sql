/* =============================================================================
 * stg_higher_ed_courses
 * -----------------------------------------------------------------------------
 * Conformed course-level Censup microdata covering twelve census years
 * (2013–2024).
 *
 * Production loading: Tableau Prep flow "Dados IES cursos" — each yearly
 * course-level CSV is read with the same column contract; the prep tool
 * unions them with nu_ano_censo as the discriminator and writes the
 * result to the warehouse in **truncate-and-load** mode. The full Censup
 * course-level schema is preserved (modality, degree level, area of
 * knowledge, vacancies, applicants, intake / enrolled / graduated counts
 * broken down by gender, age band, race, financing, school provenance,
 * affirmative-action reservation, special programs, status).
 *
 * Year scope:
 *   - Staging: full history (2013–2024) is preserved.
 *   - Mart (vw_market_courses): filters to the five most recent census
 *     years to align with the institution view used by the dashboard.
 *
 * The downstream mart selects from this table and exposes the columns
 * actually consumed by the dashboard. Anything new added by INEP in a
 * future Censup release becomes available downstream by extending the
 * mart view, with no change required here.
 *
 * Downstream consumer: vw_market_courses
 * ============================================================================= */

SELECT *
FROM warehouse_raw.raw_censup_courses
;
