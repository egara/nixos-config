{ config, lib, pkgs, c, fontName }:
''
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: switcherWindow
            required property var modelData
            screen: modelData

            visible: windowSwitcherActive || (modalCard.opacity > 0)

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "sicos:window-switcher"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            Rectangle {
                id: bgDim
                anchors.fill: parent
                color: "#00000000"
                opacity: windowSwitcherActive ? 0.4 : 0
                Behavior on opacity {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: windowSwitcherActive = false
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

            function focusSelected() {
                if (selectedIndex >= 0 && selectedIndex < allWindows.length) {
                    var win = allWindows[selectedIndex];
                    if (win && win.address) {
                        var addrFormatted = "0x" + win.address.replace("0x", "");
                        Hyprland.dispatch("hl.dsp.focus({ window = 'address:" + addrFormatted + "' })");
                    }
                }
                windowSwitcherActive = false;
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
                y: windowSwitcherActive ? 70 : 50
                Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                opacity: windowSwitcherActive ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                width: Math.min(switcherWindow.width - 80, cardsRow.implicitWidth + 64)
                height: cardsRow.implicitHeight + 64
                radius: 28
                color: "#E6${c.base00}"
                border.color: "#33${c.base05}"
                border.width: 1

                Row {
                    id: cardsRow
                    anchors.centerIn: parent
                    spacing: 16

                    Repeater {
                        model: allWindows

                        Rectangle {
                            id: winCard
                            required property var modelData
                            required property int index

                            width: 200
                            height: 150
                            radius: 12
                            color: switcherWindow.selectedIndex === index ? "#55${c.base02}" : "#33${c.base01}"
                            border.color: switcherWindow.selectedIndex === index ? "#${c.base0D}" : "#44${c.base05}"
                            border.width: switcherWindow.selectedIndex === index ? 2 : 1

                            Rectangle {
                                id: thumbContainer
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.margins: 8
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
                                        captureSource: windowSwitcherActive ? modelData.wayland : null
                                        live: true
                                    }
                                }
                            }

                            Row {
                                id: infoContainer
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 8
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 8
                                height: 20

                                Image {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 16; height: 16
                                    sourceSize.width: 16; sourceSize.height: 16
                                    fillMode: Image.PreserveAspectFit
                                    source: {
                                        var cls = modelData.initialClass || modelData["class"] || (modelData.wayland ? modelData.wayland.appId : null) || "?";
                                        var title = modelData.title || modelData.initialTitle || "";
                                        return switcherWindow.resolveIconSource(cls, title);
                                    }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: {
                                        var t = modelData.title || modelData.initialTitle || "Unknown";
                                        return t.length > 18 ? t.substring(0, 17) + "…" : t;
                                    }
                                    color: switcherWindow.selectedIndex === index ? "#${c.base0D}" : "#${c.base05}"
                                    font.family: "${fontName}"
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: (modelData.workspace && modelData.workspace.name) ? modelData.workspace.name : ""
                                    color: "#${c.base04}"
                                    font.family: "${fontName}"
                                    font.pixelSize: 10
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: switcherWindow.selectedIndex = index
                                onClicked: {
                                    switcherWindow.selectedIndex = index;
                                    switcherWindow.focusSelected();
                                }
                            }
                        }
                    }
                }
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
                    focusScope.forceActiveFocus();
                }
            }

            FocusScope {
                id: focusScope
                anchors.fill: parent
                focus: true

                Keys.onLeftPressed: event => {
                    switcherWindow.moveSelection(-1);
                    event.accepted = true;
                }
                Keys.onRightPressed: event => {
                    switcherWindow.moveSelection(1);
                    event.accepted = true;
                }
                Keys.onTabPressed: event => {
                    if (event.modifiers & Qt.ShiftModifier) {
                        switcherWindow.moveSelection(-1);
                    } else {
                        switcherWindow.moveSelection(1);
                    }
                    event.accepted = true;
                }
                Keys.onReturnPressed: event => {
                    switcherWindow.focusSelected();
                    event.accepted = true;
                }
                Keys.onEscapePressed: event => {
                    windowSwitcherActive = false;
                    event.accepted = true;
                }
            }
        }
    }
''
