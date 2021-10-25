{ pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    vimAlias = true;
    defaultEditor = true;
  };

  services.shadowsocks = {
    enable = true;
    port = 53232;
    encryptionMethod = "aes-256-gcm";
    passwordFile = "/persist/shadowsocks.txt";
  };

  environment.systemPackages = with pkgs; [
    htop
    curl
    ncdu
  ];
}
