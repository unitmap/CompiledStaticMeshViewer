pragma Singleton
import QtQuick

Item {
    property FontLoader robotoMonoRegular: FontLoader {
        source: "qrc:/Assets/RobotoMono-Regular.ttf"
    }

    function name() {
        return robotoMonoRegular.name;
    }
}

