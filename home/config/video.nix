{ pkgs, ... }: {
  programs.mpv = {
    enable = true;
    config = {
      hwdec = "auto";
      hwdec-codecs = "all";
      gpu-context = "wayland";
    };
  };

  programs.mpv.bindings = {
    WHEEL_UP = "add volume 2";
    WHEEL_DOWN = "add volume -2";
    WHEEL_LEFT = "seek 10";
    WHEEL_RIGHT = "seek -10";
    UP = "add volume 5";
    DOWN = "add volume -5";
    LEFT = "seek -5";
    RIGHT = "seek 5";
  };

  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      obs-vaapi
      obs-vkcapture
    ];
  };

}
