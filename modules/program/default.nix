{ pkgs, ... }:
{
  programs.fish.enable = true;
  programs.fish.useBabelfish = true;

  programs.adb.enable = true;
  users.groups."adbusers".members = [ "diffumist" ];

  environment.systemPackages = with pkgs; [
    fd
    xh
    bat
    eza
    duf
    ncdu
    btop
    comma
    neovim
    patchelf
    ripgrep
    binutils
    dnsutils
    pciutils
    tealdeer
    man-pages
    libarchive
  ];
}
