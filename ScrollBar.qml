import QtQuick
import QtQuick.Controls.Basic
import "." as Components

ScrollBar {
    id: _control
    padding: 0

    background: Rectangle {
        radius: {
            if (_control.orientation == Qt.Vertical) {
                return width / 2;
            }

            return height / 2;
        }

        border.width: 0
        color: Components.Style.colorBlock

        implicitWidth: {
            if (_control.orientation == Qt.Vertical) {
                return _control.width;
            }

            return null;
        }

        implicitHeight: {
            if (_control.orientation == Qt.Horizontal) {
                return _control.height;
            }

            return null;
        }

        Behavior on color {
            ColorAnimation {
                duration: 100
            }
        }

        Behavior on border.color {
            ColorAnimation {
                duration: 100
            }
        }
    }

    contentItem: Rectangle {
        radius: {
            if (_control.orientation == Qt.Vertical) {
                return width / 2;
            }

            return height / 2;
        }

        border.width: 0
        color: Components.Style.colorSection

        implicitWidth: {
            if (_control.orientation == Qt.Vertical) {
                return _control.width;
            }

            return null;
        }

        implicitHeight: {
            if (_control.orientation == Qt.Horizontal) {
                return _control.height;
            }

            return null;
        }

        Behavior on color {
            ColorAnimation {
                duration: 100
            }
        }

        Behavior on border.color {
            ColorAnimation {
                duration: 100
            }
        }
    }
}
