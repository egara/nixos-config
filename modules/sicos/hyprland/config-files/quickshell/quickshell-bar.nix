{ config, lib, nixosConfig, pkgs }:

let
  c = config.lib.stylix.colors;
  fontName = config.stylix.fonts.monospace.name;
  
  # Import modularized components
  battery = import ./components/battery.nix { inherit config lib pkgs c fontName; };
  workspaces = import ./components/workspaces.nix { inherit config lib pkgs c fontName; };
  clock = import ./components/clock.nix { inherit config lib pkgs c fontName; };
  system = import ./components/system.nix { inherit config lib pkgs c fontName; };
  sysinfo = import ./components/sysinfo.nix { inherit config lib pkgs c fontName; };
  power = import ./components/power.nix { inherit config lib pkgs c fontName; };
  tray = import ./components/tray.nix { inherit config lib pkgs c fontName; };
in
''
//@ pragma UseQApplication
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Quickshell.Services.SystemTray
import Quickshell.Io // for Process

PanelWindow {
    id: root
    
    // Floating bar setup
    anchors {
        top: true
        left: true
        right: true
    }
    
    // Add some margins for a floating look
    margins {
        top: 8
        left: 12
        right: 12
    }
    
    implicitHeight: 40
    color: "transparent"
    
    // Exclusive zone so windows don't overlap
    exclusiveZone: 48

    // Popup visibility state for smooth animations
    property bool batteryVisible: false
    property bool sysinfoVisible: false
    property bool trayMenuVisible: false

    // Invisible background window to catch outside clicks for smooth exit animations
    PanelWindow {
        id: backgroundCatcher
        anchors {
            top: true; bottom: true; left: true; right: true
        }
        color: "#01000000"
        visible: root.batteryVisible || root.sysinfoVisible || root.trayMenuVisible || popupContent.opacity > 0
        
        MouseArea {
            anchors.fill: parent
            onClicked: {
                root.batteryVisible = false
                root.sysinfoVisible = false
                root.trayMenuVisible = false
            }
        }
    }

    // Helper component to run commands
    Process {
        id: cmdRunner
    }

    ${battery.popup}
    ${sysinfo.popup}

    Rectangle {
        anchors.fill: parent
        color: "#CC${c.base00}" // Stylix background with some transparency (CC = 80%)
        radius: 12
        border.color: "#${c.base02}"
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: 6
            spacing: 8

            // ==========================================
            // LEFT WIDGETS
            // ==========================================
            RowLayout {
                Layout.alignment: Qt.AlignLeft
                spacing: 12

                ${system}
                ${sysinfo.widget}
                ${workspaces}
            }

            // ==========================================
            // CENTER WIDGETS
            // ==========================================
            RowLayout {
                Layout.alignment: Qt.AlignCenter
                
                ${clock}
            }

            // ==========================================
            // RIGHT WIDGETS
            // ==========================================
            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 12

                ${tray}

                ${battery.widget}
                ${power}
            }
        }
    }
}
''
