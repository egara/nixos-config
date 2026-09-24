{ config, lib, pkgs, c, fontName }:
''
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: switcherWindow
            required property var modelData
            screen: modelData

            // Only the focused screen renders the overlay (empty target = render on all screens).
            // The target check must also gate the fade-out clause, otherwise
            // modalCard.opacity > 0 would make every screen visible while open.
            property bool isTargetScreen: windowSwitcherTargetScreen === "" || modelData.name === windowSwitcherTargetScreen
            visible: isTargetScreen && (windowSwitcherActive || modalCard.opacity > 0)

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

            property var rawWindows: {
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

            // Usage statistics for frequency-based ordering: how many times
            // each window address has been focused and when it was focused
            // last. Stats are session-scoped and decay over time so that
            // often and recently used windows float to the front of the list.
            property var focusCounts: ({})
            property var lastFocusTime: ({})
            property real lastDecayTime: Date.now()
            // var property mutations do not emit change signals, so this epoch
            // counter is bumped instead to make the allWindows binding re-sort.
            property int usageEpoch: 0
            // Usage score halves every 10 minutes without focus, so current
            // habits outweigh older ones instead of freezing the ranking.
            property real usageHalfLifeMs: 600000

            Connections {
                target: Hyprland
                function onRawEvent(event) {
                    // HyprlandToplevel exposes no focus-changed signal, so the
                    // activewindowv2 IPC event (address of the newly focused
                    // window) is the reliable way to track usage.
                    if (event.name === "activewindowv2") {
                        switcherWindow.noteWindowFocused(event.data);
                    }
                }
            }

            // FIFO-driven requests arrive through mainScope counters; every
            // instance receives the change, but only the target screen acts.
            Connections {
                target: mainScope
                function onWindowSwitcherCycleRequestChanged() {
                    if (switcherWindow.isTargetScreen && mainScope.windowSwitcherActive) {
                        switcherWindow.moveSelection(1);
                    }
                }
            }

            // Last window that received focus, tracked continuously. The
            // overlay itself steals keyboard focus when it maps (which nulls
            // Hyprland.focusedToplevel), so the initial selection must anchor
            // to this stored value instead of a live lookup.
            property string lastFocusedAddress: ""

            Component.onCompleted: {
                // Seed the anchor with the window focused at startup, so the
                // first Alt+Tab of the session already anchors correctly.
                if (Hyprland.focusedToplevel && Hyprland.focusedToplevel.address) {
                    lastFocusedAddress = Hyprland.focusedToplevel.address.replace("0x", "");
                }
            }

            function noteWindowFocused(addr) {
                if (!addr) return;
                // Toplevel addresses carry no 0x prefix; normalize the event
                // data so both sources always match.
                addr = addr.replace("0x", "");
                if (!addr) return;
                lastFocusedAddress = addr;
                var now = Date.now();
                var factor = Math.pow(0.5, (now - lastDecayTime) / usageHalfLifeMs);
                for (var key in focusCounts) {
                    focusCounts[key] *= factor;
                    if (focusCounts[key] < 0.01) delete focusCounts[key];
                }
                lastDecayTime = now;
                focusCounts[addr] = (focusCounts[addr] || 0) + 1;
                lastFocusTime[addr] = now;
                usageEpoch++;
            }

            function sortWindowsByUsage(wins) {
                var counts = focusCounts;
                var times = lastFocusTime;
                var arr = wins.slice();
                arr.sort(function(a, b) {
                    var ca = counts[a.address] || 0;
                    var cb = counts[b.address] || 0;
                    if (ca !== cb) return cb - ca;
                    var ta = times[a.address] || 0;
                    var tb = times[b.address] || 0;
                    if (ta !== tb) return tb - ta;
                    return 0;
                });
                return arr;
            }

            property var allWindows: {
                // Read the epoch so the list re-sorts when usage stats change
                var epoch = usageEpoch;
                return sortWindowsByUsage(rawWindows);
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
                    var focusedAddr = lastFocusedAddress;
                    var found = false;
                    for (var i = 0; i < allWindows.length; i++) {
                        if (allWindows[i].address === focusedAddr) {
                            selectedIndex = i;
                            found = true;
                            break;
                        }
                    }
                    if (!found) selectedIndex = 0;

                    // Classic Alt+Tab behavior: the same keypress that opens
                    // the overlay already moves the selection one window
                    // ahead, so a quick tap switches and releasing ALT
                    // confirms without ever needing Enter.
                    moveSelection(1);

                    // Small delay to ensure Wayland has mapped the surface before requesting focus
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
                if (windowSwitcherActive && allWindows.length === 0) {
                    windowSwitcherActive = false;
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
                Keys.onReleased: event => {
                    // Classic Alt+Tab confirm: the overlay owns keyboard
                    // focus, so releasing the ALT modifier here confirms the
                    // selection without any compositor-side bind.
                    if (event.key === Qt.Key_Alt && windowSwitcherActive) {
                        switcherWindow.focusSelected();
                        event.accepted = true;
                    }
                }
                Keys.onEscapePressed: event => {
                    windowSwitcherActive = false;
                    event.accepted = true;
                }
            }
        }
    }
''
