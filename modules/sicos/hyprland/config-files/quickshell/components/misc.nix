{ config, lib, pkgs, c, fontName }:
{
  popup = ''
    PopupWindow {
            HyprlandFocusGrab {
                active: root.miscVisible
                windows: [miscPopup, root]
                onCleared: root.miscVisible = false
            }
        id: miscPopup
        anchor.window: root
        anchor.rect.x: root.width - 20
        anchor.rect.y: root.height
        anchor.rect.width: 1
        anchor.rect.height: 1
        anchor.edges: Edges.Bottom | Edges.Right
        visible: root.miscVisible || popupContentMisc.opacity > 0
        implicitWidth: 340
        implicitHeight: 460
        color: "transparent"

        property var manualPlayer: null
        property var activePlayer: {
            var players = Mpris.players.values;
            if (!players || players.length === 0) return null;
            if (manualPlayer && players.includes(manualPlayer)) return manualPlayer;

            // Priority 1: Currently playing media
            for (var i = 0; i < players.length; i++) {
                if (players[i].playbackState === 1) return players[i];
            }

            // Priority 2: Paused media with real title/artist (e.g. Spotify, YouTube, VLC)
            for (var j = 0; j < players.length; j++) {
                var p = players[j];
                if (p.playbackState === 2) {
                    var title = (p.trackTitle || (p.metadata && p.metadata["xesam:title"]) || "").toString().trim();
                    var artist = (p.trackArtist || (p.metadata && p.metadata["xesam:artist"]) || "").toString().trim();
                    var url = (p.metadata && p.metadata["xesam:url"] ? p.metadata["xesam:url"].toString() : "").toLowerCase();
                    // Ignore WhatsApp Web or generic audio when paused
                    if (url.includes("web.whatsapp.com") || title.toLowerCase() === "whatsapp") continue;
                    if (title !== "" || artist !== "") return p;
                }
            }
            return null;
        }

        property real currentTrackPosition: 0
        Timer {
            interval: 1000
            running: root.miscVisible && miscPopup.activePlayer && miscPopup.activePlayer.playbackState === 1
            repeat: true
            onTriggered: {
                if (miscPopup.activePlayer) {
                    miscPopup.currentTrackPosition = miscPopup.activePlayer.position;
                }
            }
        }
        Connections {
            target: miscPopup.activePlayer
            ignoreUnknownSignals: true
            function onPlaybackStateChanged() {
                if (miscPopup.activePlayer) miscPopup.currentTrackPosition = miscPopup.activePlayer.position;
            }
            function onPositionChanged() {
                if (miscPopup.activePlayer) miscPopup.currentTrackPosition = miscPopup.activePlayer.position;
            }
        }

        // Audio Visualization logic replaced by Native QML Effects

        Rectangle {
            id: popupContentMisc
            width: parent.width
            height: parent.height
            color: "transparent"

            // Ambient Background Mask (Body + Beak)
            Item {
                id: popupBgMask
                anchors.fill: parent
                visible: false

                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 12
                    radius: 16
                    color: "black"
                }

                Rectangle {
                    width: 20
                    height: 20
                    color: "black"
                    rotation: 45
                    y: 12 - 10 // stick out by 10px
                    // Dynamically calculate X position using the globally tracked button coordinate
                    x: {
                        if (root.miscButtonX > 0) {
                            // The popup is anchored with Edges.Right to root.width - 20.
                            // This means its right edge is exactly at root.width - 20.
                            let popupLeftEdge = (root.width - 20) - miscPopup.implicitWidth;
                            // Ensure the beak doesn't go outside the rounded corners
                            let calculatedX = root.miscButtonX - popupLeftEdge - (width / 2);
                            return Math.max(20, Math.min(miscPopup.implicitWidth - 40, calculatedX));
                        }
                        return parent.width - 98; // Fallback
                    }
                }
            }

            // Raw image for ambient bg
            Image {
                id: ambientBgImg
                anchors.fill: parent
                anchors.topMargin: 12
                source: albumImage.source
                fillMode: Image.PreserveAspectCrop
                visible: false
            }

            // Blurred ambient bg
            FastBlur {
                id: ambientBlur
                anchors.fill: parent
                source: ambientBgImg
                radius: 80
                visible: false
                cached: true
            }

            // Clipped blurred bg
            OpacityMask {
                anchors.fill: parent
                source: ambientBlur
                maskSource: popupBgMask
            }

            // Tint layer (Masked)
            Rectangle {
                id: tintRect
                anchors.fill: parent
                color: "#E6${c.base01}" // 90% solid base color to darken the blur
                visible: false
            }
            OpacityMask {
                anchors.fill: parent
                source: tintRect
                maskSource: popupBgMask
            }

            opacity: root.miscVisible ? 1 : 0
            y: root.miscVisible ? 0 : -20
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 16 + 12
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                anchors.bottomMargin: 16
                spacing: 14

                // Top Source Switcher and Close button
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32

                    Row {
                        anchors.centerIn: parent
                        spacing: 14
                        Repeater {
                            model: Mpris.players.values
                            delegate: Rectangle {
                                width: 32; height: 32
                                radius: 16
                                color: sourceMouseArea.containsMouse ? "#${c.base03}" : (miscPopup.activePlayer === modelData ? "#${c.base02}" : "transparent")
                                border.color: miscPopup.activePlayer === modelData ? "#33${c.base0D}" : "transparent"
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: {
                                        let id = (modelData.identity || "").toLowerCase();
                                        if (id.includes("spotify")) return "";
                                        if (id.includes("youtube") || id.includes("firefox") || id.includes("chrome")) return "";
                                        if (id.includes("vlc") || id.includes("mpv")) return "";
                                        return "";
                                    }
                                    color: miscPopup.activePlayer === modelData ? "#${c.base0D}" : "#${c.base05}"
                                    font.family: "${fontName}"
                                    font.pixelSize: 18
                                }
                                MouseArea {
                                    id: sourceMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: miscPopup.manualPlayer = modelData
                                }
                            }
                        }
                    }

                }

                // Album Art Vinyl and Glow
                Item {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 180
                    Layout.preferredHeight: 180

                    // Breathing Glow behind the Album
                    Glow {
                        id: albumGlow
                        anchors.fill: maskRect
                        source: maskRect
                        color: "#${c.base0D}" // Cyan Glow
                        radius: 10
                        spread: 0.1
                        samples: 41
                        transparentBorder: true
                    }

                    SequentialAnimation {
                        running: miscPopup.activePlayer && miscPopup.activePlayer.playbackState === 1 // Only animate when playing
                        loops: Animation.Infinite
                        NumberAnimation { target: albumGlow; property: "radius"; from: 10; to: 40; duration: 1800; easing.type: Easing.InOutQuad }
                        NumberAnimation { target: albumGlow; property: "radius"; from: 40; to: 10; duration: 1800; easing.type: Easing.InOutQuad }
                    }

                    Rectangle {
                        id: maskRect
                        width: 140
                        height: 140
                        radius: 70
                        anchors.centerIn: parent
                        visible: false
                    }

                    Image {
                        id: albumImage
                        width: 140
                        height: 140
                        anchors.centerIn: parent
                        source: {
                            if (!miscPopup.activePlayer) return "";
                            let art = "";
                            if (miscPopup.activePlayer.trackArtUrl) art = miscPopup.activePlayer.trackArtUrl.toString();
                            else if (miscPopup.activePlayer.metadata && miscPopup.activePlayer.metadata["mpris:artUrl"]) art = miscPopup.activePlayer.metadata["mpris:artUrl"].toString();

                            if (art !== "") return art;

                            if (miscPopup.activePlayer.metadata && miscPopup.activePlayer.metadata["xesam:url"]) {
                                let url = miscPopup.activePlayer.metadata["xesam:url"].toString();
                                if (url.includes("youtube.com") || url.includes("youtu.be")) {
                                    let match = url.match(/(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})/i);
                                    if (match && match[1]) {
                                        return "https://img.youtube.com/vi/" + match[1] + "/hqdefault.jpg";
                                    }
                                }
                            }
                            return "";
                        }
                        fillMode: Image.PreserveAspectCrop
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: maskRect
                        }

                        // Fallback icon if no art
                        Rectangle {
                            anchors.fill: parent
                            color: "#${c.base02}"
                            visible: albumImage.status !== Image.Ready
                            radius: 70
                            Text {
                                anchors.centerIn: parent
                                text: ""
                                color: "#${c.base04}"
                                font.family: "${fontName}"
                                font.pixelSize: 44
                            }
                        }
                    }
                }

                // Track Info
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: miscPopup.activePlayer && miscPopup.activePlayer.metadata && miscPopup.activePlayer.metadata["xesam:artist"] ? miscPopup.activePlayer.metadata["xesam:artist"].toString() : "Unknown Artist"
                        color: "#${c.base04}"
                        font.family: "${fontName}"
                        font.pixelSize: 15
                        elide: Text.ElideRight
                    }

                    // Real-ish EQ based on Pipewire peak
                    PwNodePeakMonitor {
                        id: outputPeakMonitor
                        node: Pipewire.defaultAudioSink
                        enabled: root.miscVisible && miscPopup.activePlayer && miscPopup.activePlayer.playbackState === 1
                    }

                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredHeight: 14
                        spacing: 3
                        Repeater {
                            model: 8
                            delegate: Rectangle {
                                width: 3
                                radius: 1
                                color: "#${c.base0D}"
                                anchors.verticalCenter: parent.verticalCenter

                                height: {
                                    if (!miscPopup.activePlayer || miscPopup.activePlayer.playbackState !== 1) return 3;

                                    let p = outputPeakMonitor.peak || 0;
                                    let factor = 1.0;
                                    let factors = [0.7, 1.2, 1.1, 0.9, 1.3, 0.8, 1.1, 0.8];
                                    if (index >= 0 && index < factors.length) factor = factors[index];

                                    let targetHeight = 3 + (p * 14 * factor);
                                    return Math.min(16, targetHeight);
                                }

                                Behavior on height {
                                    NumberAnimation { duration: 75; easing.type: Easing.OutQuad }
                                }
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: miscPopup.activePlayer && miscPopup.activePlayer.metadata && miscPopup.activePlayer.metadata["xesam:title"] ? miscPopup.activePlayer.metadata["xesam:title"].toString() : "Unknown Track"
                        color: "#${c.base05}"
                        font.family: "${fontName}"
                        font.pixelSize: 16
                        font.bold: true
                        elide: Text.ElideRight
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                    }
                }

                // Progress Bar
                RowLayout {
                    Layout.fillWidth: true
                    visible: {
                        if (!miscPopup.activePlayer || !miscPopup.activePlayer.metadata) return false;
                        return (miscPopup.activePlayer.metadata["mpris:length"] > 0);
                    }
                    spacing: 12

                    Rectangle {
                        Layout.fillWidth: true
                        height: 6
                        radius: 3
                        color: "#33${c.base05}"
                        clip: true

                        Rectangle {
                            height: parent.height
                            radius: 3
                            color: "#${c.base0D}"
                            width: {
                                if (!miscPopup.activePlayer || !miscPopup.activePlayer.length) return 0;
                                let ratio = miscPopup.currentTrackPosition / miscPopup.activePlayer.length;
                                return Math.max(0, Math.min(1, ratio)) * parent.width;
                            }
                            Behavior on width { NumberAnimation { duration: 1000; easing.type: Easing.Linear } }
                        }
                    }

                    Text {
                        text: {
                            if (!miscPopup.activePlayer || !miscPopup.activePlayer.metadata) return "";
                            let len = miscPopup.activePlayer.metadata["mpris:length"] || 0;
                            if (len <= 0) return "";
                            let s = Math.floor(len / 1000000);
                            return Math.floor(s / 60) + ":" + (s % 60).toString().padStart(2, '0');
                        }
                        color: "#${c.base04}"
                        font.family: "${fontName}"
                        font.pixelSize: 15
                    }
                }

                // Controls
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 20

                    Rectangle {
                        width: 32; height: 32; radius: 16
                        color: prevBtnArea.containsMouse ? "#${c.base03}" : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "󰙣"
                            color: "#${c.base05}"
                            font.pixelSize: 18
                            font.family: "${fontName}"
                        }
                        MouseArea {
                            id: prevBtnArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: if (miscPopup.activePlayer) miscPopup.activePlayer.previous()
                        }
                    }

                    Rectangle {
                        width: 44; height: 44; radius: 22
                        color: "#${c.base0D}"
                        Text {
                            anchors.centerIn: parent
                            text: miscPopup.activePlayer && miscPopup.activePlayer.playbackState === 1 ? "󰏥" : ""
                            color: "#${c.base00}"
                            font.pixelSize: 24
                            font.family: "${fontName}"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: if (miscPopup.activePlayer) miscPopup.activePlayer.togglePlaying()
                        }
                    }

                    Rectangle {
                        width: 32; height: 32; radius: 16
                        color: nextBtnArea.containsMouse ? "#${c.base03}" : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "󰙡"
                            color: "#${c.base05}"
                            font.pixelSize: 18
                            font.family: "${fontName}"
                        }
                        MouseArea {
                            id: nextBtnArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: if (miscPopup.activePlayer) miscPopup.activePlayer.next()
                        }
                    }
                }
            }

            // Hover tracker using HoverHandler (Qt 6) - does NOT interfere with child buttons
            // Unlike MouseArea, HoverHandler doesn't steal hover from child MouseAreas
            HoverHandler {
                id: popupHoverHandler
                onHoveredChanged: {
                    if (hovered) {
                        root.miscHovering = true;
                        popupCloseTimer.stop();
                    } else {
                        root.miscHovering = false;
                        popupCloseTimer.start();
                    }
                }
            }

            // Wheel interceptor (separate from hover tracking)
            // acceptedButtons: Qt.NoButton ensures clicks pass through to child buttons
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                onWheel: {}
            }

            Timer {
                id: popupCloseTimer
                interval: 400
                repeat: false
                onTriggered: if (!root.miscHovering) root.miscVisible = false
            }
        }
    }
  '';

  widget = ''
    // Miscellaneous Island
    Rectangle {
        id: miscIslandMain
        color: hoverWidget.hovered ? "#${c.base03}" : (root.miscVisible ? "#E6${c.base02}" : "#CC${c.base01}")
        radius: 12
        Layout.preferredHeight: 32
        Layout.preferredWidth: miscLayout.implicitWidth + 20

        property bool capsLockOn: false
        property bool numLockOn: false
        property bool firstLockCheck: true

        Timer {
            interval: 500
            running: true
            repeat: true
            onTriggered: {
                locksProc.running = true;
            }
        }

        Process {
            id: locksProc
            command: ["sh", "-c", "hyprctl devices -j | awk -F'[:,]' '/\"capsLock\"/{c=$2} /\"numLock\"/{n=$2} /\"main\": true/{print \"CAPS:\"c\" NUM:\"n}' | tr -d ' \\t\\r\\n'"]
            running: true

            stdout: StdioCollector {
                onStreamFinished: {
                    if (text === "") return;
                    var str = text;
                    var newCaps = str.indexOf("CAPS:true") !== -1;
                    var newNum = str.indexOf("NUM:true") !== -1;

                    if (!miscIslandMain.firstLockCheck) {
                        if (newCaps !== miscIslandMain.capsLockOn) {
                            mainScope.progressOsdType = "Caps Lock";
                            mainScope.progressOsdValue = newCaps ? 1 : 0;
                            mainScope.progressOsdVisible = true;
                            var timerCode = 'import QtQuick; Timer { interval: 2000; running: true; repeat: false; onTriggered: { mainScope.progressOsdVisible = false; this.destroy(); } }';
                            Qt.createQmlObject(timerCode, root, "capsTimer" + Math.random().toString().replace(".", ""));
                        }
                        if (newNum !== miscIslandMain.numLockOn) {
                            mainScope.progressOsdType = "Num Lock";
                            mainScope.progressOsdValue = newNum ? 1 : 0;
                            mainScope.progressOsdVisible = true;
                            var timerCodeNum = 'import QtQuick; Timer { interval: 2000; running: true; repeat: false; onTriggered: { mainScope.progressOsdVisible = false; this.destroy(); } }';
                            Qt.createQmlObject(timerCodeNum, root, "numTimer" + Math.random().toString().replace(".", ""));
                        }
                    }

                    miscIslandMain.capsLockOn = newCaps;
                    miscIslandMain.numLockOn = newNum;
                    miscIslandMain.firstLockCheck = false;
                }
            }
        }

        // Track Pipewire nodes so their properties and streams update live in Quickshell
        PwObjectTracker {
            objects: (Pipewire.ready && Pipewire.nodes && Pipewire.nodes.values) ? Pipewire.nodes.values : []
        }

        // Pipewire Privacy Tracking Properties
        property int _pwPrivacyTrigger: 0
        Connections {
            target: Pipewire.nodes
            function onValuesChanged() { miscIslandMain._pwPrivacyTrigger += 1; }
        }

        // Microphone in use detection (filtering out Quickshell internal peak monitor and cava)
        property bool micInUse: {
            var trigger = miscIslandMain._pwPrivacyTrigger;
            if (!Pipewire.ready || !Pipewire.nodes || !Pipewire.nodes.values) return false;
            var nodes = Pipewire.nodes.values;
            for (var i = 0; i < nodes.length; i++) {
                var node = nodes[i];
                if (!node) continue;
                if (node.isStream && node.isSink === false) {
                    var name = (node.name || "").toLowerCase();
                    var mediaName = (node.properties && node.properties["media.name"] || "").toLowerCase();
                    var appName = (node.properties && node.properties["application.name"] || "").toLowerCase();
                    var category = (node.properties && node.properties["media.category"] || "").toLowerCase();
                    var combined = name + " " + mediaName + " " + appName + " " + category;
                    // Ignore Quickshell's own peak monitor, cava, system monitors
                    if (/quickshell|peak detect|cava|monitor|system/.test(combined)) continue;
                    return true;
                }
            }
            return false;
        }

        property bool rawCameraInUse: false

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: cameraCheckProc.running = true
        }

        Process {
            id: cameraCheckProc
            command: ["python3", "-c", "import glob, os\ndef chk():\n    for f in glob.glob('/proc/[0-9]*/fd/*'):\n        try:\n            t = os.readlink(f)\n            if t.startswith('/dev/video'):\n                pid = f.split('/')[2]\n                with open(f'/proc/{pid}/cmdline', 'rb') as c:\n                    cmd = c.read()\n                    if b'wireplumber' not in cmd and b'pipewire' not in cmd:\n                        return True\n        except (OSError, UnicodeDecodeError):\n            pass\n    return False\nprint('CAM:1' if chk() else 'CAM:0')"]
            running: true
            stdout: StdioCollector {
                onStreamFinished: {
                    if (text.indexOf("CAM:1") !== -1) {
                        miscIslandMain.rawCameraInUse = true;
                    } else if (text.indexOf("CAM:0") !== -1) {
                        miscIslandMain.rawCameraInUse = false;
                    }
                }
            }
        }

        // Camera in use detection (combining direct V4L2 device usage and Pipewire streams)
        property bool cameraInUse: {
            if (rawCameraInUse) return true;
            var trigger = miscIslandMain._pwPrivacyTrigger;
            if (!Pipewire.ready || !Pipewire.nodes || !Pipewire.nodes.values) return false;
            var nodes = Pipewire.nodes.values;
            for (var i = 0; i < nodes.length; i++) {
                var node = nodes[i];
                if (!node) continue;
                // Check 1: Active camera input stream (WebRTC, OBS, Portals)
                if (node.isStream && node.properties && (node.properties["media.class"] === "Stream/Input/Video" || node.properties["media.type"] === "Video")) {
                    return true;
                }
                // Check 2: Physical/V4L2 camera source node actively running/streaming
                if (node.properties && (node.properties["media.class"] === "Video/Source" || node.properties["media.role"] === "Camera")) {
                    if (node.state === "running" || node.state === "active" || node.state === 3) {
                        return true;
                    }
                }
            }
            return false;
        }

        // Screencast / Screen sharing in use detection
        property bool screenShareInUse: {
            var trigger = miscIslandMain._pwPrivacyTrigger;
            if (!Pipewire.ready || !Pipewire.nodes || !Pipewire.nodes.values) return false;
            var nodes = Pipewire.nodes.values;
            for (var i = 0; i < nodes.length; i++) {
                var node = nodes[i];
                if (!node) continue;
                var mediaClass = (node.properties && node.properties["media.class"]) || "";
                var mediaName = (node.properties && node.properties["media.name"] || "").toLowerCase();
                var nodeName = (node.name || "").toLowerCase();
                var appName = (node.properties && node.properties["application.name"] || "").toLowerCase();
                var combined = mediaClass + " " + mediaName + " " + nodeName + " " + appName;

                // Case 1: xdg-desktop-portal-hyprland screencast node (Stream/Output/Video or Video/Source with xdph)
                if (combined.indexOf("xdph") !== -1 || combined.indexOf("screencast") !== -1 || combined.indexOf("screen-cast") !== -1) {
                    if (node.state === "running" || node.state === "active" || node.state === 3 || (node.properties && node.properties["stream.is-live"] === "true")) {
                        return true;
                    }
                }

                // Case 2: General Stream/Output/Video portals/OBS
                if (mediaClass === "Stream/Output/Video") {
                    if (/xdg-desktop-portal|xdpw|screencast|screen|obs|hyprland/.test(combined)) {
                        return true;
                    }
                }
            }
            return false;
        }

        property var activePlayer: {
            var players = Mpris.players.values;
            if (!players || players.length === 0) return null;

            // Priority 1: Currently playing media
            for (var i = 0; i < players.length; i++) {
                if (players[i].playbackState === 1) { // Playing
                    return players[i];
                }
            }

            // Priority 2: Paused media with real title/artist (e.g. Spotify, YouTube, VLC)
            for (var j = 0; j < players.length; j++) {
                var p = players[j];
                if (p.playbackState === 2) { // Paused
                    var title = (p.trackTitle || (p.metadata && p.metadata["xesam:title"]) || "").toString().trim();
                    var artist = (p.trackArtist || (p.metadata && p.metadata["xesam:artist"]) || "").toString().trim();
                    var url = (p.metadata && p.metadata["xesam:url"] ? p.metadata["xesam:url"].toString() : "").toLowerCase();
                    // Ignore WhatsApp Web or generic audio when paused
                    if (url.includes("web.whatsapp.com") || title.toLowerCase() === "whatsapp") continue;
                    if (title !== "" || artist !== "") return p;
                }
            }
            return null;
        }

        RowLayout {
            id: miscLayout
            anchors.centerIn: parent
            spacing: 12

            // Caps Lock Indicator
            Rectangle {
                width: 24; height: 24
                radius: 12
                color: "#${c.base08}"
                visible: miscIslandMain.capsLockOn

                Text {
                    anchors.centerIn: parent
                    text: "󰘲"
                    color: "#${c.base00}"
                    font.family: "${fontName}"
                    font.pixelSize: 16
                }
            }

            // Num Lock Indicator
            Rectangle {
                width: 24; height: 24
                radius: 12
                color: "#${c.base0A}"
                visible: miscIslandMain.numLockOn

                Text {
                    anchors.centerIn: parent
                    text: "󰎦"
                    color: "#${c.base00}"
                    font.family: "${fontName}"
                    font.pixelSize: 16
                }
            }

            // Microphone In Use Indicator
            Rectangle {
                property bool isMuted: Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio && Pipewire.defaultAudioSource.audio.muted
                width: 24; height: 24
                radius: 12
                color: isMuted ? "#${c.base03}" : "#${c.base08}"
                visible: miscIslandMain.micInUse

                Text {
                    anchors.centerIn: parent
                    text: parent.isMuted ? "󰍭" : "󰍬"
                    color: parent.isMuted ? "#${c.base08}" : "#${c.base00}"
                    font.family: "${fontName}"
                    font.pixelSize: 15
                }

                // Click to mute/unmute default audio source
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio) {
                            Pipewire.defaultAudioSource.audio.muted = !Pipewire.defaultAudioSource.audio.muted;
                        }
                    }
                }
            }

            // Camera In Use Indicator
            Rectangle {
                width: 24; height: 24
                radius: 12
                color: "#${c.base09}"
                visible: miscIslandMain.cameraInUse

                Text {
                    anchors.centerIn: parent
                    text: "󰄀"
                    color: "#${c.base00}"
                    font.family: "${fontName}"
                    font.pixelSize: 15
                }
            }

            // Screen Sharing In Use Indicator
            Rectangle {
                width: 24; height: 24
                radius: 12
                color: "#${c.base0C}"
                visible: miscIslandMain.screenShareInUse

                Text {
                    anchors.centerIn: parent
                    text: "󰕩"
                    color: "#${c.base00}"
                    font.family: "${fontName}"
                    font.pixelSize: 15
                }
            }

            // MPRIS Media Icon
            Rectangle {
                id: musicIconRect
                width: 24; height: 24
                radius: 12
                color: (miscIslandMain.activePlayer && miscIslandMain.activePlayer.playbackState === 1) ? "#${c.base0D}" : "#${c.base02}"
                visible: miscIslandMain.activePlayer !== null

                Text {
                    anchors.centerIn: parent
                    text: "" // Music icon
                    color: (miscIslandMain.activePlayer && miscIslandMain.activePlayer.playbackState === 1) ? "#${c.base00}" : "#${c.base05}"
                    font.family: "${fontName}"
                    font.pixelSize: 16
                }

                // Click to toggle play/pause directly
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (miscIslandMain.activePlayer) {
                            miscIslandMain.activePlayer.togglePlaying();
                        }
                    }
                }
            }

            // Power Profile Indicator
            Rectangle {
                width: 24; height: 24
                radius: 12
                color: PowerProfiles.profile === 0 ? "#${c.base0B}" : (PowerProfiles.profile === 1 ? "#${c.base0D}" : "#${c.base08}")

                Text {
                    anchors.centerIn: parent
                    text: PowerProfiles.profile === 0 ? "" : (PowerProfiles.profile === 1 ? "" : "")
                    color: "#${c.base00}"
                    font.family: "${fontName}"
                    font.pixelSize: PowerProfiles.profile === 2 ? 13 : 18
                }

                // Allow direct clicking for power profiles to cycle through modes
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        let nextCmd = "balanced-mode";
                        if (PowerProfiles.profile === 0) {
                            nextCmd = "balanced-mode";
                        } else if (PowerProfiles.profile === 1) {
                            nextCmd = "powerprofilesctl set performance";
                        } else {
                            nextCmd = "power-saver-mode";
                        }
                        indicatorProc.exec(["sh", "-c", nextCmd])
                    }
                }
                Process {
                    id: indicatorProc
                }
            }
        }

        // Hover tracker using HoverHandler (Qt 6) - does NOT interfere with child buttons
        // Unlike MouseArea, HoverHandler doesn't steal hover from child MouseAreas
        HoverHandler {
            id: hoverWidget
            onHoveredChanged: {
                if (hovered) {
                    root.miscHovering = true;
                    widgetCloseTimer.stop();
                    if (miscIslandMain.activePlayer) miscOpenTimer.start();
                } else {
                    root.miscHovering = false;
                    miscOpenTimer.stop();
                    widgetCloseTimer.start();
                }
            }
        }

        Timer {
            id: miscOpenTimer
            interval: 200
            repeat: false
            onTriggered: {
                if (miscIslandMain.activePlayer) {
                    root.miscButtonX = musicIconRect.mapToItem(null, musicIconRect.width / 2, 0).x;
                    root.miscVisible = true;
                }
            }
        }

        Timer {
            id: widgetCloseTimer
            interval: 400
            repeat: false
            onTriggered: if (!root.miscHovering) root.miscVisible = false
        }
    }
  '';
}
