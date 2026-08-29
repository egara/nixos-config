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
import Quickshell.Services.Notifications
import Quickshell.Io // for Process
import "Model.js" as Model

Scope {

PanelWindow {
    id: root
    
    // Floating bar setup
    anchors {
        top: true
        left: true
        right: true
    }
    
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    
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
    property bool clockVisible: false
    
    // Do not disturb mode
    property bool dndMode: false

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

    // Notifications Model and Server
    property var notifObjects: ({})
    
    ListModel {
        id: notificationModel
    }

    NotificationServer {
        id: notifServer
        onNotification: notif => {
            var iconName = notif.image;
            if (!iconName || iconName === "") {
                iconName = notif.appIcon;
            }
            if (!iconName || iconName === "") {
                iconName = notif.desktopEntry;
            }
            if (!iconName || iconName === "") {
                iconName = "dialog-information"; // fallback
            }
            
            var safeBody = notif.body ? notif.body.toString().replace(/<[^>]*>?/gm, "") : "";
            
            root.notifObjects[notif.id] = notif;
            
            // Extract existing data for the same app to keep them grouped
            var appNameToMatch = notif.appName || "Sistema";
            var existingData = [];
            for (var i = notificationModel.count - 1; i >= 0; i--) {
                var item = notificationModel.get(i);
                if (item.appName === appNameToMatch) {
                    existingData.unshift({
                        notifId: item.notifId,
                        appName: item.appName,
                        summary: item.summary,
                        body: item.body,
                        iconName: item.iconName,
                        timeStr: item.timeStr
                    });
                    notificationModel.remove(i);
                }
            }
            
            notificationModel.insert(0, {
                notifId: notif.id,
                appName: appNameToMatch,
                summary: notif.summary || "",
                body: safeBody,
                iconName: iconName,
                timeStr: Qt.formatTime(new Date(), "hh:mm")
            });
            
            for (var j = 0; j < existingData.length; j++) {
                notificationModel.insert(j + 1, existingData[j]);
            }
            
            if (!root.dndMode) {
                // Play notification sound
                soundPlayer.running = true;
                
                // Show OSD popup
                var osdId = notif.id;
                osdModel.insert(0, {
                    notifId: osdId,
                    appName: notif.appName || "Sistema",
                    summary: notif.summary || "",
                    body: safeBody,
                    iconName: iconName,
                    timeStr: Qt.formatTime(new Date(), "hh:mm")
                });
                
                // Auto-dismiss OSD after 5 seconds
                var timerCode = 'import QtQuick; Timer { interval: 5000; running: true; repeat: false; onTriggered: { root.removeOsd(' + osdId + '); this.destroy(); } }';
                Qt.createQmlObject(timerCode, root, "osdTimer" + osdId);
            }
        }
    }
    
    function clearNotifications() {
        for (var k in root.notifObjects) {
            try { root.notifObjects[k].dismiss(); } catch(e) {}
        }
        root.notifObjects = {};
        notificationModel.clear();
    }
    
    function dismissNotification(notifId, index) {
        try { root.notifObjects[notifId].dismiss(); } catch(e) {}
        delete root.notifObjects[notifId];
        notificationModel.remove(index);
    }
    
    function dismissNotificationGroup(appName) {
        for (var i = notificationModel.count - 1; i >= 0; i--) {
            if (notificationModel.get(i).appName === appName) {
                var notifId = notificationModel.get(i).notifId;
                try { root.notifObjects[notifId].dismiss(); } catch(e) {}
                delete root.notifObjects[notifId];
                notificationModel.remove(i);
            }
        }
    }
    
    function removeOsd(id) {
        for (var i = 0; i < osdModel.count; i++) {
            if (osdModel.get(i).notifId === id) {
                osdModel.remove(i);
                break;
            }
        }
    }
    
    function forceDismissNotification(notifId) {
        removeOsd(notifId);
        for (var i = 0; i < notificationModel.count; i++) {
            if (notificationModel.get(i).notifId === notifId) {
                dismissNotification(notifId, i);
                break;
            }
        }
    }

    // Storage for OSD notifications
    ListModel { id: osdModel }
    
    // Sound player
    Process {
        id: soundPlayer
        command: ["pw-play", "/run/current-system/sw/share/sounds/freedesktop/stereo/message.oga"]
    }

    // Helper component to run commands
    Process {
        id: cmdRunner
    }

    // --- POPUPS ---
    ${battery.popup}
    ${sysinfo.popup}
    ${clock.popup}

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
                
                ${clock.widget}
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

    // --- OSD WINDOW ---
    PanelWindow {
        id: osdWindow
        visible: osdModel.count > 0
        
        anchors {
            top: true
            left: false
            right: false
            bottom: false
        }
        
        margins { top: 60 }
        
        color: "transparent"
        exclusiveZone: -1
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        
        implicitWidth: osdLayout.implicitWidth
        implicitHeight: osdLayout.implicitHeight
        
        ColumnLayout {
            id: osdLayout
            spacing: 8
            
            Repeater {
                model: osdModel
                Rectangle {
                    width: 420
                    implicitHeight: Math.max(90, osdCol.implicitHeight + 32)
                    color: "#F0${c.base01}"
                    radius: 16
                    border.color: "#33${c.base05}"
                    border.width: 1
                    clip: true

                    Rectangle {
                        id: osdIcon
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.margins: 12
                        width: height
                        radius: 8
                        color: "transparent"
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: {
                                var img = model.iconName.toString();
                                if (img.startsWith("image://") || img.startsWith("file://")) return img;
                                if (img.startsWith("/")) return "file://" + img;
                                return "image://icon/" + img;
                            }
                            sourceSize.width: 128
                            sourceSize.height: 128
                            fillMode: Image.PreserveAspectCrop
                        }
                    }

                    ColumnLayout {
                        id: osdCol
                        anchors.left: osdIcon.right
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: 16
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: model.appName
                                color: "#${c.base0D}"
                                font.family: "${fontName}"
                                font.pixelSize: 14
                                font.bold: true
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            Text {
                                text: model.timeStr
                                color: "#${c.base04}"
                                font.family: "${fontName}"
                                font.pixelSize: 12
                            }
                            
                            Rectangle {
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24
                                radius: 12
                                color: osdCloseHover.hovered ? "#33${c.base08}" : "transparent"
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰅖"
                                    color: osdCloseHover.hovered ? "#${c.base08}" : "#${c.base05}"
                                    font.family: "${fontName}"
                                    font.pixelSize: 14
                                }
                                
                                HoverHandler {
                                    id: osdCloseHover
                                }
                                
                                TapHandler {
                                    onTapped: {
                                        root.forceDismissNotification(model.notifId)
                                    }
                                }
                            }
                        }

                        Text {
                            text: model.summary
                            color: "#${c.base05}"
                            font.family: "${fontName}"
                            font.pixelSize: 15
                            font.bold: true
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }

                        Text {
                            text: model.body
                            color: "#${c.base04}"
                            font.family: "${fontName}"
                            font.pixelSize: 14
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                            visible: text !== ""
                        }
                    }    
                    
                    Component.onCompleted: osdEnterAnim.start()
                    NumberAnimation on opacity {
                        id: osdEnterAnim
                        from: 0
                        to: 1
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }
}
''
