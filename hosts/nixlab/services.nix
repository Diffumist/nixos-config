_: {
  modules = {
    nginx.enable = true;
    transmission.enable = true;
    jellyfin.enable = true;
    nas-sync = {
      enable = true;
      username = "diffumist";
      folder = [
        "Music"
        "Videos"
        "Pictures"
        "Documents"
        "Other"
      ];
    };
  };
}
