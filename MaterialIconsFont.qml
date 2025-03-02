pragma Singleton
import QtQuick

Item {
    property FontLoader materialIconsRegular: FontLoader {
        source: "qrc:/Assets/MaterialIcons-Regular.ttf"
    }

    function name() {
        return materialIconsRegular.name;
    }
}

