{ lib, pkgs, ... }:
{
  programs.chromium = {
    enable = true;
    extensions = [
      { id = "padekgcemlokbadohgkifijomclgjgif"; }
      { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; }
      { id = "aapbdbdomjkkjkaonfhkkikfgjllcleb"; }
      { id = "nngceckbapebfimnlniiiahkandclblb"; }
      { id = "dhdgffkkebhmkfjojejmpbldmpobfkfo"; }
      { id = "pncfbmialoiaghdehhbnbhkkgmjanfhe"; }
      { id = "niloccemoadcdkdjlinkgdfekeahmflj"; }
      { id = "ajhmfdgkijocedmfjonnpjfojldioehi"; }
      { id = "jklfcpboamajpiikgkbjcnnnnooefbhh"; }
      { id = "ponfpcnoihfmfllpaingbgckeeldkhle"; }
      { id = "mpkodccbngfoacfalldjimigbofkhgjn"; }
    ];
  };
}
