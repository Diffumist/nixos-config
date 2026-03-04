# AGENTS.md

Last verified: 2026-02-25
Audience: future coding agents / LLMs
Goal: understand this repo quickly and refactor safely.

## 1. What this repo is

This is a flake-based, declarative multi-host NixOS repository.

- Local primary machine: `hawkpoint` (desktop, Niri + Home Manager).
- Remote machines: VPS/server hosts (partially complete).
- Installer image host: `nixiso` (custom NixOS ISO for VPS bootstrap).

## 2. Entry points and build graph

Primary entry point:
- `flake.nix`

Outputs:
- `nixosConfigurations` -> from `./nixos/default.nix`
- `deploy` -> from `./nixos/deploy.nix`
- `overlays.default` -> from `./overlay/default.nix`

Build flow:
1. `flake.nix` wires inputs and outputs.
2. `nixos/default.nix` defines all hosts in `hosts` and builds them via `lib.nixosSystem`.
3. `overlay/default.nix` auto-imports every package under `pkgs/*`.
4. `nixos/deploy.nix` generates deploy-rs nodes from `nixosConfigurations` (excluding `hawkpoint`, `nixiso`).

## 3. Repository structure (high signal)

```text
.
├── flake.nix
├── overlay/default.nix
├── pkgs/
│   ├── apple-emoji/default.nix
│   └── systemd-run-app/default.nix
└── nixos/
    ├── default.nix
    ├── deploy.nix
    ├── common/
    │   ├── default.nix
    │   ├── nixconfig.nix
    │   ├── secrets.yaml
    │   └── services/{sshd.nix,fail2ban.nix}
    ├── hawkpoint/{default.nix,boot.nix,hardware.nix,home/default.nix}
    ├── nixiso/{default.nix,boot.nix,disko.nix}
    ├── liteserver/{default.nix,boot.nix,secrets.yaml,services/*}
    ├── phoenix/{default.nix,boot.nix,services/*}
    ├── dedirock/{default.nix,boot.nix}
    ├── solidvps/default.nix       # empty placeholder
    ├── colocrossing/default.nix   # empty placeholder
    └── qiniu/default.nix          # empty placeholder
```

## 4. Host inventory and status

| Host | Role | Status | Notes |
|---|---|---|---|
| `hawkpoint` | Local desktop | Mature | Niri + Noctalia + Home Manager, CachyOS kernel overlay. |
| `nixiso` | Custom installer ISO | Usable | Used to bootstrap VPS from provider panel ISO mount. |
| `liteserver` | Remote service node | Partial | Caddy, EasyTier, Immich, rqbit, SOPS secrets. |
| `phoenix` | Remote service node | Partial | Vaultwarden configured; `services/caddy.nix` is empty. |
| `dedirock` | Remote node | Partial | Base boot/network present, fewer app services. |
| `solidvps` | Remote node | Incomplete | `default.nix` empty placeholder. |
| `colocrossing` | Remote node | Incomplete | `default.nix` empty placeholder. |
| `qiniu` | Remote node | Incomplete | `default.nix` empty placeholder. |

## 5. Core module rules (important invariants)

From `nixos/default.nix`:

- Global default extra modules:
  - `disko`
  - `sops-nix`
  - `impermanence`
  - `nur-xddxdd` modules
- `specialArgs` passed to every host:
  - `inputs`
  - `overlays`
  - `hostName`
- `hawkpoint` is special:
  - `useCommon = false`
  - still imports `../common/nixconfig.nix` manually in `nixos/hawkpoint/default.nix`
  - adds `home-manager` and `noctalia` modules

Consequence:
- Changes in `nixos/common/default.nix` do not automatically affect `hawkpoint`.
- Shared host behavior should usually be refactored into explicit reusable modules, not assumed global inheritance.

## 6. Local machine profile (`hawkpoint`)

Owner-declared hardware:
- CPU: AMD 8745HS
- iGPU: AMD Radeon 780M

Configured stack:
- WM/compositor: `programs.niri.enable = true`
- Shell layer: `services.noctalia-shell.enable = true` (Quickshell preset)
- User environment: Home Manager (`nixos/hawkpoint/home/default.nix`)
- Kernel: `pkgs.cachyosKernels.linuxPackages-cachyos-latest-lto-zen4`

Interpretation:
- This host is the reference desktop target and the safest place to validate UX-related changes.

## 7. Remote-server pattern (current)

Observed on multiple remote hosts (`liteserver`, `phoenix`, `dedirock`):
- `systemd-networkd` static networking
- `disko` declarative disk layout
- `impermanence` persistence under `/persist`
- `tmpfs` root style + persisted state directories/files

Treat this as the intended server baseline, but not fully normalized yet.

## 8. External inputs and why they exist

- `Mic92/sops-nix`: declarative secret decryption/permissions.
- `nix-community/disko`: declarative partition/filesystem config in Nix.
- `serokell/deploy-rs`: remote NixOS deployment.
- `nix-community/impermanence`: persist allowlisted paths, keep rest ephemeral.
- `noctalia-dev/noctalia-shell`: Quickshell preset for richer desktop shell with Niri.
- `xddxdd/nur-packages`: extra package/module source.
- `nix-community/nix-vscode-extensions`: extensions overlay for VSCode/VSCodium.
- `xddxdd/nix-cachyos-kernel`: third-party CachyOS kernel overlay.

## 9. Secrets model

- SOPS policy: `./.sops.yaml`
- Current rule: `nixos/[^/]+/secrets.yaml`
- Existing secrets files:
  - `nixos/common/secrets.yaml`
  - `nixos/liteserver/secrets.yaml`

Rules for refactor:
- Never commit plaintext credentials.
- Keep per-host secret files at `nixos/<host>/secrets.yaml`.
- After secrets changes, run at least one host-specific build/check.

## 10. Deployment model

- File: `nixos/deploy.nix`
- deploy-rs nodes are generated from `self.nixosConfigurations`.
- Excluded hosts: `nixiso`, `hawkpoint`.
- Connection defaults:
  - `user = "root"`
  - `sshUser = "diffumist"`

Risk:
- Placeholder hosts are still declared in `hosts`; keep deploy scope controlled until configs are complete.

## 11. Known debt and refactor opportunities

High-priority debt:
1. Empty host configs: `solidvps`, `colocrossing`, `qiniu`.
2. Empty service module: `nixos/phoenix/services/caddy.nix`.
3. Repeated server `boot.nix` logic across hosts (good candidate for shared server base module).

Recommended refactor sequence:
1. Create `nixos/common/server` base module for shared boot/network/persistence defaults.
2. Convert each remote host to thin host-specific overrides.
3. Complete placeholder hosts with minimum viable configs.
4. Add per-host validation commands (documented and runnable).
5. Revisit deploy targeting strategy after host completeness improves.

## 12. Safe change checklist

Before merging infrastructure changes:
1. Confirm impact scope (`hawkpoint`, `nixiso`, or remote hosts).
2. Keep diff minimal and avoid unrelated cleanup.
3. Run checks/build for touched hosts.
4. Explicitly call out untested parts.

High-risk areas (flag in PR notes):
- SSH
- firewall/networkd
- bootloader/kernel/disko
- deploy-rs node generation

## 13. Useful commands

```bash
# global checks
nix flake check

# build local desktop system closure
nix build .#nixosConfigurations.hawkpoint.config.system.build.toplevel

# build custom ISO
nix build .#nixosConfigurations.nixiso.config.system.build.isoImage

# build a remote host closure (example)
nix build .#nixosConfigurations.liteserver.config.system.build.toplevel
```

Use phased deploys; avoid all-host rollout when remote configs are incomplete.

## 14. Documentation lookup priority

When consulting documentation during implementation or refactors:
1. Prefer `mcp-nixos` first (NixOS/Home Manager/flake/Nix ecosystem references).
2. Use `context7` second when `mcp-nixos` is insufficient or the topic is outside Nix scope.

Do not skip `mcp-nixos` for Nix-related questions unless it is unavailable.
