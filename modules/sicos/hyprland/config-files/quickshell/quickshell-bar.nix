{ config, lib, nixosConfig, pkgs }:

let
  c = config.lib.stylix.colors;
  fontName = config.stylix.fonts.monospace.name;
in
''
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.UPower
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
    
    height: 40
    color: "transparent"
    
    // Exclusive zone so windows don't overlap
    exclusiveZone: 48

    // Helper component to run commands
    Process {
        id: cmdRunner
    }

    PopupWindow {
        id: batteryPopup
        anchor.window: root
        anchor.rect.x: root.width - 240 // Adjust position for wider popup
        anchor.rect.y: root.height
        anchor.rect.width: 65
        anchor.rect.height: 0
        anchor.edges: Edges.Bottom
        visible: false
        width: 380
        height: 220
        color: "transparent"

        // Helper functions
        function getRealBatteryHealth() {
            let h = UPower.displayDevice != null ? UPower.displayDevice.healthPercentage : 0;
            if (h > 0) return Math.round(h) + "%";
            for (let i = 0; i < UPower.devices.values.length; i++) {
                let d = UPower.devices.values[i];
                if (d.type === 2 && d.healthPercentage > 0) return Math.round(d.healthPercentage) + "%";
            }
            return "Unknown";
        }
        
        function getRealBatteryCapacity() {
            let cap = UPower.displayDevice != null ? UPower.displayDevice.energyFull : 0;
            if (cap > 0) return cap.toFixed(1) + " Wh";
            for (let i = 0; i < UPower.devices.values.length; i++) {
                let d = UPower.devices.values[i];
                if (d.type === 2 && d.energyFull > 0) return d.energyFull.toFixed(1) + " Wh";
            }
            return "Unknown";
        }
        
        function getBatteryStateString() {
            if (!UPower.displayDevice) return "Unknown";
            switch(UPower.displayDevice.state) {
                case 1: return "Charging";
                case 2: return "Discharging";
                case 3: return "Empty";
                case 4: return "Fully Charged";
                case 5: return "Pending Charge";
                case 6: return "Pending Discharge";
                default: return "Unknown";
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "#F0${c.base01}" // Slightly transparent dark background
            radius: 16
            border.color: "#33${c.base05}"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                // Top Row: Icon, Status, Close
                RowLayout {
                    Layout.fillWidth: true
                    
                    Text {
                        text: ""
                        color: "#${c.base0D}" // Cyan
                        font.family: "${fontName}"
                        font.pixelSize: 22
                    }
                    
                    Text {
                        text: "<font color='#${c.base05}'><b>" + (UPower.displayDevice != null ? Math.round(UPower.displayDevice.percentage * 100) : 0) + "%</b></font> <font color='#${c.base04}'>" + batteryPopup.getBatteryStateString() + "</font>"
                        font.family: "${fontName}"
                        font.pixelSize: 18
                        textFormat: Text.RichText
                        Layout.fillWidth: true
                        Layout.leftMargin: 8
                    }
                    
                    Text {
                        text: "✕"
                        color: closeArea.containsMouse ? "#${c.base05}" : "#${c.base04}"
                        font.family: "${fontName}"
                        font.pixelSize: 18
                        MouseArea {
                            id: closeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: batteryPopup.visible = false
                        }
                    }
                }

                // Middle Row: Cards
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16
                    
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 70
                        radius: 12
                        color: "#${c.base02}"
                        
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: "Health"
                                color: "#${c.base0D}"
                                font.family: "${fontName}"
                                font.pixelSize: 13
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: batteryPopup.getRealBatteryHealth()
                                color: "#${c.base05}"
                                font.family: "${fontName}"
                                font.bold: true
                                font.pixelSize: 20
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 70
                        radius: 12
                        color: "#${c.base02}"
                        
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: "Capacity"
                                color: "#${c.base0D}"
                                font.family: "${fontName}"
                                font.pixelSize: 13
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: batteryPopup.getRealBatteryCapacity()
                                color: "#${c.base05}"
                                font.family: "${fontName}"
                                font.bold: true
                                font.pixelSize: 20
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                }

                // Bottom Row: Power Profiles
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    spacing: 8
                    
                    Repeater {
                        model: [
                            { name: "Power Saver", cmd: "power-saver", enumVal: 0, notify: " Power-saver " },
                            { name: "Balanced", cmd: "balanced", enumVal: 1, notify: " Balanced " },
                            { name: "Performance", cmd: "performance", enumVal: 2, notify: " Performance " }
                        ]
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 20
                            color: PowerProfiles.profile === modelData.enumVal ? "#${c.base0D}" : 
                                   (profileArea.containsMouse ? "#${c.base03}" : "#${c.base02}")
                            
                            Text {
                                anchors.centerIn: parent
                                text: modelData.name
                                color: PowerProfiles.profile === modelData.enumVal ? "#${c.base00}" : "#${c.base04}"
                                font.family: "${fontName}"
                                font.pixelSize: 14
                                font.bold: PowerProfiles.profile === modelData.enumVal
                            }
                            
                            MouseArea {
                                id: profileArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    profileProc.exec(["sh", "-c", "${pkgs.power-profiles-daemon}/bin/powerprofilesctl set " + modelData.cmd + " && ${pkgs.libnotify}/bin/notify-send -t 3500 -u low -r 9993 'Energy Profile' '" + modelData.notify + "'"])
                                }
                            }
                            Process {
                                id: profileProc
                            }
                        }
                    }
                }
            }
        }
    }

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

                // Launcher Button
                Rectangle {
                    width: 28; height: 28
                    radius: 14
                    color: launcherMouseArea.containsMouse ? "#${c.base03}" : "#${c.base0D}"
                    
                    Text {
                        anchors.centerIn: parent
                        text: "" // NixOS icon (Nerd Fonts)
                        color: "#${c.base00}"
                        font.family: "${fontName}"
                        font.pixelSize: 18
                    }
                    
                    MouseArea {
                        id: launcherMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            cmdRunner.command = ["uwsm", "app", "--", "walker"]
                            cmdRunner.start()
                        }
                    }
                }

                // CPU / Mem Placeholders
                Rectangle {
                    color: "#${c.base01}"
                    radius: 8
                    Layout.preferredHeight: 28
                    Layout.preferredWidth: 60
                    Text {
                        anchors.centerIn: parent
                        text: " CPU"
                        color: "#${c.base05}"
                        font.family: "${fontName}"
                        font.pixelSize: 12
                    }
                }
                Rectangle {
                    color: "#${c.base01}"
                    radius: 8
                    Layout.preferredHeight: 28
                    Layout.preferredWidth: 60
                    Text {
                        anchors.centerIn: parent
                        text: " RAM"
                        color: "#${c.base05}"
                        font.family: "${fontName}"
                        font.pixelSize: 12
                    }
                }

                // Workspace Switcher
                Row {
                    spacing: 6
                    Repeater {
                        model: Hyprland.workspaces
                        Rectangle {
                            property bool isActive: Hyprland.focusedWorkspace != null && Hyprland.focusedWorkspace.id === modelData.id
                            width: isActive ? 32 : 24
                            height: 24
                            radius: 12
                            color: isActive ? "#${c.base0D}" : "#${c.base02}"
                            anchors.verticalCenter: parent.verticalCenter
                            
                            Behavior on width { NumberAnimation { duration: 200 } }
                            Behavior on color { ColorAnimation { duration: 200 } }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.name
                                color: isActive ? "#${c.base00}" : "#${c.base05}"
                                font.family: "${fontName}"
                                font.pixelSize: 12
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: Hyprland.dispatch("workspace " + modelData.id)
                            }
                        }
                    }
                }
            }

            // ==========================================
            // CENTER WIDGETS
            // ==========================================
            RowLayout {
                Layout.alignment: Qt.AlignCenter
                
                Text {
                    id: clockText
                    color: "#${c.base05}"
                    font.family: "${fontName}"
                    font.pixelSize: 14
                    font.bold: true
                    text: Qt.formatDateTime(new Date(), "ddd MMM d  hh:mm")
                    
                    Timer {
                        interval: 1000
                        running: true
                        repeat: true
                        onTriggered: clockText.text = Qt.formatDateTime(new Date(), "ddd MMM d  hh:mm")
                    }
                }
            }

            // ==========================================
            // RIGHT WIDGETS
            // ==========================================
            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 12

                // Tray placeholder
                Rectangle {
                    color: "#${c.base01}"
                    radius: 8
                    Layout.preferredHeight: 28
                    Layout.preferredWidth: 60
                    Text {
                        anchors.centerIn: parent
                        text: "Tray..."
                        color: "#${c.base05}"
                        font.family: "${fontName}"
                        font.pixelSize: 12
                    }
                }

                // Battery Widget
                Rectangle {
                    id: batteryWidgetContainer
                    color: (UPower.displayDevice != null && UPower.displayDevice.state === 1) ? "#${c.base0A}" : "#${c.base0B}" // Yellow charging, Green otherwise
                    radius: 8
                    Layout.preferredHeight: 28
                    Layout.preferredWidth: 65
                    visible: UPower.displayDevice != null && UPower.displayDevice.isPresent
                    
                    Text {
                        anchors.centerIn: parent
                        text: UPower.displayDevice != null ? " " + Math.round(UPower.displayDevice.percentage * 100) + "%" : ""
                        color: "#${c.base00}"
                        font.family: "${fontName}"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            batteryPopup.visible = !batteryPopup.visible
                        }
                    }
                }

                // Power Profile Indicator
                Rectangle {
                    color: "#${c.base02}"
                    radius: 8
                    Layout.preferredHeight: 28
                    Layout.preferredWidth: 28
                    
                    Text {
                        anchors.centerIn: parent
                        text: PowerProfiles.profile === 0 ? "" : (PowerProfiles.profile === 1 ? "" : "")
                        color: PowerProfiles.profile === 0 ? "#${c.base0B}" : (PowerProfiles.profile === 1 ? "#${c.base0D}" : "#${c.base08}") // Green for saver, Cyan for balanced, Red for performance
                        font.family: "${fontName}"
                        font.pixelSize: 14
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            // Cycle profiles on click
                            let nextProfile = "balanced";
                            let notifyIcon = " Balanced ";
                            if (PowerProfiles.profile === 0) { // from saver to balanced
                                nextProfile = "balanced";
                                notifyIcon = " Balanced ";
                            } else if (PowerProfiles.profile === 1) { // from balanced to performance
                                nextProfile = "performance";
                                notifyIcon = " Performance ";
                            } else { // from performance to saver
                                nextProfile = "power-saver";
                                notifyIcon = " Power-saver ";
                            }
                            indicatorProc.exec(["sh", "-c", "${pkgs.power-profiles-daemon}/bin/powerprofilesctl set " + nextProfile + " && ${pkgs.libnotify}/bin/notify-send -t 3500 -u low -r 9993 'Energy Profile' '" + notifyIcon + "'"])
                        }
                    }
                    Process {
                        id: indicatorProc
                    }
                }

                // Power Menu Button
                Rectangle {
                    width: 28; height: 28
                    radius: 14
                    color: powerMouseArea.containsMouse ? "#${c.base08}" : "#${c.base02}" // Red on hover
                    
                    Text {
                        anchors.centerIn: parent
                        text: "" // Power icon
                        color: powerMouseArea.containsMouse ? "#${c.base00}" : "#${c.base05}"
                        font.family: "${fontName}"
                        font.pixelSize: 14
                    }
                    
                    MouseArea {
                        id: powerMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            cmdRunner.exec(["uwsm", "app", "--", "wlogout"])
                        }
                    }
                }
            }
        }
    }
}
''
