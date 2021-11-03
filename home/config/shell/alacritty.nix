{
  # See: https://github.com/alacritty/alacritty/blob/master/alacritty.yml
  window = {
    dimensions = {
      columns = 110;
      lines = 35;
    };
    position = {
      x = 550;
      y = 550;
    };
    dynamic_title = true;
  };
  shell.program = "fish";
  mouse.hide_when_typing = true;
  font = {
    size = 10;
    normal = {
      family = "JetBrains Mono";
      style = "Regular";
    };
    bold = { family = "JetBrains Mono Nerd Font"; };
    italic = { family = "JetBrains Mono Nerd Font"; };
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
}
