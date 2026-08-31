{ config, lib, pkgs, c, fontName }:
{
  popup = ''
    PopupWindow {
        id: ccPopup
        anchor.window: root
        anchor.rect.x: root.width - 10
        anchor.rect.y: root.height
        anchor.rect.width: 1
        anchor.rect.height: 1
        anchor.edges: Edges.Bottom | Edges.Right
        visible: root.controlcenterVisible || popupContentCC.opacity > 0
        implicitWidth: 480
        implicitHeight: 580
        color: "transparent"

        Rectangle {
            id: popupContentCC
            width: parent.width
            height: parent.height
            color: "transparent"
            // Global state properties
            property bool appsExpanded: false
            property bool brightnessExpanded: false
            property bool isDraggingBrightness: false
            property var brightnessDevices: []
            property int mainBrightness: 0
            
            function setDeviceBrightness(name, p) {
                brightnessSetProc.command = ["brightnessctl", "-d", name, "set", Math.round(p) + "%", "-q"];
                brightnessSetProc.running = true;
            }
            
            // Intercept all clicks
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onWheel: {}
            }
            
            // Ambient Background Mask (Body + Beak)
            Item {
                id: popupBgMaskCC
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
                    x: {
                        if (root.controlcenterButtonX > 0) {
                            let popupLeftEdge = (root.width - 10) - ccPopup.implicitWidth;
                            let calculatedX = root.controlcenterButtonX - popupLeftEdge - (width / 2);
                            return Math.max(20, Math.min(ccPopup.implicitWidth - 40, calculatedX));
                        }
                        return parent.width - 40; // Fallback
                    }
                }
            }

            Rectangle {
                id: ccBg
                anchors.fill: parent
                color: "#F0${c.base01}" // 94% opacity background
                visible: false
            }

            OpacityMask {
                anchors.fill: parent
                source: ccBg
                maskSource: popupBgMaskCC
            }

            QtObject {
                id: ccData
                property bool profileExpanded: false
                property string user: ""
                property string uptime: ""
                property string host: ""
                property string os: ""
                property string home: ""
            }

            Process {
                id: ccInfoProc
                property string script: "uptime_val=$(awk '{d=int($1/86400); h=int(($1%86400)/3600); m=int(($1%3600)/60); if(d>0) printf \"%dd %dh %dm\\n\", d, h, m; else if(h>0) printf \"%dh %dm\\n\", h, m; else printf \"%dm\\n\", m}' /proc/uptime); user_val=$(whoami); host_val=$(hostname); os_val=$(awk -F'=' '/^PRETTY_NAME/ {gsub(/\"/, \"\", $2); print $2}' /etc/os-release); echo \"{\\\"uptime\\\": \\\"$uptime_val\\\", \\\"user\\\": \\\"$user_val\\\", \\\"host\\\": \\\"$host_val\\\", \\\"os\\\": \\\"$os_val\\\", \\\"home\\\": \\\"$HOME\\\"}\""
                command: ["sh", "-c", script]
                running: false
                stdout: StdioCollector {
                    onStreamFinished: {
                        if (text !== "") {
                            try {
                                let data = JSON.parse(text.trim());
                                ccData.user = data.user;
                                ccData.uptime = data.uptime;
                                ccData.host = data.host;
                                ccData.os = data.os;
                                ccData.home = data.home;
                            } catch (e) {
                                console.log("Error parsing ccInfo JSON: " + e);
                            }
                        }
                    }
                }
            }
            
            Timer {
                interval: 60000
                running: root.controlcenterVisible
                repeat: true
                onTriggered: ccInfoProc.running = true
            }
            
            Connections {
                target: root
                function onControlcenterVisibleChanged() {
                    if (root.controlcenterVisible) {
                        ccInfoProc.running = true;
                    }
                }
            }

            Component.onCompleted: ccInfoProc.running = true
            
            opacity: root.controlcenterVisible ? 1 : 0
            y: root.controlcenterVisible ? 0 : -20
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 32
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                anchors.bottomMargin: 20
                spacing: 16

                // Top Header: User Profile (Expandable)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        
                        // Avatar and Info area (Clickable)
                        Rectangle {
                            Layout.preferredHeight: 48
                            Layout.preferredWidth: profileContent.implicitWidth + 16
                            color: profileMouseArea.containsMouse ? "#1A${c.base05}" : "transparent"
                            radius: 12
                            
                            RowLayout {
                                id: profileContent
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 4
                                spacing: 12
                                
                                Item {
                                    width: 48; height: 48
                                    
                                    Rectangle {
                                        id: avatarMask
                                        width: 48; height: 48; radius: 24
                                        color: "black"
                                        visible: false
                                    }
                                    
                                    Image {
                                        id: avatarImage
                                        width: 48; height: 48
                                        source: ccData.home !== "" ? "file://" + ccData.home + "/.config/hypr/user.jpg" : ""
                                        fillMode: Image.PreserveAspectCrop
                                        visible: false
                                    }
                                    
                                    OpacityMask {
                                        width: 48; height: 48
                                        source: avatarImage
                                        maskSource: avatarMask
                                        visible: avatarImage.status === Image.Ready
                                    }
                                    
                                    Rectangle {
                                        width: 48; height: 48; radius: 24
                                        color: "#${c.base02}"
                                        visible: avatarImage.status !== Image.Ready
                                        Text {
                                            anchors.centerIn: parent
                                            text: ""
                                            color: "#${c.base05}"
                                            font.family: "${fontName}"
                                            font.pixelSize: 24
                                        }
                                    }
                                }
                                ColumnLayout {
                                    spacing: 2
                                    Text {
                                        text: ccData.user !== "" ? ccData.user : "User"
                                        color: "#${c.base05}"
                                        font.family: "${fontName}"
                                        font.pixelSize: 18
                                        font.bold: true
                                    }
                                    Text {
                                        text: ccData.uptime !== "" ? "up " + ccData.uptime : "up 0 minutes"
                                        color: "#${c.base04}"
                                        font.family: "${fontName}"
                                        font.pixelSize: 13
                                    }
                                }
                                // Expand Indicator
                                Text {
                                    text: ccData.profileExpanded ? "" : ""
                                    color: "#${c.base04}"
                                    font.family: "${fontName}"
                                    font.pixelSize: 14
                                }
                            }
                            
                            MouseArea {
                                id: profileMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: ccData.profileExpanded = !ccData.profileExpanded
                            }
                        }

                        // Spacer to push the power button to the right
                        Item {
                            Layout.fillWidth: true
                        }

                        // Action Buttons (Power)
                        Rectangle {
                            width: 36; height: 36; radius: 18
                            color: btnArea.containsMouse ? "#${c.base03}" : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: ""
                                color: "#${c.base05}"
                                font.family: "${fontName}"
                                font.pixelSize: 16
                            }
                            MouseArea {
                                id: btnArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    cmdRunner.exec(["uwsm", "app", "--", "wlogout", "--protocol", "layer-shell", "-b", "6"])
                                    root.controlcenterVisible = false;
                                }
                            }
                        }
                    }

                    // Expanded Content (Host & Distro)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: ccData.profileExpanded ? expandedContentCol.implicitHeight + 16 : 0
                        opacity: ccData.profileExpanded ? 1 : 0
                        visible: opacity > 0 // This avoids layout calculations when closed
                        clip: true
                        color: "#1A${c.base03}"
                        radius: 8
                        
                        Behavior on Layout.preferredHeight { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        
                        ColumnLayout {
                            id: expandedContentCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 8
                            spacing: 4
                            
                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: ""; color: "#${c.base0D}"; font.family: "${fontName}"; font.pixelSize: 14; Layout.preferredWidth: 24 }
                                Text { text: ccData.host !== "" ? ccData.host : "Hostname"; color: "#${c.base05}"; font.family: "${fontName}"; font.pixelSize: 13; font.bold: true; Layout.fillWidth: true }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: ""; color: "#${c.base0D}"; font.family: "${fontName}"; font.pixelSize: 14; Layout.preferredWidth: 24 }
                                Text { text: ccData.os !== "" ? ccData.os : "Linux"; color: "#${c.base04}"; font.family: "${fontName}"; font.pixelSize: 13; Layout.fillWidth: true }
                            }
                        }
                    }
                }
                
                // Sliders (Volume, Brightness)
                ColumnLayout {
                    id: slidersColumn
                    property var currentAudioStreams: {
                        var arr = [];
                        var nodes = Pipewire.nodes.values;
                        if (nodes) {
                            for (var i = 0; i < nodes.length; i++) {
                                var n = nodes[i];
                                if (n && n.audio && n.isSink && n.isStream) {
                                    arr.push(n);
                                }
                            }
                        }
                        return arr;
                    }
                    
                    Process {
                        id: brightnessPollProc
                        command: ["brightnessctl", "-l", "-m"]
                        running: true
                        stdout: StdioCollector {
                            onStreamFinished: {
                                var lines = text.trim().split("\n");
                                var arr = [];
                                var mainP = 0;
                                for (var i = 0; i < lines.length; i++) {
                                    var parts = lines[i].split(",");
                                    if (parts.length >= 5) {
                                        var name = parts[0];
                                        var cls = parts[1];
                                        var p = parseInt(parts[3].replace("%", ""));
                                        if (cls === "backlight") {
                                            mainP = p;
                                            arr.push({ name: name, class: cls, percent: p });
                                        } else if (name.toLowerCase().indexOf("kbd") !== -1 || name.toLowerCase().indexOf("keyboard") !== -1) {
                                            // Ensure we only add ONE keyboard backlight if multiple exist
                                            var alreadyHasKbd = false;
                                            for (var j = 0; j < arr.length; j++) {
                                                if (arr[j].name.toLowerCase().indexOf("kbd") !== -1 || arr[j].name.toLowerCase().indexOf("keyboard") !== -1) {
                                                    alreadyHasKbd = true;
                                                    break;
                                                }
                                            }
                                            if (!alreadyHasKbd) {
                                                arr.push({ name: name, class: cls, percent: p });
                                            }
                                        }
                                    }
                                }
                                if (!popupContentCC.isDraggingBrightness) {
                                    popupContentCC.brightnessDevices = arr;
                                    popupContentCC.mainBrightness = mainP;
                                }
                            }
                        }
                    }
                    
                    Timer {
                        interval: 2000
                        running: root.controlcenterVisible && !popupContentCC.isDraggingBrightness
                        repeat: true
                        onTriggered: brightnessPollProc.running = true
                    }
                    
                    Process {
                        id: brightnessSetProc
                    }
                    
                    Layout.fillWidth: true
                    spacing: 16
                    
                    // Volume Section
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        
                        PwObjectTracker {
                            objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
                        }
                        
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12
                            
                            Text {
                                text: (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio.muted) ? "" : ""
                                color: (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio.muted) ? "#${c.base08}" : "#${c.base0D}"
                                font.family: "${fontName}"
                                font.pixelSize: 18
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: if (Pipewire.defaultAudioSink) Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted
                                }
                            }
                            
                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 24
                                property real percent: Pipewire.defaultAudioSink ? Math.max(0, Math.min(1.0, Pipewire.defaultAudioSink.audio.volume / 2.0)) : 0
                                
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width
                                    height: 8
                                    radius: 4
                                    color: "#33${c.base05}"
                                    
                                    Rectangle {
                                        width: parent.width * parent.parent.percent
                                        height: parent.height
                                        radius: 4
                                        color: (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio.volume > 1.005) ? "#${c.base08}" : "#${c.base0D}"
                                    }
                                    
                                    Rectangle {
                                        x: parent.width * 0.5
                                        width: 2
                                        height: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: "#${c.base00}"
                                    }
                                }
                                
                                // Thumb (Pelotita)
                                Rectangle {
                                    width: 16
                                    height: 16
                                    radius: 8
                                    color: "#${c.base05}"
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: Math.max(0, Math.min(parent.width - width, (parent.width * parent.percent) - (width / 2)))
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    function updateVolume(mouse) {
                                        if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
                                            let p = Math.max(0, Math.min(1, mouse.x / width));
                                            Pipewire.defaultAudioSink.audio.volume = p * 2.0;
                                            if (p > 0) Pipewire.defaultAudioSink.audio.muted = false;
                                        }
                                    }
                                    onPressed: (mouse) => updateVolume(mouse)
                                    onPositionChanged: (mouse) => {
                                        if (pressed) updateVolume(mouse);
                                    }
                                }
                            }
                            
                            Text {
                                text: (Pipewire.defaultAudioSink ? Math.round(Pipewire.defaultAudioSink.audio.volume * 100) : 0) + "%"
                                color: "#${c.base05}"
                                font.family: "${fontName}"
                                font.pixelSize: 14
                                Layout.preferredWidth: 40
                                horizontalAlignment: Text.AlignRight
                            }
                            
                            Rectangle {
                                width: 24
                                height: 24
                                radius: 12
                                color: appMouseArea.containsMouse ? "#33${c.base03}" : "transparent"
                                Text {
                                    anchors.centerIn: parent
                                    text: popupContentCC.appsExpanded ? "" : ""
                                    color: "#${c.base04}"
                                    font.family: "${fontName}"
                                    font.pixelSize: 16
                                }
                                MouseArea {
                                    id: appMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: popupContentCC.appsExpanded = !popupContentCC.appsExpanded
                                }
                            }
                        }
                        
                        ColumnLayout {
                            Layout.fillWidth: true
                            visible: popupContentCC.appsExpanded
                            spacing: 8
                            
                            Repeater {
                                model: parent.parent.parent.currentAudioStreams
                                delegate: RowLayout {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 24
                                    spacing: 12
                                    
                                    Image {
                                        width: 14
                                        height: 14
                                        sourceSize.width: 14
                                        sourceSize.height: 14
                                        fillMode: Image.PreserveAspectFit
                                        source: {
                                            let p = modelData.properties;
                                            if (!p) return "image://icon/audio-x-generic";
                                            let name = (p["application.name"] || "").toLowerCase();
                                            let bin = (p["application.process.binary"] || "").toLowerCase();
                                            let iconName = (p["application.icon-name"] || p["application.icon_name"] || "").toLowerCase();
                                            
                                            let matchStr = name + " " + bin + " " + iconName;
                                            if (matchStr.indexOf("spotify") !== -1) return "image://icon/spotify";
                                            if (matchStr.indexOf("firefox") !== -1) return "image://icon/firefox";
                                            if (matchStr.indexOf("chrome") !== -1) return "image://icon/google-chrome";
                                            if (matchStr.indexOf("brave") !== -1) return "image://icon/brave";
                                            if (matchStr.indexOf("discord") !== -1) return "image://icon/discord";
                                            if (matchStr.indexOf("telegram") !== -1) return "image://icon/telegram";
                                            if (matchStr.indexOf("mpv") !== -1) return "image://icon/mpv";
                                            if (matchStr.indexOf("vlc") !== -1) return "image://icon/vlc";
                                            
                                            if (iconName && iconName !== "") return "image://icon/" + iconName;
                                            if (bin && bin !== "") return "image://icon/" + bin;
                                            
                                            return "image://icon/audio-x-generic";
                                        }
                                        opacity: modelData.audio.muted ? 0.5 : 1.0
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: modelData.audio.muted = !modelData.audio.muted
                                        }
                                    }
                                    
                                    Text {
                                        text: {
                                            let p = modelData.properties;
                                            return p ? (p["application.name"] || p["media.name"] || modelData.name) : modelData.name;
                                        }
                                        color: "#${c.base05}"
                                        font.family: "${fontName}"
                                        font.pixelSize: 13
                                        Layout.preferredWidth: 80
                                        Layout.minimumWidth: 80
                                        Layout.maximumWidth: 80
                                        elide: Text.ElideRight
                                    }
                                    
                                    Item {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 18
                                        property real percent: modelData.audio ? Math.max(0, Math.min(1.0, modelData.audio.volume / 2.0)) : 0
                                        
                                        Rectangle {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: parent.width
                                            height: 6
                                            radius: 3
                                            color: "#33${c.base05}"
                                            
                                            Rectangle {
                                                width: parent.width * parent.parent.percent
                                                height: parent.height
                                                radius: 3
                                                color: (modelData.audio && modelData.audio.volume > 1.005) ? "#${c.base08}" : "#${c.base0D}"
                                            }
                                            
                                            Rectangle {
                                                x: parent.width * 0.5
                                                width: 2
                                                height: 10
                                                anchors.verticalCenter: parent.verticalCenter
                                                color: "#${c.base00}"
                                            }
                                        }
                                        
                                        Rectangle {
                                            width: 14
                                            height: 14
                                            radius: 7
                                            color: "#${c.base05}"
                                            anchors.verticalCenter: parent.verticalCenter
                                            x: Math.max(0, Math.min(parent.width - width, (parent.width * parent.percent) - (width / 2)))
                                        }
                                        
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            function updateAppVol(mouse) {
                                                if (modelData.audio) {
                                                    let p = Math.max(0, Math.min(1, mouse.x / width));
                                                    modelData.audio.volume = p * 2.0;
                                                    if (p > 0) modelData.audio.muted = false;
                                                }
                                            }
                                            onPressed: (mouse) => updateAppVol(mouse)
                                            onPositionChanged: (mouse) => {
                                                if (pressed) updateAppVol(mouse);
                                            }
                                        }
                                    }
                                    
                                    Text {
                                        text: Math.round(modelData.audio.volume * 100) + "%"
                                        color: "#${c.base05}"
                                        font.family: "${fontName}"
                                        font.pixelSize: 12
                                        Layout.preferredWidth: 40
                                        horizontalAlignment: Text.AlignRight
                                    }
                                    
                                    Item { width: 24; height: 24 }
                                    
                                    PwObjectTracker { objects: [modelData] }
                                }
                            }
                        }
                    }
                    
                    // Brightness Section
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12
                            
                            Text {
                                text: ""
                                color: "#${c.base0D}"
                                font.family: "${fontName}"
                                font.pixelSize: 18
                            }
                            
                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 24
                                property real percent: popupContentCC.mainBrightness / 100.0
                                
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width
                                    height: 8
                                    radius: 4
                                    color: "#33${c.base05}"
                                    
                                    Rectangle {
                                        width: parent.width * parent.parent.percent
                                        height: parent.height
                                        radius: 4
                                        color: "#${c.base0D}"
                                    }
                                }
                                
                                Rectangle {
                                    width: 16
                                    height: 16
                                    radius: 8
                                    color: "#${c.base05}"
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: Math.max(0, Math.min(parent.width - width, (parent.width * parent.percent) - (width / 2)))
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onPressedChanged: popupContentCC.isDraggingBrightness = pressed
                                    function updateB(mouse) {
                                        let p = Math.max(0, Math.min(1, mouse.x / width)) * 100;
                                        // Update visual instantly for all backlight class devices
                                        for (let i = 0; i < popupContentCC.brightnessDevices.length; i++) {
                                            if (popupContentCC.brightnessDevices[i].class === "backlight") {
                                                popupContentCC.brightnessDevices[i].percent = p;
                                                popupContentCC.setDeviceBrightness(popupContentCC.brightnessDevices[i].name, p);
                                            }
                                        }
                                        popupContentCC.mainBrightness = p;
                                    }
                                    onPressed: (mouse) => updateB(mouse)
                                    onPositionChanged: (mouse) => { if (pressed) updateB(mouse); }
                                }
                            }
                            
                            Text {
                                text: Math.round(popupContentCC.mainBrightness) + "%"
                                color: "#${c.base05}"
                                font.family: "${fontName}"
                                font.pixelSize: 14
                                Layout.preferredWidth: 40
                                horizontalAlignment: Text.AlignRight
                            }
                            
                            Rectangle {
                                width: 24
                                height: 24
                                radius: 12
                                color: brightMouseArea.containsMouse ? "#33${c.base03}" : "transparent"
                                Text {
                                    anchors.centerIn: parent
                                    text: popupContentCC.brightnessExpanded ? "" : ""
                                    color: "#${c.base04}"
                                    font.family: "${fontName}"
                                    font.pixelSize: 16
                                }
                                MouseArea {
                                    id: brightMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: popupContentCC.brightnessExpanded = !popupContentCC.brightnessExpanded
                                }
                            }
                        }
                        
                        ColumnLayout {
                            Layout.fillWidth: true
                            visible: popupContentCC.brightnessExpanded
                            spacing: 8
                            
                            Repeater {
                                model: popupContentCC.brightnessDevices
                                delegate: RowLayout {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 24
                                    spacing: 12
                                    
                                    Text {
                                        text: modelData.class === "backlight" ? "" : ""
                                        color: "#${c.base05}"
                                        font.family: "${fontName}"
                                        font.pixelSize: 14
                                    }
                                    
                                    Text {
                                        text: {
                                            let n = modelData.name.toLowerCase();
                                            if (n.indexOf("kbd") !== -1 || n.indexOf("keyboard") !== -1) return "Keyboard";
                                            return "Display";
                                        }
                                        color: "#${c.base05}"
                                        font.family: "${fontName}"
                                        font.pixelSize: 13
                                        Layout.preferredWidth: 80
                                        Layout.minimumWidth: 80
                                        Layout.maximumWidth: 80
                                        elide: Text.ElideRight
                                    }
                                    
                                    Item {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 18
                                        property real percent: modelData.percent / 100.0
                                        
                                        Rectangle {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: parent.width
                                            height: 6
                                            radius: 3
                                            color: "#33${c.base05}"
                                            
                                            Rectangle {
                                                width: parent.width * parent.parent.percent
                                                height: parent.height
                                                radius: 3
                                                color: "#${c.base0D}"
                                            }
                                        }
                                        
                                        Rectangle {
                                            width: 14
                                            height: 14
                                            radius: 7
                                            color: "#${c.base05}"
                                            anchors.verticalCenter: parent.verticalCenter
                                            x: Math.max(0, Math.min(parent.width - width, (parent.width * parent.percent) - (width / 2)))
                                        }
                                        
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onPressedChanged: popupContentCC.isDraggingBrightness = pressed
                                            function updateDeviceB(mouse) {
                                                let p = Math.max(0, Math.min(1, mouse.x / width)) * 100;
                                                modelData.percent = p;
                                                if (modelData.class === "backlight") {
                                                    popupContentCC.mainBrightness = p;
                                                }
                                                // Avoid rewriting array during drag. Visual updates via modelData bind directly or on next poll.
                                                parent.percent = p / 100.0;
                                                popupContentCC.setDeviceBrightness(modelData.name, p);
                                            }
                                            onPressed: (mouse) => updateDeviceB(mouse)
                                            onPositionChanged: (mouse) => { if (pressed) updateDeviceB(mouse); }
                                        }
                                    }
                                    
                                    Text {
                                        text: Math.round(modelData.percent) + "%"
                                        color: "#${c.base05}"
                                        font.family: "${fontName}"
                                        font.pixelSize: 12
                                        Layout.preferredWidth: 40
                                        horizontalAlignment: Text.AlignRight
                                    }
                                    
                                    Item { width: 24; height: 24 }
                                }
                            }
                        }
                    }
                }


                // Grid of Toggles
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    rowSpacing: 16
                    columnSpacing: 16
                    
                    Repeater {
                        model: [
                            { icon: "", title: "Hobbiton", subtitle: "59%", active: true },
                            { icon: "", title: "Disabled", subtitle: "Off", active: false },
                            { icon: "", title: "Ryzen HD Audio...", subtitle: "65%", active: true },
                            { icon: "", title: "Ryzen HD Audio...", subtitle: "45%", active: true }
                        ]
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 64
                            radius: 14
                            color: modelData.active ? "#33${c.base0D}" : "#${c.base02}"
                            border.color: modelData.active ? "#33${c.base0D}" : "transparent"
                            border.width: 1
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 14
                                Text {
                                    text: modelData.icon
                                    color: modelData.active ? "#${c.base0D}" : "#${c.base05}"
                                    font.family: "${fontName}"
                                    font.pixelSize: 22
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    Text {
                                        text: modelData.title
                                        color: modelData.active ? "#${c.base05}" : "#${c.base05}"
                                        font.family: "${fontName}"
                                        font.pixelSize: 14
                                        font.bold: true
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: modelData.subtitle
                                        color: "#${c.base04}"
                                        font.family: "${fontName}"
                                        font.pixelSize: 12
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Bottom actions (Night Mode)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16
                    
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 56
                        radius: 12
                        color: "#33${c.base0D}"
                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 10
                            Text { text: ""; color: "#${c.base0D}"; font.family: "${fontName}"; font.pixelSize: 16 }
                            Text { text: "Night Mode"; color: "#${c.base05}"; font.family: "${fontName}"; font.bold: true; font.pixelSize: 14 }
                        }
                    }
                }
            }
        }
    }
  '';

  widget = ''
    Rectangle {
        id: ccButton
        width: 28; height: 28
        radius: 14
        color: ccMouseArea.containsMouse ? "#${c.base03}" : (root.controlcenterVisible ? "#${c.base02}" : "#${c.base02}")
        
        Text {
            anchors.centerIn: parent
            text: "" // Sliders icon
            color: root.controlcenterVisible ? "#${c.base0D}" : "#${c.base05}"
            font.family: "${fontName}"
            font.pixelSize: 14
        }
        
        MouseArea {
            id: ccMouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                root.controlcenterButtonX = ccButton.mapToItem(null, ccButton.width / 2, 0).x;
                root.controlcenterVisible = !root.controlcenterVisible;
            }
        }
    }
  '';
}
