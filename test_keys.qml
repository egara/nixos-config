import Quickshell

PopupWindow {
    id: root
    Component.onCompleted: {
        for (var prop in root) {
            if (prop.toLowerCase().indexOf("key") !== -1 || prop.toLowerCase().indexOf("focus") !== -1) {
                console.log(prop + " = " + root[prop]);
            }
        }
        Qt.quit();
    }
}
