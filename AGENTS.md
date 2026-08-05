# AGENTS.md

Last verified: 2026-08-02
Audience: future coding agents / LLMs
Goal: understand this repo quickly and change it safely.

## 1. What this repo is

Flake-based, declarative multi-host NixOS repository.

- `hawkpoint-lap`: local desktop, Niri + Home Manager.
- Remote VPS/server fleet: most hosts use the shared server baseline; some are DN42 nodes.
- `nixiso` and `bootstrap`: installer/bootstrap targets.

## 2. Entry points

- `flake.nix`: wires inputs and outputs.
- `hosts/default.nix`: host table, `nixosConfigurations`, and Colmena hive generation.
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
- `hosts/default.nix`: host inventory and system/hive builders.
- `profiles/base/server.nix`: shared server policy.
- `profiles/roles`: explicit opt-in behavior such as containers, DN42, and fail2ban.
- `profiles/common`: shared profile fragments and DN42 topology data.
- `modules/default.nix`: registry for reusable repo-local NixOS modules.
- `hosts/<host>`: per-host NixOS modules and secrets.
- `overlay/default.nix`: local overlay entry point.
- `pkgs`: local packages.

Do not duplicate the full host or service directory tree here; `hosts/default.nix`
and the filesystem are the source of truth.

## 4. Host table rules

All host inventory lives in the single `inventory` attrset in
`hosts/default.nix`. Host names, NixOS systems, Colmena nodes and tags, and CI
systems are derived from it.

Per-host fields:

- `stateVersion`: required NixOS state version.
- `roles`: explicit host capabilities; `server`, `container`, `dn42`, and
  `fail2ban` compose server behavior, while `desktop` selects desktop overlays.
- `tags`: Colmena selectors assigned directly to the host.
- `system`: optional target system; defaults to `x86_64-linux`.
- `path`: optional host module directory; defaults to `./${hostName}`.
- `deploy`: optional; defaults to true for Colmena, set false to exclude.
- `ciBuild`: optional; defaults to `deploy`.
- `externalModules`: optional replacement for the default external module set.
- `modules`: optional extra NixOS modules.
- `targetHost`: Colmena SSH host; defaults to host attr name.
- `targetUser`: Colmena SSH user; defaults to `root`.
- `targetPort`: optional Colmena SSH port.
- `buildOnTarget`: optional Colmena remote-build flag; defaults to false.

`specialArgs` for every host:

- `inputs`
- `overlays`
- `self`
- `hostName`
- `hostPath`
- `hostRoles`
- `hostTags`

`modules/system/hostname.nix` sets `networking.hostName` from `hostName` with
`mkDefault`; keep explicit per-host `networking.hostName` only for deliberate
overrides.
`modules/system/sops.nix` sets `sops.defaultSopsFile` from `hostPath`, so normal
hosts do not need to repeat `./secrets.yaml`.
The `server` role imports `modules/default.nix` and
`profiles/base/server.nix`. Optional server behavior must remain in explicit
roles rather than the server baseline.

## 5. Deployment

Deployment uses Colmena, not deploy-rs.

Common commands:

```bash
# deploy one host; local build, then push closure
colmena apply --on liteserver-ams -p 8

# deploy selected hosts in parallel
colmena apply --on nosla-sjc,vmiss-lax -p 8

# build locally only
colmena build --on liteserver-ams

# push closure only, no activation
colmena apply push --on liteserver-ams

# activation variants
colmena apply test --on liteserver-ams
colmena apply dry-activate --on liteserver-ams
colmena apply boot --on liteserver-ams
```

Colmena defaults to local build + push closure. Use `buildOnTarget = true;` in
the host table, or CLI `--build-on-target`, only when the target should build
its own system profile.

There is no deploy-rs `fastConnection`, `magicRollback`, or `autoRollback`.
Treat SSH, firewall, networkd, bootloader, kernel, and disko changes as high
risk; a broken remote deploy may require provider console access.

## 6. Shared modules and options

Repo-local service options live under `my.services.*`, usually implemented in
`modules/services/*` and registered by `modules/default.nix`.

Current important options:

- `my.services.caddy`
- `my.services.dn42`
- `my.services.dn42.peers`
- `my.services.postgresql`
- `my.services.prometheus-node`
- `my.services.sema`
- `my.services.sing-box`

Prefer adding a small reusable module under `modules/services` when at
least two hosts need the same behavior. For one host, keep it in that host.

## 7. DN42

DN42 is provided by `nix-dn42` plus repo modules under `modules/services/dn42`.
The repo mesh topology lives in `profiles/common/services/dn42.nix`; external
peer data lives in `profiles/common/services/dn42-peers.nix`.

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
- Per-host secrets: `hosts/<host>/secrets.yaml`.
- Shared secrets: encrypted files under `profiles/common/secrets/`.
- Local management key: `diffumist` age key is included in rules.

Edit encrypted files with:

```bash
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops hosts/<host>/secrets.yaml
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
nix build .#nixosConfigurations.hawkpoint-lap.config.system.build.toplevel

# build one remote host
nix build .#nixosConfigurations.liteserver-ams.config.system.build.toplevel

# build installer ISO
nix build .#nixosConfigurations.nixiso.config.system.build.isoImage

# inspect Colmena nodes
nix eval --json .#colmenaHive.nodes --apply builtins.attrNames

# deploy one host
colmena apply --on liteserver-ams -p 8
```
