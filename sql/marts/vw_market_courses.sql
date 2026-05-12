/* =============================================================================
 * vw_market_courses
 * -----------------------------------------------------------------------------
 * Secondary dashboard source: one row per course per IES per census year.
 *
 * Consumed by the Tableau dashboard via *data blending* on
 * (cod_ies, nu_ano_censo) against vw_market_institutions. Blending is
 * preferred over a SQL join here because the institution view is at a
 * coarser grain and a SQL join would explode its metrics.
 *
 * Filters applied:
 *   - Five-year window aligned with the institution view.
 *
 * Column scope: mirrors the public Censup course-level microdata schema
 * (INEP). The full set of columns below matches the set consumed by the
 * production dashboard worksheets (modality, degree, area of knowledge,
 * vacancies, applicants, intake / enrolled / graduated counts broken
 * down by gender, age band, race, financing, school provenance,
 * affirmative-action reservation, special programs, status). All of
 * these fields are part of the openly published Censup dataset.
 *
 * No commercial overlay is attached at the course level — overlay
 * attributes (cluster, executive, customer status) come from the
 * institution view via the blend.
 * ============================================================================= */

SELECT
  /* ---------- Keys / identification ---------- */
  cod_ies,
  nu_ano_censo,
  co_curso,
  no_curso,

  /* ---------- Course classification ---------- */
  tp_grau_academico,
  tp_nivel_academico,
  tp_modalidade_ensino,
  tp_dimensao,
  tp_categoria_administrativa,
  tp_organizacao_academica,
  tp_rede,
  in_gratuito,

  /* ---------- CINE area of knowledge ---------- */
  co_cine_rotulo,
  no_cine_rotulo,
  co_cine_area_geral,
  no_cine_area_geral,
  co_cine_area_especifica,
  no_cine_area_especifica,
  co_cine_area_detalhada,
  no_cine_area_detalhada,

  /* ---------- Geography ---------- */
  co_regiao,
  no_regiao,
  co_uf,
  sg_uf,
  no_uf,
  co_municipio,
  no_municipio,
  in_capital,

  /* ---------- Vacancies / applicants ---------- */
  qt_curso,
  qt_vg_total,
  qt_vg_total_presencial,
  qt_vg_total_ead,
  qt_inscrito_total,
  qt_inscrito_total_presencial,
  qt_inscrito_total_ead,
  qt_insc_proc_seletivo,
  qt_insc_vg_nova,
  qt_insc_vg_remanesc,
  qt_insc_vg_prog_especial,

  /* ---------- Intake (ingressantes) ---------- */
  qt_ing,
  qt_ing_presencial,
  qt_ing_ead,
  qt_ing_fem,
  qt_ing_masc,
  qt_ing_0_17,
  qt_ing_18_24,
  qt_ing_25_29,
  qt_ing_30_34,
  qt_ing_35_39,
  qt_ing_40_49,
  qt_ing_50_59,
  qt_ing_60_mais,
  qt_ing_branca,
  qt_ing_preta,
  qt_ing_parda,
  qt_ing_amarela,
  qt_ing_indigena,
  qt_ing_cornd,
  qt_ing_deficiente,
  qt_ing_apoio_social,
  qt_ing_ativ_extracurricular,
  qt_ing_mob_academica,
  qt_ing_egr,
  /* Intake — selection process */
  qt_ing_proc_seletivo,
  qt_ing_vestibular,
  qt_ing_enem,
  qt_ing_avaliacao_seriada,
  qt_ing_selecao_simplifica,
  qt_ing_outro_tipo_selecao,
  qt_ing_outra_forma,
  qt_ing_vg_nova,
  qt_ing_vg_remanesc,
  qt_ing_vg_prog_especial,
  /* Intake — financing */
  qt_ing_financ,
  qt_ing_financ_reemb,
  qt_ing_financ_reemb_outros,
  qt_ing_financ_nreemb,
  qt_ing_financ_nreemb_outros,
  qt_ing_fies,
  qt_ing_rpfies,
  qt_ing_nrpfies,
  qt_ing_prounii,
  qt_ing_prounip,
  /* Intake — school provenance */
  qt_ing_procescpublica,
  qt_ing_procescprivada,
  qt_ing_procnaoinformada,
  /* Intake — affirmative-action reservation */
  qt_ing_reserva_vaga,
  qt_ing_rvredepublica,
  qt_ing_rvetnico,
  qt_ing_rvpdef,
  qt_ing_rvsocial_rf,
  qt_ing_rvoutros,

  /* ---------- Enrolled (matriculados) ---------- */
  qt_mat,
  qt_mat_presencial,
  qt_mat_ead,
  qt_mat_fem,
  qt_mat_masc,
  qt_mat_0_17,
  qt_mat_18_24,
  qt_mat_25_29,
  qt_mat_30_34,
  qt_mat_35_39,
  qt_mat_40_49,
  qt_mat_50_59,
  qt_mat_60_mais,
  qt_mat_branca,
  qt_mat_preta,
  qt_mat_parda,
  qt_mat_amarela,
  qt_mat_indigena,
  qt_mat_cornd,
  qt_mat_deficiente,
  qt_mat_apoio_social,
  qt_mat_ativ_extracurricular,
  qt_mat_mob_academica,
  /* Enrolled — financing */
  qt_mat_financ,
  qt_mat_financ_reemb,
  qt_mat_financ_reemb_outros,
  qt_mat_financ_nreemb,
  qt_mat_financ_nreemb_outros,
  qt_mat_fies,
  qt_mat_rpfies,
  qt_mat_nrpfies,
  qt_mat_prounii,
  qt_mat_prounip,
  /* Enrolled — school provenance */
  qt_mat_procescpublica,
  qt_mat_procescprivada,
  qt_mat_procnaoinformada,
  /* Enrolled — affirmative-action reservation */
  qt_mat_reserva_vaga,
  qt_mat_rvredepublica,
  qt_mat_rvetnico,
  qt_mat_rvpdef,
  qt_mat_rvsocial_rf,
  qt_mat_rvoutros,

  /* ---------- Graduated (concluintes) ---------- */
  qt_conc,
  qt_conc_presencial,
  qt_conc_ead,
  qt_conc_fem,
  qt_conc_masc,
  qt_conc_0_17,
  qt_conc_18_24,
  qt_conc_25_29,
  qt_conc_30_34,
  qt_conc_35_39,
  qt_conc_40_49,
  qt_conc_50_59,
  qt_conc_60_mais,
  qt_conc_branca,
  qt_conc_preta,
  qt_conc_parda,
  qt_conc_amarela,
  qt_conc_indigena,
  qt_conc_cornd,
  qt_conc_deficiente,
  qt_conc_apoio_social,
  qt_conc_ativ_extracurricular,
  qt_conc_mob_academica,
  /* Graduated — financing */
  qt_conc_financ,
  qt_conc_financ_reemb,
  qt_conc_financ_reemb_outros,
  qt_conc_financ_nreemb,
  qt_conc_financ_nreemb_outros,
  qt_conc_fies,
  qt_conc_rpfies,
  qt_conc_nrpfies,
  qt_conc_prounii,
  qt_conc_prounip,
  /* Graduated — school provenance */
  qt_conc_procescpublica,
  qt_conc_procescprivada,
  qt_conc_procnaoinformada,
  /* Graduated — affirmative-action reservation */
  qt_conc_reserva_vaga,
  qt_conc_rvredepublica,
  qt_conc_rvetnico,
  qt_conc_rvpdef,
  qt_conc_rvsocial_rf,
  qt_conc_rvoutros,

  /* ---------- Status / movement / extras ---------- */
  qt_aluno_deficiente,
  qt_apoio_social,
  qt_ativ_extracurricular,
  qt_mob_academica,
  qt_sit_trancada,
  qt_sit_desvinculado,
  qt_sit_transferido,
  qt_sit_falecido
FROM warehouse_curated.stg_higher_ed_courses
WHERE nu_ano_censo IN ('2020', '2021', '2022', '2023', '2024')
;
