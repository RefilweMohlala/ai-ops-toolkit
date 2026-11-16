# AI Ops Toolkit

A reusable playbook and n8n operations layer for taking AI automations to production safely.
Installed as a versioned copy into each engagement, which runs in its own isolated environment.


Built and tested on n8n 2.46.7 with Claude Haiku 5.5.

## Contents

- **Playbook:** readiness checklist (16 controls), risk tiers, Automation Standard, templates
- **Ops workflows (n8n):** AI Gateway (versioned prompts, budget circuit breaker, retries, cost logging,
  output validation), Redact PII, Claim Item, Log Run, Request Review / Review Decision, Error Handler,
  Monitor, Retention, Eval Runner
- **Scripts:** install-toolkit, import-workflows, export-workflows, activate-prompt (eval gate), scorecard


## Install into a project

    scripts/install-toolkit.sh ../<project> <port>

Then, in the project: copy .env.example to .env and fill in new secrets, start Docker, create the
credentials (Ops DB, Anthropic, Gmail), and run scripts/import-workflows.sh toolkit/workflows.
Publish Ops: Error Handler, Ops: Review Decision, Ops: Monitor and Ops: Retention.

## Known limitations

- Pattern-based redaction catches obvious markers, not everything (a school's name, a club).
  High-risk projects add paired bias tests and a human decision.
- Review links are safe against email link scanners (a confirmation click is required), but anyone who
  holds the full link can still confirm it.
- The daily budget is checked before each call, so several calls at once can overshoot it slightly.
- Code nodes can read environment variables. This is an accepted risk, recorded in the Automation Standard.
- Sending data to a hosted model can be a cross-border transfer under POPIA. Each engagement should
  record its own decision on this.
