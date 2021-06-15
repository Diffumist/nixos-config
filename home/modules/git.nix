{ ... }:
{
  programs.git = {
    enable = true;
    signing.signByDefault = true;

    userName = "diffumist";
    userEmail = "misanzhiwu@gmail.com";
    signing.key = "C753CC5B08CA116C83E9253FAFBF30648956131E";

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