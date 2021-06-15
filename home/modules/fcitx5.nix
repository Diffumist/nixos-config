{ lib, pkgs, ...}:
{
  programs.fcitx5 = {
    enable = true;
  };
  home.packages = with pkgs; [
    fcitx5-chinese-addons
    fcitx5-pinyin-zhwiki
    fcitx5-pinyin-moegirl
    fcitx5-material-color
  ];
  xdg.configFile."fcitx5/conf/classicui.conf".text = ''
    Vertical Candidate List=False
    PerScreenDPI=True
    Font="Noto Sans CJK SC 12"
    Theme=Material-Color-Indigo
  '';
}