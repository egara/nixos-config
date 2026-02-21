{ config, lib, nixosConfig }:

let
  c = config.lib.stylix.colors;
  cfg = nixosConfig.programs.sicos.hyprland;
in
''
{
    "layer": "top",
    "position": "top",
    "margin-left": 5,
    "margin-right": 5,
    "margin-top": 5,

    "modules-left": [
        "custom/walker",
        "hyprland/workspaces",
        "cpu",
        "memory",
        "wlr/taskbar"
    ],
    "modules-center": [
        "custom/notification",
        "clock"${if cfg.insync.enable then ", \"custom/insync\"" else ""}
    ],
    "modules-right": [
        "keyboard-state",
        "backlight",
        "pulseaudio",
        "network",
        "tray",
        "battery"${if cfg.powerManagement.enable then ", \"power-profiles-daemon\"" else ""},
        "custom/power"
    ],

    "custom/insync": {
        "format": "{text}",
        "exec-if": "which insync",
        "exec": "insync-integration.sh",
        "return-type": "json",
        "interval": 2,
        "tooltip": true,
        "on-click": "insync show"
    },

    "custom/walker": {
        "format": "  ",
        "tooltip": true,
        "tooltip-format": "Applications",
        "on-click": "walker"
    },
    "hyprland/workspaces": {
      "active-only": false,
      "all-outputs": false,
      "disable-scroll": false,
      "format": "{name}",
      "format-icons": {
        "active": "",
        "default": "",
        "sort-by-number": true,
        "urgent": ""
      },
      "on-click": "activate",
      "on-scroll-down": "hyprctl dispatch workspace e+1",
      "on-scroll-up": "hyprctl dispatch workspace e-1"
    },
    "wlr/taskbar": {
        "format": "{icon}",
        "icon-size": 18,
        "tooltip-format": "{title}",
        "on-click": "activate",
        "on-click-middle": "close"
    },
    "keyboard-state": {
        "numlock": true,
        "capslock": true,
        "format": "{name} {icon}",
        "format-icons": {
            "locked": " ",
            "unlocked": " "
        }
    },
    "tray": {
        "icon-size": 18,
        "spacing": 5,
        "show-passive-items": true
    },
    "custom/notification": {
      "tooltip": false,
      "format": "{icon}",
      "format-icons": {
        "notification": "<span foreground='#${c.base08}'></span>",
        "none": "",
        "dnd-notification": "<span foreground='#${c.base08}'></span>",
        "dnd-none": "",
        "inhibited-notification": "<span foreground='#${c.base08}'></span>",
        "inhibited-none": "",
        "dnd-inhibited-notification": "<span foreground='#${c.base08}'></span>",
        "dnd-inhibited-none": ""
      },
      "return-type": "json",
      "exec-if": "which swaync-client",
      "exec": "swaync-client -swb",
      "on-click": "swaync-client -t -sw",
      "on-click-right": "swaync-client -d -sw",
      "escape": true
    },
    "clock": {
        "interval": 60,
        "format": "  {:%a %b %d  %H:%M %p}",
        "rotate": 0,
        "tooltip-format": "<span>{calendar}</span>",
        "calendar": {
            "mode": "month",
            "on-scroll": 1,
            "format": {
                "months": "<span color='#${c.base0E}'><b>{}</b></span>",
                "days": "<span color='#${c.base05}' font_family='monospace'><b>{}</b></span>",
                "weekdays": "<span color='#${c.base0B}'><b>{}</b></span>",
                "today": "<span color='#${c.base0A}'><b>{}</b></span>"
            }
        },
        "actions":  {
            "on-click": "shift_down",
            "on-click-right": "shift_up",
            "on-click-middle": "shift_reset"
        }
    },
   "temperature": {
        "critical-threshold": 80,
        "interval": 2,
        "format": "{temperatureC}°C ",
        "format-icons": ["", "", ""]
    },
    "cpu": {
        "interval": 2,
        "format": "{usage}%  ",
        "tooltip": false
    },
    "memory": {
        "interval": 2,
        "format": "{}%  "
    },
   "disk": {
        "interval": 15,
        "format": "{percentage_used}% 󰋊 "
    },
    "backlight": {
        "format": "{percent}% {icon}",
        "format-icons": ["", "", "", "", "", "", "", "", ""]
    },
    "battery": {
        "states": {
            "good": 95,
            "warning": 30,
            "critical": 15
        },
        "format": "{capacity}% {icon}",
        "format-charging": "{capacity}% ",
        "format-plugged": "{capacity}%  ",
        "format-alt": "{time} {icon}",
        "format-icons": [" ", " ", " ", " ", " "]
    },
    "battery#bat2": {
        "bat": "BAT2"
    },
    "network": {
        "format-wifi": "{ipaddr}",
        "format-ethernet": "{ipaddr}/{cidr}",
        "tooltip-format-wifi": "{essid} ({signalStrength}%)  ",
        "tooltip-format": "{ifname} via {gwaddr} 󰈀",
        "format-linked": "{ifname} (No IP)",
        "format-disconnected": "Disconnected ",
        "format-alt": "{ifname}: {ipaddr}/{cidr}"
    },
    "pulseaudio": {
        "format": "{volume}% {icon}",
        "format-bluetooth": "{volume}% {icon} 󰂯",
        "format-bluetooth-muted": "󰖁 {icon} 󰂯",
        "format-muted": "󰖁 {format_source}",
        "format-source": "{volume}% ",
        "format-source-muted": " ",
        "format-icons": {
            "headphone": "󰋋",
            "hands-free": "󱡒 ",
            "headset": "󰋎",
            "phone": "",
            "portable": "",
            "car": " ",
            "default": ["", " ", " "]
        },
        "on-click": "pavucontrol"
    },
    "custom/power": {
        "format": " ⏻ ",
        "tooltip": false,
        "on-click": "wlogout --protocol layer-shell"
    },
    "power-profiles-daemon": {
        "format": "{icon}",
        "tooltip-format": "Power profile: {profile}",
        "tooltip": true,
        "format-icons": {
        "default": "",
        "performance": "",
        "balanced": "",
        "power-saver": ""
      }
    },
    "custom/playerctl#backward": {
      "format": "󰙣 ",
      "on-click": "playerctl previous",
      "on-scroll-down": "playerctl volume .05-",
      "on-scroll-up": "playerctl volume .05+"
    },
    "custom/playerctl#foward": {
      "format": "󰙡 ",
      "on-click": "playerctl next",
      "on-scroll-down": "playerctl volume .05-",
      "on-scroll-up": "playerctl volume .05+"
    },
    "custom/playerctl#play": {
      "exec": "playerctl -a metadata --format '{\"text\": \"{{artist}} - {{markup_escape(title)}}\", \"tooltip\": \"{{playerName}} : {{markup_escape(title)}}\", \"alt\": \"{{status}}\", \"class\": \"{{status}}\"}' -F",
      "format": "{icon}",
      "format-icons": {
        "Paused": "<span> </span>",
        "Playing": "<span>󰏥 </span>",
        "Stopped": "<span> </span>"
      },
      "on-click": "playerctl play-pause",
      "on-scroll-down": "playerctl volume .05-",
      "on-scroll-up": "playerctl volume .05+",
      "return-type": "json"
    },
    "custom/playerlabel": {
      "exec": "playerctl -a metadata --format '{\"text\": \"{{artist}} - {{markup_escape(title)}}\", \"tooltip\": \"{{playerName}} : {{markup_escape(title)}}\", \"alt\": \"{{status}}\", \"class\": \"{{status}}\"}' -F",
      "format": "<span>󰎈 {} 󰎈</span>",
      "max-length": 40,
      "on-click": "",
      "return-type": "json"
    },
    "custom/clipboard": {
      "format": "  ",
      "tooltip": true,
      "tooltip-format": "Clipboard",
      "on-click": "walker -m clipboard"
    },
    "cava#right": {
      "autosens": 1,
      "bar_delimiter": 0,
      "bars": 18,
      "format-icons": [
        "<span foreground='#${c.base0E}'>▁</span>",
        "<span foreground='#${c.base0E}'>▂</span>",
        "<span foreground='#${c.base0E}'>▃</span>",
        "<span foreground='#${c.base0E}'>▄</span>",
        "<span foreground='#${c.base0D}'>▅</span>",
        "<span foreground='#${c.base0D}'>▆</span>",
        "<span foreground='#${c.base0D}'>▇</span>",
        "<span foreground='#${c.base0D}'>█</span>"
      ],
      "framerate": 60,
      "higher_cutoff_freq": 10000,
      "input_delay": 2,
      "lower_cutoff_freq": 50,
      "method": "pipewire",
      "monstercat": false,
      "reverse": false,
      "source": "auto",
      "stereo": true,
      "waves": false
    }
}
''
