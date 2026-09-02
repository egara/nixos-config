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
  misc = import ./components/misc.nix { inherit config lib pkgs c fontName; };
  controlcenter = import ./components/controlcenter.nix { inherit config lib pkgs c fontName; };
  tray = import ./components/tray.nix { inherit config lib pkgs c fontName; };
  progressOsd = import ./components/progressOsd.nix { inherit config lib pkgs c fontName; };
  overview = import ./components/overview.nix { inherit config lib pkgs c fontName; };
in
''
//@ pragma UseQApplication
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.UPower
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.Notifications
import Quickshell.Io // for Process
import Qt5Compat.GraphicalEffects
import "Model.js" as Model

Scope {
    property bool overviewActive: false

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
    property bool miscVisible: false
    property real miscButtonX: 0
    property bool controlcenterVisible: false
    property real controlcenterButtonX: 0
    
    // Do not disturb mode
    property bool dndMode: false
    
    // Progress OSD State
    property int progressOsdValue: 0
    property string progressOsdType: ""
    property bool progressOsdVisible: false
    
    Timer {
        id: progressOsdTimer
        interval: 2000
        repeat: false
        onTriggered: root.progressOsdVisible = false
    }

    // Invisible background window to catch outside clicks for smooth exit animations
    PanelWindow {
        id: backgroundCatcher
        anchors {
            top: true; bottom: true; left: true; right: true
        }
        color: "#01000000"
        visible: root.batteryVisible || root.sysinfoVisible || root.trayMenuVisible || root.miscVisible || root.controlcenterVisible || popupContent.opacity > 0 || popupContentMisc.opacity > 0 || popupContentCC.opacity > 0
        
        MouseArea {
            anchors.fill: parent
            onClicked: {
                root.batteryVisible = false
                root.sysinfoVisible = false
                root.trayMenuVisible = false
                root.miscVisible = false
                root.controlcenterVisible = false
            }
        }
    }

    // Notifications Model and Server
    property var notifObjects: ({})
    property var expandedGroups: ({})
    
    function toggleGroup(appName) {
        var copy = Object.assign({}, expandedGroups);
        if (copy[appName]) {
            delete copy[appName];
        } else {
            copy[appName] = true;
        }
        expandedGroups = copy;
    }
    
    ListModel {
        id: notificationModel
    }

    NotificationServer {
        id: notifServer
        
        keepOnReload: false
        actionsSupported: true
        actionIconsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        inlineReplySupported: true
        persistenceSupported: true

        onNotification: notif => {
            if (notif.summary === "Volume" || notif.summary === "Brightness") {
                var val = 0;
                if (notif.hints && notif.hints["value"] !== undefined) {
                    val = notif.hints["value"];
                }
                
                var isMuted = notif.body && notif.body.toString().toLowerCase().indexOf("muted") !== -1;
                if (isMuted) val = 0;
                
                root.progressOsdType = notif.summary;
                root.progressOsdValue = val;
                root.progressOsdVisible = true;
                progressOsdTimer.restart();
                
                try { notif.dismiss(); } catch(e) {}
                return;
            }

            notif.tracked = true;
            
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
            
            // Listen for when the sender closes the notification
            if (notif.Retainable) {
                var dropHandler = function() {
                    root.forceDismissNotification(notif.id, true);
                };
                notif.Retainable.dropped.connect(dropHandler);
            }
            
            // Extract existing data for the same app to keep them grouped
            var appNameToMatch = notif.appName || "Sistema";
            var existingData = [];
            for (var i = notificationModel.count - 1; i >= 0; i--) {
                var item = notificationModel.get(i);
                if (item.appName === appNameToMatch) {
                    if (item.notifId !== notif.id) {
                        existingData.unshift({
                            notifId: item.notifId,
                            appName: item.appName,
                            summary: item.summary,
                            body: item.body,
                            iconName: item.iconName,
                            desktopEntry: item.desktopEntry || "",
                            appIcon: item.appIcon || "",
                            timeStr: item.timeStr
                        });
                    }
                    notificationModel.remove(i);
                }
            }
            
            notificationModel.insert(0, {
                notifId: notif.id,
                appName: appNameToMatch,
                summary: notif.summary || "",
                body: safeBody,
                iconName: iconName,
                desktopEntry: notif.desktopEntry || "",
                appIcon: notif.appIcon || "",
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
                root.removeOsd(osdId); // Clear existing if this is an update
                
                osdModel.insert(0, {
                    notifId: osdId,
                    appName: notif.appName || "Sistema",
                    summary: notif.summary || "",
                    body: safeBody,
                    iconName: iconName,
                    desktopEntry: notif.desktopEntry || "",
                    appIcon: notif.appIcon || "",
                    timeStr: Qt.formatTime(new Date(), "hh:mm")
                });
                
                // Auto-dismiss OSD after 5 seconds
                var timerCode = 'import QtQuick; Timer { interval: 5000; running: true; repeat: false; onTriggered: { root.removeOsd(' + osdId + '); this.destroy(); } }';
                Qt.createQmlObject(timerCode, root, "osdTimer" + osdId);
            }
        }
    }
    
    property var removalQueue: []
    Timer {
        id: removalTimer
        interval: 120
        repeat: true
        onTriggered: {
            if (root.removalQueue.length > 0) {
                var notifId = root.removalQueue.shift();
                root.forceDismissNotification(notifId);
            } else {
                stop();
            }
        }
    }
    
    function clearNotifications() {
        var newQueue = root.removalQueue.slice();
        var toQueue = [];
        var toInstant = [];
        var seenApps = {};
        
        for (var i = 0; i < notificationModel.count; i++) {
            var notif = notificationModel.get(i);
            var isExpanded = root.expandedGroups[notif.appName] === true;
            
            if (isExpanded || !seenApps[notif.appName]) {
                toQueue.push(notif.notifId);
                seenApps[notif.appName] = true;
            } else {
                toInstant.push(notif.notifId);
            }
        }
        
        for (var j = 0; j < toInstant.length; j++) {
            root.forceDismissNotification(toInstant[j]);
        }
        for (var k = 0; k < toQueue.length; k++) {
            newQueue.push(toQueue[k]);
        }
        
        root.removalQueue = newQueue;
        if (root.removalQueue.length > 0) removalTimer.start();
    }
    
    function dismissNotificationGroup(appName) {
        var newQueue = root.removalQueue.slice();
        var isExpanded = root.expandedGroups[appName] === true;
        var firstFound = false;
        var toQueue = [];
        var toInstant = [];
        
        for (var i = 0; i < notificationModel.count; i++) {
            var notif = notificationModel.get(i);
            if (notif.appName === appName) {
                if (isExpanded || !firstFound) {
                    toQueue.push(notif.notifId);
                    firstFound = true;
                } else {
                    toInstant.push(notif.notifId);
                }
            }
        }
        
        for (var j = 0; j < toInstant.length; j++) {
            root.forceDismissNotification(toInstant[j]);
        }
        for (var k = 0; k < toQueue.length; k++) {
            newQueue.push(toQueue[k]);
        }
        
        root.removalQueue = newQueue;
        if (root.removalQueue.length > 0) removalTimer.start();
    }
    
    function removeOsd(id) {
        for (var i = 0; i < osdModel.count; i++) {
            if (osdModel.get(i).notifId === id) {
                osdModel.remove(i);
                break;
            }
        }
    }
    
    function forceDismissNotification(notifId, fromSender) {
        removeOsd(notifId);
        for (var i = 0; i < notificationModel.count; i++) {
            if (notificationModel.get(i).notifId === notifId) {
                var obj = root.notifObjects[notifId];
                delete root.notifObjects[notifId];
                notificationModel.remove(i);
                if (!fromSender && obj) {
                    try { obj.dismiss(); } catch(e) {}
                }
                break;
            }
        }
    }
    
    function invokeDefaultAction(notifId) {
        var obj = root.notifObjects[notifId];
        if (obj) {
            var invoked = false;
            if (typeof obj.invokeDefaultAction === 'function') {
                try { obj.invokeDefaultAction(); invoked = true; } catch(e) {}
            } else if (obj.actions) {
                for (var i = 0; i < obj.actions.length; i++) {
                    if (obj.actions[i].id === "default") {
                        try { obj.actions[i].invoke(); invoked = true; } catch(e) {}
                        break;
                    }
                }
                if (!invoked && obj.actions.length > 0) {
                    try { obj.actions[0].invoke(); invoked = true; } catch(e) {}
                }
            }
            root.forceDismissNotification(notifId, false);
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
    ${misc.popup}
    ${controlcenter.popup}

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
                ${misc.widget}
                ${controlcenter.widget}
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
        
        implicitWidth: 420
        implicitHeight: osdList.height
        
        ListView {
            id: osdList
            width: 420
            height: Math.min(contentHeight, 800)
            spacing: 8
            interactive: false
            
            add: Transition {
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 300; easing.type: Easing.OutCubic }
                    NumberAnimation { property: "y"; from: -20; duration: 300; easing.type: Easing.OutBack }
                }
            }
            remove: Transition {
                NumberAnimation { property: "opacity"; to: 0; duration: 200; easing.type: Easing.OutCubic }
            }
            
            model: osdModel
            delegate: Rectangle {
                    width: 420
                    implicitHeight: Math.max(90, osdCol.implicitHeight + 32)
                    color: "#F0${c.base01}"
                    radius: 16
                    border.color: "#33${c.base05}"
                    border.width: 1
                    clip: true
                    
                    HoverHandler {
                        cursorShape: Qt.PointingHandCursor
                    }
                    
                    TapHandler {
                        onTapped: {
                            root.invokeDefaultAction(model.notifId)
                        }
                    }

                    Rectangle {
                        id: osdIcon
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.margins: 12
                        width: 66
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
                            
                            onStatusChanged: {
                                if (status === Image.Error) {
                                    if (model.desktopEntry && source.toString() !== "image://icon/" + model.desktopEntry) {
                                        source = "image://icon/" + model.desktopEntry;
                                    } else if (model.appIcon && source.toString() !== "image://icon/" + model.appIcon) {
                                        source = "image://icon/" + model.appIcon;
                                    } else {
                                        var generic = "image://icon/dialog-information";
                                        if (source.toString() !== generic) source = generic;
                                    }
                                }
                            }
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
                }
            }
        }
    
    ${progressOsd.widget}
    
    ${overview}
}
''
