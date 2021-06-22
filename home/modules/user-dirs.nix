{ config, ... }:
{
  xdg = {
    userDirs = let prefix = "$HOME/.local/share/xdg"; in
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
    configFile = {
      "go/env".text = ''
        GOPATH=${config.xdg.cacheHome}/go
        GOBIN=${config.xdg.dataHome}/go/bin
        GO111MODULE=on
        GOPROXY=https://goproxy.cn
        GOSUMDB=sum.golang.google.cn
      '';
    };
  };
}
