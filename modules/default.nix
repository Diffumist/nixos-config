[
  # env
  ./base
  ./cloud
  ./nix-config.nix

  ./services/gnome-env
  ./hardware

  # networking
  ./services/clash.nix
  ./services/nginx/xray.nix
  ./services/transmission.nix
  # web services
  ./services/nginx
  ./services/nginx/vaultwarden.nix
  ./services/nginx/acme.nix
  ./services/nginx/fail2ban.nix
]
