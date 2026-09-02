{ config, lib, pkgs, c, fontName }:
{
  popup = ''
    PopupWindow {
        id: miscPopup
        anchor.window: root
        anchor.rect.x: root.width - 20
        anchor.rect.y: root.height
        anchor.rect.width: 1
        anchor.rect.height: 1
        anchor.edges: Edges.Bottom | Edges.Right
        visible: root.miscVisible || popupContentMisc.opacity > 0
        implicitWidth: 380
        implicitHeight: 512
        color: "transparent"

        property var manualPlayer: null
        property var activePlayer: {
            var players = Mpris.players.values;
            if (!players || players.length === 0) return null;
            if (manualPlayer && players.includes(manualPlayer)) return manualPlayer;
            for (var i = 0; i < players.length; i++) {
                if (players[i].playbackState === 1) return players[i];
            }
            return players[0];
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
            
            // Intercept all clicks to prevent them from passing through to Hyprland windows below
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onWheel: {} // intercept scroll events too
            }
            
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
                anchors.topMargin: 20 + 12
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                anchors.bottomMargin: 20
                spacing: 16

                // Top Source Switcher and Close button
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    
                    Row {
                        anchors.centerIn: parent
                        spacing: 16
                        Repeater {
                            model: Mpris.players.values
                            delegate: Rectangle {
                                width: 36; height: 36
                                radius: 18
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

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "✕"
                        color: closeAreaMisc.containsMouse ? "#${c.base05}" : "#${c.base04}"
                        font.family: "${fontName}"
                        font.pixelSize: 18
                        MouseArea {
                            id: closeAreaMisc
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.miscVisible = false
                        }
                    }
                }

                // Album Art Vinyl and Glow
                Item {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 200
                    Layout.preferredHeight: 200
                    
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
                        width: 160
                        height: 160
                        radius: 80
                        anchors.centerIn: parent
                        visible: false
                    }

                    Image {
                        id: albumImage
                        width: 160
                        height: 160
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
                            radius: 80
                            Text {
                                anchors.centerIn: parent
                                text: ""
                                color: "#${c.base04}"
                                font.family: "${fontName}"
                                font.pixelSize: 48
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
                        font.pixelSize: 14
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
                        Layout.preferredHeight: 16
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
                        font.pixelSize: 12
                    }
                }

                // Controls
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 24

                    Rectangle {
                        width: 40; height: 40; radius: 20
                        color: prevBtnArea.containsMouse ? "#${c.base03}" : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "󰙣"
                            color: "#${c.base05}"
                            font.pixelSize: 20
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
                        width: 50; height: 50; radius: 25
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
                        width: 40; height: 40; radius: 20
                        color: nextBtnArea.containsMouse ? "#${c.base03}" : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "󰙡"
                            color: "#${c.base05}"
                            font.pixelSize: 20
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
        }
    }
  '';

  widget = ''
    // Miscellaneous Island
    Rectangle {
        id: miscIslandMain
        color: miscIslandArea.containsMouse ? "#${c.base03}" : (root.miscVisible ? "#${c.base02}" : "#${c.base02}")
        radius: 14
        Layout.preferredHeight: 28
        Layout.preferredWidth: miscLayout.implicitWidth + 24
        
        property var activePlayer: {
            var players = Mpris.players.values;
            if (!players || players.length === 0) return null;
            for (var i = 0; i < players.length; i++) {
                if (players[i].playbackState === 1) { // Playing
                    return players[i];
                }
            }
            return players[0];
        }

        MouseArea {
            id: miscIslandArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                if (parent.activePlayer) {
                    // Calculate exactly when clicked! Layout is 100% finished and accurate.
                    root.miscButtonX = musicIconRect.mapToItem(null, musicIconRect.width / 2, 0).x;
                    root.miscVisible = !root.miscVisible;
                }
            }
        }

        RowLayout {
            id: miscLayout
            anchors.centerIn: parent
            spacing: 12

            // MPRIS Media Icon
            Rectangle {
                id: musicIconRect
                width: 20; height: 20
                radius: 10
                color: "transparent"
                visible: parent.parent.activePlayer !== null
                
                Text {
                    anchors.centerIn: parent
                    text: "" // Music icon
                    color: parent.parent.parent.activePlayer && parent.parent.parent.activePlayer.playbackState === 1 ? "#${c.base0D}" : "#${c.base05}"
                    font.family: "${fontName}"
                    font.pixelSize: 14
                }
            }

            // Power Profile Indicator
            Rectangle {
                color: "transparent"
                Layout.preferredHeight: 20
                Layout.preferredWidth: 20
                
                Text {
                    anchors.centerIn: parent
                    text: PowerProfiles.profile === 0 ? "" : (PowerProfiles.profile === 1 ? "" : "")
                    color: PowerProfiles.profile === 0 ? "#${c.base0B}" : (PowerProfiles.profile === 1 ? "#${c.base0D}" : "#${c.base08}")
                    font.family: "${fontName}"
                    font.pixelSize: 14
                }
                
                // Allow direct clicking for power profiles even if misc area is large
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
    }
  '';
}
