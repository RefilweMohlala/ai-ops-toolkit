-- ---------- Registry ----------
CREATE TABLE automations (
    id                TEXT PRIMARY KEY,
    name              TEXT NOT NULL,
    owner_team        TEXT NOT NULL,
    business_owner    TEXT NOT NULL,
    technical_owner   TEXT NOT NULL DEFAULT 'AI Operations',
    risk_tier         TEXT CHECK (risk_tier IN ('low', 'medium', 'high')),
    status            TEXT NOT NULL DEFAULT 'inherited', -- inherited | in_review | hardened | approved
    source_url        TEXT,
    original_author   TEXT,
    licence           TEXT,
    daily_budget_usd  NUMERIC(8,2) NOT NULL DEFAULT 0.50,
    eval_threshold    NUMERIC(4,3),                      -- null = no eval required for this tier
    toolkit_version   TEXT,
    inherited_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------- The audit ----------
CREATE TABLE controls (
    id            TEXT PRIMARY KEY,
    area          TEXT NOT NULL,
    description   TEXT NOT NULL,
    required_for  TEXT[] NOT NULL
);

CREATE TABLE readiness_scores (
    automation_id  TEXT REFERENCES automations(id),
    phase          TEXT CHECK (phase IN ('before', 'after')),
    control_id     TEXT REFERENCES controls(id),
    score          SMALLINT CHECK (score BETWEEN 0 AND 2), -- 0 missing, 1 partial, 2 in place
    evidence       TEXT NOT NULL,
    scored_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (automation_id, phase, control_id)
);

CREATE TABLE findings (
    id              SERIAL PRIMARY KEY,
    automation_id   TEXT REFERENCES automations(id),
    control_id      TEXT REFERENCES controls(id),
    severity        TEXT CHECK (severity IN ('high', 'medium', 'low')),
    description     TEXT NOT NULL,
    recommendation  TEXT NOT NULL,
    status          TEXT NOT NULL DEFAULT 'open', -- open | fixed | accepted
    resolution      TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    closed_at       TIMESTAMPTZ
);

CREATE TABLE changes (
    id                 SERIAL PRIMARY KEY,
    automation_id      TEXT REFERENCES automations(id),
    finding_id         INT REFERENCES findings(id),
    description        TEXT NOT NULL,
    reason             TEXT NOT NULL,
    changes_behaviour  BOOLEAN NOT NULL,
    agreed_with        TEXT,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------- Runtime ----------
CREATE TABLE prompts (
    automation_id  TEXT REFERENCES automations(id),
    name           TEXT NOT NULL,
    version        TEXT NOT NULL,
    system_prompt  TEXT NOT NULL,
    user_template  TEXT NOT NULL,                -- {{variable}} placeholders
    output_schema  JSONB,                        -- expected JSON structure; null = free text, not validated
    active         BOOLEAN NOT NULL DEFAULT false,
    activated_at   TIMESTAMPTZ,
    notes          TEXT,
    PRIMARY KEY (automation_id, name, version)
);

CREATE UNIQUE INDEX one_active_prompt ON prompts (automation_id, name) WHERE active;

CREATE TABLE ai_calls (
    id               BIGSERIAL PRIMARY KEY,
    automation_id    TEXT,
    prompt_version   TEXT,
    model            TEXT,
    outcome          TEXT NOT NULL,              -- ok | invalid_output | failed | budget_exceeded
    input_tokens     INT NOT NULL DEFAULT 0,
    output_tokens    INT NOT NULL DEFAULT 0,
    cost_usd         NUMERIC(10,6) NOT NULL DEFAULT 0,
    latency_ms       INT,
    error            TEXT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE runs (
    id             BIGSERIAL PRIMARY KEY,
    automation_id  TEXT,
    item_ref       TEXT,                         -- an ID or reference, never personal details
    outcome        TEXT NOT NULL,                -- completed | needs_review | failed | skipped_duplicate
    detail         TEXT,
    execution_id   TEXT,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE processed_items (
    automation_id  TEXT,
    item_ref       TEXT,
    processed_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (automation_id, item_ref)
);

CREATE TABLE review_queue (
    id             SERIAL PRIMARY KEY,
    automation_id  TEXT,
    item_ref       TEXT NOT NULL,
    reason         TEXT NOT NULL,
    summary        TEXT,                         -- no personal details
    status         TEXT NOT NULL DEFAULT 'pending', -- pending | approved | rejected
    decided_by     TEXT,
    decided_at     TIMESTAMPTZ,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE workflow_errors (
    id            BIGSERIAL PRIMARY KEY,
    workflow      TEXT,
    node          TEXT,
    message       TEXT,
    execution_id  TEXT,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE alerts (
    name           TEXT PRIMARY KEY,
    state          TEXT NOT NULL DEFAULT 'ok',
    since          TIMESTAMPTZ,
    last_notified  TIMESTAMPTZ,
    detail         TEXT
);

-- ---------- Evals ----------
CREATE TABLE eval_cases (
    automation_id  TEXT REFERENCES automations(id),
    case_id        TEXT NOT NULL,
    kind           TEXT NOT NULL CHECK (kind IN ('expected', 'pair')),
    input          JSONB NOT NULL,               -- 'expected': {vars}   'pair': {"a": {vars}, "b": {vars}}
    expected       JSONB,
    note           TEXT,
    PRIMARY KEY (automation_id, case_id)
);

CREATE TABLE eval_runs (
    id              SERIAL PRIMARY KEY,
    automation_id   TEXT,
    prompt_version  TEXT,
    cases           INT,
    accuracy        NUMERIC(5,4),
    pairs_failed    INT,
    passed          BOOLEAN NOT NULL,
    details         JSONB,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------- The scorecard ----------
CREATE VIEW readiness_scorecard AS
SELECT a.id,
       a.name,
       a.risk_tier,
       s.phase,
       sum(s.score)                                   AS points,
       2 * count(*)                                   AS max_points,
       round(10.0 * sum(s.score) / (2 * count(*)), 1) AS score_out_of_10,
       count(*) FILTER (
           WHERE a.risk_tier = ANY (c.required_for)
             AND s.score < 2
       )                                              AS required_gaps
FROM readiness_scores s
JOIN automations a ON a.id = s.automation_id
JOIN controls c    ON c.id = s.control_id
GROUP BY a.id, a.name, a.risk_tier, s.phase;