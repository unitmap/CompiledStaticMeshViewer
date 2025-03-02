import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import "." as Components

Item {
    property alias border: _background.border
    property alias radius: _background.radius
    property alias color: _background.color
    property bool shadow: true

    id: _control

    Rectangle {
        id: _background
        anchors.fill: parent
        radius: Components.Style.radius
        layer.enabled: _control.shadow
        border.color: Components.Style.colorFrame
        border.width: 2
        color: Components.Style.colorFrame

        layer.effect: DropShadow {
            color: Qt.rgba(0, 0, 0, 1)
            radius: 5
            verticalOffset: 0
            samples: 16
        }
    }

    property real innerRadius: Math.round(radius - border.width)
}
