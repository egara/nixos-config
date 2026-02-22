{ config, lib, nixosConfig }:

let
  c = config.lib.stylix.colors;
in
''
@define-color window_bg_color #${c.base00};
@define-color accent_bg_color #${c.base0D};
@define-color theme_fg_color #${c.base05};
@define-color error_bg_color #${c.base08};
@define-color error_fg_color #${c.base00};

* {
  all: unset;
}

popover {
  background: lighter(@window_bg_color);
  border: 1px solid darker(@accent_bg_color);
  border-radius: 18px;
  padding: 10px;
}

.normal-icons {
  -gtk-icon-size: 16px;
}

.large-icons {
  -gtk-icon-size: 32px;
}

scrollbar {
  opacity: 0;
}

.box-wrapper {
  box-shadow:
    0 19px 38px rgba(0, 0, 0, 0.1),
    0 15px 12px rgba(0, 0, 0, 0.08);
  background: @window_bg_color;
  padding: 20px;
  border-radius: 20px;
  border: 1px solid #${c.base02};
}

.preview-box,
.elephant-hint,
.placeholder {
  color: @theme_fg_color;
}

.box {
}

.search-container {
  border-radius: 10px;
}

.input placeholder {
  opacity: 0.5;
}

.input selection {
  background: alpha(@accent_bg_color, 0.3);
}

.input {
  caret-color: @accent_bg_color;
  background: #${c.base01};
  padding: 10px;
  color: @theme_fg_color;
  border: 1px solid #${c.base02};
  border-radius: 8px;
}

.input:focus,
.input:active {
    border-color: @accent_bg_color;
}

.content-container {
}

.placeholder {
}

.scroll {
}

.list {
  color: @theme_fg_color;
}

child {
}

.item-box {
  border-radius: 10px;
  padding: 10px;
}

.item-quick-activation {
  background: alpha( @accent_bg_color, 0.1);
  border-radius: 5px;
  padding: 10px;
}

child:selected .item-box {
  background: alpha( @accent_bg_color, 0.15);
}

.item-text-box {
}

.item-subtext {
  font-size: 12px;
  opacity: 0.7;
}

.providerlist .item-subtext {
  font-size: unset;
  opacity: 0.75;
}

.item-image-text {
  font-size: 28px;
}

.preview {
  border: 1px solid #${c.base02};
  padding: 10px;
  border-radius: 10px;
  color: @theme_fg_color;
}

.calc .item-text {
  font-size: 24px;
}

.calc .item-subtext {
}

.symbols .item-image {
  font-size: 24px;
}

.todo.done .item-text-box {
  opacity: 0.25;
}

.todo.urgent {
  font-size: 24px;
}

.todo.active {
  font-weight: bold;
}

.bluetooth.disconnected {
  opacity: 0.5;
}

.preview .large-icons {
  -gtk-icon-size: 64px;
}

.keybinds {
  padding-top: 10px;
  border-top: 1px solid #${c.base02};
  font-size: 12px;
  color: @theme_fg_color;
}

.global-keybinds {
}

.item-keybinds {
}

.keybind {
}

.keybind-button {
  opacity: 0.5;
}

.keybind-button:hover {
  opacity: 0.75;
}

.keybind-bind {
  text-transform: lowercase;
  opacity: 0.35;
}

.keybind-label {
  padding: 2px 4px;
  border-radius: 4px;
  border: 1px solid @theme_fg_color;
}

.error {
  padding: 10px;
  background: @error_bg_color;
  color: @error_fg_color;
  border-radius: 8px;
}

:not(.calc).current {
  font-style: italic;
}

.preview-content.archlinuxpkgs, .preview-content.dnfpackages {
  font-family: monospace;
}
''
