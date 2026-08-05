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
    ./services/dufs.nix
    ./services/knot.nix
    ./services/flap-damping.nix
  ];
  my.networking.static = {
    enable = true;
    macAddress = "bc:24:11:f0:69:6b";
    ipv4.prefixLength = 24;
    ipv6 = {
      enable = true;
      acceptRA = false;
    };
  };

  nixpkgs.flake = {
    setFlakeRegistry = false;
    setNixPath = false;
  };
  system.disableInstallerTools = true;

  my.services.sing-box = {
    enable = true;
    domain = "overload-reshoot-aids-silencer.503418.xyz";
    port = 8443;
  };

  environment.etc."vnstat.conf".text = ''
    MonthRotate 5
  '';
}
