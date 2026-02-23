{ config, lib, nixosConfig }:

let
  c = config.lib.stylix.colors;
in
''
* {
    border: none;
    border-radius: 0;
    min-height: 0;
    font-family: ${config.stylix.fonts.monospace.name}, Roboto, Helvetica, Arial, sans-serif;
    font-size: 13px;
}

@define-color base00 #${c.base00};
@define-color base01 #${c.base01};
@define-color base02 #${c.base02};
@define-color base03 #${c.base03};
@define-color base04 #${c.base04};
@define-color base05 #${c.base05};
@define-color base06 #${c.base06};
@define-color base07 #${c.base07};
@define-color base08 #${c.base08};
@define-color base09 #${c.base09};
@define-color base0A #${c.base0A};
@define-color base0B #${c.base0B};
@define-color base0C #${c.base0C};
@define-color base0D #${c.base0D};
@define-color base0E #${c.base0E};
@define-color base0F #${c.base0F};

window#waybar {
    background-color: rgba(0, 0, 0, 0);
    border-radius: 5px;
    font-size: 13px;
    transition-property: background-color;
    transition-duration: 0.5s;
}

window#waybar.hidden {
    opacity: 0.2;
}

window#waybar.empty {
    background-color: transparent;
}

button {
    /* Use box-shadow instead of border so the text isn't offset */
    box-shadow: inset 0 -3px transparent;
    /* Avoid rounded borders under each button name */
    border: none;
    border-radius: 0;
}

/* https://github.com/Alexays/Waybar/wiki/FAQ#the-workspace-buttons-have-a-strange-hover-effect */
button:hover {
    background: inherit;
    box-shadow: inset 0 -3px @base05;
}

.modules-left,
.modules-center,
.modules-right {
    border-radius: 5px;
    background-color: alpha(@base01, 0.6);
    padding: 2px 6px;
}

#mode {
    background-color: @base0D;
    box-shadow: inset 0 -3px @base05;
}

#workspaces {
    background: @base00;
    margin: 5px 5px;
    padding: 8px 5px;
    border-radius: 15px;
    color: @base0E;
}
#workspaces button {
    padding: 0px 5px;
    margin: 0px 3px;
    border-radius: 16px;
    color: transparent;
    background: alpha(@base02, 1);
    transition: all 0.3s ease-in-out;
}

#workspaces button.active {
    background-color: @base0D;
    color: @base00;
    border-radius: 16px;
    min-width: 50px;
    background-size: 400% 400%;
    transition: all 0.3s ease-in-out;
}

#workspaces button:hover {
    background-color: @base05;
    color: @base00;
    border-radius: 16px;
    min-width: 50px;
    background-size: 400% 400%;
}

#clock,
#battery,
#power-profiles-daemon,
#cpu,
#memory,
#disk,
#backlight,
#network,
#pulseaudio,
#wireplumber,
#taskbar,
#custom-clipboard,
#custom-notification,
#custom-insync {
    background: @base00;
    margin: 5px 5px;
    padding: 8px;
    border-radius: 15px;
    color: @base05;
}

#custom-notification {
    padding: 8px 10px;
}

#custom-insync {
    padding: 8px 13px 8px 7px;
}

#custom-power {
    padding: 8px 12px;
}

tooltip {
    background: alpha(@base00, 0.9);
    border: 1px solid @base0E;
    border-radius: 10px;
}

tooltip label {
    color: @base05;
}

#calendar {
    padding: 10px;
    background-color: ${if config.stylix.polarity == "light" then "@base01" else "@base00"};
    margin: 5px;
}

#calendar .header {
    color: @base0E;
}

#calendar .days {
    color: @base05;
}

#calendar .weekdays {
    color: @base0B;
}

#calendar .today {
    color: @base00;
    background-color: @base0A;
    border-radius: 5px;
    font-weight: bold;
}

#tray {
    background: ${if config.stylix.polarity == "light" then "@base03" else "@base02"};
    margin: 5px 5px;
    padding: 8px;
    border-radius: 15px;
    color: @base05;
}

@keyframes blink {
    to {
        background-color: transparent;
        color: @base00;
    }
}

/* Using steps() instead of linear as a timing function to limit cpu usage */
#battery.critical:not(.charging) {
    background-color: transparent;
    color: @base08;
    animation-name: blink;
    animation-duration: 0.5s;
    animation-timing-function: steps(12);
    animation-iteration-count: infinite;
    animation-direction: alternate;
}

#power-profiles-daemon.performance {
    background-color: @base00;
    color: @base08;
}

#power-profiles-daemon.balanced {
    background-color: @base00;
    color: @base0D;
}

#power-profiles-daemon.power-saver {
    background-color: @base00;
    color: @base0B;
}

label:focus {
    background-color: @base00;
}

#cpu {
    background: @base00;
}

#memory {
    background: @base00;
}

#disk {
    background: @base00;
}

#backlight {
    background: @base00;
}

#network {
    background: @base00;
}

#network.disconnected {
    background-color: @base08;
    color: @base09;
}

#pulseaudio {
    background: @base00;
}

#pulseaudio.muted {
    background: @base00;
    color: @base09;
}

#wireplumber {
    background: @base00;
}

#wireplumber.muted {
    background: @base00;
    color: @base09;
}

/* playerctl for displaying and managing music in waybar */
#custom-playerctl.backward,
#custom-playerctl.play,
#custom-playerctl.foward {
    background: @base00;
    font-size: 18px;
    margin: 5px 0px;
}

#custom-playerctl.backward:hover,
#custom-playerctl.play:hover,
#custom-playerctl.foward:hover {
    color: @base05;
}

#custom-playerctl.backward {
    color: @base0E;
    border-radius: 15px 0px 0px 15px;
    padding-left: 12px;
    margin-left: 7px;
}

#custom-playerctl.play {
    color: @base0D;
    padding-right: 3px;
    padding-left: 10px;
}

#custom-playerctl.foward {
    color: @base0E;
    border-radius: 0px 15px 15px 0px;
    padding-right: 4px;
    padding-left: 8px;
    margin-right: 5px;
}

#custom-playerlabel {
    background: @base00;
    color: @base05;
    padding: 0 20px;
    border-radius: 24px 10px 24px 10px;
    margin: 5px 0;
    font-weight: bold;
}

#custom-media {
    background-color: @base0B;
    color: @base00;
    min-width: 100px;
}

#custom-media.custom-spotify {
    background-color: @base0B;
}

#custom-media.custom-vlc {
    background-color: @base09;
}

#temperature {
    background-color: @base09;
    padding: 5px 5px;
}

#temperature.critical {
    background-color: @base08;
}

#tray > .passive {
    -gtk-icon-effect: dim;
}

#tray > .needs-attention {
    -gtk-icon-effect: highlight;
    background-color: @base08;
}

#idle_inhibitor {
    background-color: @base03;
}

#idle_inhibitor.activated {
    background-color: @base05;
    color: @base00;
}

#mpd {
    background-color: @base0B;
    color: @base00;
}

#mpd.disconnected {
    background-color: @base08;
}

#mpd.stopped {
    background-color: @base04;
}

#mpd.paused {
    background-color: @base0C;
}

#language {
    background: @base0D;
    color: @base00;
    padding: 0 5px;
    margin: 0 5px;
    min-width: 16px;
    padding: 5px 5px;
}

#keyboard-state {
    background-color: transparent;
    color: @base05;
    margin: 0 5px;
    min-width: 16px;
    padding: 5px 5px;
}

#keyboard-state > label {
    padding: 0 5px;
}

#keyboard-state > label.locked {
    background: @base0A;
}

#scratchpad {
    background: alpha(@base00, 0.2);
}

#scratchpad.empty {
    background-color: transparent;
}

#privacy {
    padding: 0;
}

#privacy-item {
    padding: 0 5px;
    color: @base05;
}

#privacy-item.screenshare {
    background-color: @base09;
}

#privacy-item.audio-in {
    background-color: @base0B;
}

#privacy-item.audio-out {
    background-color: @base0D;
}

#taskbar.empty {
    background: transparent;
}

#taskbar {
    background: @base00;
    margin: 5px 5px;
    padding: 8px;
    border-radius: 15px;
    color: @base05;
}

#taskbar button.active {
    background-color: @base0D;
    color: @base00;
    border-radius: 10px;
}

#cava.left,
#cava.right {
    background: @base00;
    margin: 5px;
    padding: 8px 16px;
    color: @base0E;
}

#cava.left {
    border-radius: 24px 10px 24px 10px;
}

#cava.right {
    border-radius: 10px 24px 10px 24px;
}

#custom-walker {
    font-size: 16px;
}

#custom-clipboard {
    background: @base00;
    margin: 5px 5px;
    padding: 8px;
    border-radius: 15px;
    color: @base05;
    font-size: 16px;
}

#custom-insync.error {
    color: @base08;
}

#custom-insync.syncing {
    color: @base0D;
}

/* Make backlight and pulseaudio modules look like a single block */
#backlight {
    margin: 5px 0 5px 5px;
    border-radius: 15px 0 0 15px;
    padding-right: 0px;
    min-width: 55px;
}

#pulseaudio {
    margin: 5px 5px 5px 0;
    border-radius: 0 15px 15px 0;
    padding-left: 0px;
    min-width: 55px;
}

/* Make cpu and memory modules look like a single block */
#cpu {
    margin: 5px 0 5px 5px;
    border-radius: 15px 0 0 15px;
    padding-right: 0px;
    min-width: 55px;
}

#memory {
    margin: 5px 5px 5px 0;
    border-radius: 0 15px 15px 0;
    padding-left: 0px;
    min-width: 55px;
}

/* Make battery and power-profiles-daemon modules look like a single block */
#battery {
    margin: 5px 0 5px 5px;
    border-radius: 15px 0 0 15px;
    padding-right: 4px;
}

#power-profiles-daemon {
    margin: 5px 5px 5px 0;
    border-radius: 0 15px 15px 0;
    padding-left: 4px;
    padding-right: 12px;
}
''
