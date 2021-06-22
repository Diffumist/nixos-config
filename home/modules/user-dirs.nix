{ config, ... }:
{
  xdg = {
    userDirs = let
      prefix = "$HOME/.local/share/xdg";
    in
      {
        enable = true;
        desktop = "$HOME/Desktop";
        download = "$HOME/Downloads";
        pictures = "$HOME/Pictures";
        documents = "$HOME/Documents";
        music = "$HOME/Music";
        publicShare = "$HOME";
        templates = "$HOME";
        videos = "$HOME/Videos";
      };
  };
}
