{ lib, pkgs, ...}:
{
  xdg.configFile."fcitx5/conf/classicui.conf".text = ''
    Vertical Candidate List=False
    PerScreenDPI=True
    Font="Noto Sans CJK SC 10"
    UseInputMethodLangaugeToDisplayText=True
    Theme=Material-Color-Black
  '';
}