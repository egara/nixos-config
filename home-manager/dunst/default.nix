{ config, pkgs, ... }: {

  services.dunst = {
    enable = true;
    settings = {
      global = {
        browser = "${config.programs.firefox.package}/bin/firefox -new-tab";
        dmenu = "${pkgs.wofi}/bin/wofi -dmenu";
        follow = "mouse";
        font = "Droid Sans 10";
        format = "<b>%s</b>\\n%b%a";
        frame_color = "#aaaaaa";
        frame_width = 2;
        geometry = "0x0-5+30";
        notification_height = 0;
        horizontal_padding = 8;
        icon_position = "off";
        line_height = 0;
        markup = "full";
        padding = 8;
        separator_color = "frame";
        separator_height = 2;
        transparency = 10;
        word_wrap = true;
        sort = true;
        stack_duplicates = true;
      };

      urgency_low = {
        background = "#2b2b2b";
        foreground = "#ffffff";
        timeout = 10;
      };

      urgency_normal = {
        background = "#2b2b2b";
        foreground = "#ffffff";
        timeout = 15;
      };

      urgency_critical = {
        background = "#900000";
        foreground = "#ffffff";
        frame_color = "#dd5633";
        timeout = 0;
      };

      shortcuts = {
        context = "mod4+grave";
        close = "mod4+shift+space";
      };
    };
  };

}