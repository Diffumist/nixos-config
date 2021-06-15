{ pkgs, ...}:
{
  nixpkgs.overlays = [
    (self: super: {
      mpv = super.mpv-with-scripts.override {
        scripts = [ self.mpvScripts.sponsorblock ];
      };
    })
  ];
  programs.mpv = {
    enable = true;
    config.hwdec = "auto";
    config.hwdec-codecs = "all";
  };

  programs.mpv.bindings = {
    WHEEL_UP    =  "add volume 2";
    WHEEL_DOWN  =  "add volume -2";
    WHEEL_LEFT  =  "seek 10";
    WHEEL_RIGHT =  "seek -10";
    UP          =  "add volume 5";
    DOWN        =  "add volume -5";
    LEFT        =  "seek -5";
    RIGHT       =  "seek 5";
  };


}