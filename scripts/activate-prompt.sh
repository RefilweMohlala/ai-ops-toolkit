#!/usr/bin/env bash
# Usage: scripts/activate-prompt.sh <automation> <prompt-name> <version> [--rollback]
# Refuses unless the version passed the eval in the last 24h (automations without an eval threshold are exempt).
set -euo pipefail
cd "$(dirname "$0")/.."

docker compose exec -T postgres psql -U ops -d ops -v ON_ERROR_STOP=1 \
  -v aut="$1" -v pname="$2" -v ver="$3" \
  -v rollback="$([ "${4:-}" = "--rollback" ] && echo on || echo off)" <<'SQL'
SELECT set_config('ops.aut',      :'aut',      false),
       set_config('ops.pname',    :'pname',    false),
       set_config('ops.ver',      :'ver',      false),
       set_config('ops.rollback', :'rollback', false);

DO $$
DECLARE
  a          text := current_setting('ops.aut');
  n          text := current_setting('ops.pname');
  v          text := current_setting('ops.ver');
  needs_eval boolean;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM prompts
                  WHERE automation_id = a AND name = n AND version = v) THEN
    RAISE EXCEPTION 'Prompt %/% version % does not exist', a, n, v;
  END IF;

  SELECT eval_threshold IS NOT NULL INTO needs_eval
    FROM automations WHERE id = a;

  IF current_setting('ops.rollback') = 'on' THEN
    IF NOT EXISTS (SELECT 1 FROM prompts
                    WHERE automation_id = a AND name = n AND version = v
                      AND activated_at IS NOT NULL) THEN
      RAISE EXCEPTION 'Rollback refused: % was never active before', v;
    END IF;
  ELSIF needs_eval AND NOT EXISTS (
    SELECT 1 FROM eval_runs
     WHERE automation_id = a AND prompt_version = v
       AND passed AND created_at > now() - interval '24 hours'
  ) THEN
    RAISE EXCEPTION 'Activation refused: % has no passing eval for % in the last 24 hours', v, a;
  END IF;

  UPDATE prompts SET active = false
   WHERE automation_id = a AND name = n AND active;
  UPDATE prompts SET active = true, activated_at = now()
   WHERE automation_id = a AND name = n AND version = v;

  RAISE NOTICE 'Activated %/% %', a, n, v;
END $$;
SQL