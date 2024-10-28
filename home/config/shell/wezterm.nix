_: {
  programs.wezterm = {
    enable = true;
    extraConfig = ''
      local SOLID_RIGHT_ARROW = utf8.char(0xe0b0)

      local Grey = "#0f1419"
      local LightGrey = "#191f26"

      local TAB_BAR_BG = "#242424"
      local ACTIVE_TAB_BG = "Yellow"
      local ACTIVE_TAB_FG = "#242424"
      local HOVER_TAB_BG = Grey
      local HOVER_TAB_FG = "White"
      local NORMAL_TAB_BG = LightGrey
      local NORMAL_TAB_FG = "White"
      wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
        panes = panes
        config = config
        max_width = max_width

        local background = NORMAL_TAB_BG
        local foreground = NORMAL_TAB_FG

        local is_first = tab.tab_id == tabs[1].tab_id
        local is_last = tab.tab_id == tabs[#tabs].tab_id

        if tab.is_active then
          background = ACTIVE_TAB_BG
          foreground = ACTIVE_TAB_FG
        elseif hover then
          background = HOVER_TAB_BG
          foreground = HOVER_TAB_FG
        end

        local leading_fg = NORMAL_TAB_FG
        local leading_bg = background

        local trailing_fg = background
        local trailing_bg = NORMAL_TAB_BG

        if is_first then
          leading_fg = TAB_BAR_BG
        else
          leading_fg = NORMAL_TAB_BG
        end

        if is_last then
          trailing_bg = TAB_BAR_BG
        else
          trailing_bg = NORMAL_TAB_BG
        end

        local title = tab.active_pane.title
        -- broken?
        -- local title = " " .. wezterm.truncate_to_width(tab.active_pane.title, 30) .. " "

        return {
          {Attribute={Italic=false}},
          {Attribute={Intensity=hover and "Bold" or "Normal"}},
          {Background={Color=leading_bg}},  {Foreground={Color=leading_fg}},
            {Text=SOLID_RIGHT_ARROW},
          {Background={Color=background}},  {Foreground={Color=foreground}},
            {Text=" "..title.." "},
          {Background={Color=trailing_bg}}, {Foreground={Color=trailing_fg}},
            {Text=SOLID_RIGHT_ARROW},
        }
      end)
      return {
        font = wezterm.font("JetBrains Mono"),
        font_size = 12.0,
        front_end = "WebGpu",
        color_scheme = 'myTheme',
        hide_tab_bar_if_only_one_tab = true,
        use_fancy_tab_bar = false,
        tab_max_width = 32,
        initial_cols = 110,
        initial_rows = 35,
        colors = {
          tab_bar = {
            background = TAB_BAR_BG,
          },
        },
        tab_bar_style = {
          new_tab = wezterm.format{
            {Background={Color=HOVER_TAB_BG}},
            {Foreground={Color=TAB_BAR_BG}},
            {Text=SOLID_RIGHT_ARROW},
            {Background={Color=HOVER_TAB_BG}},
            {Foreground={Color=HOVER_TAB_FG}},
            {Text=" + "},
            {Background={Color=TAB_BAR_BG}},
            {Foreground={Color=HOVER_TAB_BG}},
            {Text=SOLID_RIGHT_ARROW},
          },
          new_tab_hover = wezterm.format{
            {Attribute={Italic=false}},
            {Attribute={Intensity="Bold"}},
            {Background={Color=NORMAL_TAB_BG}},
            {Foreground={Color=TAB_BAR_BG}},
            {Text=SOLID_RIGHT_ARROW},
            {Background={Color=NORMAL_TAB_BG}},
            {Foreground={Color=NORMAL_TAB_FG}},
            {Text=" + "},
            {Background={Color=TAB_BAR_BG}},
            {Foreground={Color=NORMAL_TAB_BG}},
            {Text=SOLID_RIGHT_ARROW},
          },
        },
        keys = {
          { key= "n", mods= "SHIFT|CTRL", action= "ToggleFullScreen" },
          { key = "k", mods = "ALT", action = wezterm.action({ SpawnTab = "CurrentPaneDomain" }) },
        }
      }
    '';
    colorSchemes = {
      myTheme = {
        ansi = [
          "#000000"
          "#d52370"
          "#41af1a"
          "#bc7053"
          "#6964ab"
          "#c71fbf"
          "#939393"
          "#998eac"
        ];
        brights = [
          "#786d69"
          "#f41d99"
          "#22e529"
          "#f59574"
          "#9892f1"
          "#e90cdd"
          "#eeeeee"
          "#cbb6ff"
        ];
        foreground = "#eff0eb";
        background = "#242424";
        cursor_bg = "#ff65fd";
        cursor_border = "#ff65fd";
        cursor_fg = "#24242e";
        selection_bg = "#c05cbf";
        selection_fg = "#24242e";
      };
    };
  };
}