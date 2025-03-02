import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts
import QtQuick.Dialogs
import "." as Components

Components.Frame {
    shadow: false
    color: Components.Style.colorBlock
    border.width: 0
    id: _control

    property bool mapIsAlpha: false
    property string mapName: ""
    property string filename: ""
    property alias text: _titleLabel.text
    property alias socketColor: _socket.color

    signal openImage(string filename)
    signal closeFile()

    FileDialog {
        id: _fileOpenDialog
        fileMode: FileDialog.OpenFile

        nameFilters: [
            "Image files (*.jpg; *.bmp; *.png; *.dds)"
        ]

        onAccepted: {
            openImage(selectedFile.toString().substr(8));
        }
    }

    Components.Label {
        id: _titleLabel
        anchors.left: parent.left
        anchors.right: _socket.left
        anchors.top: parent.top
        anchors.margins: _mask.anchors.margins
        font.bold: true
    }

    Rectangle {
        id: _socket
        width: height
        height: 12
        radius: height / 2
        border.width: 0
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: _mask.anchors.margins
    }

    Rectangle {
        id: _mask
        opacity: 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: _titleLabel.bottom
        anchors.margins: Components.Style.margins
        anchors.bottom: _buttonLayout.top
        radius: parent.radius - anchors.margins / 2
    }

    Image {
        anchors.fill: _mask
        fillMode: Image.Tile
        source: "qrc:/Assets/Background.png"
        layer.enabled: true
        visible: _control.mapIsAlpha || _mapImage.status !== Image.Ready

        layer.effect: OpacityMask {
            maskSource: _mask
        }
    }

    function resetSource() {
        var old = _mapImage.source;
        _mapImage.source = "";
        _mapImage.source = old;
    }

    onMapNameChanged: {
        _mapImage.source = "image://imageprovider/" + _control.mapName;
    }

    Image {
        id: _mapImage

        cache: false
        anchors.fill: _mask
        fillMode: Image.PreserveAspectFit
        layer.enabled: true

        layer.effect: OpacityMask {
            maskSource: _mask
        }
    }

    Components.Label {
        font.family: Components.MaterialIconsFont.name()
        antialiasing: false
        text: "\ue3ad"
        anchors.centerIn: _mask
        visible: _mapImage.status !== Image.Ready
        color: Components.Style.colorBlock
        font.bold: true
        font.pixelSize: 42
    }

    RowLayout {
        id: _buttonLayout
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 32
        anchors.margins: _mask.anchors.margins
        spacing: 0

        Components.Button {
            Layout.fillHeight: true
            implicitWidth: height
            radius: _mask.radius
            backgroundColor: Components.Style.colorSection
            font.family: Components.MaterialIconsFont.name()
            textAntialiasing: false
            text: "\ue2c7"
            font.bold: true

            onClicked: {
                _fileOpenDialog.open();
            }
        }

        Item {
            Layout.fillWidth: true
        }

        Components.Button {
            Layout.fillHeight: true
            implicitWidth: height
            radius: _mask.radius
            backgroundColor: Components.Style.colorSection
            font.family: Components.MaterialIconsFont.name()
            textAntialiasing: false
            text: "\ue8f4"
            font.bold: true
            enabled: _mapImage.status === Image.Ready

            onClicked: {
                Qt.openUrlExternally("file:///" + _control.filename)
            }
        }
    }
}
