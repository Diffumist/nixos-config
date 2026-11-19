{ config, pkgs, ... }:
{
  home.pointerCursor = {
    enable = true;
    package = pkgs.capitaine-cursors;
    name = "capitaine-cursors";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  programs.umbriel = {
    enable = true;
    settings = {
      include = {
        files = [ "${config.programs.umbriel.package}/share/umbriel/config.toml" ];
        optional.files = [ "${config.xdg.configHome}/umbriel/noctalia.toml" ];
      };
      environment.ELECTRON_OZONE_PLATFORM_HINT = "wayland";
      output = {
        eDP-1 = {
          mode = "2880x1800@120.000";
          position = [
            2560
            0
          ];
          scale = 2.0;
        };
        HDMI-A-1 = {
          mode = "3840x2160@59.997";
          position = [
            0
            0
          ];
          scale = 1.5;
        };
      };
      layout = {
        mode = "scrolling";
        gap = 4;
        extent_presets = [
          0.33333
          0.5
          0.66667
        ];
        scrolling.default_extent_fraction = 0.5;
      };
      appearance = {
        prefer_no_csd = false;
        corner_radius = 16;
        border_width = 2;
        blur = {
          enabled = true;
          optimized = true;
          radius = 5;
        };
      };
      input = {
        cursor = {
          theme = config.home.pointerCursor.name;
          size = config.home.pointerCursor.size;
        };
        keyboard = {
          layout = "us";
          numlock_toggle = true;
        };
        focus.follows_mouse = "off";
        touchpad = {
          tap = true;
          natural_scroll = true;
          disable_while_typing = true;
        };
        mouse.accel_profile = "flat";
      };
      keybinds = {
        "Mod+Return" = "spawn ghostty";
        "Mod+Print" = {
          action = "spawn noctalia msg screenshot-region --copy-to-clipboard";
          repeat = false;
        };
        "Mod+Tab" = {
          action = "overview-toggle";
          repeat = false;
        };
      };
    };
  };

  programs.noctalia = {
    enable = true;
    settings = {
      hot_corners = {
        enabled = true;
        delay_ms = 250;
        top_left = {
          action = "command";
          command = "${config.programs.umbriel.package}/bin/umbriel msg overview-toggle";
        };
      };
      shell = {
        font_family = "Sarasa Gothic SC";
        polkit_agent = true;
        launch_apps_as_systemd_services = true;
      };
      theme.templates = {
        enable_builtin_templates = true;
        builtin_ids = [
          "umbriel"
          "ghostty"
          "helix"
          "gtk3"
          "gtk4"
        ];
      };
    };
  };
}
