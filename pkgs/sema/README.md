# sema

`sema` is a small dead man's switch webhook server.

## Run

```bash
cp sema.example.toml sema.toml
sema --config sema.toml
```

Ping a check:

```bash
curl -X POST -H 'x-sema-token: replace-with-a-long-random-token' http://127.0.0.1:8080/ping
```

Inspect state:

```bash
curl http://127.0.0.1:8080/status
```

## Behavior

- A check becomes down after `period_seconds + grace_seconds` without a ping.
- During process startup, each check gets its `grace_seconds` window before it can be marked down.
- First down transition queues a `down` webhook.
- Continued down state does not notify again unless `remind_every_seconds` has elapsed.
- A ping after down queues one `recovery` webhook.
- Webhook delivery uses a persistent outbox: failed deliveries stay queued and
  are retried by later scans.
- State writes use same-directory temp files and atomic rename.
- Tokens are accepted through the `x-sema-token` header to avoid putting secrets
  in URL paths and access logs.
