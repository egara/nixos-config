{ config, pkgs, lib, nixosConfig, ... }:

let
  c = config.lib.stylix.colors;
  iconSet = if config.stylix.polarity == "light" then "black" else "white";
  # Styling variables - Adjusted for larger buttons
  button_rad = 20;
  active_rad = 40;
  mgn = 100; # Horizontal margin (smaller means wider bar)
  v_mgn = 200; # Vertical margin (smaller means taller buttons)
  hvr_mgn = 180; # Vertical margin on hover (lift effect)
in
''
* {
    background-image: none;
    box-shadow: none;
    font-family: "${config.stylix.fonts.sansSerif.name}";
}

window {
    background-color: transparent;
}

button {
    color: #${c.base05};
    background-color: alpha(#${c.base01}, 0.7);
    outline-style: none;
    border: none;
    border-width: 0px;
    background-repeat: no-repeat;
    background-position: center 35%;
    background-size: 40%;
    border-radius: 0px;
    margin: ${toString v_mgn}px 0px ${toString v_mgn}px 0px;
    font-size: ${toString config.stylix.fonts.sizes.desktop}pt;
    padding-top: 120px;
    
    /* Smooth return transition without overshoot */
    transition: all 0.2s ease-in-out;
}

button:focus, button:hover {
    background-color: #${c.base0D};
    border-radius: ${toString active_rad}px;
    color: #${c.base00};
    
    /* Elastic entry transition (HyDE style) */
    transition: all 0.3s cubic-bezier(.55,0.0,.28,1.682);
}

button:focus {
    background-size: 50%;
}

button:hover {
    background-size: 55%;
}

/* Specific styling for endpoints of the row */
#shutdown {
    border-radius: ${toString button_rad}px 0px 0px ${toString button_rad}px;
    margin-left: ${toString mgn}px;
}

#suspend {
    border-radius: 0px ${toString button_rad}px ${toString button_rad}px 0px;
    margin-right: ${toString mgn}px;
}

/* Hover Margins for lifting effect */
button:hover#shutdown {
    margin: ${toString hvr_mgn}px 0px ${toString hvr_mgn}px ${toString mgn}px;
}

button:hover#logout,
button:hover#reboot,
button:hover#lock,
button:hover#hibernate {
    margin: ${toString hvr_mgn}px 0px ${toString hvr_mgn}px 0px;
}

button:hover#suspend {
    margin: ${toString hvr_mgn}px ${toString mgn}px ${toString hvr_mgn}px 0px;
}

'' + ( if iconSet == "black" then ''
#lock { background-image: image(url("./icons/lock-black.png")); }
#logout { background-image: image(url("./icons/logout-black.png")); }
#suspend { background-image: image(url("./icons/suspend-black.png")); }
#hibernate { background-image: image(url("./icons/hibernate-black.png")); }
#shutdown { background-image: image(url("./icons/shutdown-black.png")); }
#reboot { background-image: image(url("./icons/reboot-black.png")); }
'' else ''
#lock { background-image: image(url("./icons/lock.png")); }
#logout { background-image: image(url("./icons/logout.png")); }
#suspend { background-image: image(url("./icons/suspend.png")); }
#hibernate { background-image: image(url("./icons/hibernate.png")); }
#shutdown { background-image: image(url("./icons/shutdown.png")); }
#reboot { background-image: image(url("./icons/reboot.png")); }
'')
