{ config, ... }: {

  programs.wofi = {
    enable = true;

    settings = {
      allow_markup = true;
      width = 450;
      show = "drun";
      prompt = "Apps";
      normal_window = true;
      layer = "top";
      term = "kitty";
      height = "305px";
      orientation = "vertical";
      halign = "fill";
      line_wrap = "off";
      dynamic_lines = false;
      allow_images = true;
      image_size = 24;
      exec_search = false;
      hide_search = false;
      parse_search = false;
      insensitive = true;
      hide_scroll = true;
      no_actions = true;
      sort_order = "default";
      gtk_dark = true;
      filter_rate = 100;
      key_expand = "Tab";
      key_exit = "Escape";
    };

    style = ''
      /** ********** Fonts ********** **/

      * {
        /*font-family: "SFProDisplay Nerd Font";*/
        font-family: "FontAwesome";
        font-weight: 500;
        font-size: 12px;
      }

      #window {
        background-color: transparent;
        color: #ECECEC;
        border-radius: 12px;
      }

      #outer-box {
        padding: 20px;
      }

      #input {
        background-color: #101012;
        border: 0px solid #a158ff;
        padding: 8px 12px;
      }

      #scroll {
        margin-top: 20px;
      }

      #inner-box {}

      #img {
        padding-right: 8px;
      }

      #text {
        color: #E4E5E7;
      }

      #text:selected {
        color: #FCFCFC;
      }

      #entry {
        padding: 6px;
      }

      #entry:selected {
        background-color: #a158ff;
        color: #000000;
      }

      #unselected {}

      #selected {}

      #input,
      #entry:selected {
        border-radius: 12px;
      }
    '';
  };
}
