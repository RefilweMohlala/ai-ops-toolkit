# Changelog

## 1.0.0

- Initial release: playbook, ops schema, ten ops workflows, scripts.
- Review links need a confirmation click, so email link scanners can't decide an item.
- Database timezone set to Africa/Johannesburg so the daily budget resets at local midnight.
- Retention purges every ops table, not just processed_items (one statement, returns row counts).
- Phone-number redaction requires a + or a leading 0.
- AI Gateway adapted for Claude Haiku 5.5: no temperature, higher default max_tokens, effort set to low,
  refusals and truncated outputs treated as invalid.
- Ops workflows must be published in n8n 2.x for the Error Handler to be selectable as an error workflow.
- Added scripts/import-workflows.sh, which maps credential IDs by name on import.
