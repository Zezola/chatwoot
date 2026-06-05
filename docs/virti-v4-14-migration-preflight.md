# Virti Chatwoot v4.14 Migration Preflight

Run these checks before applying the v4.14 migrations in any environment.

## Required backup

- Create a Chatwoot database backup before `db:migrate`.
- Keep the exact Chatwoot git revision and backup path together.

## Destructive or irreversible migrations

- Confirm `channel_voice` is empty before `20260326120001_drop_channel_voice`.
- Export affected `custom_filters` containing `country_code` before `20260112092041_remove_country_code_from_conversation_filters`.
- Export affected contact filters and automation rules containing `attribute_key = company` before `20260427094500_rename_company_condition_key_in_automation_rules`.
- Export `accounts.feature_flags` and `ACCOUNT_LEVEL_FEATURE_DEFAULTS` before feature flag migrations.

## Model-backed backfills

- Validate existing `webhooks` rows before `20260226084618_backfill_webhook_secrets`.
- Validate existing `agent_bots` and `channel_api` rows before `20260324070835_backfill_agent_bot_and_channel_api_secrets`.
- Fix invalid legacy rows before migration because these backfills use application models and can abort on validations.

## External side effects

- Confirm enabled OpenAI integration hooks before `20260515000000_enqueue_validate_openai_hooks_job`; invalid hooks may be destroyed by the queued job.

## Enterprise/Captain tables

- Confirm `captain_documents` and `captain_assistant_responses` tables exist even when Enterprise code is removed.

## Operational checks

- Confirm `WEBHOOK_TIMEOUT=50` is present in runtime env or GlobalConfig.
- Confirm `SAFE_FETCH_ALLOWED_PRIVATE_HOSTS` includes internal webhook hosts used by this deployment.
- Confirm table sizes/write traffic for `webhooks`, `csat_survey_responses`, `captain_documents`, `companies`, and channel tables before running lock-taking schema changes.
