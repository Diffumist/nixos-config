# Project Context

- Project name: `sema`.
- Purpose: Rust dead man's switch webhook server.
- Configuration is file-based in `sema.toml`; runtime state is persisted separately in JSON.
- Notification design must avoid storms:
  - send once on first down transition;
  - while still down, repeat only after `remind_every_seconds`;
  - send one recovery notification when a down check pings again.
- Webhook delivery must use timeout and bounded retries, and must not block the scanner loop.
- Notification state is delivery-confirmed:
  - queue down/reminder/recovery events in the persisted outbox first;
  - update `last_*_notified_at` only after every webhook target for that event succeeds;
  - keep webhook secrets in config, not copied into persisted state.
- Ping tokens are accepted through the `x-sema-token` header, not URL paths.

# Coding Notes

- Comments in code should explain why, not how.
- Prefer small functions and explicit data transformations.
