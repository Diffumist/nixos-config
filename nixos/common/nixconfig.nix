_: {
  # nix-config
  nixpkgs.config.allowUnfree = true;

  nix = {
    channel.enable = false;
    settings = {
      trusted-users = [
        "root"
        "@wheel"
      ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
    };

    gc = {
      automatic = true;
      dates = "Sun";
      options = "--delete-older-than 20d";
    };
  };

  documentation.doc.enable = false;

  system.stateVersion = "25.11";
}
