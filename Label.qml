import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import "." as Components

Text {
    property bool shadow: false
    property bool antialiasing: true

    font.family: Components.RobotoFont.name()
    color: Components.Style.colorText
    font.pixelSize: 13
    style: antialiasing ? Text.Normal : Text.Sunken
    styleColor: Components.Style.colorTransparent
    layer.enabled: shadow

    layer.effect: DropShadow {
        color: "black"
        radius: 3
    }
}
