{
  imports = [
    ./hardware/ephemeral-btrfs.nix
    ./system/static-network.nix
    ./services/caddy.nix
    ./services/dst-server.nix
    ./services/garage.nix
    ./services/komari.nix
    ./services/mihomo-server.nix
    ./services/monitoring-agent.nix
    ./services/postgresql.nix
    ./services/prometheus-node.nix
    ./services/sema.nix
    ./services/sing-box.nix
  ];
}
