{ config, lib, pkgs, c, fontName }:
''
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: monitorWindow
            required property var modelData
            screen: modelData

            visible: monitorManagerActive || (modalCard.opacity > 0)

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "sicos:monitor-manager"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            Rectangle {
                id: bgDim
                anchors.fill: parent
                color: "#00000000"
                opacity: monitorManagerActive ? 0.5 : 0
                Behavior on opacity {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        monitorWindow.openDropdownIndex = -1;
                        monitorManagerActive = false;
                    }
                }
            }

            property bool kanshiEnabled: true
            property string activeProfile: ""
            property var monitorList: []
            property int selectedIndex: 0
            property int openDropdownIndex: -1

            Process {
                id: monitorStatusProc
                command: ["sh", "-c", "if [ -f $HOME/Zero/nixos-config/home-manager/desktop/hyprland/scripts/sicos-monitors.py ]; then python3 $HOME/Zero/nixos-config/home-manager/desktop/hyprland/scripts/sicos-monitors.py --status; elif [ -f $HOME/.config/sicos/scripts/sicos-monitors.py ]; then python3 $HOME/.config/sicos/scripts/sicos-monitors.py --status; else python3 $HOME/Zero/nixos-config/modules/sicos/hyprland/scripts/sicos-monitors.py --status; fi"]
                running: false
                stdout: StdioCollector {
                    onStreamFinished: {
                        if (text !== "") {
                            try {
                                var data = JSON.parse(text.trim());
                                monitorWindow.kanshiEnabled = !!data.kanshi_enabled;
                                monitorWindow.activeProfile = data.active_profile || "";
                                monitorWindow.monitorList = data.monitors || [];
                                if (monitorWindow.selectedIndex >= monitorWindow.monitorList.length) {
                                    monitorWindow.selectedIndex = Math.max(0, monitorWindow.monitorList.length - 1);
                                }
                            } catch (e) {
                                console.log("Error parsing sicos-monitors JSON: " + e);
                            }
                        }
                    }
                }
            }

            Process {
                id: monitorActionProc
                running: false
                onRunningChanged: {
                    if (!running) {
                        // Refresh status after executing toggle or mode change
                        monitorStatusProc.running = true;
                    }
                }
            }

            function toggleSelected() {
                if (monitorList.length > 0 && selectedIndex >= 0 && selectedIndex < monitorList.length) {
                    toggleMonitor(monitorList[selectedIndex]);
                }
            }

            function toggleMonitor(mon) {
                if (!mon || !mon.name) return;
                var monName = mon.name;
                var scriptCmd = "if [ -f $HOME/Zero/nixos-config/home-manager/desktop/hyprland/scripts/sicos-monitors.py ]; then python3 $HOME/Zero/nixos-config/home-manager/desktop/hyprland/scripts/sicos-monitors.py --toggle " + monName + "; elif [ -f $HOME/.config/sicos/scripts/sicos-monitors.py ]; then python3 $HOME/.config/sicos/scripts/sicos-monitors.py --toggle " + monName + "; else python3 $HOME/Zero/nixos-config/modules/sicos/hyprland/scripts/sicos-monitors.py --toggle " + monName + "; fi";
                monitorActionProc.command = ["sh", "-c", scriptCmd];
                monitorActionProc.running = true;
            }

            function setMonitorMode(monName, modeStr) {
                if (!monName || !modeStr) return;
                var scriptCmd = "if [ -f $HOME/Zero/nixos-config/home-manager/desktop/hyprland/scripts/sicos-monitors.py ]; then python3 $HOME/Zero/nixos-config/home-manager/desktop/hyprland/scripts/sicos-monitors.py --mode " + monName + " " + modeStr + "; elif [ -f $HOME/.config/sicos/scripts/sicos-monitors.py ]; then python3 $HOME/.config/sicos/scripts/sicos-monitors.py --mode " + monName + " " + modeStr + "; else python3 $HOME/Zero/nixos-config/modules/sicos/hyprland/scripts/sicos-monitors.py --mode " + monName + " " + modeStr + "; fi";
                monitorActionProc.command = ["sh", "-c", scriptCmd];
                monitorActionProc.running = true;
            }

            function setMonitorLayout(layoutStr) {
                if (!layoutStr) return;
                var scriptCmd = "if [ -f $HOME/Zero/nixos-config/home-manager/desktop/hyprland/scripts/sicos-monitors.py ]; then python3 $HOME/Zero/nixos-config/home-manager/desktop/hyprland/scripts/sicos-monitors.py --layout '" + layoutStr + "'; elif [ -f $HOME/.config/sicos/scripts/sicos-monitors.py ]; then python3 $HOME/.config/sicos/scripts/sicos-monitors.py --layout '" + layoutStr + "'; else python3 $HOME/Zero/nixos-config/modules/sicos/hyprland/scripts/sicos-monitors.py --layout '" + layoutStr + "'; fi";
                monitorActionProc.command = ["sh", "-c", scriptCmd];
                monitorActionProc.running = true;
            }

            function moveSelection(delta) {
                var count = monitorList.length;
                if (count === 0) return;
                selectedIndex = (selectedIndex + delta + count) % count;
            }

            Rectangle {
                id: modalCard
                anchors.horizontalCenter: parent.horizontalCenter
                y: monitorManagerActive ? 70 : 50
                Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                opacity: monitorManagerActive ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                width: Math.min(monitorWindow.width - 80, Math.max(headerCol.implicitWidth + 80, contentArea.implicitWidth + 80))
                height: headerCol.implicitHeight + contentArea.implicitHeight + 96
                radius: 28
                color: "#F0${c.base00}"
                border.color: "#66${c.base0D}"
                border.width: 1

                Column {
                    anchors.centerIn: parent
                    spacing: 20

                    // Modal Header (Centered Title + Centered Profile Subtitle)
                    Column {
                        id: headerCol
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 6

                        // Main Title Row
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 12

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "󰍹"
                                color: "#${c.base0D}"
                                font.family: "${fontName}"
                                font.pixelSize: 22
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Display & Monitor Manager"
                                color: "#${c.base05}"
                                font.family: "${fontName}"
                                font.pixelSize: 18
                                font.bold: true
                            }
                        }

                        // Kanshi Profile Row (Centered below Title with Stylix accent color)
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 6

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: monitorWindow.kanshiEnabled ? (monitorWindow.activeProfile !== "" ? "󰒓" : "󱃪") : "󰅚"
                                color: monitorWindow.kanshiEnabled ? "#${c.base0D}" : "#${c.base08}"
                                font.family: "${fontName}"
                                font.pixelSize: 15
                            }

                            Text {
                                id: profileText
                                anchors.verticalCenter: parent.verticalCenter
                                text: {
                                    if (!monitorWindow.kanshiEnabled) return "Kanshi Disabled";
                                    if (monitorWindow.activeProfile !== "") return "Profile: " + monitorWindow.activeProfile;
                                    return "No Profile Matched";
                                }
                                color: monitorWindow.kanshiEnabled ? "#${c.base0D}" : "#${c.base08}"
                                font.family: "${fontName}"
                                font.pixelSize: 15
                                font.bold: true
                            }
                        }
                    }

                    // Content Area (Warning if Kanshi disabled, or Monitor Cards with Canvas)
                    Item {
                        id: contentArea
                        anchors.horizontalCenter: parent.horizontalCenter
                        implicitWidth: monitorWindow.kanshiEnabled ? (monitorWindow.monitorList.length === 0 ? emptyNotice.implicitWidth : cardsColumn.implicitWidth) : kanshiDisabledBox.implicitWidth
                        implicitHeight: monitorWindow.kanshiEnabled ? (monitorWindow.monitorList.length === 0 ? emptyNotice.implicitHeight : cardsColumn.implicitHeight) : kanshiDisabledBox.implicitHeight

                        // Warning when Kanshi is disabled
                        Rectangle {
                            id: kanshiDisabledBox
                            visible: !monitorWindow.kanshiEnabled
                            anchors.centerIn: parent
                            implicitWidth: 540
                            implicitHeight: 140
                            radius: 16
                            color: "#22${c.base01}"
                            border.color: "#44${c.base08}"
                            border.width: 1

                            Column {
                                anchors.centerIn: parent
                                spacing: 10
                                width: parent.width - 48

                                Row {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    spacing: 10
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "󰅚"
                                        color: "#${c.base08}"
                                        font.family: "${fontName}"
                                        font.pixelSize: 24
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "Kanshi Integration Required"
                                        color: "#${c.base08}"
                                        font.family: "${fontName}"
                                        font.pixelSize: 16
                                        font.bold: true
                                    }
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "Dynamic monitor management and profiles in SicOS are only available when Kanshi is enabled in your NixOS configuration."
                                    color: "#${c.base04}"
                                    font.family: "${fontName}"
                                    font.pixelSize: 12
                                    horizontalAlignment: Text.AlignHCenter
                                    wrapMode: Text.Wrap
                                    width: parent.width
                                }

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: codeText.implicitWidth + 20
                                    height: 28
                                    radius: 6
                                    color: "#33${c.base00}"
                                    border.color: "#33${c.base03}"
                                    border.width: 1

                                    Text {
                                        id: codeText
                                        anchors.centerIn: parent
                                        text: "programs.sicos.hyprland.kanshi.enable = true;"
                                        color: "#${c.base0B}"
                                        font.family: "${fontName}"
                                        font.pixelSize: 12
                                    }
                                }
                            }
                        }

                        // Notice when Kanshi is enabled but no monitors detected
                        Text {
                            id: emptyNotice
                            visible: monitorWindow.kanshiEnabled && monitorWindow.monitorList.length === 0
                            anchors.centerIn: parent
                            text: "No monitors detected by Hyprland"
                            color: "#${c.base04}"
                            font.family: "${fontName}"
                            font.pixelSize: 14
                        }

                        // Column containing Arrangement Canvas and Monitor Cards Row
                        Column {
                            id: cardsColumn
                            visible: monitorWindow.kanshiEnabled && monitorWindow.monitorList.length > 0
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 16

                            // Drag & Drop Arrangement Canvas
                            Rectangle {
                                id: arrangementArea
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: Math.max(560, monitorCardsRow.implicitWidth)
                                height: 120
                                radius: 16
                                color: "#22${c.base01}"
                                border.color: "#33${c.base03}"
                                border.width: 1

                                property var activeMonitors: {
                                    var list = [];
                                    for (var i = 0; i < monitorWindow.monitorList.length; i++) {
                                        var m = monitorWindow.monitorList[i];
                                        if (m && m.enabled) {
                                            list.push(m);
                                        }
                                    }
                                    list.sort(function(a, b) {
                                        return (a.x || 0) - (b.x || 0);
                                    });
                                    return list;
                                }

                                property real totalEffectiveWidth: {
                                    var w = 0;
                                    for (var i = 0; i < activeMonitors.length; i++) {
                                        var m = activeMonitors[i];
                                        var sc = m.scale > 0 ? m.scale : 1.0;
                                        w += (m.width || 1920) / sc;
                                    }
                                    return w > 0 ? w : 1920;
                                }

                                property real canvasScale: {
                                    var availableW = arrangementArea.width - 60;
                                    var s = availableW / totalEffectiveWidth;
                                    return Math.min(s, 0.055);
                                }

                                // Arrangement Header with Instructions
                                Row {
                                    anchors {
                                        top: parent.top
                                        topMargin: 10
                                        left: parent.left
                                        leftMargin: 16
                                    }
                                    spacing: 8

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "󱤱"
                                        color: "#${c.base0D}"
                                        font.family: "${fontName}"
                                        font.pixelSize: 13
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: arrangementArea.activeMonitors.length > 1 ? "Arrange Displays (drag display cards horizontally to reposition)" : "Display Arrangement"
                                        color: "#${c.base04}"
                                        font.family: "${fontName}"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }

                                // Interactive display boxes container
                                Item {
                                    id: screensContainer
                                    anchors.centerIn: parent
                                    anchors.verticalCenterOffset: 10
                                    width: {
                                        var w = 0;
                                        for (var i = 0; i < arrangementArea.activeMonitors.length; i++) {
                                            var m = arrangementArea.activeMonitors[i];
                                            var sc = m.scale > 0 ? m.scale : 1.0;
                                            w += Math.max(90, Math.round(((m.width || 1920) / sc) * arrangementArea.canvasScale)) + 12;
                                        }
                                        return Math.max(0, w - 12);
                                    }
                                    height: 70

                                    Repeater {
                                        id: screensRepeater
                                        model: arrangementArea.activeMonitors

                                        Rectangle {
                                            id: miniScreen
                                            required property var modelData
                                            required property int index

                                            property real effWidth: (modelData.width || 1920) / (modelData.scale > 0 ? modelData.scale : 1.0)
                                            property real effHeight: (modelData.height || 1080) / (modelData.scale > 0 ? modelData.scale : 1.0)

                                            width: Math.max(90, Math.round(effWidth * arrangementArea.canvasScale))
                                            height: Math.max(46, Math.min(64, Math.round(effHeight * arrangementArea.canvasScale)))
                                            anchors.verticalCenter: parent.verticalCenter

                                            // Default target X position based on natural order
                                            property real naturalX: {
                                                var curX = 0;
                                                for (var k = 0; k < index; k++) {
                                                    var prevM = arrangementArea.activeMonitors[k];
                                                    var prevSc = prevM.scale > 0 ? prevM.scale : 1.0;
                                                    var prevW = Math.max(90, Math.round(((prevM.width || 1920) / prevSc) * arrangementArea.canvasScale));
                                                    curX += prevW + 12;
                                                }
                                                return curX;
                                            }

                                            x: naturalX

                                            radius: 8
                                            color: miniDragMouse.drag.active ? "#EE${c.base02}" : (miniDragMouse.containsMouse ? "#DD${c.base01}" : "#AA${c.base01}")
                                            border.color: miniDragMouse.drag.active ? "#${c.base0D}" : (miniDragMouse.containsMouse ? "#${c.base04}" : "#${c.base0B}")
                                            border.width: miniDragMouse.drag.active ? 2 : 1
                                            z: miniDragMouse.drag.active ? 100 : 1

                                            Behavior on x {
                                                enabled: !miniDragMouse.drag.active
                                                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                                            }

                                            Column {
                                                anchors.centerIn: parent
                                                spacing: 2

                                                Row {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    spacing: 5
                                                    Text {
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        text: miniScreen.modelData.name || ""
                                                        color: "#${c.base05}"
                                                        font.family: "${fontName}"
                                                        font.pixelSize: 11
                                                        font.bold: true
                                                    }
                                                    Rectangle {
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        visible: miniScreen.modelData.focused
                                                        width: 6
                                                        height: 6
                                                        radius: 3
                                                        color: "#${c.base0B}"
                                                    }
                                                }

                                                Text {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    text: (miniScreen.modelData.width || 0) + "x" + (miniScreen.modelData.height || 0)
                                                    color: "#${c.base04}"
                                                    font.family: "${fontName}"
                                                    font.pixelSize: 9
                                                }

                                                Text {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    text: "pos: " + (miniScreen.modelData.x || 0) + "," + (miniScreen.modelData.y || 0)
                                                    color: "#${c.base0D}"
                                                    font.family: "${fontName}"
                                                    font.pixelSize: 9
                                                }
                                            }

                                            MouseArea {
                                                id: miniDragMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: arrangementArea.activeMonitors.length > 1 ? Qt.SizeHorCursor : Qt.ArrowCursor
                                                drag.target: arrangementArea.activeMonitors.length > 1 ? parent : null
                                                drag.axis: Drag.XAxis
                                                drag.minimumX: -40
                                                drag.maximumX: screensContainer.width + 40

                                                onReleased: {
                                                    if (arrangementArea.activeMonitors.length <= 1) {
                                                        parent.x = parent.naturalX;
                                                        return;
                                                    }

                                                    // Calculate final order by horizontal center coordinate
                                                    var items = [];
                                                    for (var idx = 0; idx < screensRepeater.count; idx++) {
                                                        var it = screensRepeater.itemAt(idx);
                                                        if (it) {
                                                            items.push({
                                                                mon: it.modelData,
                                                                centerX: it.x + (it.width / 2.0),
                                                                originalIndex: idx
                                                            });
                                                        }
                                                    }

                                                    items.sort(function(a, b) {
                                                        return a.centerX - b.centerX;
                                                    });

                                                    // Check if ordering actually changed
                                                    var orderChanged = false;
                                                    for (var k = 0; k < items.length; k++) {
                                                        if (items[k].originalIndex !== k) {
                                                            orderChanged = true;
                                                            break;
                                                        }
                                                    }

                                                    if (orderChanged) {
                                                        var curXOffset = 0;
                                                        var layoutParts = [];
                                                        for (var j = 0; j < items.length; j++) {
                                                            var monItem = items[j].mon;
                                                            var s = monItem.scale > 0 ? monItem.scale : 1.0;
                                                            var effW = Math.round((monItem.width || 1920) / s);
                                                            layoutParts.push(monItem.name + ":" + curXOffset + ",0");
                                                            curXOffset += effW;
                                                        }

                                                        var layoutCmd = layoutParts.join(" ");
                                                        monitorWindow.setMonitorLayout(layoutCmd);
                                                    } else {
                                                        // Reset naturally to previous slot
                                                        for (var r = 0; r < screensRepeater.count; r++) {
                                                            var itm = screensRepeater.itemAt(r);
                                                            if (itm) itm.x = itm.naturalX;
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Monitors Cards Row
                            Row {
                                id: monitorCardsRow
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 18

                            Repeater {
                                model: monitorWindow.monitorList

                                Rectangle {
                                    id: monCard
                                    required property var modelData
                                    required property int index

                                    property bool isSelected: monitorWindow.selectedIndex === index
                                    property bool isHovered: cardMouse.containsMouse
                                    property bool isEnabled: modelData.enabled
                                    property bool dropdownOpen: monitorWindow.openDropdownIndex === index

                                    width: 290
                                    height: dropdownOpen ? 370 : 240
                                    Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                    radius: 18
                                    color: (isHovered || isSelected) ? "#55${c.base01}" : "#33${c.base01}"
                                    border.color: isEnabled ? "#${c.base0B}" : "#${c.base08}"
                                    border.width: (isHovered || isSelected) ? 2 : 1

                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    Behavior on border.color { ColorAnimation { duration: 150 } }

                                    // Card Background Click Area (only focuses / selects the card, never toggles)
                                    MouseArea {
                                        id: cardMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onEntered: monitorWindow.selectedIndex = index
                                        onClicked: {
                                            monitorWindow.selectedIndex = index;
                                            if (monitorWindow.openDropdownIndex !== -1 && monitorWindow.openDropdownIndex !== index) {
                                                monitorWindow.openDropdownIndex = -1;
                                            }
                                        }
                                    }

                                    // Status Badge (ON / OFF) at top right
                                    Rectangle {
                                        anchors.top: parent.top
                                        anchors.right: parent.right
                                        anchors.margins: 14
                                        width: statusText.implicitWidth + 16
                                        height: 24
                                        radius: 12
                                        color: isEnabled ? "#33${c.base0B}" : "#33${c.base08}"
                                        border.color: isEnabled ? "#${c.base0B}" : "#${c.base08}"
                                        border.width: 1

                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 5
                                            Rectangle {
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: 6; height: 6; radius: 3
                                                color: isEnabled ? "#${c.base0B}" : "#${c.base08}"
                                            }
                                            Text {
                                                id: statusText
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: isEnabled ? "ACTIVE" : "OFF"
                                                color: isEnabled ? "#${c.base0B}" : "#${c.base08}"
                                                font.family: "${fontName}"
                                                font.pixelSize: 10
                                                font.bold: true
                                            }
                                        }
                                    }

                                    // Display Icon, Port Name, Specs & Controls
                                    Column {
                                        anchors.top: parent.top
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.margins: 16
                                        spacing: 12

                                        Row {
                                            spacing: 12
                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: isEnabled ? "󰍹" : "󰍷"
                                                color: isEnabled ? "#${c.base0B}" : "#${c.base08}"
                                                font.family: "${fontName}"
                                                font.pixelSize: 28
                                            }

                                            Column {
                                                anchors.verticalCenter: parent.verticalCenter
                                                spacing: 3
                                                Text {
                                                    text: modelData.name || "Unknown"
                                                    color: "#${c.base05}"
                                                    font.family: "${fontName}"
                                                    font.pixelSize: 16
                                                    font.bold: true
                                                }
                                                Text {
                                                    text: {
                                                        var desc = modelData.description || (modelData.make ? (modelData.make + " " + modelData.model) : "");
                                                        return desc.length > 24 ? desc.substring(0, 23) + "…" : desc;
                                                    }
                                                    color: "#${c.base04}"
                                                    font.family: "${fontName}"
                                                    font.pixelSize: 11
                                                }
                                            }
                                        }

                                        // Specs Box
                                        Rectangle {
                                            width: parent.width - 4
                                            height: 58
                                            radius: 10
                                            color: "#22${c.base00}"
                                            border.color: "#1A${c.base05}"
                                            border.width: 1

                                            Column {
                                                anchors.centerIn: parent
                                                spacing: 6
                                                width: parent.width - 16

                                                // Current resolution row with dropdown trigger
                                                Item {
                                                    width: parent.width
                                                    height: 22

                                                    Text {
                                                        anchors.left: parent.left
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        text: "Resolution:"
                                                        color: "#${c.base04}"
                                                        font.family: "${fontName}"
                                                        font.pixelSize: 11
                                                    }

                                                    // Interactive Mode / Dropdown trigger
                                                    Rectangle {
                                                        anchors.right: parent.right
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        width: modeRowText.implicitWidth + (isEnabled && modelData.availableModes && modelData.availableModes.length > 0 ? 22 : 8)
                                                        height: 22
                                                        radius: 5
                                                        color: resTriggerMouse.containsMouse ? "#33${c.base0D}" : "transparent"
                                                        border.color: resTriggerMouse.containsMouse ? "#${c.base0D}" : "transparent"
                                                        border.width: 1

                                                        Row {
                                                            anchors.centerIn: parent
                                                            spacing: 4
                                                            Text {
                                                                id: modeRowText
                                                                anchors.verticalCenter: parent.verticalCenter
                                                                text: modelData.width > 0 ? (modelData.width + "x" + modelData.height + " @" + modelData.refreshRate + "Hz") : "Disabled"
                                                                color: isEnabled ? "#${c.base05}" : "#${c.base04}"
                                                                font.family: "${fontName}"
                                                                font.pixelSize: 11
                                                                font.bold: isEnabled
                                                            }
                                                            Text {
                                                                visible: isEnabled && modelData.availableModes && modelData.availableModes.length > 0
                                                                anchors.verticalCenter: parent.verticalCenter
                                                                text: monCard.dropdownOpen ? "󰅃" : "󰅀"
                                                                color: "#${c.base0D}"
                                                                font.family: "${fontName}"
                                                                font.pixelSize: 11
                                                            }
                                                        }

                                                        MouseArea {
                                                            id: resTriggerMouse
                                                            anchors.fill: parent
                                                            enabled: isEnabled && modelData.availableModes && modelData.availableModes.length > 0
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: {
                                                                monitorWindow.selectedIndex = index;
                                                                if (monitorWindow.openDropdownIndex === index) {
                                                                    monitorWindow.openDropdownIndex = -1;
                                                                } else {
                                                                    monitorWindow.openDropdownIndex = index;
                                                                }
                                                            }
                                                        }
                                                    }
                                                }

                                                // Scale Factor row
                                                Item {
                                                    width: parent.width
                                                    height: 18

                                                    Text {
                                                        anchors.left: parent.left
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        text: "Scale Factor:"
                                                        color: "#${c.base04}"
                                                        font.family: "${fontName}"
                                                        font.pixelSize: 11
                                                    }
                                                    Text {
                                                        anchors.right: parent.right
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        text: modelData.scale ? (modelData.scale + "x") : "1.00x"
                                                        color: "#${c.base0D}"
                                                        font.family: "${fontName}"
                                                        font.pixelSize: 11
                                                        font.bold: true
                                                    }
                                                }
                                            }
                                        }

                                        // Available Resolutions Dropdown List (Expanded)
                                        Rectangle {
                                            width: parent.width - 4
                                            height: monCard.dropdownOpen ? 110 : 0
                                            visible: monCard.dropdownOpen
                                            radius: 8
                                            color: "#F8${c.base01}"
                                            border.color: "#${c.base0D}"
                                            border.width: 1
                                            clip: true

                                            ListView {
                                                id: modesListView
                                                anchors.fill: parent
                                                anchors.margins: 4
                                                model: modelData.availableModes || []
                                                clip: true
                                                spacing: 2
                                                currentIndex: {
                                                    var modes = modelData.availableModes || [];
                                                    var curMode = (monCard.modelData.width + "x" + monCard.modelData.height).toLowerCase();
                                                    for (var i = 0; i < modes.length; i++) {
                                                        if (modes[i].toLowerCase().indexOf(curMode) !== -1) {
                                                            return i;
                                                        }
                                                    }
                                                    return -1;
                                                }

                                                Connections {
                                                    target: monCard
                                                    function onDropdownOpenChanged() {
                                                        if (monCard.dropdownOpen && modesListView.currentIndex >= 0) {
                                                            modesListView.positionViewAtIndex(modesListView.currentIndex, ListView.Center);
                                                        }
                                                    }
                                                }

                                                delegate: Rectangle {
                                                    required property var modelData
                                                    required property int index

                                                    width: parent ? parent.width : 270
                                                    height: 24
                                                    radius: 5
                                                    property bool isCur: {
                                                        var curStr = (monCard.modelData.width + "x" + monCard.modelData.height + "@" + monCard.modelData.refreshRate).toLowerCase();
                                                        return modelData.toLowerCase().indexOf(curStr) !== -1 || (monCard.modelData.width + "x" + monCard.modelData.height === modelData.split("@")[0]);
                                                    }
                                                    color: modeItemMouse.containsMouse ? "#33${c.base0D}" : (isCur ? "#22${c.base0B}" : "transparent")

                                                    Row {
                                                        anchors.fill: parent
                                                        anchors.leftMargin: 8
                                                        anchors.rightMargin: 8
                                                        spacing: 6

                                                        Text {
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            text: isCur ? "󰄬" : " "
                                                            color: "#${c.base0B}"
                                                            font.family: "${fontName}"
                                                            font.pixelSize: 11
                                                        }

                                                        Text {
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            text: modelData
                                                            color: isCur ? "#${c.base0B}" : (modeItemMouse.containsMouse ? "#${c.base05}" : "#${c.base04}")
                                                            font.family: "${fontName}"
                                                            font.pixelSize: 11
                                                            font.bold: isCur
                                                        }
                                                    }

                                                    MouseArea {
                                                        id: modeItemMouse
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            monitorWindow.selectedIndex = monCard.index;
                                                            monitorWindow.openDropdownIndex = -1;
                                                            monitorWindow.setMonitorMode(monCard.modelData.name, modelData);
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        // Toggle Button Pill (Exclusively toggles monitor when clicked)
                                        Rectangle {
                                            id: toggleButton
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            width: parent.width - 4
                                            height: 32
                                            radius: 9
                                            color: {
                                                if (toggleBtnMouse.containsMouse) {
                                                    return isEnabled ? "#${c.base08}" : "#${c.base0B}";
                                                }
                                                if (monCard.isSelected) {
                                                    return isEnabled ? "#66${c.base08}" : "#66${c.base0B}";
                                                }
                                                return isEnabled ? "#33${c.base08}" : "#33${c.base0B}";
                                            }
                                            border.color: isEnabled ? "#${c.base08}" : "#${c.base0B}"
                                            border.width: 1

                                            Behavior on color { ColorAnimation { duration: 150 } }

                                            Row {
                                                anchors.centerIn: parent
                                                spacing: 6
                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: isEnabled ? "󰈆" : "󰐥"
                                                    color: toggleBtnMouse.containsMouse ? "#${c.base00}" : (isEnabled ? "#${c.base08}" : "#${c.base0B}")
                                                    font.family: "${fontName}"
                                                    font.pixelSize: 13
                                                }
                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: isEnabled ? "Disable Display" : "Enable Display"
                                                    color: toggleBtnMouse.containsMouse ? "#${c.base00}" : (isEnabled ? "#${c.base08}" : "#${c.base0B}")
                                                    font.family: "${fontName}"
                                                    font.pixelSize: 12
                                                    font.bold: true
                                                }
                                            }

                                            MouseArea {
                                                id: toggleBtnMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    monitorWindow.selectedIndex = index;
                                                    monitorWindow.toggleMonitor(monCard.modelData);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            }

            onVisibleChanged: {
                if (visible) {
                    monitorWindow.openDropdownIndex = -1;
                    monitorStatusProc.running = true;
                    focusTimer.start();
                } else {
                    monitorWindow.openDropdownIndex = -1;
                }
            }

            Timer {
                id: focusTimer
                interval: 50
                repeat: false
                onTriggered: focusScope.forceActiveFocus()
            }

            FocusScope {
                id: focusScope
                anchors.fill: parent
                focus: true

                Keys.onLeftPressed: event => {
                    monitorWindow.openDropdownIndex = -1;
                    monitorWindow.moveSelection(-1);
                    event.accepted = true;
                }
                Keys.onRightPressed: event => {
                    monitorWindow.openDropdownIndex = -1;
                    monitorWindow.moveSelection(1);
                    event.accepted = true;
                }
                Keys.onTabPressed: event => {
                    monitorWindow.openDropdownIndex = -1;
                    if (event.modifiers & Qt.ShiftModifier) {
                        monitorWindow.moveSelection(-1);
                    } else {
                        monitorWindow.moveSelection(1);
                    }
                    event.accepted = true;
                }
                Keys.onReturnPressed: event => {
                    monitorWindow.toggleSelected();
                    event.accepted = true;
                }
                Keys.onSpacePressed: event => {
                    monitorWindow.toggleSelected();
                    event.accepted = true;
                }
                Keys.onEscapePressed: event => {
                    if (monitorWindow.openDropdownIndex !== -1) {
                        monitorWindow.openDropdownIndex = -1;
                    } else {
                        monitorManagerActive = false;
                    }
                    event.accepted = true;
                }
            }
        }
    }
''
