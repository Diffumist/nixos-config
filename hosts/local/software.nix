{ pkgs, config, ... }: {
  # HiDPI display
  hardware.video.hidpi.enable = true;
  console.font = "${pkgs.terminus_font}/share/consolefonts/ter-u24n.psf.gz";

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
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        ovmf.enable = true;
        verbatimConfig = ''
          seccomp_sandbox = 0
          capability_filters = [ "device.json" ]
        '';
      };
    };
    kvmgt = {
      enable = true;
      vgpus.i915-GVTg_V5_4.uuid = [ "9dfe21be-dd2f-411e-b21c-6eef9c8b3703" ];
    };
    podman.enable = true;
    oci-containers.backend = "podman";
  };
  users.groups."libvirtd".members = [ "diffumist" ];

  programs.fish.enable = true;
  programs.fish.useBabelfish = true;
}
