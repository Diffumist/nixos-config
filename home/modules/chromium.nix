{ lib, pkgs, ... }:
{
  programs.chromium = {
    enable = true;
    extensions = [
      { id = "padekgcemlokbadohgkifijomclgjgif"; }
      { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; }
      { id = "aapbdbdomjkkjkaonfhkkikfgjllcleb"; }
    ];
  };
}
