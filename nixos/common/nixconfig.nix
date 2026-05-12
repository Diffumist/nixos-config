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
      extra-substituters = [
        "https://cache.numtide.com"
        "https://cache.garnix.io"
      ];
      extra-trusted-public-keys = [
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      ];
      auto-allocate-uids = true;
      download-buffer-size = 536870912; # 512 MiB
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
