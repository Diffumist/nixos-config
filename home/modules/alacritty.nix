{ pkgs, ... }:
{
  programs.alacritty = {
    enable = true;
    # See: https://github.com/alacritty/alacritty/blob/master/alacritty.yml
    settings = {
      window = {
        dimensions = {
          columns = 110;
          lines = 35;
        };
        dynamic_title = true;
      };
      shell.program = "fish";
      mouse.hide_when_typing = true;
      font = {
        size = 10;
        normal = {
          family = "JetBrainsMono NerFontd ";
          style = "Regular";
        };
        bold = {
          family = "JetBrainsMono Nerd Font";
        };
        italic = {
          family = "JetBrainsMono Nerd Font";
        };
      };
      draw_bold_text_with_bright_colors = true;
      background_opacity = 1;
      colors = {
        primary = {
          background = "#272727";
          foreground = "#eff0eb";
        };
        selection = {
          text = "#282a36";
          background = "#feffff";
        };
        normal = {
          black = "#282a36";
          red = "#ff5c57";
          green = "#5af78e";
          yellow = "#f3f99d";
          blue = "#57c7ff";
          magenta = "#ff6ac1";
          cyan = "#9aedfe";
          white = "#f1f1f0";
        };
        bright = {
          black = "#686868";
          red = "#ff5c57";
          green = "#5af78e";
          yellow = "#f3f99d";
          blue = "#57c7ff";
          magenta = "#ff6ac1";
          cyan = "#9aedfe";
          white = "#eff0eb";
        };
      };
    };
  };
  home.packages = [
    # See: https://bugs.kde.org/show_bug.cgi?id=438204
    (
      pkgs.runCommand "alacritty-desktop" {} ''
        mkdir -p $out/share/applications
        cp ${pkgs.alacritty}/share/applications/Alacritty.desktop $out/share/applications/alacritty.desktop
        sed 's/Name=Alacritty/Name=alacritty/g' --in-place $out/share/applications/alacritty.desktop
      ''
    )
  ];
}
