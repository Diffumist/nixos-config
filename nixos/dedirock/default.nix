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
          "216.45.50.94/25"
          "2607:9d00:2000:f8::a51d:57e1/64"
        ];
        Gateway = [
          "216.45.50.1"
          "2607:9d00:2000:f8::1"
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
  networking.hostName = "dedirock";
}
