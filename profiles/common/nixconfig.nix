{ self, ... }:
{
  nix = {
    registry.p.flake = self;

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
        "https://attic.diffumist.me/nixos-config"
        "https://cache.numtide.com"
        "https://cache.lantian.pub/lantian"
      ];
      extra-trusted-public-keys = [
        "nixos-config:rU8MVfJPcTuFqpL7Ezl4oVthnMEkH1VGG0ctfM68ue4="
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        "lantian:WVGO7vsRMSEN+h7Lp7kv6SAmrkEXgUGbbXm7jMDjBuQ="
      ];
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

  documentation.enable = false;
  documentation.man.enable = false;
  documentation.info.enable = false;
  documentation.doc.enable = false;

}
