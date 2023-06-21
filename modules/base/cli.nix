{ pkgs, ... }: {
  services.earlyoom = {
    enable = true;
    enableNotifications = true;
  };

  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
    };
    oci-containers.backend = "podman";
  };

  programs.fish.enable = true;
  programs.fish.useBabelfish = true;

  environment.systemPackages = with pkgs; [
    fd
    bat
    exa
    duf
    neovim
    ripgrep
    binutils
    dnsutils
    pciutils
    tealdeer
    man-pages
    libarchive
  ];
}
