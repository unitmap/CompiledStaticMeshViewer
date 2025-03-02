pragma Singleton
import QtQuick

Item {
    property FontLoader robotoRegular: FontLoader {
        source: "qrc:/Assets/Roboto-Regular.ttf"
    }

    function name() {
        return robotoRegular.name;
    }
}

