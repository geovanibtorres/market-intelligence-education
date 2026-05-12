/* =============================================================================
 * sup_holding_cluster
 * -----------------------------------------------------------------------------
 * Commercial clusterization at the *holding* level — i.e. the controlling
 * legal entity that may own one or more groups (and indirectly many IES).
 *
 * Joined by normalized CNPJ to the institution row. The CNPJ is kept here
 * as a join key only; in this portfolio the values are synthetic.
 *
 * Same sanitization pattern as sup_group_cluster: real holding names and
 * commercial cluster labels are replaced with opaque codes.
 * ============================================================================= */

SELECT
  company_tax_id,                -- normalized CNPJ (digits only) — synthetic here
  cluster_mant                   -- e.g. CLUSTER_HOLDING_1 / CLUSTER_HOLDING_2 / ...
FROM warehouse_raw.raw_commercial_holding_cluster
;
