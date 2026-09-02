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
            property bool networkExpanded: false
            property string networkTab: "ethernet"
            property var ethernetList: []
            property var wifiList: []
            property string ethStatus: "Disconnected"
            property string wifiStatus: "Disconnected"
            property string activeNetworkName: "Network"
            property string activeNetworkSignal: "Disconnected"
            property string activeNetworkType: "none"
            property string netPing: "-"
            property string netLoss: "-"
            property string netRxSpeed: "-"
            property string netTxSpeed: "-"
            property string netRxTotal: "-"
            property string netTxTotal: "-"
            property string netIp: "-"
            property string netGateway: "-"
            
            // Bluetooth properties
            property bool bluetoothExpanded: false
            property var bluetoothList: []
            property string activeBluetoothName: "Bluetooth"
            property string activeBluetoothBattery: "Disconnected"
            property string bluetoothStatus: "Off"
            
            property bool isDraggingBrightness: false
            property var brightnessDevices: []
            property int mainBrightness: 0
            
            // Pipewire dynamic properties
            property int _pwUpdateTrigger: 0
            Connections {
                target: Pipewire.nodes
                function onValuesChanged() { popupContentCC._pwUpdateTrigger += 1; }
            }
            
            property var currentAudioStreams: {
                var trigger = popupContentCC._pwUpdateTrigger;
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
            
            property bool micsExpanded: false
            property var currentMics: {
                var trigger = popupContentCC._pwUpdateTrigger;
                var arr = [];
                var nodes = Pipewire.nodes.values;
                if (nodes) {
                    for (var i = 0; i < nodes.length; i++) {
                        var n = nodes[i];
                        if (n && n.audio && !n.isSink && !n.isStream) {
                            arr.push(n);
                        }
                    }
                }
                return arr;
            }
            
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
                property bool caffeineActive: false
                property bool nightlightActive: false
            }

            Process {
                id: ccInfoProc
                property string script: "uptime_val=$(awk '{d=int($1/86400); h=int(($1%86400)/3600); m=int(($1%3600)/60); if(d>0) printf \"%dd %dh %dm\\n\", d, h, m; else if(h>0) printf \"%dh %dm\\n\", h, m; else printf \"%dm\\n\", m}' /proc/uptime); user_val=$(whoami); host_val=$(hostname); os_val=$(awk -F'=' '/^PRETTY_NAME/ {gsub(/\"/, \"\", $2); print $2}' /etc/os-release); if systemctl --user is-active --quiet hypridle.service; then caf=false; else caf=true; fi; if pgrep -x hyprsunset > /dev/null; then nl=true; else nl=false; fi; echo \"{\\\"uptime\\\": \\\"$uptime_val\\\", \\\"user\\\": \\\"$user_val\\\", \\\"host\\\": \\\"$host_val\\\", \\\"os\\\": \\\"$os_val\\\", \\\"home\\\": \\\"$HOME\\\", \\\"caffeine\\\": $caf, \\\"nightlight\\\": $nl}\""
                command: ["sh", "-c", script]
                running: false
                stdout: StdioCollector {
                    onStreamFinished: {
                        if (text !== "") {
                            try {
                                let data = JSON.parse(text);
                                ccData.user = data.user;
                                ccData.uptime = data.uptime;
                                ccData.host = data.host;
                                ccData.os = data.os;
                                ccData.home = data.home;
                                ccData.caffeineActive = data.caffeine;
                                ccData.nightlightActive = data.nightlight;
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
                        networkPollProc.running = true;
                    }
                }
            }

            Process {
                id: networkPollProc
                command: ["sh", "-c", "if [ -f $HOME/.config/hypr/scripts/network-status.sh ]; then $HOME/.config/hypr/scripts/network-status.sh; else echo '{\"ethernet\":[],\"wifi\":[],\"eth_status\":\"Disconnected\",\"wifi_status\":\"Disconnected\"}'; fi"]
                running: false
                stdout: StdioCollector {
                    onStreamFinished: {
                        if (text !== "") {
                            try {
                                let data = JSON.parse(text.trim());
                                popupContentCC.ethernetList = data.ethernet;
                                popupContentCC.wifiList = data.wifi;
                                popupContentCC.ethStatus = data.eth_status;
                                popupContentCC.wifiStatus = data.wifi_status;
                                popupContentCC.activeNetworkName = data.active_name;
                                popupContentCC.activeNetworkSignal = data.active_signal;
                                popupContentCC.activeNetworkType = data.active_type;
                                // Removed auto-switch tab to prevent overriding user selection
                            } catch (e) {
                                console.log("Error parsing network JSON: " + e);
                            }
                        }
                    }
                }
            }
            
            Timer {
                interval: 5000
                running: root.controlcenterVisible
                repeat: true
                onTriggered: {
                    networkPollProc.running = true;
                    bluetoothPollProc.running = true;
                }
            }

            Process {
                id: networkStatsProc
                command: ["sh", "-c", "if [ -f $HOME/.config/hypr/scripts/network-stats.sh ]; then $HOME/.config/hypr/scripts/network-stats.sh; fi"]
                running: false
                stdout: StdioCollector {
                    onStreamFinished: {
                        if (text !== "") {
                            try {
                                let data = JSON.parse(text.trim());
                                popupContentCC.netPing = data.ping;
                                popupContentCC.netLoss = data.loss;
                                popupContentCC.netRxSpeed = data.rx_speed;
                                popupContentCC.netTxSpeed = data.tx_speed;
                                popupContentCC.netRxTotal = data.rx_total;
                                popupContentCC.netTxTotal = data.tx_total;
                                popupContentCC.netIp = data.ip;
                                popupContentCC.netGateway = data.gateway;
                            } catch (e) {
                                console.log("Error parsing network stats JSON: " + e);
                            }
                        }
                    }
                }
            }
            
            Timer {
                interval: 2000
                running: root.controlcenterVisible && ccData.profileExpanded
                repeat: true
                onTriggered: networkStatsProc.running = true
            }
            Connections {
                target: ccData
                function onProfileExpandedChanged() {
                    if (ccData.profileExpanded && root.controlcenterVisible) {
                        networkStatsProc.running = true;
                    }
                }
            }
            
            Process {
                id: bluetoothPollProc
                command: ["sh", "-c", "if [ -f $HOME/.config/hypr/scripts/bluetooth-status.sh ]; then $HOME/.config/hypr/scripts/bluetooth-status.sh; else echo '{\"devices\":[],\"status\":\"Off\",\"active_name\":\"Bluetooth\",\"active_battery\":\"Disconnected\"}'; fi"]
                running: false
                stdout: StdioCollector {
                    onStreamFinished: {
                        if (text !== "") {
                            try {
                                let data = JSON.parse(text.trim());
                                popupContentCC.bluetoothList = data.devices;
                                popupContentCC.bluetoothStatus = data.status;
                                popupContentCC.activeBluetoothName = data.active_name;
                                popupContentCC.activeBluetoothBattery = data.active_battery;
                            } catch (e) {
                                console.log("Error parsing bluetooth JSON: " + e);
                            }
                        }
                    }
                }
            }

            Component.onCompleted: {
                ccInfoProc.running = true;
                bluetoothPollProc.running = true;
            }
            
            opacity: root.controlcenterVisible ? 1 : 0
            y: root.controlcenterVisible ? 0 : -20
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

            ScrollView {
                anchors.fill: parent
                anchors.topMargin: 32
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                anchors.bottomMargin: 20
                contentWidth: availableWidth
                clip: true
                
                ColumnLayout {
                    width: parent.width
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
                                    color: "#${c.base0D}"
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

                        // Action Buttons (Screenshot)
                        Rectangle {
                            width: 36; height: 36; radius: 18
                            color: screenshotBtnArea.containsMouse ? "#${c.base03}" : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: ""
                                color: "#${c.base05}"
                                font.family: "${fontName}"
                                font.pixelSize: 16
                            }
                            MouseArea {
                                id: screenshotBtnArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    root.controlcenterVisible = false;
                                    cmdRunner.exec(["sh", "-c", "sleep 0.5 && hyprshot -m region --raw | satty --filename - --early-exit --copy-command wl-copy --initial-tool arrow --output-filename $HOME/Pictures/screenshot-$(date '+%Y%m%d-%H:%M:%S').png"]);
                                }
                            }
                        }

                        // Action Buttons (Keybindings)
                        Rectangle {
                            width: 36; height: 36; radius: 18
                            color: keybindsBtnArea.containsMouse ? "#${c.base03}" : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: "󰋖"
                                color: "#${c.base05}"
                                font.family: "${fontName}"
                                font.pixelSize: 16
                            }
                            MouseArea {
                                id: keybindsBtnArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    root.controlcenterVisible = false;
                                    cmdRunner.exec(["sh", "-c", "nohup $HOME/.config/sicos/scripts/show-hyprland-keybindings.sh >/dev/null 2>&1 &"]);
                                }
                            }
                        }

                        // Action Buttons (Info)
                        Rectangle {
                            width: 36; height: 36; radius: 18
                            color: infoBtnArea.containsMouse ? "#${c.base03}" : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: "󰙎"
                                color: "#${c.base05}"
                                font.family: "${fontName}"
                                font.pixelSize: 16
                            }
                            MouseArea {
                                id: infoBtnArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    root.controlcenterVisible = false;
                                    cmdRunner.exec(["sh", "-c", "hyprctl eval 'sicos_about_rule1 = hl.window_rule({ match = { class = \"sicos-about\" }, float = true }); sicos_about_rule2 = hl.window_rule({ match = { class = \"sicos-about\" }, size = { 1600, 900 } }); sicos_about_rule3 = hl.window_rule({ match = { class = \"sicos-about\" }, center = true })'; uwsm app -- kitty --class sicos-about sh -c $HOME/.config/sicos/scripts/fastfetch-about.sh"]);
                                }
                            }
                        }

                        // Action Buttons (Caffeine)


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

                    // Expanded Content (Host & Distro & Network Stats)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: ccData.profileExpanded ? expandedContentCol.implicitHeight + 16 : 0
                        opacity: ccData.profileExpanded ? 1 : 0
                        visible: opacity > 0
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
                            spacing: 12
                            
                            // System info
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 16
                                RowLayout {
                                    Text { text: ""; color: "#${c.base0D}"; font.family: "${fontName}"; font.pixelSize: 14 }
                                    Text { text: ccData.host !== "" ? ccData.host : "Hostname"; color: "#${c.base05}"; font.family: "${fontName}"; font.pixelSize: 13; font.bold: true; elide: Text.ElideRight; Layout.maximumWidth: 100 }
                                }
                                RowLayout {
                                    Text { text: ""; color: "#${c.base0D}"; font.family: "${fontName}"; font.pixelSize: 14 }
                                    Text { text: ccData.os !== "" ? ccData.os : "Linux"; color: "#${c.base04}"; font.family: "${fontName}"; font.pixelSize: 13; elide: Text.ElideRight; Layout.fillWidth: true }
                                }
                            }
                            
                            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#33${c.base03}" }
                            
                            // Omarchy-style Network Stats
                            GridLayout {
                                Layout.fillWidth: true
                                columns: 4
                                rowSpacing: 8
                                columnSpacing: 12
                                
                                Text { text: "Ping"; color: "#${c.base04}"; font.family: "${fontName}"; font.pixelSize: 12 }
                                Text { text: popupContentCC.netPing; color: "#${c.base05}"; font.family: "${fontName}"; font.pixelSize: 12; font.bold: true; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight }
                                Text { text: "Packet Loss"; color: "#${c.base04}"; font.family: "${fontName}"; font.pixelSize: 12 }
                                Text { text: popupContentCC.netLoss; color: "#${c.base05}"; font.family: "${fontName}"; font.pixelSize: 12; font.bold: true; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight }
                                
                                Text { text: "Receiving"; color: "#${c.base04}"; font.family: "${fontName}"; font.pixelSize: 12 }
                                Text { text: popupContentCC.netRxSpeed; color: "#${c.base05}"; font.family: "${fontName}"; font.pixelSize: 12; font.bold: true; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight }
                                Text { text: "Sending"; color: "#${c.base04}"; font.family: "${fontName}"; font.pixelSize: 12 }
                                Text { text: popupContentCC.netTxSpeed; color: "#${c.base05}"; font.family: "${fontName}"; font.pixelSize: 12; font.bold: true; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight }
                                
                                Text { text: "Downloaded"; color: "#${c.base04}"; font.family: "${fontName}"; font.pixelSize: 12 }
                                Text { text: popupContentCC.netRxTotal; color: "#${c.base05}"; font.family: "${fontName}"; font.pixelSize: 12; font.bold: true; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight }
                                Text { text: "Uploaded"; color: "#${c.base04}"; font.family: "${fontName}"; font.pixelSize: 12 }
                                Text { text: popupContentCC.netTxTotal; color: "#${c.base05}"; font.family: "${fontName}"; font.pixelSize: 12; font.bold: true; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight }
                                
                                Text { text: "IP Address"; color: "#${c.base04}"; font.family: "${fontName}"; font.pixelSize: 12 }
                                Text { text: popupContentCC.netIp; color: "#${c.base05}"; font.family: "${fontName}"; font.pixelSize: 12; font.bold: true; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight }
                                Text { text: "Gateway"; color: "#${c.base04}"; font.family: "${fontName}"; font.pixelSize: 12 }
                                Text { text: popupContentCC.netGateway; color: "#${c.base05}"; font.family: "${fontName}"; font.pixelSize: 12; font.bold: true; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight }
                            }
                        }
                    }
                }
                
                // Sliders (Volume, Brightness)
                ColumnLayout {
                    id: slidersColumn
                    
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
                    
                    // Audio Pill
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: audioPillLayout.implicitHeight + 24
                        
                        Rectangle {
                            anchors.fill: parent
                            color: "#1A${c.base03}"
                            radius: 12
                        }
                        
                        ColumnLayout {
                            id: audioPillLayout
                            anchors.fill: parent
                            anchors.margins: 12
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
                            
                            Item {
                                        Layout.preferredWidth: 32
                                        Layout.preferredHeight: 24
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
                                    }
                            
                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 24
                                property real percent: Pipewire.defaultAudioSink ? Math.max(0, Math.min(1.0, Pipewire.defaultAudioSink.audio.volume / 2.0)) : 0
                                
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width
                                    height: 12
                                    radius: 6
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
                                    width: 20
                                    height: 20
                                    radius: 10
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
                                    color: "#${c.base0D}"
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
                                model: popupContentCC.currentAudioStreams
                                delegate: RowLayout {
                                    Layout.fillWidth: true
                                    Item { width: 12 }
                                    spacing: 12
                                    
                                    Item {
                                                Layout.preferredWidth: 126
                                                Layout.preferredHeight: 24
                                                RowLayout {
                                                    anchors.fill: parent
                                                    spacing: 12
                                                    Item {
                                                        Layout.preferredWidth: 24
                                                        Layout.preferredHeight: 24
                                                        Image {
                                                            anchors.centerIn: parent
                                                            width: 16
                                                            height: 16
                                                            sourceSize.width: 16
                                                            sourceSize.height: 16
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
                                    }
                                    
                                    Text {
                                        text: {
                                            let p = modelData.properties;
                                            return p ? (p["application.name"] || p["media.name"] || modelData.name) : modelData.name;
                                        }
                                        color: "#${c.base05}"
                                        font.family: "${fontName}"
                                        font.pixelSize: 13
                                        Layout.fillWidth: true
                                        
                                        
                                        elide: Text.ElideRight
                                    }
                                                }
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
                    
                    // Mic Section
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        
                        PwObjectTracker {
                            objects: Pipewire.defaultAudioSource ? [Pipewire.defaultAudioSource] : []
                        }
                        
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12
                            
                            Item {
                                        Layout.preferredWidth: 32
                                        Layout.preferredHeight: 24
                                        Text {
                                text: (Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio.muted) ? "" : ""
                                color: (Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio.muted) ? "#${c.base08}" : "#${c.base0D}"
                                font.family: "${fontName}"
                                font.pixelSize: 18
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: if (Pipewire.defaultAudioSource) Pipewire.defaultAudioSource.audio.muted = !Pipewire.defaultAudioSource.audio.muted
                                }
                            }
                                    }
                            
                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 24
                                property real percent: Pipewire.defaultAudioSource ? Math.max(0, Math.min(1.0, Pipewire.defaultAudioSource.audio.volume / 2.0)) : 0
                                
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width
                                    height: 12
                                    radius: 6
                                    color: "#33${c.base05}"
                                    
                                    Rectangle {
                                        width: parent.width * parent.parent.percent
                                        height: parent.height
                                        radius: 4
                                        color: (Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio.volume > 1.005) ? "#${c.base08}" : "#${c.base0D}"
                                    }
                                }
                                
                                Rectangle {
                                    width: 20
                                    height: 20
                                    radius: 10
                                    color: "#${c.base05}"
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: Math.max(0, Math.min(parent.width - width, (parent.width * parent.percent) - (width / 2)))
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    function updateMicV(mouse) {
                                        if (Pipewire.defaultAudioSource) {
                                            let p = Math.max(0, Math.min(1, mouse.x / width));
                                            Pipewire.defaultAudioSource.audio.volume = p * 2.0;
                                            if (p > 0) Pipewire.defaultAudioSource.audio.muted = false;
                                        }
                                    }
                                    onPressed: (mouse) => updateMicV(mouse)
                                    onPositionChanged: (mouse) => { if (pressed) updateMicV(mouse); }
                                }
                            }
                            
                            Text {
                                text: Pipewire.defaultAudioSource ? Math.round(Pipewire.defaultAudioSource.audio.volume * 100) + "%" : "0%"
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
                                color: micMouseArea.containsMouse ? "#33${c.base03}" : "transparent"
                                Text {
                                    anchors.centerIn: parent
                                    text: popupContentCC.micsExpanded ? "" : ""
                                    color: "#${c.base0D}"
                                    font.family: "${fontName}"
                                    font.pixelSize: 16
                                }
                                MouseArea {
                                    id: micMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: popupContentCC.micsExpanded = !popupContentCC.micsExpanded
                                }
                            }
                        }
                        
                        ColumnLayout {
                            Layout.fillWidth: true
                            visible: popupContentCC.micsExpanded
                            spacing: 8
                            
                            Repeater {
                                model: popupContentCC.currentMics
                                delegate: RowLayout {
                                    Layout.fillWidth: true
                                    Item { width: 12 }
                                    spacing: 12
                                    
                                    Item {
                                                Layout.preferredWidth: 126
                                                Layout.preferredHeight: 24
                                                RowLayout {
                                                    anchors.fill: parent
                                                    spacing: 12
                                                    Rectangle {
                                        Layout.preferredWidth: 24
                                        Layout.preferredHeight: 24
                                        radius: 12
                                        color: "transparent"
                                        Text {
                                            anchors.centerIn: parent
                                            text: (modelData.audio && modelData.audio.muted) ? "" : ""
                                            color: (modelData.audio && modelData.audio.muted) ? "#${c.base08}" : "#${c.base05}"
                                            font.family: "${fontName}"
                                            font.pixelSize: 16
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: if (modelData.audio) modelData.audio.muted = !modelData.audio.muted
                                        }
                                    }
                                    
                                    Text {
                                        text: modelData.properties["node.description"] || modelData.name
                                        color: "#${c.base05}"
                                        font.family: "${fontName}"
                                        font.pixelSize: 13
                                        Layout.fillWidth: true
                                        
                                        
                                        elide: Text.ElideRight
                                    }
                                                }
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
                                        }
                                        
                                        Rectangle {
                                            width: 12
                                            height: 12
                                            radius: 6
                                            color: "#${c.base05}"
                                            anchors.verticalCenter: parent.verticalCenter
                                            x: Math.max(0, Math.min(parent.width - width, (parent.width * parent.percent) - (width / 2)))
                                        }
                                        
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            function updateAppMicV(mouse) {
                                                if (modelData.audio) {
                                                    let p = Math.max(0, Math.min(1, mouse.x / width));
                                                    modelData.audio.volume = p * 2.0;
                                                    if (p > 0) modelData.audio.muted = false;
                                                }
                                            }
                                            onPressed: (mouse) => updateAppMicV(mouse)
                                            onPositionChanged: (mouse) => { if (pressed) updateAppMicV(mouse); }
                                        }
                                    }
                                    
                                    Text {
                                        text: modelData.audio ? Math.round(modelData.audio.volume * 100) + "%" : "0%"
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
                        } // end audioPillLayout
                    } // end Audio Pill
                    
                    // Brightness Pill
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: brightnessPillLayout.implicitHeight + 24
                        
                        Rectangle {
                            anchors.fill: parent
                            color: "#1A${c.base03}"
                            radius: 12
                        }
                        
                        ColumnLayout {
                            id: brightnessPillLayout
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 16
                            
                            // Brightness Section
                            ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12
                            
                            Item {
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 24
                                Text {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: ""
                                    color: "#${c.base0D}"
                                    font.family: "${fontName}"
                                    font.pixelSize: 18
                                }
                            }
                            
                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 24
                                property real percent: popupContentCC.mainBrightness / 100.0
                                
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width
                                    height: 12
                                    radius: 6
                                    color: "#33${c.base05}"
                                    
                                    Rectangle {
                                        width: parent.width * parent.parent.percent
                                        height: parent.height
                                        radius: 4
                                        color: "#${c.base0D}"
                                    }
                                }
                                
                                Rectangle {
                                    width: 20
                                    height: 20
                                    radius: 10
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
                                    color: "#${c.base0D}"
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
                                    Item { width: 12 }
                                    spacing: 12
                                    
                                    Item {
                                        Layout.preferredWidth: 126
                                        Layout.preferredHeight: 24
                                        RowLayout {
                                            anchors.fill: parent
                                            spacing: 12
                                            
                                            Item {
                                                Layout.preferredWidth: 24
                                                Layout.preferredHeight: 24
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.class === "backlight" ? "" : ""
                                                    color: "#${c.base05}"
                                                    font.family: "${fontName}"
                                                    font.pixelSize: 16
                                                }
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
                                                Layout.fillWidth: true
                                                
                                                
                                                elide: Text.ElideRight
                                            }
                                        }
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
                        } // end brightnessPillLayout
                    } // end Brightness Pill
                }


                // Quick Toggles
                
                // Quick Toggles
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16
                    
                    // Network Quick Toggle
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 64
                        radius: 16
                        color: "#1a${c.base05}"
                        border.color: popupContentCC.networkExpanded ? "#${c.base0D}" : "transparent"
                        border.width: popupContentCC.networkExpanded ? 1 : 0
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12
                            
                            Rectangle {
                                width: 40; height: 40; radius: 20
                                color: "#${c.base0D}"
                                Text { anchors.centerIn: parent; text: popupContentCC.activeNetworkType === "ethernet" ? "󰈀" : (popupContentCC.activeNetworkType === "none" ? "󰤭" : ""); color: "#${c.base00}"; font.family: "${fontName}"; font.pixelSize: 18 }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Text { text: popupContentCC.activeNetworkName; color: "#${c.base05}"; font.family: "${fontName}"; font.pixelSize: 14; font.bold: true }
                                Text { text: popupContentCC.activeNetworkSignal; color: "#${c.base04}"; font.family: "${fontName}"; font.pixelSize: 12 }
                            }
                            Text {
                                text: popupContentCC.networkExpanded ? "" : ""
                                color: "#${c.base0D}"
                                font.family: "${fontName}"
                                font.pixelSize: 14
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: popupContentCC.networkExpanded = !popupContentCC.networkExpanded
                        }
                    }

                    // Bluetooth Quick Toggle
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 64
                        radius: 16
                        color: popupContentCC.bluetoothExpanded ? "#33${c.base0D}" : "#1a${c.base05}"
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12
                            
                            Rectangle {
                                width: 40; height: 40; radius: 20
                                color: (popupContentCC.bluetoothStatus === "Connected" || popupContentCC.bluetoothStatus === "On") ? "#${c.base0D}" : "#33${c.base05}"
                                Text { 
                                    anchors.centerIn: parent
                                    text: ""
                                    color: (popupContentCC.bluetoothStatus === "Connected" || popupContentCC.bluetoothStatus === "On") ? "#${c.base00}" : "#${c.base04}"
                                    font.family: "${fontName}"
                                    font.pixelSize: 18
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Text { text: popupContentCC.activeBluetoothName; color: "#${c.base05}"; font.family: "${fontName}"; font.pixelSize: 14; font.bold: true; elide: Text.ElideRight }
                                Text { text: popupContentCC.activeBluetoothBattery !== "" ? popupContentCC.activeBluetoothBattery : popupContentCC.bluetoothStatus; color: "#${c.base04}"; font.family: "${fontName}"; font.pixelSize: 12 }
                            }
                            // Arrow
                            Text {
                                text: popupContentCC.bluetoothExpanded ? "" : ""
                                color: "#${c.base0D}"
                                font.family: "${fontName}"
                                font.pixelSize: 14
                            }
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: popupContentCC.bluetoothExpanded = !popupContentCC.bluetoothExpanded
                        }
                    }
                }
                
                // Expanded Network Block
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: networkCol.implicitHeight + 24
                    radius: 16
                    color: "#1a${c.base05}"
                    visible: popupContentCC.networkExpanded
                    
                    ColumnLayout {
                        id: networkCol
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 16

                        // Header
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Network"; color: "#${c.base05}"; font.family: "${fontName}"; font.pixelSize: 14; font.bold: true; Layout.fillWidth: true }
                            
                            // Segmented Control (Ethernet / WiFi)
                            Rectangle {
                                width: 160; height: 32; radius: 16
                                color: "#1a${c.base05}"
                                RowLayout {
                                    anchors.fill: parent
                                    spacing: 0
                                    Rectangle {
                                        Layout.fillWidth: true; Layout.fillHeight: true; radius: 16
                                        color: popupContentCC.networkTab === "ethernet" ? "#${c.base0D}" : "transparent"
                                        Text { anchors.centerIn: parent; text: popupContentCC.networkTab === "ethernet" ? "✓ Ethernet" : "Ethernet"; color: popupContentCC.networkTab === "ethernet" ? "#${c.base00}" : "#${c.base05}"; font.family: "${fontName}"; font.pixelSize: 12; font.bold: popupContentCC.networkTab === "ethernet" }
                                        MouseArea { anchors.fill: parent; onClicked: popupContentCC.networkTab = "ethernet" }
                                    }
                                    Rectangle {
                                        Layout.fillWidth: true; Layout.fillHeight: true; radius: 16
                                        color: popupContentCC.networkTab === "wifi" ? "#${c.base0D}" : "transparent"
                                        Text { anchors.centerIn: parent; text: popupContentCC.networkTab === "wifi" ? "✓ WiFi" : "WiFi"; color: popupContentCC.networkTab === "wifi" ? "#${c.base00}" : "#${c.base05}"; font.family: "${fontName}"; font.pixelSize: 12; font.bold: popupContentCC.networkTab === "wifi" }
                                        MouseArea { anchors.fill: parent; onClicked: popupContentCC.networkTab = "wifi" }
                                    }
                                }
                            }
                        }

                        // Network List
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            
                            Repeater {
                                model: popupContentCC.networkTab === "ethernet" ? popupContentCC.ethernetList : popupContentCC.wifiList
                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 48
                                    radius: 8
                                    color: netMouseArea.containsMouse ? "#33${c.base05}" : (modelData.active ? "#33${c.base0D}" : "transparent")
                                    
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 12
                                        spacing: 12
                                        Text { text: popupContentCC.networkTab === "ethernet" ? "󰈀" : "󰤨"; color: modelData.active ? "#${c.base0D}" : "#${c.base04}"; font.family: "${fontName}"; font.pixelSize: 16 }
                                        Text { text: modelData.name; color: "#${c.base05}"; font.family: "${fontName}"; font.pixelSize: 14; Layout.fillWidth: true; elide: Text.ElideRight }
                                    }
                                    
                                    MouseArea {
                                        id: netMouseArea
                                        hoverEnabled: true
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (!modelData.active) {
                                                // Abre la GUI de NetworkManager para gestionar conexiones complejas (contraseñas, etc)
                                                cmdRunner.exec(["uwsm", "app", "--", "nm-connection-editor"]);
                                                root.controlcenterVisible = false;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Expanded Bluetooth Block
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: bluetoothCol.implicitHeight + 24
                    radius: 16
                    color: "#1a${c.base05}"
                    visible: popupContentCC.bluetoothExpanded
                    
                    ColumnLayout {
                        id: bluetoothCol
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 16

                        // Header
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Bluetooth Devices"; color: "#${c.base05}"; font.family: "${fontName}"; font.pixelSize: 14; font.bold: true; Layout.fillWidth: true }
                            
                            // Scan/Settings Button
                            Rectangle {
                                width: 28; height: 28; radius: 14
                                color: "#33${c.base05}"
                                Text { anchors.centerIn: parent; text: ""; color: "#${c.base05}"; font.family: "${fontName}"; font.pixelSize: 12 }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        cmdRunner.exec(["uwsm", "app", "--", "blueman-manager"]);
                                        root.controlcenterVisible = false;
                                    }
                                }
                            }
                        }
                        
                        // List
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            
                            Repeater {
                                model: popupContentCC.bluetoothList
                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 48
                                    radius: 8
                                    color: btMouseArea.containsMouse ? "#33${c.base05}" : (modelData.active ? "#33${c.base0D}" : "transparent")
                                    
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 12
                                        spacing: 12
                                        
                                        Text { text: ""; color: modelData.active ? "#${c.base0D}" : "#${c.base04}"; font.family: "${fontName}"; font.pixelSize: 16 }
                                        Text { text: modelData.name; color: "#${c.base05}"; font.family: "${fontName}"; font.pixelSize: 14; Layout.fillWidth: true }
                                        
                                        // Battery if available
                                        Text { 
                                            text: modelData.battery !== "" ? modelData.battery : ""
                                            color: "#${c.base04}"
                                            font.family: "${fontName}"
                                            font.pixelSize: 12
                                            visible: modelData.battery !== ""
                                        }
                                    }
                                    
                                    MouseArea {
                                        id: btMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            cmdRunner.exec(["uwsm", "app", "--", "blueman-manager"]);
                                            root.controlcenterVisible = false;
                                        }
                                    }
                                }
                            }
                            
                            Text {
                                visible: popupContentCC.bluetoothList.length === 0
                                text: "No devices found."
                                color: "#${c.base04}"
                                font.family: "${fontName}"
                                font.pixelSize: 13
                                Layout.alignment: Qt.AlignHCenter
                                Layout.topMargin: 8
                            }
                        }
                    }
                }
                
                // Bottom actions (Caffeine & Night Mode)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16
                    
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 56
                        radius: 12
                        color: ccData.caffeineActive ? "#33${c.base0D}" : (cafBottomBtnArea.containsMouse ? "#${c.base03}" : "#${c.base02}")
                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 10
                            Text { text: ""; color: ccData.caffeineActive ? "#${c.base0D}" : "#${c.base05}"; font.family: "${fontName}"; font.pixelSize: 16 }
                            Text { text: "Caffeine"; color: ccData.caffeineActive ? "#${c.base0D}" : "#${c.base05}"; font.family: "${fontName}"; font.bold: true; font.pixelSize: 14 }
                        }
                        MouseArea {
                            id: cafBottomBtnArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                ccData.caffeineActive = !ccData.caffeineActive;
                                cmdRunner.exec(["sh", "-c", "$HOME/.config/sicos/scripts/toggle-hypridle.sh"]);
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 56
                        radius: 12
                        color: ccData.nightlightActive ? "#33${c.base0D}" : (nightModeArea.containsMouse ? "#${c.base03}" : "#${c.base02}")
                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 10
                            Text { text: ""; color: ccData.nightlightActive ? "#${c.base0D}" : "#${c.base05}"; font.family: "${fontName}"; font.pixelSize: 16 }
                            Text { text: "Night Mode"; color: ccData.nightlightActive ? "#${c.base0D}" : "#${c.base05}"; font.family: "${fontName}"; font.bold: true; font.pixelSize: 14 }
                        }
                        MouseArea {
                            id: nightModeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                ccData.nightlightActive = !ccData.nightlightActive;
                                cmdRunner.exec(["sh", "-c", "$HOME/.config/sicos/scripts/toggle-nightlight.sh"]);
                            }
                        }
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
        
        Rectangle {
            id: ccBtnAvatarMask
            anchors.centerIn: parent
            width: 24; height: 24; radius: 12
            color: "black"
            visible: false
        }
        
        Image {
            id: ccBtnAvatarImage
            anchors.centerIn: parent
            width: 24; height: 24
            source: "file:///home/egarcia/.config/hypr/user.jpg"
            fillMode: Image.PreserveAspectCrop
            visible: false
        }
        
        OpacityMask {
            anchors.centerIn: parent
            width: 24; height: 24
            source: ccBtnAvatarImage
            maskSource: ccBtnAvatarMask
            visible: ccBtnAvatarImage.status === Image.Ready
        }
        
        Text {
            anchors.centerIn: parent
            text: "" // Fallback icon
            color: root.controlcenterVisible ? "#${c.base0D}" : "#${c.base05}"
            font.family: "${fontName}"
            font.pixelSize: 14
            visible: ccBtnAvatarImage.status !== Image.Ready
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
