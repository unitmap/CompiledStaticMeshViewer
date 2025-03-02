import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "." as Components

Menu {
    id: _control

    property real radius: Components.Style.radius
    property bool useIcons: false
    property int iconSize: Components.Style.fontSize * 1.2

    enter: Transition {
        NumberAnimation {
            properties: "opacity";
            from: 0
            to: 1
            duration: 100
        }
    }

    exit: Transition {
        NumberAnimation {
            properties: "opacity";
            from: 1
            to: 0
            duration: 100
        }
    }

    property real itemHeight: Components.Style.fontSize + Components.Style.margins
    property real itemWidth: 200

    delegate: MenuItem {
        id: _menuItem
        implicitWidth: _control.itemWidth
        implicitHeight: _control.itemHeight
        padding: 0

        contentItem: Item {
            implicitHeight: _control.itemHeight
            implicitWidth: _control.itemWidth
            opacity: enabled ? 1 : 0.25

            RowLayout {
                spacing: 0
                anchors.fill: parent
                anchors.leftMargin: Math.round(Components.Style.margins / 2)
                anchors.rightMargin: Math.round(Components.Style.margins / 2)
                anchors.bottomMargin: Math.round(Components.Style.margins / 2)
                anchors.topMargin: Math.round(Components.Style.margins / 2)

                Components.Label {
                    text: _control.useIcons ? _menuItem.icon.source : ""
                    Layout.fillHeight: true
                    width: height
                    visible: _control.useIcons
                    font.pixelSize: _control.iconSize
                    font.family: Components.MaterialIconsFont.name()
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    antialiasing: false

                    color: {
                        if (_menuItem.highlighted) {
                            return Components.Style.colorTextHighlighted;
                        } else {
                            return Components.Style.colorText;
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 10
                        }
                    }
                }

                Components.Label {
                    text: _menuItem.text
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.leftMargin: _control.useIcons ? Math.round(Components.Style.margins / 2) : 0

                    color: {
                        if (_menuItem.highlighted) {
                            return Components.Style.colorTextHighlighted;
                        } else {
                            return Components.Style.colorText;
                        }
                    }

                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    font.bold: true

                    Behavior on color {
                        ColorAnimation {
                            duration: 10
                        }
                    }
                }
            }
        }

        background: Rectangle {
            implicitWidth: _control.itemWidth
            implicitHeight: _control.itemHeight

            color: {
                if (!_menuItem.enabled) {
                    return Components.Style.colorTransparent;
                }

                if (_menuItem.highlighted) {
                    return Components.Style.colorAccent;
                } else {
                    return Components.Style.colorTransparent;
                }
            }

            border.width: 0
            radius: _control.radius - _control.horizontalPadding

            Behavior on color {
                ColorAnimation {
                    duration: 10
                }
            }
        }
    }

    horizontalPadding: 2
    verticalPadding: horizontalPadding

    background: Rectangle {
        color: Components.Style.colorBackground
        border.width: 0
        radius: _control.radius
        layer.enabled: true
        implicitWidth: Math.round(_control.itemWidth + horizontalPadding * 2)

        layer.effect: DropShadow {
            transparentBorder: true
            color: Qt.rgba(0, 0, 0, 0.5)
            radius: 5
            verticalOffset: 0
            samples: 16
        }
    }
}
