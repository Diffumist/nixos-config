{ pkgs, config, secrets, ... }:
{
  programs.git = {
    enable = true;
    userName = "Diffumist";
    userEmail = "git@diffumist.me";
    signing = {
      signByDefault = true;
      key = "5647BF1E460733062EBF468BC68CA02B61625AEB";
    };
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
    extraConfig.merge.tool = "meld";
  };

  programs.ssh = {
    enable = true;
    compression = true;
    hashKnownHosts = true;
    matchBlocks = secrets.home.ssh { inherit config; };
  };

  programs.gpg = {
    enable = true;
    settings = {
      default-key = "5647BF1E460733062EBF468BC68CA02B61625AEB";
    };
  };
}
