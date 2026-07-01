# AGENTS.md

Last verified: 2026-07-01
Audience: future coding agents / LLMs
Goal: understand this repo quickly and change it safely.

## 1. What this repo is

Flake-based, declarative multi-host NixOS repository.

- `hawkpoint`: local desktop, Niri + Home Manager.
- Remote VPS/server fleet: most hosts use the shared server baseline; some are DN42 nodes.
- `nixiso` and `bootstrap`: installer/bootstrap targets.

## 2. Entry points

- `flake.nix`: wires inputs and outputs.
- `nixos/default.nix`: host table, `nixosConfigurations`, and Colmena hive generation.
- `overlay/default.nix`: imports local packages from `pkgs/*`.
- `pkgs/default.nix`: local package enumeration and nix-update batch list.

Important flake outputs:

- `nixosConfigurations`: all hosts as normal NixOS systems.
- `colmena`: deployable hosts only (`deploy = true`) in Colmena hive shape.
- `colmenaHive`: `inputs.colmena.lib.makeHive self.outputs.colmena`.
- `packages`: all local packages under `pkgs/*`.
- `overlays.default`: local overlay.

## 3. Repository layout

Stable locations:

- `flake.nix`: flake inputs, dev shell, packages, Colmena outputs.
- `nixos/default.nix`: host inventory and system/hive builders.
- `nixos/common`: modules shared by hosts with `useCommon = true`.
- `nixos/<host>`: per-host NixOS modules and secrets.
- `overlay/default.nix`: local overlay entry point.
- `pkgs`: local packages.

Do not duplicate the full host or service directory tree here; `nixos/default.nix`
and the filesystem are the source of truth.

## 4. Host table rules

All host inventory lives in `nixos/default.nix`: add normal hosts to
`hostNames`, put only exceptions in `hosts`, and assign Colmena selectors in
`hostTags`.

Per-host fields:

- `system`: optional target system; defaults to `x86_64-linux`.
- `path`: optional host module directory; defaults to `./${hostName}`.
- `deploy`: optional; defaults to true for Colmena, set false to exclude.
- `useCommon`: defaults to true; false skips `nixos/common`.
- `extra`: extra NixOS modules; defaults to `defaults.extra`.
- `targetHost`: Colmena SSH host; defaults to host attr name.
- `targetUser`: Colmena SSH user; defaults to `root`.
- `targetPort`: optional Colmena SSH port.
- `tags`: do not set per host; add hosts under `hostTags.<tag>` instead.
- `buildOnTarget`: optional Colmena remote-build flag; defaults to true.

`specialArgs` for every host:

- `inputs`
- `overlays`
- `hostName`

Do not assume changes under `nixos/common` affect `useCommon = false` hosts.

## 5. Deployment

Deployment uses Colmena, not deploy-rs.

Common commands:

```bash
# deploy one host; local build, then push closure
colmena apply --on liteserver -p 8

# deploy selected hosts in parallel
colmena apply --on nosla-sjc,nosla-lax -p 8

# build locally only
colmena build --on liteserver

# push closure only, no activation
colmena apply push --on liteserver

# activation variants
colmena apply test --on liteserver
colmena apply dry-activate --on liteserver
colmena apply boot --on liteserver
```

Colmena defaults to local build + push closure. Use `buildOnTarget = true;` in
the host table, or CLI `--build-on-target`, only when the target should build
its own system profile.

There is no deploy-rs `fastConnection`, `magicRollback`, or `autoRollback`.
Treat SSH, firewall, networkd, bootloader, kernel, and disko changes as high
risk; a broken remote deploy may require provider console access.

## 6. Shared modules and options

Repo-local service options live under `my.services.*`, usually implemented in
`nixos/common/services/*`.

Current important options:

- `my.services.caddy`
- `my.services.dn42`
- `my.services.dn42.peers`
- `my.services.komari-agent`
- `my.services.postgresql`
- `my.services.prometheus-node`
- `my.services.sema`
- `my.services.sing-box`
- `my.services.wg-mgmt`

Prefer adding a small reusable module under `nixos/common/services` when at
least two hosts need the same behavior. For one host, keep it in that host.

## 7. DN42

DN42 is provided by `nix-dn42` plus repo modules under `nixos/common/services/dn42`.

- Internal mesh: `my.services.dn42` + `networking.dn42`.
- External peers: `my.services.dn42.peers.<name>`.
- Bird config is assembled by the DN42 modules; parse-check bird config after changes.
- WireGuard keys come from SOPS secrets; never commit plaintext keys.

Adding an external peer should usually only touch the target host's `default.nix`.

## 8. Local packages

Local packages are auto-imported from subdirectories under `pkgs/*` by
`pkgs/default.nix` and `overlay/default.nix`.

`nix-update-hashes` updates the explicit list in
`pkgs/default.nix:updateablePackageNames`:

```bash
nix develop -c nix-update-hashes
nix develop -c nix-update-hashes --commit
```

Keep the updateable list explicit. Do not infer updateability from random src
attributes; packages without a normal upstream version can stay out.

Notable packages:

- `caddy-cloudflare`: custom Caddy build with Cloudflare DNS plugin.
- `caddy-dns-cloudflare`: source-only plugin package.
- `cybergroupmate`: pnpm-based upstream package.
- `sema`: Rust dead man's switch webhook server.
- `xsz`: Rust package with checked-in `Cargo.lock`.

## 9. Secrets

- SOPS policy: `.sops.yaml`.
- Per-host secrets: `nixos/<host>/secrets.yaml`.
- Shared secrets: `nixos/common/secrets.yaml`.
- Local management key: `diffumist` age key is included in rules.

Edit encrypted files with:

```bash
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops nixos/<host>/secrets.yaml
```

Never commit plaintext credentials. After changing secrets, build or evaluate
at least the affected host.

## 10. Safe change checklist

Before merging infrastructure changes:

1. Identify affected hosts.
2. Keep the diff scoped; avoid unrelated cleanup.
3. Build or eval touched hosts.
4. For DN42/Bird changes, parse-check generated Bird config.
5. For sing-box changes, validate decrypted config with `sing-box check`.
6. Call out anything not tested.

High-risk areas:

- SSH
- firewall / nftables / networkd
- bootloader / kernel / disko
- secrets paths and permissions
- Colmena hive generation

## 11. Documentation lookup

For Nix/NixOS questions, prefer `mcp-nixos` first. Use upstream docs or
`context7` only when `mcp-nixos` is insufficient or the topic is outside Nix.

## 12. Useful commands

```bash
# global checks
nix flake check

# build local desktop
nix build .#nixosConfigurations.hawkpoint.config.system.build.toplevel

# build one remote host
nix build .#nixosConfigurations.liteserver.config.system.build.toplevel

# build installer ISO
nix build .#nixosConfigurations.nixiso.config.system.build.isoImage

# inspect Colmena nodes
nix eval --json .#colmenaHive.nodes --apply builtins.attrNames

# deploy one host
colmena apply --on liteserver -p 8
```
