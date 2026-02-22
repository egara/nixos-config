{ config, pkgs, lib, nixosConfig, ... }:

let
  c = config.lib.stylix.colors;
  iconSet = if config.stylix.polarity == "light" then "black" else "white";
in
''
* {
	background-image: none;
	box-shadow: none;
}

window {
	background-color: alpha(#${c.base00}, 0.9);
}

button {
    border-radius: 15px;
    border-color: #${c.base02};
	text-decoration-color: #${c.base05};
    color: #${c.base05};
	background-color: #${c.base01};
	border-style: solid;
	border-width: 2px;
	background-repeat: no-repeat;
	background-position: center;
	background-size: 20%;
    margin: 15px;
}

button:focus, button:active, button:hover {
	background-color: #${c.base0D};
	outline-style: none;
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
