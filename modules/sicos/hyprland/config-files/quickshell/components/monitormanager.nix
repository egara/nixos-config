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
                width: Math.min(monitorWindow.width - 80, Math.max(headerRow.implicitWidth + 80, contentArea.implicitWidth + 80))
                height: headerRow.implicitHeight + contentArea.implicitHeight + 96
                radius: 28
                color: "#F0${c.base00}"
                border.color: "#66${c.base0D}"
                border.width: 1

                Column {
                    anchors.centerIn: parent
                    spacing: 20

                    // Modal Header
                    Row {
                        id: headerRow
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 14

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

                        // Profile Label / Indicator (Clean Stylix Accent)
                        Row {
                            anchors.verticalCenter: parent.verticalCenter
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
                                font.pixelSize: 14
                                font.bold: true
                            }
                        }

                        // Hint pill
                        Rectangle {
                            visible: monitorWindow.kanshiEnabled && monitorWindow.monitorList.length > 0
                            anchors.verticalCenter: parent.verticalCenter
                            width: hintText.implicitWidth + 14
                            height: 24
                            radius: 12
                            color: "#22${c.base05}"

                            Text {
                                id: hintText
                                anchors.centerIn: parent
                                text: "Select & click button or Space/Enter"
                                color: "#${c.base04}"
                                font.family: "${fontName}"
                                font.pixelSize: 11
                            }
                        }
                    }

                    // Content Area (Warning if Kanshi disabled, or Monitor Cards)
                    Item {
                        id: contentArea
                        anchors.horizontalCenter: parent.horizontalCenter
                        implicitWidth: monitorWindow.kanshiEnabled ? (monitorWindow.monitorList.length === 0 ? emptyNotice.implicitWidth : monitorCardsRow.implicitWidth) : kanshiDisabledBox.implicitWidth
                        implicitHeight: monitorWindow.kanshiEnabled ? (monitorWindow.monitorList.length === 0 ? emptyNotice.implicitHeight : monitorCardsRow.implicitHeight) : kanshiDisabledBox.implicitHeight

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

                        // Monitors Cards Row
                        Row {
                            id: monitorCardsRow
                            visible: monitorWindow.kanshiEnabled && monitorWindow.monitorList.length > 0
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
                                                anchors.fill: parent
                                                anchors.margins: 4
                                                model: modelData.availableModes || []
                                                clip: true
                                                spacing: 2

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
