pragma Singleton
import QtQuick

Item {
    property real margins: 16
    property real radius: 12
    property real fontSize: 13
    property color colorTransparent: Qt.rgba(0, 0, 0, 0)
    property color colorBackground: "#242627"
    property color colorFrame: "#151718"
    property color colorBlock: "#242627"
    property color colorSection: "#2f3133"
    property color colorBorder: "#26282a"
    property color colorText: "#a1a3a5"
    property color colorTextHighlighted: "#ffffff"
    property color colorWindowCaptionText: "#dedede"
    property color colorAccent: "#005bf7"
    property color colorShadowStart: Qt.rgba(0, 0, 0, 1)
    property color colorShadowEnd: Qt.rgba(0, 0, 0, 0.0)
    property color colorButtonBackgroundDefault: Qt.rgba(0, 0, 0, 0)
    property color colorButtonBackgroundHover: "#005bf7"
    property color colorButtonBackgroundActive: "#0e3066"
    property color colorFileBrowserDirectory: "#54aeff"
    property color colorFileBrowserModel: "#c9ff66"
    property int animationTime: 300

    property var materialMapColors: [
        "#f63652",
        "#70a41c",
        "#2f84e3"
    ]
}
