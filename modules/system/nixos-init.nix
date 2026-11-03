{
  boot.kernelParams = [ "systemd.machine_id=firmware" ];

  services.userborn.enable = true;

  system = {
    nixos-init.enable = true;
    etc.overlay = {
      enable = true;
      mutable = true;
    };
  };
}
