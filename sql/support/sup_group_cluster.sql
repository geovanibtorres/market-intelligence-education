/* =============================================================================
 * sup_group_cluster
 * -----------------------------------------------------------------------------
 * Commercial clusterization of educational *groups* (an internal grouping
 * above the institution level — multiple IES can belong to the same
 * group).
 *
 * Source (sanitized): a small reference spreadsheet maintained by the
 * commercial intelligence team and loaded via Tableau Prep.
 *
 * In production this table contains real group names and a cluster
 * definition driven by total enrollment, geographic spread and ownership
 * structure. In this portfolio version both the group identifier and the
 * cluster label are reduced to opaque codes so the *modeling pattern*
 * (group → cluster) is visible without exposing the proprietary
 * classification.
 * ============================================================================= */

SELECT
  group_code,                    -- opaque group identifier (sanitized)
  cluster_grupo                  -- e.g. CLUSTER_GROUP_A / CLUSTER_GROUP_B / ...
FROM warehouse_raw.raw_commercial_group_cluster
;
