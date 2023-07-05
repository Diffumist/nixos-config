{
  default =
    ({ ... }: {
      imports = [
        # env
        (import ./base/cli.nix)
        (import ./base/nix-config.nix)
        (import ./services/gnome-env)
        (import ./hardware)
      ];
    });
  server =
    ({ ... }: {
      imports = [
        # env
        (import ./base)
        (import ./base/cli.nix)
        (import ./base/nix-config.nix)
      ];
    });
  services =
    ({ ... }: {
      imports = [
        # web services
        (import ./services/nginx)
        (import ./services/nginx/vaultwarden.nix)
        (import ./services/nginx/acme.nix)
        (import ./services/nginx/fail2ban.nix)
        (import ./services/nginx/xray.nix)
      ];
    });

}
