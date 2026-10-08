{ config, lib, pkgs, c, fontName }:
{
  popup = ''
    PopupWindow {
        id: sysinfoPopup
        anchor.window: root
        anchor.rect.x: 10
        anchor.rect.y: root.height
        anchor.rect.width: 1
        anchor.rect.height: 1
        anchor.edges: Edges.Bottom | Edges.Left
        visible: root.sysinfoVisible || popupSysContent.opacity > 0
        implicitWidth: 810
        implicitHeight: 460
        color: "transparent"

        HyprlandFocusGrab {
            active: root.sysinfoVisible
            windows: [sysinfoPopup, root]
            onCleared: root.sysinfoVisible = false
        }

        Item {
            id: popupSysContent
            width: parent.width
            height: parent.height
            
            opacity: root.sysinfoVisible ? 1 : 0
            y: root.sysinfoVisible ? 0 : -20
            
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

            // The background color providing the pixels
            Rectangle {
                id: bgSourceSysinfo
                anchors.fill: parent
                color: "#F0${c.base01}"
                visible: false // Hidden because it's only a source for the mask
            }

            // The mask shape (Body + Beak)
            Item {
                id: bgMaskSysinfo
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
                    y: 2
                    anchors.left: parent.left
                    anchors.leftMargin: 145 // Aligned with the expanded sysinfo widget island
                }
            }

            // The final masked background without overlaps or internal borders
            OpacityMask {
                anchors.fill: parent
                source: bgSourceSysinfo
                maskSource: bgMaskSysinfo
            }


            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                anchors.topMargin: 28
                spacing: 12
                
                // Header
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    Layout.preferredHeight: 32
                    spacing: 10

                    Text {
                        text: "System Monitor"
                        color: "#${c.base05}"
                        font.family: "${fontName}"
                        font.pixelSize: 18
                        Layout.fillWidth: true
                    }
                }

                // Monitor Tiles (CPU Top 5, RAM Top 5, BTRFS Disk Overview)
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 16

                    // CPU Top 5
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 12
                        color: "#${c.base02}"
                        
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

                            Text {
                                text: "Top CPU"
                                color: "#${c.base0D}"
                                font.family: "${fontName}"
                                font.pixelSize: 14
                                font.bold: true
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Canvas {
                                Layout.alignment: Qt.AlignHCenter
                                width: 70
                                height: 70
                                property real percentage: parseFloat(sysData.cpu) || 0
                                
                                onPercentageChanged: requestPaint()
                                
                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.clearRect(0, 0, width, height);
                                    
                                    var centerX = width / 2;
                                    var centerY = height / 2;
                                    var radius = width / 2 - 5;
                                    
                                    // Background circle
                                    ctx.beginPath();
                                    ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
                                    ctx.lineWidth = 5;
                                    ctx.strokeStyle = "#${c.base03}";
                                    ctx.stroke();
                                    
                                    // Foreground arc
                                    ctx.beginPath();
                                    var startAngle = -Math.PI / 2;
                                    var endAngle = startAngle + (percentage / 100) * 2 * Math.PI;
                                    ctx.arc(centerX, centerY, radius, startAngle, endAngle);
                                    ctx.lineWidth = 5;
                                    ctx.strokeStyle = "#${c.base0D}";
                                    ctx.lineCap = "round";
                                    ctx.stroke();
                                }
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: Math.round(parent.percentage) + "%"
                                    color: "#${c.base05}"
                                    font.family: "${fontName}"
                                    font.pixelSize: 16
                                    font.bold: true
                                }
                            }
                            ListView {
                                id: cpuList
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                model: ListModel { id: cpuModel }
                                delegate: Rectangle {
                                    width: cpuList.width
                                    height: 24
                                    radius: 6
                                    color: rowAreaCpu.containsMouse ? "#${c.base03}" : "transparent"
                                    
                                    MouseArea {
                                        id: rowAreaCpu
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            killProc.command = ["sh", "-c", "kill -9 " + model.pid]
                                            killProc.running = true
                                        }
                                    }
                                    
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                         Text {
                                            text: model.name
                                            color: "#${c.base05}"
                                            font.family: "${fontName}"
                                            font.pixelSize: 13
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            text: model.usage + "%"
                                            color: "#${c.base04}"
                                            font.family: "${fontName}"
                                            font.pixelSize: 13
                                        }
                                        Text {
                                            text: ""
                                            color: "#${c.base08}"
                                            font.family: "${fontName}"
                                            font.pixelSize: 13
                                            visible: rowAreaCpu.containsMouse
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // RAM Top 5
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 12
                        color: "#${c.base02}"
                        
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

                            Text {
                                text: "Top RAM"
                                color: "#${c.base0D}"
                                font.family: "${fontName}"
                                font.pixelSize: 14
                                font.bold: true
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Canvas {
                                Layout.alignment: Qt.AlignHCenter
                                width: 70
                                height: 70
                                property real percentage: parseFloat(sysData.ram) || 0
                                
                                onPercentageChanged: requestPaint()
                                
                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.clearRect(0, 0, width, height);
                                    
                                    var centerX = width / 2;
                                    var centerY = height / 2;
                                    var radius = width / 2 - 5;
                                    
                                    // Background circle
                                    ctx.beginPath();
                                    ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
                                    ctx.lineWidth = 5;
                                    ctx.strokeStyle = "#${c.base03}";
                                    ctx.stroke();
                                    
                                    // Foreground arc
                                    ctx.beginPath();
                                    var startAngle = -Math.PI / 2;
                                    var endAngle = startAngle + (percentage / 100) * 2 * Math.PI;
                                    ctx.arc(centerX, centerY, radius, startAngle, endAngle);
                                    ctx.lineWidth = 5;
                                    ctx.strokeStyle = "#${c.base0D}";
                                    ctx.lineCap = "round";
                                    ctx.stroke();
                                }
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: Math.round(parent.percentage) + "%"
                                    color: "#${c.base05}"
                                    font.family: "${fontName}"
                                    font.pixelSize: 16
                                    font.bold: true
                                }
                            }
                            ListView {
                                id: ramList
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                model: ListModel { id: ramModel }
                                delegate: Rectangle {
                                    width: ramList.width
                                    height: 24
                                    radius: 6
                                    color: rowAreaRam.containsMouse ? "#${c.base03}" : "transparent"
                                    
                                    MouseArea {
                                        id: rowAreaRam
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            killProc.command = ["sh", "-c", "kill -9 " + model.pid]
                                            killProc.running = true
                                        }
                                    }
                                    
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                         Text {
                                            text: model.name
                                            color: "#${c.base05}"
                                            font.family: "${fontName}"
                                            font.pixelSize: 13
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            text: model.usage + "%"
                                            color: "#${c.base04}"
                                            font.family: "${fontName}"
                                            font.pixelSize: 13
                                        }
                                        Text {
                                            text: ""
                                            color: "#${c.base08}"
                                            font.family: "${fontName}"
                                            font.pixelSize: 13
                                            visible: rowAreaRam.containsMouse
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Disk Overview Tile (Homogeneous tile matching CPU & RAM style)
                    Rectangle {
                        id: diskTileContainer
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 12
                        color: "#${c.base02}"

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 6

                            // Title centered on top
                            Text {
                                text: "Disk"
                                color: "#${c.base0D}"
                                font.family: "${fontName}"
                                font.pixelSize: 14
                                font.bold: true
                                Layout.alignment: Qt.AlignHCenter
                            }

                            // Circular Gauge (matching CPU & RAM tiles)
                            Canvas {
                                Layout.alignment: Qt.AlignHCenter
                                width: 70
                                height: 70
                                property real percentage: Math.min(100.0, Math.max(0.0, parseFloat(sysData.diskAllocPct))) || 0

                                onPercentageChanged: requestPaint()

                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.clearRect(0, 0, width, height);

                                    var centerX = width / 2;
                                    var centerY = height / 2;
                                    var radius = width / 2 - 5;

                                    // Background circle
                                    ctx.beginPath();
                                    ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
                                    ctx.lineWidth = 5;
                                    ctx.strokeStyle = "#${c.base03}";
                                    ctx.stroke();

                                    // Foreground arc
                                    ctx.beginPath();
                                    var startAngle = -Math.PI / 2;
                                    var endAngle = startAngle + (percentage / 100) * 2 * Math.PI;
                                    ctx.arc(centerX, centerY, radius, startAngle, endAngle);
                                    ctx.lineWidth = 5;
                                    ctx.strokeStyle = "#${c.base0D}";
                                    ctx.lineCap = "round";
                                    ctx.stroke();
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: Math.round(parent.percentage) + "%"
                                    color: "#${c.base05}"
                                    font.family: "${fontName}"
                                    font.pixelSize: 16
                                    font.bold: true
                                }
                            }

                            Item { Layout.preferredHeight: 6 }

                            // Filesystem Metrics (Device Size & Allocated Chunk Pool)
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: "Size:"
                                        color: "#${c.base04}"
                                        font.family: "${fontName}"
                                        font.pixelSize: 12
                                        Layout.preferredWidth: 70
                                    }
                                    Text {
                                        text: sysData.diskTotal
                                        color: "#${c.base05}"
                                        font.family: "${fontName}"
                                        font.pixelSize: 12
                                        font.bold: true
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: "Allocated:"
                                        color: "#${c.base04}"
                                        font.family: "${fontName}"
                                        font.pixelSize: 12
                                        Layout.preferredWidth: 70
                                    }
                                    Text {
                                        text: sysData.diskAllocated
                                        color: "#${c.base0D}"
                                        font.family: "${fontName}"
                                        font.pixelSize: 12
                                        font.bold: true
                                    }
                                }
                            }

                            Item { Layout.preferredHeight: 4 }

                            // Clean, elegant status badge using color code without long text literature
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Rectangle {
                                    width: 8
                                    height: 8
                                    radius: 4
                                    color: {
                                        if (sysData.diskStatusColor === "ok") return "#${c.base0B}";
                                        if (sysData.diskStatusColor === "danger") return "#${c.base09}";
                                        return "#${c.base08}";
                                    }
                                }

                                Text {
                                    text: {
                                        if (sysData.diskStatusColor === "ok") return "Pool Healthy";
                                        if (sysData.diskStatusColor === "danger") return "Pool Warning";
                                        return "Pool Critical";
                                    }
                                    color: {
                                        if (sysData.diskStatusColor === "ok") return "#${c.base0B}";
                                        if (sysData.diskStatusColor === "danger") return "#${c.base09}";
                                        return "#${c.base08}";
                                    }
                                    font.family: "${fontName}"
                                    font.pixelSize: 11
                                    font.bold: true
                                }

                                Item { Layout.fillWidth: true }

                                // Balance button (ButterManager functionality): compacts the data and
                                // metadata chunks left too empty after deleting snapshots and other
                                // filesystem cleaning operations
                                Rectangle {
                                    id: balanceButton
                                    Layout.preferredHeight: 22
                                    Layout.preferredWidth: balanceButtonRow.implicitWidth + 16
                                    radius: 11
                                    color: balanceArea.containsMouse ? "#${c.base03}" : "transparent"
                                    border.color: balanceArea.containsMouse ? "#${c.base0D}" : "transparent"
                                    border.width: 1

                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    Behavior on border.color { ColorAnimation { duration: 150 } }

                                    Row {
                                        id: balanceButtonRow
                                        anchors.centerIn: parent
                                        spacing: 5

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: ""
                                            color: balanceArea.containsMouse ? "#${c.base0D}" : "#${c.base04}"
                                            font.family: "${fontName}"
                                            font.pixelSize: 13
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "Balance"
                                            color: balanceArea.containsMouse ? "#${c.base05}" : "#${c.base04}"
                                            font.family: "${fontName}"
                                            font.pixelSize: 11
                                            font.bold: balanceArea.containsMouse
                                        }
                                    }

                                    MouseArea {
                                        id: balanceArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            // Closing the popup before starting the balance process
                                            root.sysinfoVisible = false
                                            // Dynamically define window rules to float, size, and center the balance window
                                            var hyprRules = "hyprctl eval 'sicos_balance_rule1 = hl.window_rule({ match = { class = \"sicos-balance\" }, float = true }); sicos_balance_rule2 = hl.window_rule({ match = { class = \"sicos-balance\" }, size = { 1600, 900 } }); sicos_balance_rule3 = hl.window_rule({ match = { class = \"sicos-balance\" }, center = true })'; ";
                                            // Launching the balance process with the current data and metadata
                                            // usage percentages, following the same logic as ButterManager
                                            var dataPct = Math.round(sysData.diskDataPct);
                                            var metaPct = Math.round(sysData.diskMetaPct);
                                            var scriptCmd = "if [ -f $HOME/Zero/nixos-config/home-manager/desktop/hyprland/scripts/btrfs-balance.sh ]; then $HOME/Zero/nixos-config/home-manager/desktop/hyprland/scripts/btrfs-balance.sh / " + dataPct + " " + metaPct + "; elif [ -f $HOME/.config/sicos/scripts/btrfs-balance.sh ]; then $HOME/.config/sicos/scripts/btrfs-balance.sh / " + dataPct + " " + metaPct + "; else $HOME/Zero/nixos-config/modules/sicos/hyprland/scripts/btrfs-balance.sh / " + dataPct + " " + metaPct + "; fi";
                                            cmdRunner.command = ["sh", "-c", hyprRules + "uwsm app -- kitty --class sicos-balance sh -c \"" + scriptCmd + "\""]
                                            cmdRunner.running = true
                                        }
                                    }
                                }
                            }

                            // Substantial breathing space before the used space of total allocated section
                            Item { Layout.preferredHeight: 14 }

                            // Subheader: Used space of total allocated
                            Text {
                                text: "Used space of total allocated:"
                                color: "#${c.base05}"
                                font.family: "${fontName}"
                                font.pixelSize: 12
                                font.bold: true
                            }

                            // Data Allocation Usage Bar
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: "Data"
                                        color: "#${c.base04}"
                                        font.family: "${fontName}"
                                        font.pixelSize: 11
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: sysData.diskDataPct + "%"
                                        color: "#${c.base0D}"
                                        font.family: "${fontName}"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 7
                                    radius: 3.5
                                    color: "#${c.base03}"
                                    clip: true

                                    Rectangle {
                                        height: parent.height
                                        width: Math.max(0, parent.width * (Math.min(100.0, Math.max(0.0, sysData.diskDataPct)) / 100.0))
                                        radius: 3.5
                                        color: "#${c.base0D}"

                                        Behavior on width {
                                            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                                        }
                                    }
                                }
                            }

                            // Metadata Allocation Usage Bar
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: "Metadata"
                                        color: "#${c.base04}"
                                        font.family: "${fontName}"
                                        font.pixelSize: 11
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: sysData.diskMetaPct + "%"
                                        color: "#${c.base0D}"
                                        font.family: "${fontName}"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 7
                                    radius: 3.5
                                    color: "#${c.base03}"
                                    clip: true

                                    Rectangle {
                                        height: parent.height
                                        width: Math.max(0, parent.width * (Math.min(100.0, Math.max(0.0, sysData.diskMetaPct)) / 100.0))
                                        radius: 3.5
                                        color: "#${c.base0D}"

                                        Behavior on width {
                                            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                                        }
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }
                    }
                }

                // Action Buttons (Btop, Force Kill Window, Gdu Disk Analyzer)
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    Layout.preferredHeight: 32
                    Layout.minimumHeight: 32
                    Layout.maximumHeight: 32
                    spacing: 10

                    // Btop Button
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: false
                        Layout.preferredHeight: 32
                        Layout.maximumHeight: 32
                        height: 32
                        radius: 16
                        color: btopArea.containsMouse ? "#${c.base03}" : "#${c.base02}"

                        Row {
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: ""
                                color: "#${c.base0D}"
                                font.family: "${fontName}"
                                font.pixelSize: 19
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Launch Btop"
                                color: "#${c.base04}"
                                font.family: "${fontName}"
                                font.pixelSize: 14
                            }
                        }

                        MouseArea {
                            id: btopArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.sysinfoVisible = false
                                cmdRunner.command = ["uwsm", "app", "--", "kitty", "--class", "btop", "-e", "btop"]
                                cmdRunner.running = true
                            }
                        }
                    }

                    // Force Kill Window Button
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: false
                        Layout.preferredHeight: 32
                        Layout.maximumHeight: 32
                        height: 32
                        radius: 16
                        color: killBtnArea.containsMouse ? "#33${c.base08}" : "#${c.base02}"
                        border.color: killBtnArea.containsMouse ? "#${c.base08}" : "transparent"
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        Row {
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "󰚌"
                                color: "#${c.base08}"
                                font.family: "${fontName}"
                                font.pixelSize: 19
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Kill Window"
                                color: killBtnArea.containsMouse ? "#${c.base08}" : "#${c.base04}"
                                font.family: "${fontName}"
                                font.pixelSize: 14
                                font.bold: killBtnArea.containsMouse
                            }
                        }

                        MouseArea {
                            id: killBtnArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.sysinfoVisible = false
                                // The window killer is rendered only on the screen
                                // whose sysinfo button was clicked
                                windowKillerTargetScreen = root.screen.name;
                                windowKillerActive = true
                            }
                        }
                    }

                    // Disk Analyzer Button (Gdu TUI)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: false
                        Layout.preferredHeight: 32
                        Layout.maximumHeight: 32
                        height: 32
                        radius: 16
                        color: gduArea.containsMouse ? "#${c.base03}" : "#${c.base02}"

                        Row {
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "󰋊"
                                color: "#${c.base0D}"
                                font.family: "${fontName}"
                                font.pixelSize: 19
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Disk Analyzer"
                                color: "#${c.base04}"
                                font.family: "${fontName}"
                                font.pixelSize: 14
                            }
                        }

                        MouseArea {
                            id: gduArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.sysinfoVisible = false
                                cmdRunner.command = ["uwsm", "app", "--", "kitty", "--class", "gdu", "-e", "gdu", "/"]
                                cmdRunner.running = true
                            }
                        }
                    }
                }
            }

            // Hover tracker using HoverHandler (Qt 6)
            HoverHandler {
                id: popupHoverSysinfo
                onHoveredChanged: {
                    if (hovered) {
                        root.sysinfoHovering = true;
                        sysinfoCloseTimer.stop();
                    } else {
                        root.sysinfoHovering = false;
                        sysinfoCloseTimer.start();
                    }
                }
            }
            
            Timer {
                id: sysinfoCloseTimer
                interval: 400
                repeat: false
                onTriggered: if (!root.sysinfoHovering) root.sysinfoVisible = false
            }
        }
        
        Process { id: killProc; running: false }

        Process {
            id: topProc
            property string script: "cpu_json=$(ps --no-headers -eo pid,%cpu,comm --sort=-%cpu | head -n 5 | awk '{pid=$1; val=$2; $1=\"\"; $2=\"\"; name=$0; sub(/^ +/, \"\", name); printf \"{\\\"pid\\\":\\\"%s\\\", \\\"usage\\\":\\\"%s\\\", \\\"name\\\":\\\"%s\\\"},\", pid, val, name}' | sed 's/,$//'); mem_json=$(ps --no-headers -eo pid,%mem,comm --sort=-%mem | head -n 5 | awk '{pid=$1; val=$2; $1=\"\"; $2=\"\"; name=$0; sub(/^ +/, \"\", name); printf \"{\\\"pid\\\":\\\"%s\\\", \\\"usage\\\":\\\"%s\\\", \\\"name\\\":\\\"%s\\\"},\", pid, val, name}' | sed 's/,$//'); echo \"{\\\"cpu\\\": [$cpu_json], \\\"mem\\\": [$mem_json]}\""
            
            command: ["sh", "-c", script]
            running: false
            
            stdout: StdioCollector {
                onStreamFinished: {
                    if (text !== "") {
                        try {
                            let data = JSON.parse(text.trim());
                            cpuModel.clear();
                            for (let i = 0; i < data.cpu.length; i++) {
                                cpuModel.append(data.cpu[i]);
                            }
                            ramModel.clear();
                            for (let i = 0; i < data.mem.length; i++) {
                                ramModel.append(data.mem[i]);
                            }
                        } catch (e) {
                            console.log("Error parsing JSON: " + e);
                        }
                    }
                }
            }
        }
        
        Timer {
            interval: 2500
            running: root.sysinfoVisible // Only poll when open!
            repeat: true
            onTriggered: topProc.running = true
        }
        
        onVisibleChanged: {
            if (visible) {
                topProc.running = true
                diskProc.running = true
            }
        }
    }
  '';

  widget = ''
    // SysInfo Island (CPU, RAM & Disk)
    Rectangle {
        id: sysinfoWidgetContainer
        color: hoverSysinfo.hovered ? "#${c.base03}" : "#CC${c.base01}"
        radius: 12 // Pill style
        Layout.preferredHeight: 32
        Layout.preferredWidth: 165
        
        RowLayout {
            anchors.centerIn: parent
            spacing: 12
            
            // CPU
            RowLayout {
                spacing: 4
                Text {
                    text: ""
                    color: "#${c.base05}"
                    font.family: "${fontName}"
                    font.pixelSize: 20
                }
                Text {
                    text: sysData.cpu + "%"
                    color: "#${c.base05}"
                    font.family: "${fontName}"
                    font.pixelSize: 14
                    font.bold: true
                }
            }
            
            // RAM
            RowLayout {
                spacing: 4
                Text {
                    text: ""
                    color: "#${c.base05}"
                    font.family: "${fontName}"
                    font.pixelSize: 18
                }
                Text {
                    text: sysData.ram + "%"
                    color: "#${c.base05}"
                    font.family: "${fontName}"
                    font.pixelSize: 14
                    font.bold: true
                }
            }

            // Disk
            RowLayout {
                spacing: 4
                Text {
                    text: "󰋊"
                    color: "#${c.base05}"
                    font.family: "${fontName}"
                    font.pixelSize: 18
                }
                Text {
                    text: Math.round(sysData.diskAllocPct) + "%"
                    color: "#${c.base05}"
                    font.family: "${fontName}"
                    font.pixelSize: 14
                    font.bold: true
                }
            }
        }

        // Hover tracker using HoverHandler (Qt 6)
        HoverHandler {
            id: hoverSysinfo
            onHoveredChanged: {
                if (hovered) {
                    root.sysinfoHovering = true;
                    sysinfoCloseTimerWidget.stop();
                    sysinfoOpenTimer.start();
                } else {
                    root.sysinfoHovering = false;
                    sysinfoOpenTimer.stop();
                    sysinfoCloseTimerWidget.start();
                }
            }
        }
        
        Timer {
            id: sysinfoOpenTimer
            interval: 200
            repeat: false
            onTriggered: root.sysinfoVisible = true
        }
        
        Timer {
            id: sysinfoCloseTimerWidget
            interval: 400
            repeat: false
            onTriggered: if (!root.sysinfoHovering) root.sysinfoVisible = false
        }
        
        QtObject {
            id: sysData
            property string cpu: "0"
            property string ram: "0"
            property string diskTotal: "0 GiB"
            property string diskAllocated: "0 GiB"
            property real diskAllocPct: 0.0
            property real diskUsedPct: 0.0
            property real diskDataPct: 0.0
            property real diskMetaPct: 0.0
            property string diskStatusText: "No problem, you have enough free space in your filesystem"
            property string diskStatusColor: "ok"
        }
        
        Process {
            id: cpuRamProc
            property string script: "mem=$(free | awk '/Mem:/ {printf \"%.0f\", $3/$2 * 100}'); cpu=$(vmstat 1 2 | tail -1 | awk '{print 100 - $15}'); echo \"$cpu $mem\""
            
            command: ["sh", "-c", script]
            running: false
            
            stdout: StdioCollector {
                onStreamFinished: {
                    if (text !== "") {
                        let parts = text.trim().split(" ");
                        if (parts.length === 2) {
                            sysData.cpu = parts[0];
                            sysData.ram = parts[1];
                        }
                    }
                }
            }
        }

        Process {
            id: diskProc
            property string diskScript: "if [ -x $HOME/Zero/nixos-config/home-manager/desktop/hyprland/scripts/btrfs-disk-stats.py ]; then python3 $HOME/Zero/nixos-config/home-manager/desktop/hyprland/scripts/btrfs-disk-stats.py; elif [ -x $HOME/.config/sicos/scripts/btrfs-disk-stats.py ]; then python3 $HOME/.config/sicos/scripts/btrfs-disk-stats.py; else python3 $HOME/Zero/nixos-config/modules/sicos/hyprland/scripts/btrfs-disk-stats.py; fi"

            command: ["sh", "-c", diskScript]
            running: false

            stdout: StdioCollector {
                onStreamFinished: {
                    if (text !== "") {
                        try {
                            let d = JSON.parse(text.trim());
                            sysData.diskTotal = d.total_str || "0 GiB";
                            sysData.diskAllocated = d.alloc_str || "0 GiB";
                            sysData.diskAllocPct = d.alloc_pct || 0.0;
                            sysData.diskUsedPct = d.used_pct || 0.0;
                            sysData.diskDataPct = d.data_used_pct || 0.0;
                            sysData.diskMetaPct = d.meta_used_pct || 0.0;
                            sysData.diskStatusText = d.status_text || "No problem, you have enough free space in your filesystem";
                            sysData.diskStatusColor = d.status_color || "ok";
                        } catch (e) {
                            console.log("Error parsing disk stats JSON: " + e);
                        }
                    }
                }
            }
        }
        
        Timer {
            interval: 3000
            running: true
            repeat: true
            onTriggered: cpuRamProc.running = true
            Component.onCompleted: cpuRamProc.running = true
        }

        Timer {
            interval: 10000
            running: true
            repeat: true
            onTriggered: diskProc.running = true
            Component.onCompleted: diskProc.running = true
        }
    }
  '';
}
