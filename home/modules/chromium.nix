{ pkgs, ...}:
{ 
  programs.chromium = {
    enable = true;
    extensions = [ "padekgcemlokbadohgkifijomclgjgif" "cjpalhdlnbpafiamejdnhcphjbkeiagm" ];
  };
}