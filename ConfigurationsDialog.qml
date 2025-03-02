import QtQuick
import QtQuick3D
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs
import QtCore
import "." as Components

Window {
    width: minimumWidth
    height: minimumHeight
    minimumWidth: 360
    minimumHeight: 460
    maximumHeight: minimumHeight
    modality: Qt.WindowModal
    flags: Qt.Dialog
    title: "Configurations"
    color: Components.Style.colorFrame
    id: _window

    Settings {
        id: _settings
        property alias directoryModels: _modelsDirectoryEdit.text
        property alias directoryMaterials: _materialsDirectoryEdit.text
        property alias textureMapSuffixesDiffuse: _textureMapSuffixesDiffuseEdit.text
        property alias textureMapSuffixesSpecular: _textureMapSuffixesSpecularEdit.text
        property alias textureMapSuffixesNormal: _textureMapSuffixesNormalEdit.text
    }

    onVisibleChanged: {
        if (visible) {
            _applyButton.focus = true;

            if (_textureMapSuffixesDiffuseEdit.text.length === 0) {
                _textureMapSuffixesDiffuseEdit.text = _textureMapSuffixesDiffuseEdit.placeholder;
            }

            if (_textureMapSuffixesSpecularEdit.text.length === 0) {
                _textureMapSuffixesSpecularEdit.text = _textureMapSuffixesSpecularEdit.placeholder;
            }

            if (_textureMapSuffixesNormalEdit.text.length === 0) {
                _textureMapSuffixesNormalEdit.text = _textureMapSuffixesNormalEdit.placeholder;
            }
        }
    }

    FolderDialog {
        id: _folderDialog
        property var lineEdit

        onAccepted: {
            if (lineEdit) {
                var path = currentFolder.toString();
                if (path.startsWith("file:///")) {
                    path = path.substring(8);
                }

                lineEdit.text = path;
            }
        }
    }

    Flickable {
        anchors.left: parent.left
        anchors.right: parent.rigth
        anchors.top: parent.top
        anchors.bottom: _buttonsBar.top
        contentHeight: _layout.height + Components.Style.margins * 2
        contentWidth: width

        ColumnLayout {
            id: _layout
            width: _window.width - Components.Style.margins * 2
            x: Components.Style.margins
            y: Components.Style.margins
            spacing: Components.Style.margins / 2

            Components.Label {
                Layout.fillWidth: true
                text: "Models directory"
                font.bold: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: parent.spacing

                Components.LineEdit {
                    id: _modelsDirectoryEdit
                    Layout.fillWidth: true
                }

                Components.Button {
                    backgroundColor: Components.Style.colorBlock
                    radius: Components.Style.radius
                    Layout.fillHeight: true
                    implicitWidth: height
                    text: "\ue2c7"
                    font.family: Components.MaterialIconsFont.name()
                    textAntialiasing: false

                    onClicked: {
                        _folderDialog.lineEdit = _modelsDirectoryEdit;
                        _folderDialog.open();
                    }
                }
            }

            Item {
               Layout.fillWidth: true
            }

            Components.Label {
                Layout.fillWidth: true
                text: "Materials directory"
                font.bold: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: parent.spacing

                Components.LineEdit {
                    id: _materialsDirectoryEdit
                    Layout.fillWidth: true
                }

                Components.Button {
                    backgroundColor: Components.Style.colorBlock
                    radius: Components.Style.radius
                    Layout.fillHeight: true
                    implicitWidth: height
                    text: "\ue2c7"
                    font.family: Components.MaterialIconsFont.name()
                    textAntialiasing: false

                    onClicked: {
                        _folderDialog.lineEdit = _materialsDirectoryEdit;
                        _folderDialog.open();
                    }
                }
            }

            Item {
               Layout.fillWidth: true
            }

            Components.Label {
                Layout.fillWidth: true
                text: "Diffuse map suffixes"
                font.bold: true
            }

            Components.LineEdit {
                id: _textureMapSuffixesDiffuseEdit
                Layout.fillWidth: true
                placeholder: "_diffuse; _dif; _d;"
            }

            Item {
               Layout.fillWidth: true
            }

            Components.Label {
                Layout.fillWidth: true
                text: "Specular map suffixes"
                font.bold: true
            }

            Components.LineEdit {
                id: _textureMapSuffixesSpecularEdit
                Layout.fillWidth: true
                placeholder: "_specular; _spec; _s;"
            }

            Item {
               Layout.fillWidth: true
            }

            Components.Label {
                Layout.fillWidth: true
                text: "Normal map suffixes"
                font.bold: true
            }

            Components.LineEdit {
                id: _textureMapSuffixesNormalEdit
                Layout.fillWidth: true
                placeholder: "_normal; _norm; _n;"
            }
        }
    }

    Components.Frame {
        id: _buttonsBar
        color: Components.Style.colorBlock
        shadow: false
        border.width: 0
        height: _buttonsLayout.height + Components.Style.margins * 2
        x: 0
        y: _window.height - height
        width: _window.width
        radius: 0

        RowLayout {
            id: _buttonsLayout
            x: Components.Style.margins
            y: Components.Style.margins
            width: parent.width -  Components.Style.margins * 2
            spacing: Components.Style.margins

            Components.Label {
                font.pixelSize: 13
                font.bold: true
                text: "Version 1.0"
            }

            Item {
                Layout.fillWidth: true
            }

            Components.Button {
                id: _applyButton
                radius: Components.Style.radius
                backgroundColor: Components.Style.colorSection
                implicitHeight: 32
                implicitWidth: 64
                font.pixelSize: 13
                font.bold: true
                text: "Apply"

                onClicked: {
                    _window.close();
                }
            }
        }
    }

    Components.NoiseLayer {
        x: 0
        y: 0
        width: _window.width
        height: _window.height
    }
}
