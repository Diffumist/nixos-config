{ ... }: {
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
      dc = "diff --cached";
      dt = "difftool";
      l = "log";
      mt = "mergetool";
      st = "status";
      sub = "submodule";
    };

    extraConfig = {
      pull.ff = "only";
      advice.detachedHead = false;

      diff.tool = "vimdiff";
      difftool.prompt = false;

      merge.tool = "vimdiff";
      merge.conflictstyle = "diff3";
      mergetool.prompt = false;
    };
  };
}
