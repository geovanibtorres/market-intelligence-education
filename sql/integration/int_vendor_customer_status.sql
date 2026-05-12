/* =============================================================================
 * int_vendor_customer_status
 * -----------------------------------------------------------------------------
 * Sanitized vendor-customer overlay.
 *
 * Production source: internal CRM/ERP extract of every institution that
 * has had a contract with the vendor. The production version carries the
 * real vendor brand on the column name and a per-contract granularity
 * with status, dates and contract codes.
 *
 * Portfolio version: collapses the contract feed into one row per
 * institution (by normalized CNPJ) with a single neutral
 * `vendor_customer_status` enum:
 *
 *   - ACTIVE   — at least one contract is currently in force or under
 *                renewal.
 *   - INACTIVE — has had a contract in the past but none is currently
 *                in force.
 *   - NEVER    — no row in the customer feed (handled at join time in
 *                the mart layer; not materialized here).
 *
 * The CNPJ is kept as a join key only; in this portfolio the values are
 * synthetic.
 *
 * Downstream consumer: vw_market_institutions
 * ============================================================================= */

WITH
  /* One row per CNPJ + contract status, sanitized. */
  customer_feed AS (
    SELECT
      REGEXP_REPLACE(company_tax_id, r'[^0-9]', '') AS company_tax_id,
      contract_status                               -- 'VIGENTE' | 'EMRENOVACAO' | 'ENCERRADO'
    FROM warehouse_raw.raw_internal_customer_contracts
  ),

  /* Roll up to one row per CNPJ. */
  rolled_up AS (
    SELECT
      company_tax_id,
      MAX(
        CASE
          WHEN contract_status IN ('VIGENTE', 'EMRENOVACAO') THEN 1
          ELSE 0
        END
      ) AS has_active,
      COUNT(1) AS n_contracts
    FROM customer_feed
    GROUP BY company_tax_id
  )

SELECT
  company_tax_id,
  CASE
    WHEN has_active = 1   THEN 'ACTIVE'
    WHEN n_contracts > 0  THEN 'INACTIVE'
  END                              AS vendor_customer_status
FROM rolled_up
;
