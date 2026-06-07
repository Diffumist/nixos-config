# AGENTS.md

Last verified: 2026-06-07
Audience: future coding agents / LLMs
Goal: understand this repo quickly and refactor safely.

## 1. What this repo is

This is a flake-based, declarative multi-host NixOS repository.

- Local primary machine: `hawkpoint` (desktop, Niri + Home Manager).
- A fleet of remote VPS/server hosts (most are also DN42 nodes).
- Installer/bootstrap hosts: `nixiso` (custom ISO) and `bootstrap`.

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
4. `nixos/deploy.nix` generates deploy-rs nodes from hosts where `deploy = true`.

## 3. Repository structure (high signal)

```text
.
├── flake.nix
├── overlay/default.nix
├── pkgs/                          # auto-imported into overlays.default
└── nixos/
    ├── default.nix                # host table + mkHost
    ├── deploy.nix                 # deploy-rs nodes (deploy == true)
    ├── common/
    │   ├── default.nix            # shared module set (imported by useCommon hosts)
    │   ├── nixconfig.nix
    │   ├── kernel.nix
    │   ├── secrets.yaml
    │   └── services/
    │       ├── sshd.nix  fail2ban.nix  caddy.nix
    │       ├── dn42.nix           # DN42 identity + internal babel mesh
    │       ├── dn42-peer.nix      # external eBGP peers (my.services.dn42-peers)
    │       ├── sing-box.nix  postgresql.nix  komari.nix
    ├── hawkpoint/                 # desktop (useCommon = false)
    ├── nixiso/  bootstrap/        # installer / bootstrap (useCommon = false)
    └── <remote hosts>/            # default.nix [+ boot.nix] [+ services/] [+ secrets.yaml]
```

## 4. Host inventory and status

`deploy` column reflects `nixos/default.nix`. Region names in parens are the
host's DN42 PoP label (see §6).

| Host | deploy | Role / notes |
|---|---|---|
| `hawkpoint` | no | Local desktop. Niri + Home Manager, CachyOS kernel. `useCommon = false`. |
| `liteserver` (ams-0) | yes | Service node + DN42. Immich, rqbit, sing-box. |
| `hostdzire` (sjc-0) | yes | Service node + DN42. authelia, lldap, vaultwarden, tgtldr, bub. |
| `vmrack` (lax-0) | yes | DN42 node + sing-box (IPv4-only uplink). |
| `dedirock` (lax-1) | yes | Service node + DN42. sillytavern, rustypaste, sing-box. |
| `geelinx-jp` (tyo-0) | yes | DN42 node + sing-box. |
| `phoenix` | yes | Service node. attic, forgejo, code-server, cyber. Not a DN42 node. |
| `geelinx-mys` | yes | Minimal node (no services dir yet). |
| `nosla-lax` | yes | sing-box node. |
| `nosla-sjc` | yes | sing-box node. |
| `colocrossing` | yes | sing-box, snac, komari-monitor. |
| `solidvps` | yes | sing-box node. |
| `texas` | no | Configured but not deployed. |
| `nixiso` | no | Custom installer ISO. `useCommon = false`. |
| `bootstrap` | no | Bootstrap/install host. `useCommon = false`. |

Note: `nixos/common/` is a shared module dir, not a host.

## 5. Core module rules (important invariants)

From `nixos/default.nix`:

- Overlays applied to every host's `pkgs`:
  - `self.overlays.default`, `llm-agents`, `quickshell`, `nix-cachyos-kernel`,
    `nix-vscode-extensions`, `nix-dn42`.
- Global default extra modules (`defaults.extra`):
  - `disko`, `sops-nix`, `hermes-agent`, `impermanence`,
    `nur-xddxdd` (`setupOverlay`), `nix-dn42`.
- `specialArgs` passed to every host: `inputs`, `overlays`, `hostName`.
- Per-host knobs in the `hosts` table: `system`, `path`, `deploy`,
  `useCommon` (default true), `extra` (default `defaults.extra`).
- Special hosts (`useCommon = false`): `hawkpoint`, `nixiso`, `bootstrap`.
  - `hawkpoint` adds `home-manager` + `dms-plugin-registry` and imports
    `../common/nixconfig.nix` manually.

Consequence:
- Changes in `nixos/common/default.nix` do not affect `useCommon = false` hosts.
- Shared behavior should be explicit reusable modules, not assumed inheritance.

### Option convention

Repo-local options live under `my.services.*` (see `common/services/*.nix`),
e.g. `my.services.sing-box`, `my.services.postgresql`, `my.services.caddy`,
`my.services.komari-agent`, `my.services.dn42-peers`. Hosts enable/configure
these in their own `default.nix` — keep the same style when adding services.

## 6. DN42 (current, significant)

Provided by the `nix-dn42` input (`networking.dn42.*`). Two layers:

- Internal mesh — `common/services/dn42.nix`. A WireGuard full-mesh between the
  DN42 member nodes, with **babel** as the IGP (not OSPF — babel suits tunnel
  meshes). Members and PoP labels:
  `liteserver=ams-0`, `hostdzire=sjc-0`, `dedirock=lax-0`,
  `geelinx-jp=tyo-0`. ASN `4242420642`, IPv4 `172.22.64.64/27`, IPv6
  `fd22:1056:95a4::/48`. ROA enabled via `dn42-registry` input. Each node has a
  single WireGuard keypair shared across all its tunnels (`dn42_wg_private_key`);
  tunnels are distinguished by port/interface.
- External eBGP peers — `common/services/dn42-peer.nix` defines the
  `my.services.dn42-peers.<name>` option (typed submodule). Each peer creates a
  WireGuard interface + a bird BGP protocol from the `dn42_peer` template
  (link-local + extended-next-hop). Defaults: `interface = wg-<name>`,
  `localLinkLocal = fe80::642`, `mtu = 1420`, shared `dn42_wg_private_key`.
  Hosts declare peers in their own `default.nix`. Currently configured:
  `dedirock`,`liteserver`,`geelinx-jp`,`hostdzire`.

Adding a peer = add a `my.services.dn42-peers.<name>` block to the host; no
changes to the module. eBGP needs TCP/179 on the peer interface and the peer's
WireGuard listen port open (the module handles both).

## 7. Remote-server pattern (current)

Observed on the DN42/service hosts:
- `systemd-networkd` static networking (often via a sops `10-lan.network` template)
- `disko` declarative disk layout
- `impermanence` persistence under `/persist`, tmpfs root
- `nftables` firewall, `useNetworkd = true`

Treat this as the intended server baseline, not yet fully normalized into a
single shared server module.

## 8. External inputs and why they exist

- `Mic92/sops-nix`: declarative secret decryption/permissions.
- `nix-community/disko`: declarative partition/filesystem config.
- `nix-community/impermanence`: persist allowlisted paths, rest ephemeral.
- `serokell/deploy-rs`: remote NixOS deployment.
- `nix-dn42` (`~prince213/nix-dn42`): `networking.dn42` module (babel/ospf/bgp).
- `dn42-registry`: DN42 registry checkout for ROA generation.
- `xddxdd/nur-packages`: extra packages/modules (`setupOverlay`).
- `xddxdd/nix-cachyos-kernel`: CachyOS kernel overlay.
- `nix-community/nix-vscode-extensions`: VSCode/VSCodium extensions overlay.
- `home-manager`, `dms-plugin-registry`, `llm-agents`, `quickshell`,
  `hermes-agent`: desktop / agent / app modules and overlays.

## 9. Secrets model

- SOPS policy: `./.sops.yaml` (per-host age recipients; `diffumist` key is in
  every rule for local management).
- Rule pattern: per-host `nixos/<host>/{*.json,*.yaml,*.keytab}` encrypted to
  that host's age key + `diffumist`.
- Per-host `secrets.yaml` files exist for most deployed hosts; `common/secrets.yaml`
  holds shared secrets.

Rules for refactor:
- Never commit plaintext credentials.
- Keep per-host secret files at `nixos/<host>/secrets.yaml`.
- To edit an encrypted file: `SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops <file>`
  (the `diffumist` key can decrypt all of them).
- After secrets changes, run at least one host-specific build/check.

## 10. Deployment model

- File: `nixos/deploy.nix` (deploy-rs nodes from hosts with `deploy = true`).
- Connection defaults: `user = "root"`, `sshUser = "root"`, `fastConnection = false`.
- **`autoRollback = false` and `magicRollback = false`** (marked DEBUG) — there is
  currently NO automatic rollback safety net. A bad deploy that drops SSH must be
  fixed via the provider console. Touch SSH / firewall / networkd carefully.

## 11. Known debt and refactor opportunities

1. Repeated server `boot.nix` / networking logic across hosts — good candidate
   for a shared `common/server` base module.
2. Minimal/placeholder hosts: `geelinx-mys`, `texas` (and varying completeness
   across the sing-box-only nodes).
3. deploy-rs rollback is disabled — re-enable `magicRollback` once link config is
   trusted, or toggle per risky deploy.
4. `nix-dn42` external peering is hand-declared per host; fine while peer count is
   small. Each node still shares one WireGuard key across all peers — if a peer
   portal requires unique keys, use the per-peer `privateKeyFile` override.

## 12. Safe change checklist

Before merging infrastructure changes:
1. Confirm impact scope (desktop / installer / which remote hosts).
2. Keep diff minimal; avoid unrelated cleanup.
3. Build the touched hosts (see §14).
4. For DN42/bird changes, parse-check bird (`bird -p -c <generated bird.conf>`).
5. For sing-box changes, validate (`sing-box check -c <decrypted config>`).
6. Explicitly call out untested parts.

High-risk areas (flag in PR notes):
- SSH
- firewall / nftables / networkd
- bootloader / kernel / disko
- deploy-rs node generation (no rollback)

## 13. Documentation lookup priority

When consulting documentation during implementation or refactors:
1. Prefer `mcp-nixos` first (NixOS/Home Manager/flake/Nix ecosystem references).
2. Use `context7` second when `mcp-nixos` is insufficient or the topic is outside
   Nix scope (e.g. sing-box, bird, dn42 tooling).

Do not skip `mcp-nixos` for Nix-related questions unless it is unavailable.

## 14. Useful commands

```bash
# global checks
nix flake check

# build local desktop system closure
nix build .#nixosConfigurations.hawkpoint.config.system.build.toplevel

# build custom ISO
nix build .#nixosConfigurations.nixiso.config.system.build.isoImage

# build a remote host closure (example)
nix build .#nixosConfigurations.liteserver.config.system.build.toplevel

# deploy a single host (no auto-rollback — verify connectivity after)
deploy -s '.#liteserver'
```

Use phased deploys; avoid all-host rollout, especially while rollback is disabled.
