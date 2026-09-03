{ config, lib, pkgs, c, fontName }:
''
    Rectangle {
        id: trayIsland
        color: "#CC${c.base01}"
        radius: 14
        Layout.preferredHeight: 36
        Layout.minimumWidth: trayLayout.width + 16
        
        PopupWindow {
            id: trayMenuPopup
            anchor.window: root
            anchor.edges: Edges.Bottom
            visible: root.trayMenuVisible
            grabFocus: true
            onVisibleChanged: {
                if (!visible && root.trayMenuVisible) {
                    root.trayMenuVisible = false;
                }
            }
            implicitWidth: 260
            implicitHeight: Math.min(450, menuColumn.contentHeight + (trayMenuPopup.menuStack.length > 1 ? 50 : 20))
            color: "transparent"

            property var rootMenuModel: null
            property var currentMenuModel: null
            property var menuStack: []

            function resetMenu(menuModel, xPos) {
                trayMenuPopup.rootMenuModel = menuModel;
                trayMenuPopup.currentMenuModel = menuModel;
                trayMenuPopup.menuStack = [menuModel];
                
                anchor.rect.x = xPos - implicitWidth / 2 + 12;
                anchor.rect.y = root.height;
                anchor.rect.width = 0;
                anchor.rect.height = 0;
                
                root.trayMenuVisible = true;
            }

            function pushMenu(menuModel) {
                trayMenuPopup.menuStack = trayMenuPopup.menuStack.concat([menuModel]);
                trayMenuPopup.currentMenuModel = menuModel;
                
                if (menuModel && typeof menuModel.updateLayout === "function") {
                    menuModel.updateLayout();
                }
                
                if (menuModel && typeof menuModel.aboutToShow === "function") {
                    menuModel.aboutToShow();
                }
                
                submenuHydrator.menu = menuModel;
                try {
                    submenuHydrator.open();
                    Qt.callLater(() => {
                        try { submenuHydrator.close(); } catch(e) {}
                    });
                } catch(e) {}
            }

            function popMenu() {
                if (trayMenuPopup.menuStack.length > 1) {
                    trayMenuPopup.menuStack = trayMenuPopup.menuStack.slice(0, -1);
                    trayMenuPopup.currentMenuModel = trayMenuPopup.menuStack[trayMenuPopup.menuStack.length - 1];
                } else {
                    root.trayMenuVisible = false;
                }
            }

            Rectangle {
                id: trayPopupContent
                width: parent.width
                height: parent.height
                color: "#F0${c.base01}"
                radius: 12
                border.color: "#33${c.base05}"
                border.width: 1
                
                opacity: root.trayMenuVisible ? 1 : 0
                y: root.trayMenuVisible ? 0 : -10
                
                Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 4

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        visible: trayMenuPopup.menuStack.length > 1
                        color: backMouseArea.containsMouse ? "#33${c.base03}" : "transparent"
                        radius: 6

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            Text {
                                text: "← Volver"
                                color: "#${c.base05}"
                                font.family: "${fontName}"
                                font.pixelSize: 16
                            }
                        }

                        MouseArea {
                            id: backMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: trayMenuPopup.popMenu()
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: "#33${c.base03}"
                        visible: trayMenuPopup.menuStack.length > 1
                    }

                    QsMenuAnchor {
                        id: submenuHydrator
                        anchor.window: trayMenuPopup
                    }

                    QsMenuOpener {
                        id: rootOpener
                        menu: trayMenuPopup.rootMenuModel
                    }

                    QsMenuOpener {
                        id: subOpener
                        menu: trayMenuPopup.currentMenuModel
                    }

                    ListView {
                        id: menuColumn
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: {
                            if (trayMenuPopup.menuStack.length <= 1) return rootOpener.children;
                            let sub = subOpener.children;
                            if (sub && sub.length !== undefined && sub.length > 0) return sub;
                            if (sub && sub.count !== undefined && sub.count > 0) return sub;
                            if (trayMenuPopup.currentMenuModel && trayMenuPopup.currentMenuModel.children) return trayMenuPopup.currentMenuModel.children;
                            return sub || [];
                        }
                        spacing: 2
                        
                        delegate: Rectangle {
                            property bool isSep: modelData && modelData.isSeparator
                            width: menuColumn.width
                            height: isSep ? 1 : 32
                            color: isSep ? "#33${c.base03}" : (itemMouseArea.containsMouse ? "#33${c.base03}" : "transparent")
                            radius: isSep ? 0 : 6
                            visible: modelData && modelData.visible !== false

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 8
                                visible: !isSep

                                // Checkbox / Radio Button
                                Rectangle {
                                    Layout.preferredWidth: 16
                                    Layout.preferredHeight: 16
                                    radius: (modelData && modelData.buttonType === 2) ? 8 : 4
                                    border.color: "#${c.base05}"
                                    border.width: 1
                                    color: "transparent"
                                    visible: modelData && modelData.buttonType !== undefined && modelData.buttonType !== 0

                                    // Radio filled dot
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 8
                                        height: 8
                                        radius: (modelData && modelData.buttonType === 2) ? 4 : 2
                                        color: "#${c.base0D}"
                                        visible: modelData && modelData.checkState === 2
                                    }

                                    // Checkmark
                                    Text {
                                        anchors.centerIn: parent
                                        text: "✔"
                                        color: "#${c.base0D}"
                                        font.pixelSize: 14
                                        visible: modelData && modelData.checkState === 1
                                    }
                                }

                                Image {
                                    source: (modelData && modelData.icon) ? modelData.icon : ""
                                    visible: source != "" && (!modelData || modelData.buttonType === undefined || modelData.buttonType === 0)
                                    Layout.preferredWidth: 16
                                    Layout.preferredHeight: 16
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: {
                                        if (!modelData) return "";
                                        let t = (modelData.label || modelData.text || "").toString();
                                        return t.replace(/&/g, "");
                                    }
                                    color: (modelData && modelData.enabled === false) ? "#${c.base04}" : "#${c.base05}"
                                    font.family: "${fontName}"
                                    font.pixelSize: 16
                                    elide: Text.ElideRight
                                }

                                Text {
                                    visible: modelData && modelData.hasChildren
                                    text: "▶"
                                    color: "#${c.base04}"
                                    font.pixelSize: 13
                                }
                            }

                            MouseArea {
                                id: itemMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: !isSep
                                onClicked: {
                                    if (!modelData || modelData.enabled === false) return;
                                    
                                    if (modelData.hasChildren) {
                                        trayMenuPopup.pushMenu(modelData.menu || modelData);
                                    } else {
                                        if (modelData.activate) {
                                            modelData.activate();
                                        } else if (modelData.triggered) {
                                            modelData.triggered();
                                        }
                                        root.trayMenuVisible = false;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            id: trayLayout
            spacing: 6
            anchors.centerIn: parent

            function trayIconSourceFor(trayItem) {
                let icon = trayItem && trayItem.icon;
                if (typeof icon === 'string' || icon instanceof String) {
                    if (icon === "") return "";
                    if (icon.indexOf("?path=") !== -1) {
                        const split = icon.split("?path=");
                        if (split.length !== 2) return icon;
                        const name = split[0];
                        const path = split[1];
                        let fileName = name.substring(name.lastIndexOf("/") + 1);
                        return "file://" + path + "/" + fileName;
                    }
                    if (icon.startsWith("/") && !icon.startsWith("file://"))
                        return "file://" + icon;
                    return icon;
                }
                return "";
            }

            Repeater {
                model: SystemTray.items.values
                
                delegate: Rectangle {
                    width: 32
                    height: 32
                    radius: 16
                    color: trayMouseArea.containsMouse ? "#44${c.base03}" : "transparent"
                    
                    Image {
                        anchors.centerIn: parent
                        source: trayLayout.trayIconSourceFor(modelData)
                        width: 20
                        height: 20
                        fillMode: Image.PreserveAspectFit
                        sourceSize: Qt.size(32, 32)
                        asynchronous: true
                    }
                    
                    MouseArea {
                        id: trayMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        onClicked: (mouse) => {
                            if (mouse.button === Qt.LeftButton) {
                                if (modelData.activate) modelData.activate();
                            } else if (mouse.button === Qt.RightButton) {
                                if (modelData.menu) {
                                    let global = trayMouseArea.mapToItem(null, mouse.x, mouse.y);
                                    trayMenuPopup.resetMenu(modelData.menu, global.x);
                                } else {
                                    // Fallback just in case
                                    if (modelData.secondaryActivate) modelData.secondaryActivate();
                                }
                            } else if (mouse.button === Qt.MiddleButton) {
                                if (modelData.scroll) modelData.scroll(1, 'vertical');
                            }
                        }
                    }
                }
            }
        }
    }
''
