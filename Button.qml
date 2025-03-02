import QtQuick
import QtQuick.Controls
import "." as Components

Rectangle {
    property alias text: _text.text
    property alias font: _text.font
    property alias textComponent: _text
    property bool autoSize: false
    property bool textAntialiasing: true

    signal clicked()

    id: _control
    state: "default"
    radius: height / 2
    border.width: 0

    property bool selected: false
    property color backgroundColor: Components.Style.colorButtonBackgroundDefault
    property color foregroundColor: Components.Style.colorText

    onSelectedChanged: {
        if (!selected) {
            if (_mouseArea.pressed) {
                _control.state = "active";
            } else {
                if (_mouseArea.containsMouse && _mouseArea.hoverEnabled) {
                    _control.state = "hover";
                } else {
                    _control.state = "default";
                }
            }
        }
    }

    onEnabledChanged: {
        if (!enabled) {
            state = "disable";
        } else {
            state = "default";
        }
    }

    Text {
        id: _text
        anchors.fill: parent
        horizontalAlignment: Qt.AlignHCenter
        verticalAlignment: Qt.AlignVCenter
        font.pixelSize: 17
        elide: Text.ElideRight
        font.family: Components.RobotoFont.name()
        style: _control.textAntialiasing ? Text.Normal : Text.Sunken
        styleColor: Components.Style.colorTransparent

        TextMetrics {
            font: _text.font
            id: _textMetrics
        }

        onTextChanged: {
            if (!_control.autoSize) {
                return;
            }

            _textMetrics.text = _text.text;
            _control.width = Math.round(_textMetrics.width + Components.Style.margins);
            _control.height = Math.round(_textMetrics.height + Components.Style.margins);
        }
    }

    states: [
        State {
            name: "disable"

            PropertyChanges {
                target: _control
                color: _control.backgroundColor
            }

            PropertyChanges {
                target: _text
                color: _control.foregroundColor
            }

            PropertyChanges {
                target: _control
                opacity: 0.25
            }
        },
        State {
            name: "default"

            PropertyChanges {
                target: _control
                color: _control.backgroundColor
            }

            PropertyChanges {
                target: _text
                color: _control.foregroundColor
            }
        },
        State {
            name: "hover"

            PropertyChanges {
                target: _control
                color: Components.Style.colorButtonBackgroundHover
            }

            PropertyChanges {
                target: _text
                color: Components.Style.colorTextHighlighted
            }
        },
        State {
            name: "active"

            PropertyChanges {
                target: _control
                color: Qt.darker(Components.Style.colorButtonBackgroundHover, 1.2)
            }

            PropertyChanges {
                target: _text
                color: Components.Style.colorTextHighlighted
            }
        },
        State {
            name: "selected"
            when: _control.selected

            PropertyChanges {
                target: _control
                color: Components.Style.colorButtonBackgroundHover
            }

            PropertyChanges {
                target: _text
                color: Components.Style.colorTextHighlighted
            }
        }
    ]

    transitions: [
        Transition {
            from: "hover"
            to: "default"

            ColorAnimation {
                target: _control
                duration: Components.Style.animationTime
            }

            ColorAnimation {
                target: _text
                duration: Components.Style.animationTime
            }
        }
    ]

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        id: _mouseArea

        onEntered: {
            if (!hoverEnabled) {
                return;
            }

            if (!_control.enabled || _control.selected) {
                return;
            }

            if (!pressed) {
                _control.state = "hover";
            }
        }

        onExited: {
            if (!hoverEnabled) {
                return;
            }

            if (!_control.enabled || _control.selected) {
                return;
            }

            if (!pressed) {
                _control.state = "default";
            }
        }

        onPressedChanged: {
            if (!_control.enabled || _control.selected) {
                return;
            }

            if (pressed) {
                _control.state = "active";
            } else {
                if (containsMouse && hoverEnabled) {
                    _control.state = "hover";
                } else {
                    _control.state = "default";
                }
            }
        }

        onClicked: {
            if (!_control.enabled) {
                return;
            }

            _control.clicked();
        }
    }
}
