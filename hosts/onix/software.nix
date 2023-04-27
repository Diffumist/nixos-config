{ pkgs, config, ... }: {

  environment.sessionVariables = {
    WINIT_X11_SCALE_FACTOR = "1.5"; # Ref: https://github.com/alacritty/alacritty/issues/3792
  };

  programs.adb.enable = true;
  users.groups."adbusers".members = [ "diffumist" ];

  services.earlyoom = {
    enable = true;
    enableNotifications = true;
  };

  virtualisation = {
    podman.enable = true;
    oci-containers.backend = "podman";
  };

  programs.fish.enable = true;
  programs.fish.useBabelfish = true;
}
