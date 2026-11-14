# Kgotla Logistics: AI Automation Standard (v1)

Owner: AI Operations · Applies to: every n8n automation that calls an AI model

## 1. Before you build

Register the automation (name, team, business owner, purpose) and agree its **risk tier** with AI Operations (RISK-TIERS.md).

## 2. Required controls by tier

| Control | Low | Medium | High |
|---|---|---|---|
| Owner + handover doc | ✓ | ✓ | ✓ |
| Credentials only in the n8n credential store | ✓ | ✓ | ✓ |
| Error workflow = Ops: Error Handler | ✓ | ✓ | ✓ |
| AI calls only through Ops: AI Gateway | ✓ | ✓ | ✓ |
| Every run logged via Ops: Log Run | ✓ | ✓ | ✓ |
| Exported to git; changes recorded | ✓ | ✓ | ✓ |
| Least-privilege account access | | ✓ | ✓ |
| Idempotency via Ops: Claim Item | | ✓ | ✓ |
| Input checks | | ✓ | ✓ |
| Structured AI output with a schema | | ✓ | ✓ |
| Eval set + prompt gate | | ✓ | ✓ + paired bias tests |
| Human review | | Drafts; review on low confidence | **A person makes every decision** |
| Personal data minimised; retention defined | | ✓ (contact details redacted) | ✓ + protected attributes redacted |

## 3. Definition of "production-ready"

All required controls for the tier score 2, with evidence, and the business owner has signed off any behaviour changes.

## 4. Changing a live automation

Prompts: new version → Eval Runner → `scripts/activate-prompt.sh`. Logic: export, record in `changes`, test.

Rollback: `scripts/activate-prompt.sh <automation> <prompt> <previous version> --rollback`.

## 5. Exceptions

A control that can't be met is recorded as an `accepted` finding with a reason, an owner and a review date.

**Accepted by default in toolkit v1.0.0**

| Risk | Why it is accepted | Owner | Review by |
|---|---|---|---|
| Code nodes can read environment variables (`N8N_BLOCK_ENV_ACCESS_IN_NODE=false`), including `REVIEW_LINK_SECRET` | The gateway and review workflows read the model name, prices and the link secret from the environment | AI Operations | May 2027 |

Mitigations: only AI Operations edits workflows; every project has its own secrets; secrets never go into git.

## 6. Isolation

Each automation runs in its own environment with its own credentials and data. The toolkit is installed as a versioned copy.

## 7. Data retention defaults

The **Ops: Retention** workflow purges these every night. Projects with personal data shorten them and add their own steps.

| Data | Kept for |
|---|---|
| `processed_items` | 90 days (an item re-delivered after that would be processed again) |
| `runs`, `ai_calls` | 180 days |
| `workflow_errors` | 90 days |
| `review_queue` (decided items only) | 180 days |
| `eval_runs` | 365 days |

Backups keep purged rows until the backups expire, so state the backup retention alongside these.