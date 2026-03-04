_: {
  nix = {
    settings = {
      trusted-users = [
        "@wheel"
      ];
      experimental-features = [
        "nix-command"
        "flakes"
        "auto-allocate-uids"
        "cgroups"
      ];
      substituters = [ "https://mirrors.cernet.edu.cn/nix-channels/store" ];
      trusted-public-keys = [ ];
      auto-allocate-uids = true;
      warn-dirty = false;
      use-xdg-base-directories = true;
      auto-optimise-store = true;
    };

    gc = {
      automatic = true;
      dates = "Sun";
      options = "--delete-older-than 7d";
    };
  };

  documentation.doc.enable = false;

  system.stateVersion = "25.11";
}
