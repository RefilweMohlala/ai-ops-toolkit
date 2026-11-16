#!/usr/bin/env bash
# Prints the before/after readiness scorecard, findings and changes.
set -euo pipefail
cd "$(dirname "$0")/.."

docker compose exec -T postgres psql -U ops -d ops <<'SQL'
SELECT b.name,
       b.risk_tier,
       b.score_out_of_10 AS before,
       a.score_out_of_10 AS after,
       b.required_gaps   AS required_gaps_before,
       a.required_gaps   AS required_gaps_after
FROM readiness_scorecard b
LEFT JOIN readiness_scorecard a
       ON a.id = b.id
      AND a.phase = 'after'
WHERE b.phase = 'before';

SELECT severity, status, count(*)
FROM findings
GROUP BY 1, 2
ORDER BY 1, 2;

SELECT count(*) AS changes,
       count(*) FILTER (WHERE changes_behaviour) AS behaviour_changes
FROM changes;
SQL