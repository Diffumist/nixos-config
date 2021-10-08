{ config, ... }: {
  programs.git = {
    enable = true;
    signing.signByDefault = false;
    userName = "diffumist";
    userEmail = "git@diffumist.me";
    signing.key = "5647BF1E460733062EBF468BC68CA02B61625AEB";
    ignores = [ "*~" "*.swp" ]; # vim swap file
    aliases = {
      br = "branch";
      cmt = "commit";
      co = "checkout";
      cp = "cherry-pick";
      d = "diff";
      dt = "difftool";
      l = "log";
      mt = "mergetool";
      st = "status";
      sub = "submodule";
    };
  };

  programs.gpg = {
    enable = true;
    settings = {
      default-key = "5647BF1E460733062EBF468BC68CA02B61625AEB";
    };
  };

  services.gpg-agent = {
    enable = true;
    pinentryFlavor = "qt";
    enableSshSupport = true;
    defaultCacheTtl = 12 * 3600;
    maxCacheTtl = 24 * 3600;
  };
}
