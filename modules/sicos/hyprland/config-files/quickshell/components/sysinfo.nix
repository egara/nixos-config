{ config, lib, pkgs, c, fontName }:
{
  popup = ''
    PopupWindow {
        id: sysinfoPopup
        anchor.window: root
        anchor.rect.x: 0
        anchor.rect.y: root.height
        anchor.rect.width: 120
        anchor.rect.height: 0
        anchor.edges: Edges.Bottom
        visible: root.sysinfoVisible || popupSysContent.opacity > 0
        implicitWidth: 400
        implicitHeight: 480
        color: "transparent"

        Rectangle {
            id: popupSysContent
            width: parent.width
            height: parent.height
            color: "#F0${c.base01}"
            radius: 16
            border.color: "#33${c.base05}"
            border.width: 1
            
            opacity: root.sysinfoVisible ? 1 : 0
            y: root.sysinfoVisible ? 0 : -20
            
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16
                
                // Header
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "System Monitor"
                        color: "#${c.base05}"
                        font.family: "${fontName}"
                        font.pixelSize: 18
                        Layout.fillWidth: true
                    }
                    Text {
                        text: "✕"
                        color: sysCloseArea.containsMouse ? "#${c.base05}" : "#${c.base04}"
                        font.family: "${fontName}"
                        font.pixelSize: 18
                        MouseArea {
                            id: sysCloseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.sysinfoVisible = false
                        }
                    }
                }

                // Process Lists
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
                            Canvas {
                                Layout.alignment: Qt.AlignHCenter
                                width: 80
                                height: 80
                                property real percentage: parseFloat(sysData.cpu) || 0
                                
                                onPercentageChanged: requestPaint()
                                
                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.clearRect(0, 0, width, height);
                                    
                                    var centerX = width / 2;
                                    var centerY = height / 2;
                                    var radius = width / 2 - 6;
                                    
                                    // Background circle
                                    ctx.beginPath();
                                    ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
                                    ctx.lineWidth = 6;
                                    ctx.strokeStyle = "#${c.base03}";
                                    ctx.stroke();
                                    
                                    // Foreground arc
                                    ctx.beginPath();
                                    var startAngle = -Math.PI / 2;
                                    var endAngle = startAngle + (percentage / 100) * 2 * Math.PI;
                                    ctx.arc(centerX, centerY, radius, startAngle, endAngle);
                                    ctx.lineWidth = 6;
                                    ctx.strokeStyle = "#${c.base0D}";
                                    ctx.lineCap = "round";
                                    ctx.stroke();
                                }
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: Math.round(parent.percentage) + "%"
                                    color: "#${c.base05}"
                                    font.family: "${fontName}"
                                    font.pixelSize: 15
                                    font.bold: true
                                }
                            }
                            Text {
                                text: "Top CPU"
                                color: "#${c.base0D}"
                                font.family: "${fontName}"
                                font.pixelSize: 13
                                Layout.alignment: Qt.AlignHCenter
                            }
                            ListView {
                                id: cpuList
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                model: ListModel { id: cpuModel }
                                delegate: Rectangle {
                                    width: cpuList.width
                                    height: 28
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
                                            font.pixelSize: 12
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            text: model.usage + "%"
                                            color: "#${c.base04}"
                                            font.family: "${fontName}"
                                            font.pixelSize: 12
                                        }
                                        Text {
                                            text: ""
                                            color: "#${c.base08}"
                                            font.family: "${fontName}"
                                            font.pixelSize: 12
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
                            Canvas {
                                Layout.alignment: Qt.AlignHCenter
                                width: 80
                                height: 80
                                property real percentage: parseFloat(sysData.ram) || 0
                                
                                onPercentageChanged: requestPaint()
                                
                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.clearRect(0, 0, width, height);
                                    
                                    var centerX = width / 2;
                                    var centerY = height / 2;
                                    var radius = width / 2 - 6;
                                    
                                    // Background circle
                                    ctx.beginPath();
                                    ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
                                    ctx.lineWidth = 6;
                                    ctx.strokeStyle = "#${c.base03}";
                                    ctx.stroke();
                                    
                                    // Foreground arc
                                    ctx.beginPath();
                                    var startAngle = -Math.PI / 2;
                                    var endAngle = startAngle + (percentage / 100) * 2 * Math.PI;
                                    ctx.arc(centerX, centerY, radius, startAngle, endAngle);
                                    ctx.lineWidth = 6;
                                    ctx.strokeStyle = "#${c.base0D}";
                                    ctx.lineCap = "round";
                                    ctx.stroke();
                                }
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: Math.round(parent.percentage) + "%"
                                    color: "#${c.base05}"
                                    font.family: "${fontName}"
                                    font.pixelSize: 15
                                    font.bold: true
                                }
                            }
                            Text {
                                text: "Top RAM"
                                color: "#${c.base0D}"
                                font.family: "${fontName}"
                                font.pixelSize: 13
                                Layout.alignment: Qt.AlignHCenter
                            }
                            ListView {
                                id: ramList
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                model: ListModel { id: ramModel }
                                delegate: Rectangle {
                                    width: ramList.width
                                    height: 28
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
                                            font.pixelSize: 12
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            text: model.usage + "%"
                                            color: "#${c.base04}"
                                            font.family: "${fontName}"
                                            font.pixelSize: 12
                                        }
                                        Text {
                                            text: ""
                                            color: "#${c.base08}"
                                            font.family: "${fontName}"
                                            font.pixelSize: 12
                                            visible: rowAreaRam.containsMouse
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Premium Button (Btop)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    radius: 20
                    color: btopArea.containsMouse ? "#${c.base03}" : "#${c.base02}"
                    
                    Text {
                        anchors.centerIn: parent
                        text: "Launch Full Monitor (Btop)"
                        color: "#${c.base04}"
                        font.family: "${fontName}"
                        font.pixelSize: 14
                    }
                    MouseArea {
                        id: btopArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            root.sysinfoVisible = false
                            cmdRunner.command = ["uwsm", "app", "--", "kitty", "--class", "btop", "-e", "btop"]
                            cmdRunner.running = true
                        }
                    }
                }
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
            }
        }
    }
  '';

  widget = ''
    // SysInfo Island (CPU & RAM)
    Rectangle {
        color: sysMouseArea.containsMouse ? "#${c.base03}" : "#${c.base01}"
        radius: 14 // Pill style
        Layout.preferredHeight: 28
        Layout.preferredWidth: 120
        
        RowLayout {
            anchors.centerIn: parent
            spacing: 12
            
            // CPU
            RowLayout {
                spacing: 4
                Text {
                    text: ""
                    color: "#${c.base05}" // Same as power icon
                    font.family: "${fontName}"
                    font.pixelSize: 14
                }
                Text {
                    text: sysData.cpu + "%"
                    color: "#${c.base05}"
                    font.family: "${fontName}"
                    font.pixelSize: 12
                    font.bold: true
                }
            }
            
            // RAM
            RowLayout {
                spacing: 4
                Text {
                    text: ""
                    color: "#${c.base05}" // Same as power icon
                    font.family: "${fontName}"
                    font.pixelSize: 13
                }
                Text {
                    text: sysData.ram + "%"
                    color: "#${c.base05}"
                    font.family: "${fontName}"
                    font.pixelSize: 12
                    font.bold: true
                }
            }
        }

        MouseArea {
            id: sysMouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                root.sysinfoVisible = !root.sysinfoVisible
            }
        }
        
        QtObject {
            id: sysData
            property string cpu: "0"
            property string ram: "0"
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
        
        Timer {
            interval: 3000
            running: true
            repeat: true
            onTriggered: cpuRamProc.running = true
            Component.onCompleted: cpuRamProc.running = true
        }
    }
  '';
}
