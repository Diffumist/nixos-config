{ config, ... }:
{
  xdg = {
    userDirs =
      let
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
    configFile = {
      "autostart/qv2ray.desktop".text = ''
        [Desktop Entry]
        Name=qv2ray
        GenericName=V2Ray Graphical Frontend
        Exec=bash -c "sleep 5; qv2ray"
        Terminal=false
        Icon=qv2ray
        Categories=Network
        Type=Application
        StartupNotify=false
        MimeType=x-scheme-handler/qv2ray;
      '';
      "autostart/latte.desktop".text = ''
        [Desktop Entry]
        Exec=latte-dock
        GenericName=Dock
        Icon=latte-dock
        InitialPreference=1
        Name=Latte
        StartupNotify=false
        StartupWMClass=latte-dock
        Terminal=false
        Type=Application
        X-DBUS-ServiceName=org.kde.lattedock
        X-DBUS-StartupType=unique
        X-KDE-StartupNotify=false
        X-KDE-SubstituteUID=false
        X-KDE-Wayland-Interfaces=org_kde_plasma_window_management,org_kde_kwin_keystate
        X-KDE-autostart-phase=1
      '';
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
