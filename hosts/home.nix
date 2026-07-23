#
#  General Home-manager configuration
#
#  flake.nix
#   ├─ ./hosts
#   │   └─ home.nix *
#   └─ ./modules
#       ├─ ./programs
#       │   └─ default.nix
#       └─ ./services
#           └─ default.nix
#

{
  pkgs,
  username,
  ...
}:

let
  # GitHub repository for yazi plugins https://github.com/yazi-rs/plugins
  yazi-plugins = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "plugins";
    rev = "main";
    hash = "sha256-ixZKOtLOwLHLeSoEkk07TB3N57DXoVEyImR3qzGUzxQ=";
  };

  # GitHub repository for wise-enter yazi plugin https://github.com/jaam8/wise-enter.yazi
  yazi-wise-enter-plugin = pkgs.fetchFromGitHub {
    owner = "jaam8";
    repo = "wise-enter.yazi";
    rev = "main";
    hash = "sha256-oYaaLbSyVbfshD2CWXx0aZEpxqzRfrWRjmQjeqCuVYU=";
  };

  # GitHub repository for tokyo night yazi theme https://github.com/BennyOe/tokyo-night.yazi
  #yazi-theme-tokyo-night = pkgs.fetchFromGitHub {
  #    owner = "BennyOe";
  #    repo = "tokyo-night.yazi";
  #    rev = "main";
  #    sha256 = "sha256-4aNPlO5aXP8c7vks6bTlLCuyUQZ4Hx3GWtGlRmbhdto=";
  #};

  # Yazi theming is done via Stylix
  # GitHub repository for catppuccin mocha yazi theme https://github.com/yazi-rs/flavors/catppuccin-mocha.yazi
  # yazi-theme-catppuccin-mocha = pkgs.fetchFromGitHub {
  #     owner = "yazi-rs";
  #     repo = "flavors";
  #     #rev = "main";
  #     rev = "4a1802a5add0f867b08d5890780c10dd1f051c36";
  #     sha256 = "sha256-RrF97Lg9v0LV+XseJw4RrdbXlv+LJzfooOgqHD+LGcw=";
  # };

in
{
  #imports =
  # Home Manager Modules
  #(import ../modules/programs) ++
  #(import ../modules/services);

  home = {
    username = "${username}";
    homeDirectory = "/home/${username}";
    stateVersion = "22.05";
    packages = with pkgs; [
      # Command line applications
      htop
      yadm
      ansible
      git
      curl
      wget
      cheat
      gcc
      gnumake
    ];

    # QMMP winamp skin
    # If QMMP doesn't switch to Winamp skin automatically, go to Edit -> Settings -> Plugins and check
    # Skinned User Interface within User Interfaces section. Then, restart QMMP
    file.".config/qmmp/skins/winamp_classic.wsz".source = ../home-manager/qmmp/skins/winamp_classic.wsz;
  };

  programs = {
    home-manager.enable = true;
  };

  # Yazi special configuration. This package won't be needed to be specifically installed
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    shellWrapperName = "y";

    # Recommended for RAR files
    package = pkgs.yazi.override {
      _7zz = pkgs._7zz-rar; # Support for RAR extraction
    };

    extraPackages = with pkgs; [
      unar
    ];

    # Theme (Tokyo Night)
    #theme = {
    #  flavor = {
    #    dark = "tokyo-night";
    #  };
    #};
    #flavors = {
    #  tokyo-night = "${yazi-theme-catppuccin-mocha}";
    #};

    # Theme was managed by stylix but stopped working
    # Enabling theming via home manager again
    # Theme (Catppuccin Mocha)
    # theme = {
    #   flavor = {
    #     dark = "catppuccin-mocha";
    #   };
    # };
    # flavors = {
    #   catppuccin-mocha = "${yazi-theme-catppuccin-mocha}/catppuccin-mocha.yazi";
    # };

    # yazi.toml
    settings = {
      opener = {
        # By default, yazi uses its own internal rules for opening files, which
        # may not align with the system's mime type associations (xdg-open).
        # The following rule overrides the default behavior and forces yazi to
        # use xdg-open for all file types, thus respecting the system's default
        # applications.
        open = [
          {
            run = "xdg-open \"$@\"";
            orphan = true;
            for = "unix";
            desc = "Open";
          }
        ];

        # The default player for music will be QMMP
        play = [
          {
            run = "qmmp \"$@\"";
            orphan = true;
            for = "unix";
          }
        ];

        # The default player for video will be VLC
        video = [
          {
            run = "vlc \"$@\"";
            orphan = true;
            for = "unix";
          }
        ];

        # The default image viewer will be feh
        image = [
          {
            run = "feh \"$@\"";
            orphan = true;
            for = "unix";
          }
        ];

        # The default PDF reader will be Papers
        pdf = [
          {
            run = "papers \"$@\"";
            orphan = true;
            for = "unix";
          }
        ];

        # The default editor will be sublime text
        #edit = [
        #  { run = "subl \"$@\""; orphan = true; for = "unix"; }
        #];

        # The default editor will be Zed
        edit = [
          {
            run = "zeditor \"$@\"";
            orphan = true;
            for = "unix";
          }
        ];

        # A generic opener for Firefox
        firefox = [
          {
            run = "firefox \"$@\"";
            orphan = true;
            for = "unix";
          }
        ];
      };

      open = {
        # Setting default applications for some kind of files
        rules = [
          {
            mime = "text/*";
            use = "edit";
          }
          {
            mime = "video/*";
            use = "video";
          }
          {
            mime = "application/json";
            use = "edit";
          }
          {
            mime = "application/pdf";
            use = [
              "pdf"
              "firefox"
            ];
          }
          {
            mime = "audio/aac";
            use = "play";
          }
          {
            mime = "audio/midi";
            use = "play";
          }
          {
            mime = "audio/x-midi";
            use = "play";
          }
          {
            mime = "audio/mpeg";
            use = "play";
          }
          {
            mime = "audio/ogg";
            use = "play";
          }
          {
            mime = "audio/wav";
            use = "play";
          }
          {
            mime = "audio/webm";
            use = "play";
          }
          {
            mime = "audio/3gpp";
            use = "play";
          }
          {
            mime = "image/jpeg";
            use = "image";
          }
          {
            mime = "image/png";
            use = "image";
          }
          {
            mime = "*";
            use = "open";
          } # Fallback to xdg-open for all other mimetypes
        ];
      };
    };

    plugins = {
      #full-border = "${yazi-plugins}/full-border.yazi";
      #toggle-pane = "${yazi-plugins}/toggle-pane.yazi";
      mount = "${yazi-plugins}/mount.yazi";
      wise-enter = "${yazi-wise-enter-plugin}/";
      #smart-enter = "${yazi-plugins}/smart-enter.yazi";

    };

    # Some plugins need to be loaded before hand.
    # Example: full-border https://github.com/yazi-rs/plugins/tree/main/full-border.yazi
    #initLua = ''
    #  require("full-border"):setup()
    #'';

    # keymap.toml
    keymap = {
      mgr.prepend_keymap = [
        {
          on = "<C-w>";
          run = "close";
          desc = "Close the current tab or quit it it's last";
        }
        {
          on = "<S-e>";
          run = ''shell 'thunar "$YAZI_CWD"' --orphan'';
          desc = "Open Thunar in the current directory";
        }
        {
          on = "<S-t>";
          run = ''shell 'kitty --directory "$YAZI_CWD"' --orphan'';
          desc = "Open kitty terminal here";
        }
        {
          on = "T";
          run = "plugin toggle-pane max-preview";
          desc = "Maximize or restore the preview pane";
        }
        {
          on = "M";
          run = "plugin mount";
          desc = "Mount and manage USB devices";
        }
        {
          on = [
            "g"
            "u"
          ];
          run = "cd /run/media/egarcia";
          desc = "USB";
        }
        {
          on = "<C-c>";
          for = "unix";
          run = [
            "shell -- for path in \"$@\"; do echo \"file://$path\"; done | wl-copy -t text/uri-list"
            "yank"
          ];
          desc = "Copy a file both in system and yazi clipboard";
        }
        {
          on = "<C-x>";
          run = "yank --cut";
          desc = "Cut a file";
        }
        {
          on = "<C-v>";
          run = "paste";
          desc = "Paste a file";
        }
        {
          on = "!";
          for = "unix";
          run = [ "shell \"$SHELL\" --block" ];
          desc = "Open $SHELL here";
        }
        {
          on = "<F2>";
          run = "rename";
          desc = "Rename a file";
        }
        {
          on = "<C-f>";
          run = "search --via=fd";
          desc = "Search files (fd)";
        }
        {
          on = "<S-f>";
          run = "search --via=rg";
          desc = "Search files by content (ripgrep)";
        }
        {
          on = "<Enter>";
          run = "plugin wise-enter";
          desc = "Enter the child directory, open the file or uncompress an archive";
        }
        # {
        #   on = "<Enter>";
        #   run = "plugin smart-enter";
        #   desc = "Enter the child directory, or open the file";
        # }
        {
          on = "<Delete>";
          run = "trash";
          desc = "Move to trash";
        }
        {
          on = "<S-Delete>";
          run = "remove";
          desc = "Delete permanently";
        }
      ];
    };
  };

  programs.zed-editor = {
    enable = true;
    extraPackages = [
      pkgs.nil
      pkgs.nixd
    ];

    # For more extensions, go to https://github.com/DuskSystems/nix-zed-extensions/tree/main/generated/extensions
    extensions = [
      "nix"
      "toml"
      "yaml"
      "java"
      "html"
      "csv"
      "markdownlint"
      "python-requirements"
      "basher"
      "docker-compose"
      "dockerfile"

    ];
    userSettings = {
      base_keymap = "SublimeText";
      vim_mode = false;
      restore_on_startup = "last_workspace";
      session = {
        trust_all_worktrees = true;
      };
      # Show file type icons in the tab bar. Also color them according to the
      # git status.
      tabs = {
        file_icons = true;
        git_status = true;
      };
      # Decrease the horizontal indent size of files & folders in the project
      # panel to avoid horizontal scrolling
      project_panel = {
        indent_size = 16;
      };
      # Set a preferred line lenth, showing a vertical gutter bar
      preferred_line_length = 160;
      # Languages special configurations
      languages = {
        Markdown = {
          # Wrap text according to the previously defined preferred line length.
          soft_wrap = "preferred_line_length";
        };
      };
      # Disabling preview tabs
      preview_tabs = {
        enabled = false;
      };
      # Agent code servers
      agent_servers = {
        OpenCode = {
          command = "opencode";
          args = [ "acp" ];
        };
      };
      # Langage models
      language_models = {
        lmstudio = {
          api_url = "http://localhost:1234/api/v0/";
        };
        openai_compatible = {
          FastFlowLM = {
            api_url = "http://localhost:52625/v1";
            available_models = [
              {
                name = "qwen3.5:4b";
                display_name = "qwen3.5:4b";
                max_tokens = 32768;
                capabilities = {
                  tools = true;
                  images = true;
                  parallel_tool_calls = true;
                  prompt_cache_key = true;
                };
              }
              {
                name = "qwen3.5:9b";
                display_name = "qwen3.5:9b";
                max_tokens = 16384;
                capabilities = {
                  tools = true;
                  images = true;
                  parallel_tool_calls = true;
                  prompt_cache_key = true;
                };
              }
              {
                name = "gpt-oss-sg:20b";
                display_name = "gpt-oss-sg:20b";
                max_tokens = 24576;
                capabilities = {
                  tools = false;
                  images = false;
                  parallel_tool_calls = false;
                  prompt_cache_key = false;
                };
              }
            ];
          };
        };
      };
    };

    # userKeymaps = [
    #   {
    #     context = "Workspace";
    #     bindings = {
    #       "ctrl-alt-t" = "terminal_panel::ToggleFocus";
    #     };
    #   }
    # ];
  };

  # Virtual Manager special configuration (https://nixos.wiki/wiki/Virt-manager)
  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = [ "qemu:///system" ];
      uris = [ "qemu:///system" ];
    };
  };

  # Configuring xdg-utils to use some default applications
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/x-nix" = "dev.zed.Zed.desktop";
      "text/plain" = "dev.zed.Zed.desktop";
      "text/markdown" = "dev.zed.Zed.desktop";
      "application/javascript" = "dev.zed.Zed.desktop";
      "application/json" = "dev.zed.Zed.desktop";
      "application/x-yaml" = "dev.zed.Zed.desktop";
      "text/css" = "dev.zed.Zed.desktop";
      #"text/x-nix" = "sublime_text.desktop";
      #"text/plain" = "sublime_text.desktop";
      #"text/markdown" = "sublime_text.desktop";
      #"application/javascript" = "sublime_text.desktop";
      #"application/json" = "sublime_text.desktop";
      #"application/x-yaml" = "sublime_text.desktop";
      #"text/css" = "sublime_text.desktop";
      #"text/html" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "application/pdf" = "org.gnome.Papers.desktop";
      "application/x-pdf" = "org.gnome.Papers.desktop";
      "x-terminal-emulator" = "kitty.desktop";
      "inode/directory" = "thunar.desktop";
      "x-scheme-handler/file" = "thunar.desktop";
      "video/mp4" = "vlc.desktop";
      "video/webm" = "vlc.desktop";
      "video/x-matroska" = "vlc.desktop";
      "audio/mpeg" = "qmmp.desktop";
      "image/jpeg" = "feh.desktop";
      "image/png" = "feh.desktop";
    };
  };
}
