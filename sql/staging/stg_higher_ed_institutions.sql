/* =============================================================================
 * stg_higher_ed_institutions
 * -----------------------------------------------------------------------------
 * Conformed institution-level Censup microdata covering twelve census
 * years (2013–2024), enriched with the latest e-MEC public-consultation
 * snapshot.
 *
 * Production loading: Tableau Prep flow "Dados IES" — each yearly Censup
 * CSV is read with the same column contract; the prep tool unions them
 * with nu_ano_censo as the discriminator and writes the result to the
 * warehouse in **truncate-and-load** mode, so the destination table is a
 * pure function of the inputs at run time. The e-MEC export is joined
 * onto the most recent census year only — older years keep their own
 * snapshot of the regulatory metadata so that historical comparisons
 * stay faithful to what was published at the time.
 *
 * Year scope:
 *   - Staging: full history (2013–2024) is preserved for ad-hoc
 *     analyses, retroactive cohort studies and back-testing of cluster
 *     definitions.
 *   - Mart (vw_market_institutions): filters to the five most recent
 *     census years for the default dashboard view.
 *
 * The SQL below documents the equivalent set-based logic so the same
 * model can be rebuilt in pure SQL if Tableau Prep is replaced.
 *
 * Downstream consumer: vw_market_institutions
 * ============================================================================= */

WITH
  /* Full Censup history. The mart layer applies the dashboard window. */
  censup_full AS (
    SELECT *
    FROM warehouse_raw.raw_censup_institutions
  ),

  /* Latest e-MEC snapshot — used to enrich the most recent census row. */
  emec_latest AS (
    SELECT *
    FROM warehouse_raw.raw_emec_public
    QUALIFY ROW_NUMBER() OVER (PARTITION BY cod_ies ORDER BY inserted_at DESC) = 1
  )

SELECT
  c.nu_ano_censo,
  c.cod_ies,
  c.nome_ies,
  c.sg_ies,
  c.sg_uf,
  c.municipio,
  c.cat_administrativa,
  c.organizacao_academica,
  c.ds_endereco_ies,
  c.ds_numero_endereco_ies,
  c.ds_complemento_endereco_ies,
  c.no_bairro_ies,
  c.nu_cep_ies,

  /* Public regulatory enrichment from e-MEC. Only attached to the most
     recent census year so historical rows keep their period-correct
     metadata. */
  CASE WHEN c.nu_ano_censo = '2024' THEN e.cod_mantenedora           END AS cod_mantenedora,
  CASE WHEN c.nu_ano_censo = '2024' THEN e.razao_social              END AS razao_social,
  CASE WHEN c.nu_ano_censo = '2024' THEN e.company_tax_id            END AS company_tax_id,
  CASE WHEN c.nu_ano_censo = '2024' THEN e.data_criacao_ies          END AS data_criacao_ies,
  CASE WHEN c.nu_ano_censo = '2024' THEN e.tipo_credenciamento       END AS tipo_credenciamento,
  CASE WHEN c.nu_ano_censo = '2024' THEN e.categoria                 END AS categoria,
  CASE WHEN c.nu_ano_censo = '2024' THEN e.natureza_juridica         END AS natureza_juridica,
  CASE WHEN c.nu_ano_censo = '2024' THEN e.situacao_ies              END AS situacao_ies,
  CASE WHEN c.nu_ano_censo = '2024' THEN e.sinalizacoes_vigentes     END AS sinalizacoes_vigentes,
  CASE WHEN c.nu_ano_censo = '2024' THEN e.telefone                  END AS telefone,
  CASE WHEN c.nu_ano_censo = '2024' THEN e.sitio                     END AS sitio,
  CASE WHEN c.nu_ano_censo = '2024' THEN e.email                     END AS email,
  CASE WHEN c.nu_ano_censo = '2024' THEN e.representante_legal       END AS representante_legal,
  CASE WHEN c.nu_ano_censo = '2024' THEN e.reitor_dirigente_principal END AS reitor_dirigente_principal,

  /* Public Censup metrics (representative subset). */
  c.in_acesso_portal_capes,
  c.in_acesso_outras_bases,
  c.in_assina_outra_base,
  c.in_repositorio_institucional,
  c.in_busca_integrada,
  c.in_servico_internet,
  c.in_participa_rede_social,
  c.in_catalogo_online,
  c.qt_periodico_eletronico,
  c.qt_livro_eletronico,
  c.qt_tec_total,
  c.qt_doc_exe,
  c.qt_doc_ex_femi,
  c.qt_doc_ex_masc,
  c.qt_doc_ex_mest,
  c.qt_doc_ex_dout
FROM censup_full c
LEFT JOIN emec_latest e
  ON e.cod_ies = c.cod_ies
;
