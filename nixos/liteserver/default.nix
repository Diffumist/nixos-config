{
  pkgs,
  config,
  inputs,
  self,
  ...
}:
{
  imports = [
    ./boot.nix
    ./services/fail2ban.nix
    ./services/nginx.nix
    ./services/vaultwarden.nix
  ];

  networking = {
    useDHCP = true;
    hostName = "liteserver";
  };

  users.users."diffumist" = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
    ];
    shell = pkgs.fish;
    hashedPasswordFile = config.sops.secrets.root_password_hash.path;
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.diffumist = {
      imports = [
        ./liteserver/home.nix
      ];
    };
  };
}
