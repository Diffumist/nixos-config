{ config, secrets, ... }:
{
  programs.git = {
    enable = true;
    userName = "Diffumist";
    userEmail = "git@diffumist.me";
    signing = {
      signByDefault = true;
      key = "8BA330B49A5694A6";
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
      default-key = "3F3A6B9E784C7DB6";
    };
    scdaemonSettings = {
      disable-ccid = true;
    };
  };
}
