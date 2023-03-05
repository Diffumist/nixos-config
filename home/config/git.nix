{ pkgs, config, secrets, ... }:
{
  programs.git = {
    enable = true;
    userName = "Diffumist";
    userEmail = "git@diffumist.me";
    signing = {
      signByDefault = true;
      key = "5C8709FEE5EBAC01";
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
      default-key = "1361F9453CAA1B3A";
    };
    scdaemonSettings = {
      disable-ccid = true;
    };
  };
}
