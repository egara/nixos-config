{ config, lib, pkgs, c, fontName }:
''
    // Workspace Switcher
    Row {
        spacing: 6
        Repeater {
            model: Hyprland.workspaces
            
            Rectangle {
                id: workspacePill
                visible: !modelData.name.startsWith("special:")
                property bool isActive: Hyprland.focusedWorkspace != null && Hyprland.focusedWorkspace.id === modelData.id
                
                // Dynamically get the list of windows for this workspace
                property var wsWindows: {
                    var wins = [];
                    // Force binding dependency on toplevels
                    if (Hyprland.toplevels === undefined) return wins;
                    var toplevels = Array.from(Hyprland.toplevels.values);
                    
                    for (var i = 0; i < toplevels.length; i++) {
                        var w = toplevels[i];
                        if (w && w.workspace && w.workspace.id === modelData.id) {
                            var cls = w.initialClass || w["class"] || (w.wayland ? w.wayland.appId : null) || "?";
                            var title = w.title || w.initialTitle || "";
                            
                            wins.push({ "class": cls, "title": title });
                        }
                    }
                    return wins;
                }

                function resolveIconName(cls, title) {
                    var c = (cls || "").toLowerCase();
                    var t = (title || "").toLowerCase();
                    
                    // Known class overrides
                    if (c === "dev.zed.zed") return "zed";
                    
                    // Check terminal window titles for specific TUI apps
                    if (c === "kitty" || c === "alacritty" || c.indexOf("terminal") !== -1) {
                        if (t.indexOf("yazi") !== -1) return "yazi";
                        if (t.indexOf("btop") !== -1) return "btop";
                        if (t.indexOf("nvim") !== -1 || t.indexOf("neovim") !== -1) return "nvim";
                        if (t.indexOf("vim") !== -1) return "vim";
                    }
                    
                    return c;
                }

                // Dynamic width based on active state and number of apps
                width: {
                    var baseWidth = isActive ? 44 : 36;
                    var appsWidth = wsWindows.length > 0 ? (wsWindows.length * 24 + 6) : 0;
                    return baseWidth + appsWidth;
                }
                height: 36
                radius: 18
                color: isActive ? "#E6${c.base0D}" : "#CC${c.base01}"
                anchors.verticalCenter: parent.verticalCenter
                
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 200 } }

                Row {
                    anchors.centerIn: parent
                    spacing: 8

                    // Workspace Number/Name
                    Text {
                        text: modelData.name
                        color: isActive ? "#${c.base00}" : "#${c.base05}"
                        font.family: "${fontName}"
                        font.pixelSize: 16
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // Application Icons
                    Row {
                        spacing: 4
                        anchors.verticalCenter: parent.verticalCenter
                        Repeater {
                            model: workspacePill.wsWindows
                            Image {
                                source: "image://icon/" + workspacePill.resolveIconName(modelData.class, modelData.title)
                                width: 20
                                height: 20
                                sourceSize.width: 20
                                sourceSize.height: 20
                                fillMode: Image.PreserveAspectFit
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) {
                            overviewActive = !overviewActive;
                        } else {
                            Hyprland.dispatch("hl.dsp.focus({ workspace = " + modelData.id + " })")
                        }
                    }
                }
            }
        }
    }
''
