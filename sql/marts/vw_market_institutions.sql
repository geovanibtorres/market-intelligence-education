/* =============================================================================
 * vw_market_institutions
 * -----------------------------------------------------------------------------
 * Primary dashboard source: one row per IES per census year, joining:
 *
 *   - 5-year Censup institution microdata (stg_higher_ed_institutions)
 *   - IGC indicator for the matching census year (sup_institution_quality_index)
 *   - Anonymized commercial overlay:
 *       * group cluster      (sup_group_cluster)
 *       * holding cluster    (sup_holding_cluster)
 *       * vendor-customer    (int_vendor_customer_status)
 *
 * Pattern shown:
 *   - Year-aware IGC join (cod_ies + ano_igc = nu_ano_censo).
 *   - Single CNPJ-normalization rule applied at the join site.
 *   - Three-state vendor-customer status: ACTIVE / INACTIVE / NEVER.
 *     NEVER is materialized here as the COALESCE fallback so downstream
 *     consumers do not need to know that the absence of a row in the
 *     customer feed means "not a customer".
 *
 * Downstream consumer: Tableau dashboard (primary source).
 *                      Blends with vw_market_courses on (cod_ies, nu_ano_censo).
 *
 * --------------------------------------------------------------------------
 * NOTE ON SANITIZATION
 * --------------------------------------------------------------------------
 * In the production model:
 *   - The vendor-customer column carries the real vendor brand name and
 *     comes directly from a CRM view that is joined twice (once for the
 *     row's own CNPJ, once for any sibling CNPJ in the same group).
 *   - The cluster columns expose real commercial cluster labels.
 *   - The CNPJ is the real CNPJ.
 *
 * Here all three are reduced to neutral surfaces:
 *   - vendor_customer_status is an opaque ACTIVE/INACTIVE/NEVER enum.
 *   - cluster_grupo / cluster_mant are opaque codes.
 *   - company_tax_id values are synthetic.
 *
 * The *join shape* and the *column contract exposed to the dashboard*
 * are preserved exactly.
 * ============================================================================= */

WITH
  ies AS (
    SELECT * FROM warehouse_curated.stg_higher_ed_institutions
  ),

  igc AS (
    SELECT * FROM warehouse_curated.sup_institution_quality_index
  ),

  group_cluster AS (
    SELECT * FROM warehouse_curated.sup_group_cluster
  ),

  holding_cluster AS (
    SELECT * FROM warehouse_curated.sup_holding_cluster
  ),

  customer_status AS (
    SELECT * FROM warehouse_curated.int_vendor_customer_status
  )

SELECT
  /* ---------- Commercial overlay (anonymized) ---------- */
  ies.group_code,
  'Account Exec — Region X'                                AS executivo,
  group_cluster.cluster_grupo,
  holding_cluster.cluster_mant,

  /* Three-state customer status. NEVER is the fallback when there is no
     row in the customer feed for this institution's CNPJ. */
  COALESCE(customer_status.vendor_customer_status, 'NEVER')
                                                           AS vendor_customer_status,

  /* ---------- Public regulatory metadata ---------- */
  ies.situacao_ies,
  ies.cod_ies,
  ies.nome_ies,
  ies.company_tax_id,
  igc.igc_continuo,
  igc.igc_faixa,
  ies.cod_mantenedora,
  ies.razao_social,
  ies.data_criacao_ies,
  ies.tipo_credenciamento,
  ies.categoria,
  ies.cat_administrativa,
  ies.natureza_juridica,
  ies.organizacao_academica,
  ies.telefone,
  ies.sitio,
  ies.email,
  ies.representante_legal,
  ies.reitor_dirigente_principal,
  ies.sinalizacoes_vigentes,

  /* ---------- Census year + address ---------- */
  ies.nu_ano_censo,
  ies.ds_endereco_ies,
  ies.ds_numero_endereco_ies,
  ies.ds_complemento_endereco_ies,
  ies.no_bairro_ies,
  ies.nu_cep_ies,
  ies.municipio,
  ies.sg_uf,

  /* ---------- Public Censup indicators (representative subset) ---------- */
  ies.in_acesso_portal_capes,
  ies.in_acesso_outras_bases,
  ies.in_assina_outra_base,
  ies.in_repositorio_institucional,
  ies.in_busca_integrada,
  ies.in_servico_internet,
  ies.in_participa_rede_social,
  ies.in_catalogo_online,
  ies.qt_periodico_eletronico,
  ies.qt_livro_eletronico,
  ies.qt_tec_total,
  ies.qt_doc_exe,
  ies.qt_doc_ex_femi,
  ies.qt_doc_ex_masc,
  ies.qt_doc_ex_mest,
  ies.qt_doc_ex_dout
FROM ies
LEFT JOIN customer_status
  ON REGEXP_REPLACE(IFNULL(ies.company_tax_id, ''), r'[^0-9]', '')
     = customer_status.company_tax_id
LEFT JOIN igc
  ON igc.cod_ies = ies.cod_ies
 AND igc.ano_igc = ies.nu_ano_censo
LEFT JOIN group_cluster
  ON group_cluster.group_code = ies.group_code
 AND ies.group_code IS NOT NULL
LEFT JOIN holding_cluster
  ON holding_cluster.company_tax_id
     = REGEXP_REPLACE(IFNULL(ies.company_tax_id, ''), r'[^0-9]', '')
 AND ies.company_tax_id IS NOT NULL
WHERE ies.nu_ano_censo IN ('2020', '2021', '2022', '2023', '2024')
   OR ies.nu_ano_censo IS NULL
;
