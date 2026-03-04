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
    
    # ./services/caddy.nix
    # ./services/easytier.nix
    ./services/vaultwarden.nix
  ];

  networking.networkmanager.enable = false;
  networking.useNetworkd = true;
  systemd.network = {
    enable = true;
    networks."10-lan" = {
      matchConfig.Name = "ens3";
      networkConfig = {
        Address = [
          "150.129.9.29/24"
          "2a04:52c0:0138:d282::8964"
        ];
        Gateway = [
          "150.129.9.1"
          "2a04:52c0:0138:d282::1"
        ];
        DNS = [
          "1.0.0.1"
          "8.8.4.4"
          "2606:4700:4700::1001"
          "2001:4860:4860::8844"
        ];
      };
    };
  };
  networking.hostName = "phoenix";
}
