{
  default = (
    { ... }:
    {
      imports = [
        (import ./nix)
        (import ./desktop)
        (import ./program)
        (import ./hardware)
        (import ./baseline)
        (import ./virtualisation)
      ];
    }
  );
  cloud = (
    { ... }:
    {
      imports = [
        (import ./services/acme.nix)
        (import ./services/fail2ban.nix)
        (import ./services/nginx.nix)
        (import ./services/sshd.nix)
        (import ./services/vaultwarden.nix)
      ];
    }
  );
}
