import QtQuick
import QtQuick.Controls.Basic
import Qt5Compat.GraphicalEffects
import "." as Components

Rectangle {
    radius: Components.Style.radius
    color: Components.Style.colorBlock
    border.width: 0

    property alias placeholder: _textField.placeholderText
    property alias text: _textField.text
    property alias inputMask: _textField.inputMask
    property alias focused: _textField.focus
    property alias readOnly: _textField.readOnly

    signal keyPressed(var event)
    signal editingFinished()

    implicitHeight: Math.round(_textField.height)
    id: _control

    FontMetrics {
        font.family: _textField.font.family
        font.pixelSize: _textField.font.pixelSize
        id: _fontMetrics
    }

    TextField {
        padding: 0
        anchors.left: parent.left
        anchors.right: _pasteButton.left
        anchors.verticalCenter: parent.verticalCenter
        clip: true
        color: Components.Style.colorText
        font.family: Components.RobotoFont.name()
        font.pixelSize: 14
        font.weight: 600
        id: _textField
        leftPadding: Components.Style.margins / 2
        placeholderTextColor: Qt.darker(color, 1.5)
        rightPadding: leftPadding
        selectByMouse: true
        selectedTextColor: Components.Style.colorTextHighlighted
        selectionColor: Qt.lighter(Components.Style.colorSection, 1.6)
        implicitHeight: _fontMetrics.height + Components.Style.margins

        Component.onCompleted: {
            _textField.focus = false;
        }

        background: Item {
            opacity: 0
        }

        Keys.onPressed: function(event) {
            _control.keyPressed(event);

            if (event.key === Qt.Key_Return ||
                event.key === Qt.Key_Enter) {
                event.accepted = true;
                focus = false;
                _control.editingFinished();
            }
        }

        onPressed: function(event) {
            if (event.button === Qt.RightButton) {
                if (!_textField.enabled) {
                    return;
                }

                _menu.popup()
            }
        }
    }

    Components.Button {
        id: _pasteButton
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        implicitWidth: height
        anchors.margins: 3
        radius: parent.radius - anchors.margins
        backgroundColor: Components.Style.colorBlock
        font.family: Components.MaterialIconsFont.name()
        textAntialiasing: false
        text: "\ue14f"
        font.pixelSize: height / 2

        onClicked: {
            _textField.clear();
            _textField.paste();
            _control.editingFinished();
        }
    }

    Components.ContextMenu {
        id: _menu
        useIcons: true
        itemWidth: 128

        Action {
            text: "Select all"
            enabled: _textField.length > 0
            icon.source: "\ue162"

            onTriggered: {
                _textField.selectAll();
            }
        }

        Action {
            text: "Copy"
            enabled: _textField.selectedText.length > 0
            icon.source: "\ue14d"

            onTriggered: {
                _textField.copy();
            }
        }

        Action {
            text: "Paste"
            enabled: _textField.canPaste && !_textField.readOnly
            icon.source: "\ue14f"

            onTriggered: {
                _textField.paste();
            }
        }

        Action {
            text: "Clear"
            enabled: _textField.length > 0 && !_textField.readOnly
            icon.source: "\ue5cd"

            onTriggered: {
                _textField.selectAll();
                _textField.clear();
            }
        }
    }
}
