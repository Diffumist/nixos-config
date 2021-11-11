{ pkgs, config, ... }:
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
    extraConfig = {
      merge.tool = "meld";
      mergetool.meld = {
        path = "${pkgs.meld}/bin/meld";
        useAutoMerge = true;
      };
      mergetool = {
        keepBackup = false;
        keepTemporaries = false;
        writeToTemp = true;
      };
    };
  };

  programs.ssh = {
    enable = true;
    compression = true;
  };

  programs.gpg = {
    enable = true;
    homedir = "${config.xdg.dataHome}/gnupg";
    settings = {
      default-key = "5647BF1E460733062EBF468BC68CA02B61625AEB";
    };
  };
}
