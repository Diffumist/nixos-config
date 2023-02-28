{ ... }: {
  imports = [
    # env
    (import ./base)
    (import ./cloud)
    (import ./nix-config.nix)
    (import ./services/gnome-env)
    (import ./hardware)
    # networking
    (import ./services/clash.nix)
    (import ./services/transmission.nix)
    # web services
    (import ./services/nginx)
    (import ./services/nginx/vaultwarden.nix)
    (import ./services/nginx/acme.nix)
    (import ./services/nginx/fail2ban.nix)
    (import ./services/nginx/xray.nix)
  ];
}
