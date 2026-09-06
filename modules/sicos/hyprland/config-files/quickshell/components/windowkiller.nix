{ config, lib, pkgs, c, fontName }:
''
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: killerWindow
            required property var modelData
            screen: modelData

            visible: windowKillerActive || (modalCard.opacity > 0)

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "sicos:window-killer"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            Rectangle {
                id: bgDim
                anchors.fill: parent
                color: "#00000000"
                opacity: windowKillerActive ? 0.5 : 0
                Behavior on opacity {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: windowKillerActive = false
                }
            }

            property var allWindows: {
                var wins = [];
                if (Hyprland.toplevels === undefined) return wins;
                var toplevels = Array.from(Hyprland.toplevels.values);
                for (var i = 0; i < toplevels.length; i++) {
                    var w = toplevels[i];
                    if (w && w.workspace && !w.workspace.name.startsWith("special:")) {
                        wins.push(w);
                    }
                }
                return wins;
            }

            property int selectedIndex: 0

            function killSelected() {
                if (selectedIndex >= 0 && selectedIndex < allWindows.length) {
                    killWindow(allWindows[selectedIndex]);
                }
            }

            function killWindow(win) {
                if (!win) return;
                var pid = null;
                if (win.lastIpcObject && win.lastIpcObject.pid) {
                    pid = win.lastIpcObject.pid;
                } else if (win.pid) {
                    pid = win.pid;
                }

                if (pid) {
                    killProcess.command = ["sh", "-c", "kill -9 " + pid];
                    killProcess.running = true;
                } else if (win.address) {
                    var addrFormatted = "0x" + win.address.replace("0x", "");
                    Hyprland.dispatch("hl.dsp.window.kill({ window = 'address:" + addrFormatted + "' })");
                }

                Qt.callLater(() => {
                    Hyprland.refreshToplevels();
                });
                windowKillerActive = false;
            }

            function moveSelection(delta) {
                var count = allWindows.length;
                if (count === 0) return;
                selectedIndex = (selectedIndex + delta + count) % count;
            }

            function resolveIconSource(cls, title) {
                var original = cls || "";
                var classLower = original.toLowerCase();
                var t = (title || "").toLowerCase();
                if (classLower === "?") return "image://icon/application-x-executable";
                if (classLower === "dev.zed.zed" || classLower === "zed") return "image://icon/zed";
                if (classLower === "kitty" || classLower === "alacritty" || classLower.indexOf("terminal") !== -1) {
                    if (t.indexOf("yazi") !== -1) return "image://icon/yazi";
                    if (t.indexOf("btop") !== -1) return "image://icon/btop";
                    if (t.indexOf("nvim") !== -1 || t.indexOf("neovim") !== -1) return "image://icon/nvim";
                    if (t.indexOf("vim") !== -1) return "image://icon/vim";
                }
                if (Quickshell.iconPath(original, true)) return "image://icon/" + original;
                if (Quickshell.iconPath(classLower, true)) return "image://icon/" + classLower;
                if (classLower.indexOf(".") !== -1) {
                    var lastPart = classLower.split(".").pop();
                    if (Quickshell.iconPath(lastPart, true)) return "image://icon/" + lastPart;
                }
                return "image://icon/application-x-executable";
            }

            Rectangle {
                id: modalCard
                anchors.horizontalCenter: parent.horizontalCenter
                y: windowKillerActive ? 70 : 50
                Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                opacity: windowKillerActive ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                width: Math.min(killerWindow.width - 80, Math.max(headerRow.implicitWidth + 64, cardsRow.implicitWidth + 64))
                height: headerRow.implicitHeight + cardsRow.implicitHeight + 84
                radius: 28
                color: "#F0${c.base00}"
                border.color: "#66${c.base08}"
                border.width: 1

                Column {
                    anchors.centerIn: parent
                    spacing: 16

                    // Modal Header
                    Row {
                        id: headerRow
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 12

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰚌"
                            color: "#${c.base08}"
                            font.family: "${fontName}"
                            font.pixelSize: 22
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Force Kill Window (SIGKILL)"
                            color: "#${c.base05}"
                            font.family: "${fontName}"
                            font.pixelSize: 18
                            font.bold: true
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: hintText.implicitWidth + 12
                            height: 22
                            radius: 11
                            color: "#33${c.base08}"

                            Text {
                                id: hintText
                                anchors.centerIn: parent
                                text: "Click or Enter to kill"
                                color: "#${c.base08}"
                                font.family: "${fontName}"
                                font.pixelSize: 11
                            }
                        }
                    }

                    // Windows Row
                    Row {
                        id: cardsRow
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 16

                        // Empty State if no windows
                        Text {
                            visible: killerWindow.allWindows.length === 0
                            text: "No active windows found to kill"
                            color: "#${c.base04}"
                            font.family: "${fontName}"
                            font.pixelSize: 14
                        }

                        Repeater {
                            model: killerWindow.allWindows

                            Rectangle {
                                id: winCard
                                required property var modelData
                                required property int index

                                property bool isSelected: killerWindow.selectedIndex === index
                                property bool isHovered: cardMouse.containsMouse

                                width: 210
                                height: 165
                                radius: 14
                                color: (isHovered || isSelected) ? "#44${c.base08}" : "#33${c.base01}"
                                border.color: (isHovered || isSelected) ? "#${c.base08}" : "#44${c.base05}"
                                border.width: (isHovered || isSelected) ? 2 : 1

                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                // Skull Tab / Badge at top of the card
                                Rectangle {
                                    id: skullTab
                                    anchors.top: parent.top
                                    anchors.topMargin: -10
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    z: 10
                                    width: 80
                                    height: 22
                                    radius: 11
                                    color: (winCard.isHovered || winCard.isSelected) ? "#${c.base08}" : "#CC${c.base02}"
                                    border.color: "#${c.base08}"
                                    border.width: 1

                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 4

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "󰚌"
                                            color: (winCard.isHovered || winCard.isSelected) ? "#${c.base00}" : "#${c.base08}"
                                            font.family: "${fontName}"
                                            font.pixelSize: 13
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "KILL"
                                            color: (winCard.isHovered || winCard.isSelected) ? "#${c.base00}" : "#${c.base08}"
                                            font.family: "${fontName}"
                                            font.pixelSize: 11
                                            font.bold: true
                                        }
                                    }
                                }

                                // Thumbnail Preview
                                Rectangle {
                                    id: thumbContainer
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.margins: 8
                                    anchors.topMargin: 16
                                    anchors.bottom: infoContainer.top
                                    anchors.bottomMargin: 8
                                    radius: 8
                                    color: "#22${c.base00}"
                                    clip: true

                                    property var geom: (modelData && modelData.lastIpcObject && modelData.lastIpcObject.size) ? modelData.lastIpcObject.size : [800, 600]
                                    property real scaleToFit: Math.min(width / geom[0], height / geom[1])

                                    Item {
                                        anchors.centerIn: parent
                                        width: thumbContainer.geom[0] * thumbContainer.scaleToFit
                                        height: thumbContainer.geom[1] * thumbContainer.scaleToFit

                                        ScreencopyView {
                                            anchors.fill: parent
                                            captureSource: windowKillerActive ? modelData.wayland : null
                                            live: true
                                        }
                                    }

                                    // Red danger tint overlay on hover/select
                                    Rectangle {
                                        anchors.fill: parent
                                        color: "#${c.base08}"
                                        opacity: (winCard.isHovered || winCard.isSelected) ? 0.15 : 0
                                        Behavior on opacity { NumberAnimation { duration: 150 } }
                                    }
                                }

                                // Info Row (Icon, Title, PID)
                                Row {
                                    id: infoContainer
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 8
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 6
                                    height: 20

                                    Image {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 16; height: 16
                                        sourceSize.width: 16; sourceSize.height: 16
                                        fillMode: Image.PreserveAspectFit
                                        source: {
                                            var cls = modelData.initialClass || modelData["class"] || (modelData.wayland ? modelData.wayland.appId : null) || "?";
                                            var title = modelData.title || modelData.initialTitle || "";
                                            return killerWindow.resolveIconSource(cls, title);
                                        }
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: {
                                            var t = modelData.title || modelData.initialTitle || "Unknown";
                                            return t.length > 14 ? t.substring(0, 13) + "…" : t;
                                        }
                                        color: (winCard.isHovered || winCard.isSelected) ? "#${c.base08}" : "#${c.base05}"
                                        font.family: "${fontName}"
                                        font.pixelSize: 11
                                        font.bold: (winCard.isHovered || winCard.isSelected)
                                        elide: Text.ElideRight
                                        width: 110
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: {
                                            var p = (modelData.lastIpcObject && modelData.lastIpcObject.pid) ? modelData.lastIpcObject.pid : (modelData.pid || "");
                                            return p ? ("PID:" + p) : "";
                                        }
                                        color: "#${c.base04}"
                                        font.family: "${fontName}"
                                        font.pixelSize: 9
                                    }
                                }

                                MouseArea {
                                    id: cardMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: killerWindow.selectedIndex = index
                                    onClicked: {
                                        killerWindow.selectedIndex = index;
                                        killerWindow.killSelected();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Process {
                id: killProcess
                running: false
            }

            onVisibleChanged: {
                if (visible) {
                    var focusedAddr = "";
                    if (Hyprland.focusedToplevel && Hyprland.focusedToplevel.address) {
                        focusedAddr = Hyprland.focusedToplevel.address;
                    }
                    var found = false;
                    for (var i = 0; i < allWindows.length; i++) {
                        if (allWindows[i].address === focusedAddr) {
                            selectedIndex = i;
                            found = true;
                            break;
                        }
                    }
                    if (!found) selectedIndex = 0;

                    focusTimer.start();
                }
            }

            Timer {
                id: focusTimer
                interval: 50
                repeat: false
                onTriggered: focusScope.forceActiveFocus()
            }

            onAllWindowsChanged: {
                if (windowKillerActive && allWindows.length === 0) {
                    windowKillerActive = false;
                }
            }

            FocusScope {
                id: focusScope
                anchors.fill: parent
                focus: true

                Keys.onLeftPressed: event => {
                    killerWindow.moveSelection(-1);
                    event.accepted = true;
                }
                Keys.onRightPressed: event => {
                    killerWindow.moveSelection(1);
                    event.accepted = true;
                }
                Keys.onTabPressed: event => {
                    if (event.modifiers & Qt.ShiftModifier) {
                        killerWindow.moveSelection(-1);
                    } else {
                        killerWindow.moveSelection(1);
                    }
                    event.accepted = true;
                }
                Keys.onReturnPressed: event => {
                    killerWindow.killSelected();
                    event.accepted = true;
                }
                Keys.onDeletePressed: event => {
                    killerWindow.killSelected();
                    event.accepted = true;
                }
                Keys.onEscapePressed: event => {
                    windowKillerActive = false;
                    event.accepted = true;
                }
            }
        }
    }
''
