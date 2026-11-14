# Readiness checklist (16 controls)

Score each control: **0** = missing · **1** = partial or informal · **2** = in place and you can point to it.

Every score needs **evidence**: the node name, a setting, or what you observed in a test.

| ID | Area | Control | Required for |
|---|---|---|---|
| C01 | Ownership | Named business owner and technical owner | all |
| C02 | Ownership | Purpose, inputs, outputs and dependencies documented | all |
| C03 | Security | No secrets in nodes or code; credentials in the n8n credential store | all |
| C04 | Security | Least-privilege access to connected accounts | medium, high |
| C05 | Reliability | Error workflow attached; failures alert a person | all |
| C06 | Reliability | Timeouts and limited retries on external calls | all |
| C07 | Reliability | Idempotent: duplicates and re-runs cause no duplicate effects | medium, high |
| C08 | Reliability | Bad input handled | medium, high |
| C09 | AI quality | AI output validated against an expected structure | medium, high |
| C10 | AI quality | Prompt versioned and stored outside the node | medium, high |
| C11 | AI quality | Eval set + threshold, run before changes (high: bias tests) | medium, high |
| C12 | Human oversight | Human review proportionate to risk | medium, high |
| C13 | Data protection | Personal data minimised before the AI and in logs; retention defined | medium, high |
| C14 | Observability | Every run logged: outcome, latency, tokens, cost | all |
| C15 | Cost | Cost limit or alert | all |
| C16 | Change control | Version-controlled; changes recorded with reasons | all |

## The five tests (run before scoring)

| Test | How | Looking for |
|---|---|---|
| Happy path | Normal input | Works as described? |
| Bad input | Empty, huge, wrong format, other language | Crash? Silent nonsense? |
| AI failure | Wrong API key | What does the user see? Does anyone find out? |
| Odd AI output | Temporarily make the prompt say "Reply with the word banana" | Is the output used anyway? |
| Duplicate | Trigger the same item twice | Two effects? |

## Severity of findings

**High**: could harm a person, the company's reputation, or break the law.

**Medium**: could cause a silent failure or wrong output reaching someone.

**Low**: hygiene.