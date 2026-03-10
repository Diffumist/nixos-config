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
    # ./services/sing-box.nix
    # ./services/netbird.nix
    # ./services/immich.nix
    # ./services/rqbit.nix
  ];

  networking = {
    nftables.enable = true;
    useNetworkd = true;
    networkmanager.enable = false;
  };

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
  networking.hostName = "liteserver";
}
