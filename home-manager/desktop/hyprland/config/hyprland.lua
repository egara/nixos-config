-- ################################
-- Monitors Configuration - START
-- ################################

-- See https://wiki.hyprland.org/Configuring/Monitors/
-- monitor = , preferred, auto, 1

-- #################################
-- Monitors Configuration - FINISH
-- #################################

-- ###########################
-- Init Applications - START
-- ###########################

-- See https://wiki.hyprland.org/Configuring/Keywords/ for more
-- Execute your favorite apps at launch

hl.on("hyprland.start", function ()
    -- Finalize UWSM startup to export WAYLAND_DISPLAY and other critical variables
    hl.exec_cmd("uwsm finalize")

    -- Initial brightness at 55%
    hl.exec_cmd("uwsm app -- brightnessctl s 55%")

    -- Kanshi (Multi monitor layout manager)
    hl.exec_cmd("uwsm app -- kanshi")

    -- Screensaver (IDLE)
    hl.exec_cmd("systemctl --user enable --now hypridle.service")
    -- hl.exec_cmd("swayidle -w timeout 300 '$lock' timeout 300 'hyprctl dispatch dpms off' resume 'hyprctl dispatch dpms on' before-sleep '$lock'")

    -- Initilize wallpaper daemon
    hl.exec_cmd("uwsm app -- awww-daemon")

    -- Networking
    hl.exec_cmd("uwsm app -- nm-applet --indicator")

    -- Waybar
    hl.exec_cmd("uwsm app -- waybar")

    -- Walker & Elephant
    hl.exec_cmd("walker --gapplication-service")
    hl.exec_cmd("elephant")

    -- Notifications
    -- hl.exec_cmd("uwsm app -- dunst")
    hl.exec_cmd("uwsm app -- swaync")

    -- Clipboard
    -- hl.exec_cmd("uwsm app -- wl-paste --type text --watch cliphist store")
    -- hl.exec_cmd("uwsm app -- wl-paste --type image --watch cliphist store")

    -- Applications
    hl.exec_cmd("uwsm app -- Telegram -startintray")
    hl.exec_cmd("uwsm app -- insync start")

    -- Polkit
    hl.exec_cmd("uwsm app -- lxqt-policykit-agent")

    -- USB mounting daemon
    hl.exec_cmd("uwsm app -- udiskie -f thunar -t")

    -- Welcome animation
    hl.exec_cmd("uwsm app -- kitty --class welcome-terminal -o window_padding_width=30 -e ~/.config/sicos/scripts/welcome-animation.sh")

    -- Set wallpaper randomly (It doesn't work!)
    -- hl.exec_cmd("/home/egarcia/.config/sicos/scripts/change-wallpaper.sh")

    -- Due to Spotify has removed desktop notifications, this
    -- script is a workaround to display them again using
    -- playerctl. For more information:
    -- https://community.spotify.com/t5/Desktop-Linux/Desktop-notifications-no-longer-work/td-p/7354304
    hl.exec_cmd("/home/egarcia/.config/sicos/scripts/spotify.sh")
end)

-- ############################
-- Init Applications - FINISH
-- ############################

-- ###############################
-- Environment variables - START
-- ###############################

-- Environment variables
-- (Moved to ~/.config/uwsm/env as per UWSM best practices)

-- ################################
-- Environment variables - FINISH
-- ################################

-- ######################
-- Key Bindings - START
-- ######################

-- Set programs that I use
local lock = "hyprlock"
local terminal = "kitty"
local fileManager = "thunar"
-- local menu = "wofi --show drun"
local menu = "walker"
local browser = "firefox"
local webapp = "google-chrome-stable --app"

-- See https://wiki.hyprland.org/Configuring/Keywords/ for more
local mainMod = "SUPER"

-- Simple binds, see https://wiki.hyprland.org/Configuring/Binds/ for more
-- For finding a special KEY, install wev application
hl.bind("CTRL + ALT + T", hl.dsp.exec_cmd("uwsm app -- " .. terminal), { description = "Terminal (Kitty)" })
hl.bind(mainMod .. " + Y", hl.dsp.exec_cmd("uwsm app -- " .. terminal .. " yazi"), { description = "File Manager (Yazi)" })
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("uwsm app -- zeditor"), { description = "Text Editor" })
hl.bind(mainMod .. " + Q", hl.dsp.window.close(), { description = "Close Window" })
hl.bind("CTRL + ALT + Delete", hl.dsp.exit(), { description = "Exit" })
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("uwsm app -- " .. fileManager), { description = "File Manager (Thunar)" })
hl.bind(mainMod .. " + F", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle Floating Window" })
hl.bind(mainMod .. " + KP_Multiply", hl.dsp.window.pseudo(), { description = "Reduce/Enlarge Current Window" })
hl.bind(mainMod .. " + KP_Divide", hl.dsp.layout("togglesplit"), { description = "Change Layout" })
hl.bind(mainMod .. " + SPACE", hl.dsp.layout("movetoroot"), { description = "Move current window to root" })
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("uwsm app -- " .. browser), { description = "Firefox" })
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("uwsm app -- " .. browser .. " --private-window"), { description = "Firefox (Private Window)" })
hl.bind(mainMod .. " + G", hl.dsp.exec_cmd("uwsm app -- " .. webapp .. "='https://gemini.google.com/'"), { description = "Gemini" })
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("~/.config/sicos/scripts/sicos-settings.sh"), { description = "SicOS settings menu" })
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("uwsm app -- " .. terminal .. " --override term=xterm-256color -e lazyssh"), { description = "Lazyssh" })
hl.bind("SUPER + SUPER_L", hl.dsp.exec_cmd(menu), { description = "App Launcher (Walker)" })
-- hl.bind("SUPER + SUPER_L", hl.dsp.exec_cmd("pgrep -x .wofi-wrapped >/dev/null 2>&1 && killall .wofi-wrapped || " .. menu), { description = "App Launcher (Wofi)" })
hl.bind(mainMod .. " + CTRL + Up", hl.dsp.window.fullscreen({ mode = "fullscreen" }), { description = "Maximize Window (Toggling)" })
-- hl.bind(mainMod .. " + KP_Subtract", hl.dsp.exec_cmd("dunstctl history-pop"), { description = "Notifications History" })
hl.bind(mainMod .. " + ALT + Right", hl.dsp.window.resize({ x = 20, y = 0, relative = true }), { repeating = true, description = "Resize Current Window (Right)" })
hl.bind(mainMod .. " + ALT + Left", hl.dsp.window.resize({ x = -20, y = 0, relative = true }), { repeating = true, description = "Resize Current Window (Left)" })
hl.bind(mainMod .. " + ALT + Up", hl.dsp.window.resize({ x = 0, y = -20, relative = true }), { repeating = true, description = "Resize Current Window (Up)" })
hl.bind(mainMod .. " + ALT + Down", hl.dsp.window.resize({ x = 0, y = 20, relative = true }), { repeating = true, description = "Resize Current Window (Down)" })
hl.bind("ALT + Tab", hl.dsp.window.cycle_next(), { description = "Next Window (Cycle)" })

-- Layouts
hl.bind(mainMod .. " + F1", function()
    hl.config({ general = { layout = "dwindle" } })
    hl.exec_cmd('notify-send -t 2500 -u low -r 9993 "Dwindle Layout" "Binary Tree layout enabled"')
end, { description = "Enable Dwindle Layout" })

hl.bind(mainMod .. " + F2", function()
    hl.config({ general = { layout = "master" } })
    hl.exec_cmd('notify-send -t 2500 -u low -r 9993 "Master Layout" "Master window layout enabled"')
end, { description = "Enable Master Layout" })

hl.bind(mainMod .. " + F3", function()
    hl.config({ general = { layout = "scrolling" } })
    hl.exec_cmd('notify-send -t 2500 -u low -r 9993 "Scrolling Layout" "Scrolling windows layout enabled"')
end, { description = "Enable Scrolling Layout" })

hl.bind(mainMod .. " + F4", function()
    hl.config({ general = { layout = "monocle" } })
    hl.exec_cmd('notify-send -t 2500 -u low -r 9993 "Monocle Layout" "Maximized windows layout enabled"')
end, { description = "Enable Monocle Layout" })

-- Volume
-- pamixer is needed to get the volume via command line
-- Old configurations with dunst
-- hl.bind(", xf86audioraisevolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ && dunstify -a '-- Changing volume --' -u low -r 9993 -h int:value:$(pamixer --get-volume) 'Volume: $(pamixer --get-volume)%'"))
-- hl.bind(", xf86audiolowervolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && dunstify -a '-- Changing volume --' -u low -r 9993 -h int:value:$(pamixer --get-volume) 'Volume: $(pamixer --get-volume)%'"))
-- hl.bind(", XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && if [ '$(pamixer --get-mute)' == 'true' ]; then dunstify -a '-- Changing volume --' -u low -r 9993 'Volume Muted'; else dunstify -a '-- Changing volume --' -u low -r 9993 'Volume Unmuted'; fi"))

-- New configuration with swaync
hl.bind("xf86audioraisevolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ && notify-send -u low -t 5000 -h string:synchronous:volume -h int:value:$(pamixer --get-volume) -h string:x-canonical-private-synchronous:script 'Volume' && cvlc --no-video --play-and-exit ~/.config/hypr/pop-sound.mp3"))
hl.bind("xf86audiolowervolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && notify-send -u low -t 5000 -h string:synchronous:volume -h int:value:$(pamixer --get-volume) -h string:x-canonical-private-synchronous:script 'Volume' && cvlc --no-video --play-and-exit ~/.config/hypr/pop-sound.mp3"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && if [ '$(pamixer --get-mute)' == 'true' ]; then notify-send -u low -r 9993 'Volume' 'Volume Muted'; else notify-send -u low -r 9993 'Volume' 'Volume unmuted'; fi"))

-- Screen brighness
-- brightnessctl is needed to change the screen brighness via command line
-- Old configurations with dunst
-- hl.bind(", XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl s +5% && dunstify -a '-- Changing brightness --' -u low -r 9993 -h int:value:$(brightnessctl g) 'Brightness: $(brightnessctl g)%'"))
-- hl.bind(", XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 5%- && dunstify -a '-- Changing brightness --' -u low -r 9993 -h int:value:$(brightnessctl g) 'Brightness: $(brightnessctl g)%'"))

-- New configuration with swaync
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl s +5% && notify-send -u low -t 5000 -h string:synchronous:brightness -h int:value:$(($(brightnessctl g)*100/$(brightnessctl m))) -h string:x-canonical-private-synchronous:script 'Brightness'"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 5%- && notify-send -u low -t 5000 -h string:synchronous:brightness -h int:value:$(($(brightnessctl g)*100/$(brightnessctl m))) -h string:x-canonical-private-synchronous:script 'Brightness'"))

-- Change the wallpaper randomly
hl.bind(mainMod .. " + 1", hl.dsp.exec_cmd("awww img /home/egarcia/Insync/eloy.garcia.pca@gmail.com/Google\\ Drive/Wallpapers/$(ls /home/egarcia/Insync/eloy.garcia.pca@gmail.com/Google\\ Drive/Wallpapers | shuf -n 1)"), { description = "Change Wallpaper (Random)" })

-- Screenshots
hl.bind("Print", hl.dsp.exec_cmd("notify-send -t 2500 -u low -r 9993 'Screenshot' 'Select the region you want' && hyprshot -m region --raw | satty --filename - --early-exit --copy-command wl-copy --initial-tool arrow --output-filename ~/Pictures/screenshot-$(date '+%Y%m%d-%H:%M:%S').png"), { description = "Take a region screenshot and edit it" })
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("hyprshot -m region --clipboard-only"), { description = "Take a screenshot and copy it to the clipboard" })

-- Lock screen manually
hl.bind("CTRL + ALT + L", hl.dsp.exec_cmd(lock), { description = "Lock Screen" })

-- Clipboard
-- hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("cliphist list | wofi --dmenu | cliphist decode | wl-copy"))

-- Submaps binds
-- Moving windows
hl.bind(mainMod .. " + RETURN", hl.dsp.submap("moveWindow"))
hl.define_submap("moveWindow", function()
    -- Fluid movement within the same monitor
    hl.bind("Right", hl.dsp.window.move({ direction = "r" }), { repeating = true, description = "Move Window (Right)" })
    hl.bind("Left", hl.dsp.window.move({ direction = "l" }), { repeating = true, description = "Move Window (Left)" })
    hl.bind("Up", hl.dsp.window.move({ direction = "u" }), { repeating = true, description = "Move Window (Up)" })
    hl.bind("Down", hl.dsp.window.move({ direction = "d" }), { repeating = true, description = "Move Window (Down)" })
    -- Precise jump to the next monitor
    hl.bind(mainMod .. " + Right", hl.dsp.window.move({ monitor = "r" }), { description = "Jump To Monitor (Right)" })
    hl.bind(mainMod .. " + Left", hl.dsp.window.move({ monitor = "l" }), { description = "Jump To Monitor (Left)" })
    hl.bind(mainMod .. " + Up", hl.dsp.window.move({ monitor = "u" }), { description = "Jump To Monitor (Up)" })
    hl.bind(mainMod .. " + Down", hl.dsp.window.move({ monitor = "d" }), { description = "Jump To Monitor (Down)" })
    hl.bind("Escape", hl.dsp.submap("reset"))
end)

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + Left", hl.dsp.focus({ direction = "l" }), { description = "Move Focus (Left)" })
hl.bind(mainMod .. " + Right", hl.dsp.focus({ direction = "r" }), { description = "Move Focus (Right)" })
hl.bind(mainMod .. " + Up", hl.dsp.focus({ direction = "u" }), { description = "Move Focus (Up)" })
hl.bind(mainMod .. " + Down", hl.dsp.focus({ direction = "d" }), { description = "Move Focus (Down)" })

-- Switch workspaces
hl.bind("CTRL + ALT + Left", hl.dsp.focus({ workspace = "r-1" }), { desc = "Switch Workspace (Left)" })
hl.bind("CTRL + ALT + Right", hl.dsp.focus({ workspace = "r+1" }), { desc = "Switch Workspace (Right)" })

-- Move active window to a workspace
hl.bind("CTRL + ALT + SHIFT + Left", hl.dsp.window.move({ workspace = "r-1" }), { desc = "Move Active Window To Workspace (Left)" })
hl.bind("CTRL + ALT + SHIFT + Right", hl.dsp.window.move({ workspace = "r+1" }), { desc = "Move Active Window To Workspace (Right)" })

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + M", hl.dsp.workspace.toggle_special("magic"), { description = "Magic Workspace (Toggling)" })
hl.bind("CTRL + ALT + SHIFT + M", hl.dsp.window.move({ workspace = "special:magic" }), { description = "Move Active Window To Workspace (Magic)" })

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.config({
	binds = {
		drag_threshold = 15 -- Fire a drag event only after dragging for more than 15px
	}
})
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- #######################
-- Key Bindings - FINISH
-- #######################

-- Clamshell mode configuration
-- Lid is opened
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("/home/egarcia/.config/sicos/scripts/disable-laptop-screen.sh open"))

-- Lid is closed
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("/home/egarcia/.config/sicos/scripts/disable-laptop-screen.sh close"))

-- Source a file (multi-file configs)
-- source = ~/.config/hypr/myColors.conf

-- For all categories, see https://wiki.hyprland.org/Configuring/Variables/
hl.config({
    input = {
        kb_layout = "es",
        kb_variant = "",
        kb_model = "",
        kb_options = "",
        kb_rules = "",

        follow_mouse = 1,

        touchpad = {
            natural_scroll = false,
            disable_while_typing = true,
        },

        sensitivity = 0, -- -1.0 to 1.0, 0 means no modification.
    },

    general = {
        -- See https://wiki.hyprland.org/Configuring/Variables/ for more

        gaps_in = 3,
        gaps_out = 6,
        border_size = 2,
        col = {
            active_border = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },

        layout = "scrolling",

        -- Please see https://wiki.hyprland.org/Configuring/Tearing/ before you turn this on
        allow_tearing = false,
    },

    decoration = {
        -- See https://wiki.hyprland.org/Configuring/Variables/ for more

        rounding = 10,

        blur = {
            enabled = true,
            size = 4,
            passes = 2,
            new_optimizations = true,
            ignore_opacity = true,
            xray = false,
        },

        dim_inactive = true,
        dim_strength = 0.1,

        shadow = {
            enabled = true,
            range = 30,
            render_power = 3,
            color = "rgba(1a1a1aee)",
        },
    },

    dwindle = {
        -- See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
        preserve_split = true,
    },

    master = {
        -- See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
        new_status = "slave",
    },

    scrolling = {
        -- See https://wiki.hyprland.org/Configuring/Scrolling-Layout/ for more
        fullscreen_on_one_column = true,
        column_width = 0.8,
    },

    gestures = {
        -- See https://wiki.hyprland.org/Configuring/Variables/ for more
        workspace_swipe_touch = false,
    },

    misc = {
        -- See https://wiki.hyprland.org/Configuring/Variables/ for more
        force_default_wallpaper = -1, -- Set to 0 or 1 to disable the anime mascot wallpapers
    },

    device = {
        {
            name = "epic-mouse-v1",
            sensitivity = -0.5,
        },
    },
})

-- Animations
hl.curve("overshot", { type = "bezier", points = { {0.13, 0.99}, {0.29, 1.1} } })

hl.animation({ leaf = "windows", enabled = true, speed = 2, bezier = "overshot", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border", enabled = true, speed = 3, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 4, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "overshot", style = "fade" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 3, bezier = "default", style = "popin" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 3, bezier = "default", style = "popin" })

-- ######################
-- Window Rules - START
-- ######################

-- In order to identify a window class use "hyprctl clients"
-- See https://wiki.hyprland.org/Configuring/Window-Rules/ for more

-- Ignore maximize window requests by any application
hl.window_rule({
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Focus on activate any window
hl.window_rule({
    match = { class = ".*" },
    focus_on_activate = true,
})

hl.window_rule({
    match = { class = "^(kitty|thunar)$" },
    opacity = "0.9 0.8",
})

hl.window_rule({
    match = { class = "^(welcome-terminal)$" },
    opacity = "0.5 0.5",
    float = true,
    center = true,
    size = {650, 100},
    pin = true,
    border_size = 0,
    no_shadow = true,
})

hl.window_rule({
    match = { class = "^(Qmmp|buttermanager|es-estoes-wallpaperDownloader-Main|quickgui|SshAskpass|com.gabm.satty)$" },
    float = true,
    center = true,
})

hl.window_rule({
    match = { class = "^(firefox|google-chrome|com.stremio.stremio)$" },
    idle_inhibit = "focus",
})

-- #######################
-- Window Rules - FINISH
-- #######################

-- #####################
-- Layer Rules - START
-- #####################

-- In order to identify a layer namespace use "hyprctl layers"
-- Rules for swaync notifications and control center for bluring the wallpaper in the background
hl.layer_rule({
    match = { namespace = "swaync-control-center" },
    blur = true,
    dim_around = true,
    ignore_alpha = 0,
    animation = "fade",
})

hl.layer_rule({
    match = { namespace = "swaync-notification-window" },
    blur = false,
    animation = "popin",
})

hl.layer_rule({
    match = { namespace = "walker" },
    blur = true,
    dim_around = true,
    ignore_alpha = 1,
    animation = "fade",
})

-- Wlogout blur and ignore alpha
hl.layer_rule({
    match = { namespace = "logout_dialog" },
    blur = true,
    ignore_alpha = 0.5,
    dim_around = true,
})

-- Disabling animations for namespace selection (which is bind to slurp) in order to avoid a "ghost" window
-- when a screenshot is taken
hl.layer_rule({
    match = { namespace = "selection" },
    no_anim = true,
})

-- ######################
-- Layer Rules - FINISH
-- ######################
