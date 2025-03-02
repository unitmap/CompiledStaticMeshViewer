import QtQuick
import QtQuick3D
import QtCore
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick3D.Effects
import Qt5Compat.GraphicalEffects
import QtQuick3D.Helpers
import Qt.labs.folderlistmodel
import Qt.labs.qmlmodels
import QtQuick.Controls.Basic as Basic
import "." as Components

Window {
    width: minimumWidth
    height: minimumHeight
    minimumWidth: 800
    minimumHeight: 600
    visible: true
    title: "Compiled static mesh viewer"
    color: Components.Style.colorBackground
    id: _window

    onClosing: {
        visibility = Window.Windowed;
        _settings.setValue("contentBarHeight", _splitView.saveState());
    }

    onVisibleChanged: {
        if (visible) {
            Components.WindowsHelper.setWindowCaptionColor(Components.Style.colorFrame,
                Components.Style.colorFrame, Components.Style.colorWindowCaptionText);
        }
    }

    Component.onCompleted: {
        if (_fileBrowserPathEdit.text.length === 0 ||
            !Components.WindowsHelper.directoryExists(_fileBrowserPathEdit.text)) {
            _fileBrowserModel.setUrl(StandardPaths.writableLocation(StandardPaths.DocumentsLocation));
        } else {
            _fileBrowserPathEdit.apply();
        }

        _splitView.restoreState(_settings.value("contentBarHeight"));

        if (Qt.application.arguments.length > 1) {
            openFile("file:///" + Components.WindowsHelper.normalizePath(Qt.application.arguments[1]));
        }
    }

    function resetView() {
        var x = Math.abs(_modelFile.boundingBoxMin.x + _modelFile.boundingBoxMax.x);
        var y = Math.abs(_modelFile.boundingBoxMin.y + _modelFile.boundingBoxMax.y);
        var z = Math.abs(_modelFile.boundingBoxMin.z + _modelFile.boundingBoxMax.z);

        _camera.z = Math.max(x, y, z) * 2;
        _cameraNode.position = Qt.vector3d(0, 0, 0);
        _cameraNode.eulerRotation = Qt.vector3d(0, 90, 0);
    }

    function validCameraZoom() {
        if (_camera.z < _cameraController.minZoom) {
            _camera.z = _cameraController.minZoom;
        } else if (_camera.z > _cameraController.maxZoom) {
            _camera.z = _cameraController.maxZoom;
        }
    }

    function zoomIn() {
        _camera.z += _camera.z * 0.1 * (-400 * 0.01);
        validCameraZoom();
    }

    function zoomOut() {
        _camera.z += _camera.z * 0.1 * (400 * 0.01);
        validCameraZoom();
    }

    function openFile(filename) {
        console.log(filename)
        _model.materials = [];
        _materialList.updateList();

        if (!_modelFile.loadCompiledStaticMesh(filename)) {
            Components.WindowsHelper.errorMessageBox("Could not open file: " + filename);
            return;
        }

        var materialDirectories = [];

        var directory = _settings.value("directoryMaterials");
        if (Components.WindowsHelper.directoryExists(
            Components.WindowsHelper.normalizePath(directory) + "/")) {
            materialDirectories.push(directory);
        }

        for (directory of _modelFile.materialDirectories) {
            materialDirectories.push(Components.WindowsHelper.normalizePath(directory) + "/");
        }

        var component = Qt.createComponent("Material.qml");

        for (const materialName of _modelFile.materials) {
            var material = component.createObject(_model);
            material.find(materialName, materialDirectories);
            _model.materials.push(material);
        }

        _materialList.updateList();
        resetView();
    }

    Settings {
        id: _settings
        property alias windowLeft: _window.x
        property alias windowTop: _window.y
        property alias windowWidth: _window.width
        property alias windowHeight: _window.height
        property alias contentBarVisible: _contentBar.visible
        property alias contentBarUseFilter: _fileBrowserFilterButton.selected
        property alias contentBarGridMode: _fileListGridView.visible
        property alias contentBarDirectory: _fileBrowserPathEdit.text
    }

    Components.ConfigurationsDialog {
        id: _configurationsDialog
    }

    FileDialog {
        id: _fileOpenDialog
        fileMode: FileDialog.OpenFile

        nameFilters: [
            "Compiled static mesh (*.csm)"
        ]

        onAccepted: {
            openFile(selectedFile);
        }
    }

    SplitView {
        anchors.fill: parent
        orientation: Qt.Vertical
        id: _splitView

        handle: Item {
            id: _splitViewHandle
            implicitWidth: Components.Style.margins / 2
            implicitHeight: implicitWidth

            Components.Frame {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: parent.height / 2
                radius: 0
                border.width: 0
            }

            Rectangle {
                anchors.fill: parent
                color: Components.Style.colorFrame
            }

            Components.NoiseLayer {
                anchors.fill: parent
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.SizeVerCursor
            }

            onYChanged: {
                if (SplitHandle.pressed) {
                    if (_contentBar.SplitView.minimumHeight > _contentBar.height - 1) {
                        _contentBar.visible = false;
                    }
                }
            }
        }

        /*
            Model view
        */
        Item {
            SplitView.minimumHeight: parent.height / 4
            SplitView.fillHeight: true

            /*
                Background
            */
            Image {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                fillMode: Image.Tile
                id: _background
                source: "qrc:/Assets/Background.png"
            }

            /*
                Scene
            */
            View3D {
                id: _scene
                anchors.fill: _background

                environment: ExtendedSceneEnvironment  {
                    tonemapMode: (_light.off || _debugSettings.mode !== DebugSettings.None) ?
                        SceneEnvironment.TonemapModeLinear : SceneEnvironment.TonemapModeFilmic
                    backgroundMode: SceneEnvironment.Transparent
                    glowEnabled: !(_light.off || _debugSettings.mode !== DebugSettings.None)
                    glowBloom: 1
                    glowStrength: 1
                    glowUseBicubicUpscale: !(_light.off || _debugSettings.mode !== DebugSettings.None)
                    whitePoint: 0.3
                    clearColor: Qt.rgba(0, 0, 0, 0)

                    debugSettings: DebugSettings{
                        id: _debugSettings
                        property int mode: DebugSettings.None

                        materialOverride: {
                            if (mode === DebugSettings.None) {
                                if (_light.off) {
                                    return DebugSettings.BaseColor;
                                }

                                return DebugSettings.None;
                            }

                            return mode;
                        }
                    }
                }

                Node {
                    id: _cameraNode
                    eulerRotation: Qt.vector3d(0, 90, 0)

                    PerspectiveCamera {
                        id: _camera
                        clipNear: 0.1
                        clipFar: _cameraController.maxZoom * 2

                        PointLight {
                            visible: false
                            brightness: 1
                            id: _flashlight
                            color: Qt.rgba(1.0 * colorOpacity, 1.0 * colorOpacity, 1.5 * colorOpacity, 1.0)
                            property real colorOpacity: 0.5
                        }

                        SpotLight {
                            brightness: _flashlight.brightness * 10
                            visible: _flashlight.visible
                            color: _flashlight.color
                        }
                    }
                }

                Node {
                    eulerRotation: Qt.vector3d(_lightAngleController.value, 180 - _lightRotateController.angle, 0)

                    DirectionalLight {
                        color: off ? Qt.rgba(1, 1, 1, 1.0) :
                            Qt.rgba(1.0 * colorOpacity, 1.0 * colorOpacity, 1.1 * colorOpacity, 1.0)
                        ambientColor: off ? Qt.rgba(1, 1, 1, 1.0) :
                            Qt.rgba(1 * shadowOpacity, 1 * shadowOpacity, 1.2 * shadowOpacity, 1)
                        brightness: 1
                        id: _light
                        castsShadow: !off
                        shadowMapQuality: Light.ShadowMapQualityVeryHigh
                        shadowFactor: 100 * (1 - shadowOpacity)
                        shadowMapFar: _camera.clipFar

                        property bool off: false
                        property real shadowOpacity: 0.15
                        property real colorOpacity: 0.9
                    }
                }

                Node {
                    id: _modelNode

                    position: {
                        var x = (_modelFile.boundingBoxMin.x + _modelFile.boundingBoxMax.x) / 2.0;
                        var y = (_modelFile.boundingBoxMin.y + _modelFile.boundingBoxMax.y) / 2.0;
                        var z = (_modelFile.boundingBoxMin.z + _modelFile.boundingBoxMax.z) / 2.0;

                        return Qt.vector3d(-x, -y, -z);
                    }

                    Components.Model {
                        id: _modelFile
                    }

                    Model {
                        id: _model
                        geometry: _modelFile.modelGeometry
                    }

                    Model {
                        id: _normalsModel
                        geometry: _modelFile.normalGeometry
                        visible: false
                        castsShadows: false
                        receivesShadows: false

                        materials: [
                            DefaultMaterial {
                                lighting: DefaultMaterial.NoLighting
                                diffuseColor: Qt.rgba(255 / 255, 0 / 255, 80 / 255, 1)
                            }
                        ]
                    }

                    Model {
                        id: _gridModel
                        geometry: _modelFile.gridGeometry
                        visible: false
                        castsShadows: false
                        receivesShadows: false

                        materials: [
                            DefaultMaterial {
                                lighting: DefaultMaterial.NoLighting
                                diffuseColor: Qt.rgba(0 / 255, 255 / 255, 106 / 255, 1)
                            }
                        ]
                    }
                }

                Item {
                    id: _cameraController
                    anchors.fill: parent
                    readonly property bool inputsNeedProcessing: _inputProcessor.rotateProcess || _inputProcessor.panningProcess
                    property real maxZoom: 9000
                    property real defaultZoom: 8
                    property real minZoom: 1

                    DragHandler {
                        target: null
                        acceptedButtons: Qt.LeftButton
                        acceptedModifiers: Qt.NoModifier

                        onCentroidChanged: {
                            _cameraController.mouseMoved(
                                Qt.vector2d(centroid.position.x, centroid.position.y), false);
                        }

                        onActiveChanged: {
                            if (active) {
                                _cameraController.mousePressed(
                                    Qt.vector2d(centroid.position.x, centroid.position.y));
                            } else {
                                _cameraController.mouseReleased(
                                    Qt.vector2d(centroid.position.x, centroid.position.y));
                            }
                        }
                    }

                    DragHandler {
                        target: null
                        acceptedButtons: Qt.RightButton | Qt.MiddleButton
                        acceptedModifiers: Qt.NoModifier

                        onCentroidChanged: {
                            _cameraController.panningEvent(
                                Qt.vector2d(centroid.position.x, centroid.position.y));
                        }

                        onActiveChanged: {
                            if (active) {
                                _cameraController.startPanning(
                                    Qt.vector2d(centroid.position.x, centroid.position.y));
                            } else {
                                _cameraController.endPanning();
                            }
                        }
                    }

                    PinchHandler {
                        target: null
                        property real distance: 0

                        onCentroidChanged: {
                            _cameraController.panningEvent(
                                Qt.vector2d(centroid.position.x, centroid.position.y))
                        }

                        onActiveChanged: {
                            if (active) {
                                _cameraController.startPanning(
                                    Qt.vector2d(centroid.position.x, centroid.position.y))
                                distance = _camera.z;
                            } else {
                                _cameraController.endPanning()
                                distance = 0;
                            }
                        }

                        onScaleChanged: {
                            _camera.z = distance * (1 / scale);
                            validCameraZoom();
                        }
                    }

                    TapHandler {
                        onTapped: _cameraController.forceActiveFocus()
                    }

                    WheelHandler {
                        orientation: Qt.Vertical
                        target: null

                        onWheel: function(event) {
                            _camera.z += _camera.z * 0.1 * (-event.angleDelta.y * 0.01)
                            validCameraZoom();
                        }
                    }

                    function mousePressed(position) {
                        _cameraController.forceActiveFocus()
                        _inputProcessor.currentPosition = position
                        _inputProcessor.lastPosition = position
                        _inputProcessor.rotateProcess = true;
                    }

                    function mouseReleased(position) {
                        _inputProcessor.rotateProcess = false;
                    }

                    function mouseMoved(position) {
                        _inputProcessor.currentPosition = position;
                    }

                    function startPanning(position) {
                        _inputProcessor.panningProcess = true;
                        _inputProcessor.currentViewPosition = position;
                        _inputProcessor.lastViewPosition = position;
                    }

                    function endPanning() {
                        _inputProcessor.panningProcess = false;
                    }

                    function panningEvent(newPos: vector2d) {
                        _inputProcessor.currentViewPosition = newPos;
                    }

                    FrameAnimation {
                        running: _cameraController.inputsNeedProcessing

                        onTriggered: {
                            _inputProcessor.processInput(frameTime * 100)
                        }
                    }

                    QtObject {
                        id: _inputProcessor

                        property vector2d lastPosition: Qt.vector2d(0, 0)
                        property vector2d lastViewPosition: Qt.vector2d(0, 0)
                        property vector2d currentPosition: Qt.vector2d(0, 0)
                        property vector2d currentViewPosition: Qt.vector2d(0, 0)
                        property vector2d sensitivity: Qt.vector2d(0.1, 0.1)
                        property bool rotateProcess: false
                        property bool panningProcess: false

                        function processInput(frameDelta) {
                            if (rotateProcess) {
                                var rotationVector = _cameraNode.eulerRotation;
                                var delta = Qt.vector2d(lastPosition.x - currentPosition.x,
                                    lastPosition.y - currentPosition.y);

                                var rotateX = delta.x * sensitivity.x * frameDelta
                                rotationVector.y += rotateX;

                                var rotateY = delta.y * -sensitivity.y * frameDelta
                                rotateY = -rotateY;
                                rotationVector.x += rotateY;

                                _cameraNode.setEulerRotation(rotationVector);
                                lastPosition = currentPosition;
                            }

                            if (panningProcess) {
                                delta = currentViewPosition.minus(lastViewPosition);
                                delta.x = -delta.x
                                delta.x = (delta.x / _cameraController.width) * _camera.z * frameDelta
                                delta.y = (delta.y / _cameraController.height) * _camera.z * frameDelta

                                var velocity = Qt.vector3d(0, 0, 0)
                                velocity = velocity.plus(
                                    Qt.vector3d(
                                        _cameraNode.right.x * delta.x,
                                        _cameraNode.right.y * delta.x,
                                        _cameraNode.right.z * delta.x
                                    )
                                );

                                velocity = velocity.plus(
                                    Qt.vector3d(
                                        _cameraNode.up.x * delta.y,
                                        _cameraNode.up.y * delta.y,
                                        _cameraNode.up.z * delta.y
                                    )
                                );

                                _cameraNode.position = _cameraNode.position.plus(velocity)
                                lastViewPosition = currentViewPosition
                            }
                        }
                    }
                }
            }

            /*
                Info
            */
            GridLayout {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Components.Style.margins
                columns: 2
                columnSpacing: anchors.margins / 2
                rowSpacing: columnSpacing

                Components.Label {
                    font.family: Components.RobotoMonoFont.name()
                    shadow: true
                    Layout.alignment: Qt.AlignRight
                    color: "#ffffff"
                    text: "Version"
                    antialiasing: false
                }

                Components.Label {
                    font.family: Components.RobotoMonoFont.name()
                    shadow: true
                    color: "#00ff6a"
                    text: _modelFile.version === 0 ? "-" : _modelFile.version
                    antialiasing: false
                }

                Components.Label {
                    font.family: Components.RobotoMonoFont.name()
                    shadow: true
                    Layout.alignment: Qt.AlignRight
                    color: "#ffffff"
                    text: "Vertices"
                    antialiasing: false
                }

                Components.Label {
                    font.family: Components.RobotoMonoFont.name()
                    shadow: true
                    color: "#00ff6a"
                    text: _modelFile.vertexCount
                    antialiasing: false
                }

                Components.Label {
                    font.family: Components.RobotoMonoFont.name()
                    shadow: true
                    Layout.alignment: Qt.AlignRight
                    color: "#ffffff"
                    text: "Vertex data"
                    antialiasing: false
                }

                Components.Label {
                    font.family: Components.RobotoMonoFont.name()
                    shadow: true
                    color: "#00ff6a"
                    text: _fileBrowserModel.formatBytes(_modelFile.vertexDataSize)
                    antialiasing: false
                }

                Components.Label {
                    font.family: Components.RobotoMonoFont.name()
                    shadow: true
                    Layout.alignment: Qt.AlignRight
                    color: "#ffffff"
                    text: "Faces"
                    antialiasing: false
                }

                Components.Label {
                    font.family: Components.RobotoMonoFont.name()
                    shadow: true
                    color: "#00ff6a"
                    text: _modelFile.faceCount
                    antialiasing: false
                }

                Components.Label {
                    font.family: Components.RobotoMonoFont.name()
                    shadow: true
                    Layout.alignment: Qt.AlignRight
                    color: "#ffffff"
                    text: "Face data"
                    antialiasing: false
                }

                Components.Label {
                    font.family: Components.RobotoMonoFont.name()
                    shadow: true
                    color: "#00ff6a"
                    text: _fileBrowserModel.formatBytes(_modelFile.faceDataSize)
                    antialiasing: false
                }

                Components.Label {
                    font.family: Components.RobotoMonoFont.name()
                    shadow: true
                    Layout.alignment: Qt.AlignRight
                    color: "#ffffff"
                    text: "Materials"
                    antialiasing: false
                }

                Components.Label {
                    font.family: Components.RobotoMonoFont.name()
                    shadow: true
                    color: "#00ff6a"
                    text: _modelFile.materialCount
                    antialiasing: false
                }
            }

            /*
                Drop area
            */
            DropArea {
                anchors.fill: parent

                onEntered: function(event) {
                    if (!event.urls || event.urls.length === 0) {
                        event.accepted = false;
                        return;
                    }

                    event.accepted = true;
                }

                onDropped: function(event) {
                    if (!event.urls || event.urls.length === 0) {
                        return;
                    }

                    openFile(event.urls[0]);
                }
            }

            /*
                Tool bar
            */
            Components.Frame {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: Components.Style.margins
                width: Math.round(_toolButtonsLayout.width + border.width * 2)
                height: Math.round(_toolButtonsLayout.height + border.width * 2)
                radius: Components.Style.radius
                id: _toolButtonsLayoutFrame

                RowLayout {
                    id: _toolButtonsLayout
                    spacing: 2
                    height: Math.round(Components.Style.margins * 2)
                    x: _toolButtonsLayoutFrame.border.width
                    y: _toolButtonsLayoutFrame.border.width

                    Components.Button {
                        Layout.fillHeight: true
                        font.family: Components.MaterialIconsFont.name()
                        implicitWidth: height
                        radius: _toolButtonsLayoutFrame.innerRadius
                        text: "\ue2c7"
                        textAntialiasing: false

                        onClicked: {
                            _fileOpenDialog.open();
                        }
                    }

                    Components.Button {
                        Layout.fillHeight: true
                        font.family: Components.MaterialIconsFont.name()
                        implicitWidth: height
                        radius: _toolButtonsLayoutFrame.innerRadius
                        text: "\ue8b8"
                        textAntialiasing: false

                        onClicked: {
                            _configurationsDialog.show();
                        }
                    }
/*
                    Components.Button {
                        Layout.fillHeight: true
                        implicitWidth: height
                        text: "\ue89c"
                        radius: _toolButtonsLayoutFrame.innerRadius
                        font.family: Components.MaterialIconsFont.name()
                        textAntialiasing: false
                    }
*/

                    Rectangle {
                        width: 1
                        Layout.fillHeight: true
                        Layout.topMargin: _toolButtonsLayoutFrame.border.width * 4
                        Layout.bottomMargin: Layout.topMargin
                        Layout.leftMargin: _toolButtonsLayoutFrame.border.width * 2
                        Layout.rightMargin: Layout.leftMargin
                        color: Components.Style.colorBorder
                    }

                    Components.Button {
                        Layout.fillHeight: true
                        implicitWidth: height
                        text: "\uf053"
                        radius: _toolButtonsLayoutFrame.innerRadius
                        font.family: Components.MaterialIconsFont.name()
                        textAntialiasing: false

                        onClicked: {
                            resetView();
                        }
                    }

                    Components.Button {
                        Layout.fillHeight: true
                        implicitWidth: height
                        text: "\ue56b"
                        radius: _toolButtonsLayoutFrame.innerRadius
                        font.family: Components.MaterialIconsFont.name()
                        textAntialiasing: false

                        onClicked: {
                            zoomIn();
                        }
                    }

                    Components.Button {
                        Layout.fillHeight: true
                        implicitWidth: height
                        text: "\ueb2d"
                        radius: _toolButtonsLayoutFrame.innerRadius
                        font.family: Components.MaterialIconsFont.name()
                        textAntialiasing: false

                        onClicked: {
                            zoomOut();
                        }
                    }

                    Rectangle {
                        width: 1
                        Layout.fillHeight: true
                        Layout.topMargin: _toolButtonsLayoutFrame.border.width * 4
                        Layout.bottomMargin: Layout.topMargin
                        Layout.leftMargin: _toolButtonsLayoutFrame.border.width * 2
                        Layout.rightMargin: Layout.leftMargin
                        color: Components.Style.colorBorder
                    }

                    Components.Button {
                        Layout.fillHeight: true
                        implicitWidth: height
                        selected: !_light.off
                        text: "\ue518"
                        radius: _toolButtonsLayoutFrame.innerRadius
                        font.family: Components.MaterialIconsFont.name()
                        textAntialiasing: false

                        onClicked: {
                            _light.off = !_light.off;
                        }
                    }

                    Components.Button {
                        Layout.fillHeight: true
                        implicitWidth: height
                        selected: _flashlight.visible
                        text: "\uf00b"
                        radius: _toolButtonsLayoutFrame.innerRadius
                        font.family: Components.MaterialIconsFont.name()
                        textAntialiasing: false

                        onClicked: {
                            _flashlight.visible = !_flashlight.visible;
                        }
                    }

                    Components.Button {
                        Layout.fillHeight: true
                        implicitWidth: height
                        text: _background.visible ? "\ue421" : "\ue23a"
                        radius: _toolButtonsLayoutFrame.innerRadius
                        font.family: Components.MaterialIconsFont.name()
                        textAntialiasing: false

                        onClicked: {
                            _background.visible = !_background.visible;
                        }
                    }

                    Rectangle {
                        width: 1
                        Layout.fillHeight: true
                        Layout.topMargin: _toolButtonsLayoutFrame.border.width * 4
                        Layout.bottomMargin: Layout.topMargin
                        Layout.leftMargin: _toolButtonsLayoutFrame.border.width * 2
                        Layout.rightMargin: Layout.leftMargin
                        color: Components.Style.colorBorder
                    }

                    Components.Button {
                        Layout.fillHeight: true
                        implicitWidth: height
                        selected: _gridModel.visible
                        text: "\ue3ec"
                        radius: _toolButtonsLayoutFrame.innerRadius
                        font.family: Components.MaterialIconsFont.name()
                        textAntialiasing: false

                        onClicked: {
                            _gridModel.visible = !_gridModel.visible;
                        }
                    }

                    Components.Button {
                        Layout.fillHeight: true
                        implicitWidth: height
                        selected: _normalsModel.visible
                        text: "\ue0e4"
                        radius: _toolButtonsLayoutFrame.innerRadius
                        font.family: Components.MaterialIconsFont.name()
                        textAntialiasing: false

                        onClicked: {
                            _normalsModel.visible = !_normalsModel.visible;
                        }
                    }

                    Components.Button {
                        Layout.fillHeight: true
                        implicitWidth: height
                        text: "\ue53b"
                        radius: _toolButtonsLayoutFrame.innerRadius
                        font.family: Components.MaterialIconsFont.name()
                        textAntialiasing: false

                        Components.ContextMenu {
                            itemWidth: 128
                            id: _toolButtonsLayersContextMenu

                            Action {
                                text: "Default"

                                onTriggered: {
                                    _debugSettings.mode = DebugSettings.None;
                                }
                            }

                            Action {
                                text: "Base color"

                                onTriggered: {
                                    _debugSettings.mode = DebugSettings.BaseColor;
                                }
                            }
/*
                            Action {
                                text: "Specular"

                                onTriggered: {
                                    _debugSettings.mode = DebugSettings.Specular;
                                }
                            }
*/

                            Action {
                                text: "Normals"

                                onTriggered: {
                                    _debugSettings.mode = DebugSettings.Normals;
                                }
                            }
                        }

                        onClicked: {
                            _toolButtonsLayersContextMenu.x = -_toolButtonsLayersContextMenu.width + width;
                            _toolButtonsLayersContextMenu.y = height + Components.Style.margins / 2;
                            _toolButtonsLayersContextMenu.open();
                        }
                    }
                }

                Components.NoiseLayer {
                    anchors.fill: parent
                }
            }

            /*
                Light controller
            */
            Item {
                anchors.left: _lightAngleController.right
                anchors.bottom: parent.bottom
                anchors.margins: Components.Style.margins - _lightRotateControllerDial.anchors.margins
                width: 100
                height: 100
                id: _lightRotateController

                property real angle: (Math.PI + Math.atan2(
                        _lightRotateControllerMouseArea.direction.y,
                        _lightRotateControllerMouseArea.direction.x
                    )) / 2 * 360 / Math.PI

                function updateAngle(x, y) {
                    _lightRotateControllerMouseArea.direction = Qt.vector2d(
                        x - _lightRotateControllerDial.width / 2,
                        y - _lightRotateControllerDial.height / 2
                    ).normalized();
                }

                Component.onCompleted: {
                    updateAngle(_lightRotateController.width / 2 - _lightRotateControllerDial.anchors.margins, 0);
                }

                Rectangle {
                    anchors.fill: _lightRotateControllerDial
                    anchors.margins: -1
                    color: Components.Style.colorTransparent
                    radius: height / 2
                    border.width: _lightRotateControllerDial.border.width + 2
                    border.color: Qt.rgba(0, 0, 0, 0.3)
                }

                Components.Frame {
                    anchors.fill: parent
                    radius: height / 2
                    anchors.margins: _lightRotateControllerHandle.width / 2
                    id: _lightRotateControllerDial
                    clip: false
                    color: Components.Style.colorTransparent
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 1)
                    shadow: false
                }

                Rectangle {
                    anchors.fill: _lightRotateControllerHandle
                    anchors.margins: -1
                    color: Qt.rgba(0, 0, 0, 0.5)
                    radius: height / 2
                }

                Components.Frame {
                    id: _lightRotateControllerHandle
                    x: parent.width / 2 - width / 2 +
                       _lightRotateControllerMouseArea.direction.x * _lightRotateControllerDial.radius
                    y: parent.height / 2 - height / 2 +
                       _lightRotateControllerMouseArea.direction.y * _lightRotateControllerDial.radius
                    width: Components.Style.margins
                    height: Components.Style.margins
                    color: Qt.rgba(1, 1, 1, 1)
                    radius: height / 2
                    border.width: 0
                    shadow: false
                }

                DragHandler {
                    id: _lightRotateControllerMouseArea
                    acceptedButtons: Qt.LeftButton
                    acceptedModifiers: Qt.NoModifier
                    property vector2d direction: Qt.vector2d(0, 0);

                    Component.onCompleted: {
                        _lightRotateController.updateAngle(75, 8);
                    }

                    onCentroidChanged: {
                        if (!active) {
                            return;
                        }

                        _lightRotateController.updateAngle(
                            _lightRotateControllerMouseArea.centroid.position.x,
                            _lightRotateControllerMouseArea.centroid.position.y
                        );
                    }
                }
            }

            Basic.Slider {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.margins: Components.Style.margins
                height: _lightRotateControllerDial.height
                id: _lightAngleController
                orientation: Qt.Vertical
                width: Components.Style.margins
                from: -180
                to: 0
                value: -75
                topPadding: 0
                bottomPadding: 0

                background: Item {
                    width: 1
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -1
                        color: Components.Style.colorTransparent
                        radius: width / 2
                        border.width: width + 2
                        border.color: Qt.rgba(0, 0, 0, 0.3)
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: "white"
                        radius: width / 2
                        border.width: 0
                    }
                }

                handle: Item {
                    id: _lightAngleControllerHandle
                    x: _lightAngleController.leftPadding +
                       _lightAngleController.availableWidth / 2 - width / 2
                    y: _lightAngleController.topPadding +
                       _lightAngleController.visualPosition * (_lightAngleController.availableHeight - height)
                    implicitWidth: Components.Style.margins
                    implicitHeight: Components.Style.margins


                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -1
                        color: Components.Style.colorTransparent
                        radius: height / 2
                        border.width: 1
                        border.color: Qt.rgba(0, 0, 0, 0.5)
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: Qt.rgba(1, 1, 1, 1)
                        radius: height / 2
                        border.width: 0
                    }
                }
            }

            /*
                Content bar button
            */
            Components.Frame {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: Components.Style.margins
                width: Math.round(_contentButtonLayout.width + border.width * 2)
                height: Math.round(_toolButtonsLayout.height + border.width * 2)
                radius: Components.Style.radius
                visible: !_contentBar.visible

                RowLayout {
                    id: _contentButtonLayout
                    spacing: 2
                    height: Math.round(Components.Style.margins * 2)
                    x: _toolButtonsLayoutFrame.border.width
                    y: _toolButtonsLayoutFrame.border.width

                    Components.Button {
                        Layout.fillHeight: true
                        font.family: Components.MaterialIconsFont.name()
                        implicitWidth: height
                        radius: _toolButtonsLayoutFrame.innerRadius
                        text: "\ue8f2"
                        textAntialiasing: false

                        onClicked: {
                            _contentBar.visible = true;
                        }
                    }
                }

                Components.NoiseLayer {
                    anchors.fill: parent
                }
            }
        }

        /*
            Content bar
        */
        Components.Frame {
            SplitView.minimumHeight: parent.height / 4
            shadow: false
            radius: 0
            id: _contentBar
            visible: false
            border.width: 0

            /*
                Tab bar
            */
            Item {
                id: _contentBarTabBarLayout
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.margins: Components.Style.margins
                anchors.topMargin: Math.round(Components.Style.margins - Components.Style.margins / 2)
                width: 18

                ColumnLayout {
                    anchors.fill: parent
                    spacing: -1

                    Repeater {
                        id: _contentBarTabBarLayoutRepeater

                        model: [
                            "Browser",
                            "Materials"
                        ]

                        delegate: Components.Button {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: Math.round(width / 2)
                            backgroundColor: Components.Style.colorBlock
                            text: modelData
                            textComponent.rotation: 270
                            textComponent.elide: Qt.ElideNone
                            clip: true
                            font.pixelSize: 11
                            font.bold: true
                            id: _contentBarTabDelegate
                            textComponent.z: 1
                            selected: index === _contentBarStack.currentIndex

                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: parent.radius
                                color: parent.color
                                border.width: parent.border.width
                                border.color: parent.border.color
                                visible: index > 0
                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.top: parent.top
                                anchors.topMargin: parent.radius
                                height: parent.radius * 2
                                color: parent.color
                                border.width: parent.border.width
                                border.color: parent.border.color
                                visible: index < _contentBarTabBarLayoutRepeater.count - 1
                            }

                            onClicked: {
                                _contentBarStack.currentIndex = index;
                            }
                        }
                    }
                }
            }

            StackLayout {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: _contentBarTabBarLayout.right
                currentIndex: 0
                id: _contentBarStack

                /*
                    File browser
                */
                Item {
                    id: _fileBrowser

                    RowLayout {
                        id: _fileBrowserToolBar
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: Components.Style.margins
                        anchors.topMargin: Components.Style.margins - Components.Style.margins / 2
                        spacing: Components.Style.margins / 2

                        Components.Button {
                            implicitHeight: _fileBrowserPathEdit.height
                            implicitWidth: height
                            radius: Components.Style.radius
                            backgroundColor: Components.Style.colorBlock
                            font.family: Components.MaterialIconsFont.name()
                            textAntialiasing: false
                            text: _fileListGridView.visible ? "\ue8ee" : "\ue9b0"

                            onClicked: {
                                _fileListGridView.visible = !_fileListGridView.visible;
                            }
                        }

                        Components.Button {
                            implicitHeight: _fileBrowserPathEdit.height
                            implicitWidth: height
                            radius: Components.Style.radius
                            backgroundColor: Components.Style.colorBlock
                            font.family: Components.MaterialIconsFont.name()
                            textAntialiasing: false
                            text: "\uef4f"
                            id: _fileBrowserFilterButton

                            onClicked: {
                                selected = !selected;
                            }
                        }

                        Components.Button {
                            implicitHeight: _fileBrowserPathEdit.height
                            implicitWidth: height
                            radius: Components.Style.radius
                            backgroundColor: Components.Style.colorBlock
                            font.family: Components.MaterialIconsFont.name()
                            textAntialiasing: false
                            text: "\ue2c7"

                            Components.ContextMenu {
                                itemWidth: 128
                                id: _directoriesContextMenu
                                useIcons: true
                                radius: Components.Style.radius

                                Component.onCompleted: {
                                    var drives = Components.WindowsHelper.driveList();

                                    for (var i = 0; i < drives.length; i++) {
                                        var action = Qt.createQmlObject(`
                                            import QtQuick
                                            import QtQuick.Controls

                                            Action {
                                                text: \"` + drives[i] + `\"
                                                icon.source: \"\ue1db\"

                                                onTriggered: {
                                                    _fileBrowserModel.setFolder("` + drives[i] + `");
                                                }
                                            }
                                        `, _directoriesContextMenu)

                                        _directoriesContextMenu.addAction(action);
                                    }
                                }

                                Action {
                                    text: "Desktop"
                                    icon.source: "\ue30c"

                                    onTriggered: {
                                        _fileBrowserModel.setUrl(StandardPaths.writableLocation(
                                            StandardPaths.DesktopLocation));
                                    }
                                }

                                Action {
                                    text: "Documents"
                                    icon.source: "\ue2c9"

                                    onTriggered: {
                                        _fileBrowserModel.setUrl(StandardPaths.writableLocation(
                                            StandardPaths.DocumentsLocation));
                                    }
                                }

                                Action {
                                    text: "Downloads"
                                    icon.source: "\uf090"

                                    onTriggered: {
                                        _fileBrowserModel.setUrl(StandardPaths.writableLocation(
                                            StandardPaths.DownloadLocation));
                                    }
                                }

                                Action {
                                    text: "Models"
                                    icon.source: "\ue9fe"

                                    onTriggered: {
                                        var path = _settings.value("directoryModels");
                                        if (!path || !Components.WindowsHelper.directoryExists(path)) {
                                            _configurationsDialog.show();
                                            return;
                                        }

                                        _fileBrowserModel.setFolder(path);
                                    }
                                }

                            }

                            onClicked: {
                                _directoriesContextMenu.y = height + Components.Style.margins / 2;
                                _directoriesContextMenu.open();
                            }
                        }

                        /*
                        Components.Button {
                            implicitHeight: _fileBrowserPathEdit.height
                            implicitWidth: height
                            radius: Components.Style.radius
                            backgroundColor: Components.Style.colorBlock
                            font.family: Components.MaterialIconsFont.name()
                            textAntialiasing: false
                            text: "\ue5c4"

                            onClicked: {

                            }
                        }

                        Components.Button {
                            implicitHeight: _fileBrowserPathEdit.height
                            implicitWidth: height
                            radius: Components.Style.radius
                            backgroundColor: Components.Style.colorBlock
                            font.family: Components.MaterialIconsFont.name()
                            textAntialiasing: false
                            text: "\ue5c8"

                            onClicked: {

                            }
                        }
                        */

                        Components.Button {
                            implicitHeight: _fileBrowserPathEdit.height
                            implicitWidth: height
                            radius: Components.Style.radius
                            backgroundColor: Components.Style.colorBlock
                            font.family: Components.MaterialIconsFont.name()
                            textAntialiasing: false
                            text: "\ue5d8"
                            font.bold: true

                            onClicked: {
                                _fileBrowserModel.up();
                            }
                        }

                        Components.LineEdit {
                            id: _fileBrowserPathEdit
                            Layout.fillWidth: true

                            property bool isEditMode: false

                            function setPath(path) {
                                if (isEditMode) {
                                    return;
                                }

                                text = path;
                            }

                            function apply() {
                                isEditMode = true;
                                text = _fileBrowserModel.normalizePath(text.trim());
                                _fileBrowserModel.setFolder(text);
                                isEditMode = false;
                            }

                            onEditingFinished: {
                                apply();
                            }
                        }
                    }

                    Components.ScrollBar {
                        id: _fileListTableViewScrollBar
                        anchors.right: parent.right
                        anchors.top: _fileBrowserToolBar.bottom
                        anchors.bottom: parent.bottom
                        anchors.margins: Components.Style.margins
                        visible: size < 1 && _fileListTableView.visible
                        implicitWidth: Math.round(Components.Style.margins / 2)
                    }

                    Components.ScrollBar {
                        id: _fileListGridViewScrollBar
                        anchors.right: parent.right
                        anchors.top: _fileBrowserToolBar.bottom
                        anchors.bottom: parent.bottom
                        anchors.margins: Components.Style.margins
                        visible: size < 1 && _fileListGridView.visible
                        implicitWidth: Math.round(Components.Style.margins / 2)
                    }

                    Components.ContextMenu {
                        id: _fileBrowserContextMenu
                        useIcons: true
                        radius: Components.Style.radius

                        property string itemPath

                        Action {
                            text: "Show in explorer"
                            icon.source: "\ue2c7"

                            onTriggered: {
                                Components.WindowsHelper.showInExplorer(_fileBrowserContextMenu.itemPath);
                            }
                        }

                        Action {
                            text: "Copy path"
                            icon.source: "\ue157"

                            onTriggered: {
                                Components.WindowsHelper.copyFilenameToClipBoard(_fileBrowserContextMenu.itemPath);
                            }
                        }

                        Action {
                            text: "Properties"
                            icon.source: "\ue88e"

                            onTriggered: {
                                Components.WindowsHelper.openFilePropertyDialog(_fileBrowserContextMenu.itemPath);
                            }
                        }
                    }

                    ListView {
                        id: _fileListTableView
                        ScrollBar.vertical: _fileListTableViewScrollBar
                        anchors.left: parent.left
                        anchors.right: _fileListTableViewScrollBar.visible ? _fileListTableViewScrollBar.left : parent.right
                        anchors.top: _fileBrowserToolBar.bottom
                        anchors.bottom: parent.bottom
                        anchors.margins: Components.Style.margins
                        anchors.bottomMargin: 0
                        clip: true
                        model: _fileListGridView.model
                        spacing: 0
                        visible: !_fileListGridView.visible
                        keyNavigationEnabled: true
                        boundsMovement: Flickable.StopAtBounds

                        footer: Item {
                            height: Components.Style.margins
                        }

                        delegate: Rectangle {
                            id: _fileListTableViewDelegate
                            implicitWidth: _fileListTableView.width
                            implicitHeight: _fileBrowserPathEdit.height
                            color: isSelected ? Components.Style.colorAccent : Components.Style.colorTransparent
                            radius: Components.Style.radius

                            property bool isSelected: index === _fileListTableView.currentIndex

                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: 1
                                border.width: 0
                                color: Components.Style.colorBorder
                                visible: index !== _fileListTableView.count - 1 &&
                                    !_fileListTableViewDelegate.isSelected &&
                                    index + 1 !== _fileListTableView.currentIndex
                            }

                            RowLayout {
                                anchors.fill: parent
                                id: _fileListTableViewDelegateLayout
                                spacing: 0

                                Components.Label {
                                    font.pixelSize: 15
                                    font.family: Components.MaterialIconsFont.name()
                                    text: _fileBrowserModel.itemIcon(fileIsDir, fileSuffix.toLowerCase())
                                    color: _fileBrowserModel.itemColor(fileIsDir,
                                        fileSuffix, _fileListTableViewDelegate.isSelected)
                                    Layout.alignment: Qt.AlignVCenter
                                    leftPadding: Components.Style.margins
                                    antialiasing: false
                                }

                                Components.Label {
                                    font.bold: true
                                    text: fileName
                                    color: _fileListTableViewDelegate.isSelected ?
                                        Components.Style.colorTextHighlighted : Components.Style.colorText
                                    leftPadding: Components.Style.margins
                                    rightPadding: Components.Style.margins
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Item {
                                    implicitWidth: {
                                        var value = _fileListTableViewDelegate.width / 6;
                                        if (value > 100) {
                                            value = 100;
                                        }

                                        return value;
                                    }

                                    Layout.fillHeight: true

                                    Components.Label {
                                        visible: !fileIsDir
                                        font.bold: true
                                        text: _fileBrowserModel.formatBytes(fileSize)
                                        color: _fileListTableViewDelegate.isSelected ?
                                            Components.Style.colorTextHighlighted : Components.Style.colorText
                                        elide: Text.ElideRight
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        horizontalAlignment: Qt.AlignRight
                                    }
                                }

                                Components.Label {
                                    font.bold: true
                                    text: Qt.formatDateTime(fileModified, "dd.MM.yyyy hh:mm");
                                    color: _fileListTableViewDelegate.isSelected ?
                                        Components.Style.colorTextHighlighted : Components.Style.colorText
                                    leftPadding: Components.Style.margins
                                    rightPadding: Components.Style.margins
                                    Layout.alignment: Qt.AlignVCenter
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.RightButton

                                onDoubleClicked: function(event) {
                                    if (event.button === Qt.LeftButton) {
                                        _fileBrowserModel.itemDoubleClicked(fileName, index, fileIsDir);
                                    }
                                }

                                onPressed: function(event) {
                                    _fileListTableView.currentIndex = index;
                                    _fileBrowserModel.itemPressed(fileName, event.button);
                                }
                            }
                        }
                    }

                    GridView {
                        id: _fileListGridView
                        visible: false
                        ScrollBar.vertical: _fileListGridViewScrollBar
                        anchors.left: parent.left
                        anchors.right: _fileListGridViewScrollBar.visible ? _fileListGridViewScrollBar.left : parent.right
                        anchors.top: _fileBrowserToolBar.bottom
                        anchors.bottom: parent.bottom
                        anchors.margins: Components.Style.margins / 2
                        anchors.bottomMargin: 0
                        cellWidth: 100
                        cellHeight: cellWidth + _fileListGridView.titleFontSize * 2 + Components.Style.margins / 2
                        clip: true
                        boundsMovement: Flickable.StopAtBounds

                        footer: Item {
                            height: Components.Style.margins / 2
                        }

                        model: FolderListModel {
                            id: _fileBrowserModel
                            showDirsFirst: true

                            property url lastPath: ""
                            property string currentPath: normalizePath(folder.toString().substr(8))

                            onCurrentPathChanged: {
                                _fileBrowserPathEdit.setPath(currentPath);
                            }

                            nameFilters: {
                                if (_fileBrowserFilterButton.selected) {
                                    return [
                                        "*.csm"
                                    ];
                                }

                                return [];
                            }

                            function itemPressed(name, button) {
                                if (button === Qt.RightButton) {
                                    _fileBrowserContextMenu.itemPath =
                                        _fileBrowserModel.currentPath + "/" + name;
                                    _fileBrowserContextMenu.popup()
                                } else {
                                    if (name.toLowerCase().endsWith(".csm")) {
                                        openFile("file:///" + _fileBrowserModel.currentPath + "/" + name);
                                    }
                                }
                            }

                            function itemDoubleClicked(name, index, fileIsDir) {
                                if (fileIsDir) {
                                    _fileBrowserModel.openFolder(name, index);
                                    return;
                                }

                                if (name.toLowerCase().endsWith(".csm")) {
                                    return;
                                }

                                Qt.openUrlExternally("file:///" + _fileBrowserModel.currentPath + "/" + name);
                            }

                            function selectDirectory(index) {
                                _fileListGridView.currentIndex = index;
                                _fileListTableView.currentIndex = index;
                            }

                            function formatBytes(bytes, decimals) {
                                if(bytes === 0) {
                                    return '0 Bytes';
                                }

                                var dm = decimals || 2;

                                var sizes = [
                                    'Bytes',
                                    'KB',
                                    'MB',
                                    'GB',
                                    'TB',
                                    'PB',
                                    'EB',
                                    'ZB',
                                    'YB'
                                ];

                                var i = Math.floor(Math.log(bytes) / Math.log(1024));
                                return parseFloat((bytes / Math.pow(1024, i)).toFixed(decimals || 2)) + ' ' + sizes[i];
                            }

                            function normalizePath(path) {
                                path = Components.WindowsHelper.normalizePath(path);

                                if (path.startsWith("/")) {
                                    path = path.substr(1);
                                }

                                if (path.endsWith("/") && !path.endsWith(":/")) {
                                    path = path.slice(0, -1);
                                }

                                return path;
                            }

                            onFolderChanged: {
                                if (!lastPath) {
                                    return;
                                }

                                var index = indexOf(lastPath);
                                if (index < 0 || !isFolder(index)) {
                                    selectDirectory(-1);
                                } else {
                                    selectDirectory(index);
                                }
                            }

                            function up() {
                                if (currentPath.endsWith(":/")) {
                                    Components.WindowsHelper.beep();
                                    return;
                                }

                                var index = currentPath.lastIndexOf("/");
                                if (index < 1) {
                                    Components.WindowsHelper.beep();
                                    return;
                                }

                                setFolder(currentPath.substr(0, index + 1), folder);
                            }

                            function openFolder(name, index) {
                                lastPath = "";

                                if (folder.toString().endsWith("/")) {
                                    folder += name;
                                } else {
                                    folder += "/" + name;
                                }

                                selectDirectory(-1);
                            }

                            function setFolder(path, lastDirectory) {
                                if (!Components.WindowsHelper.directoryExists(path)) {
                                    Components.WindowsHelper.beep();
                                    return;
                                }

                                if (!lastDirectory) {
                                    lastPath = "";
                                } else {
                                    var value = lastDirectory.toString();
                                    if (value.endsWith("/")) {
                                        lastPath = value.slice(0, -1);
                                    } else {
                                        lastPath = lastDirectory;
                                    }
                                }

                                folder = "file:///" + path;
                                selectDirectory(-1);
                            }

                            function setUrl(url) {
                                lastPath = "";
                                folder = url;
                                selectDirectory(-1);
                            }

                            function itemIcon(fileIsDir, fileSuffix) {
                                if (fileIsDir) {
                                    return "\ue2c7";
                                }

                                switch (fileSuffix) {
                                case "csm":
                                    return "\ue9fe";

                                case "dds":
                                case "png":
                                case "jpg":
                                case "bmp":
                                case "tga":
                                case "tif":
                                case "tiff":
                                    return "\ue3f4";

                                case "mp3":
                                case "wav":
                                case "ogg":
                                    return "\ue405";

                                case "zip":
                                case "rar":
                                case "bz2":
                                case "7z":
                                case "pak":
                                    return "\ueb2c";

                                default:
                                    return "\uf1c6";
                                }
                            }

                            function itemColor(fileIsDir, fileSuffix, highlighted) {
                                if (fileIsDir) {
                                    if (highlighted) {
                                        return Qt.lighter(Components.Style.colorFileBrowserDirectory, 1.5);
                                    }

                                    return Components.Style.colorFileBrowserDirectory;
                                }

                                if (fileSuffix === "csm") {
                                    if (highlighted) {
                                        return Qt.lighter(Components.Style.colorFileBrowserModel, 1.5);
                                    }

                                    return Components.Style.colorFileBrowserModel;
                                }

                                if (highlighted) {
                                    return Components.Style.colorTextHighlighted;
                                }

                                return Components.Style.colorText;
                            }
                        }

                        property real titleFontSize: 12

                        delegate: Item {
                            width: _fileListGridView.cellWidth
                            height: _fileListGridView.cellHeight
                            id: _fileBrowserDelegate

                            property bool isSelected: _fileListGridView.currentIndex === index
                            property bool isHovered: _fileBrowserDelegateMouseArea.containsMouse

                            Rectangle {
                                radius: Components.Style.radius
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                implicitHeight: width
                                anchors.margins: Components.Style.margins / 2
                                id: _fileBrowserDelegateBackground

                                Components.Label {
                                    font.family: Components.MaterialIconsFont.name()
                                    font.pixelSize: parent.width / 1.5
                                    anchors.centerIn: parent
                                    id: _fileBrowserDelegateIcon
                                    text: _fileBrowserModel.itemIcon(fileIsDir, fileSuffix.toLowerCase())
                                    antialiasing: false
                                }
                            }

                            Components.Label {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: _fileBrowserDelegateBackground.bottom
                                anchors.margins: Components.Style.margins / 2
                                id: _fileBrowserDelegateFilenameLabel
                                horizontalAlignment: Qt.AlignHCenter
                                text: fileName
                                elide: Text.ElideRight
                                wrapMode: Text.WrapAnywhere
                                maximumLineCount: 2
                                font.pixelSize: _fileListGridView.titleFontSize
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                id: _fileBrowserDelegateMouseArea
                                acceptedButtons: Qt.LeftButton | Qt.RightButton

                                onPressed: function(event) {
                                    _fileListGridView.currentIndex = index;
                                    _fileBrowserModel.itemPressed(fileName, event.button);
                                }

                                onDoubleClicked: function(event) {
                                    if (event.button === Qt.LeftButton) {
                                        _fileBrowserModel.itemDoubleClicked(fileName, index, fileIsDir);
                                    }
                                }
                            }

                            states: [
                                State {
                                    name: "default"
                                    when: !_fileBrowserDelegate.isHovered && !_fileBrowserDelegate.isSelected

                                    PropertyChanges {
                                        target: _fileBrowserDelegateFilenameLabel
                                        color: Components.Style.colorText
                                    }

                                    PropertyChanges {
                                        target: _fileBrowserDelegateIcon
                                        color: _fileBrowserModel.itemColor(fileIsDir, fileSuffix, false)
                                    }

                                    PropertyChanges {
                                        target: _fileBrowserDelegateBackground
                                        color: Components.Style.colorBlock
                                    }
                                },

                                State {
                                    name: "hover"
                                    when: _fileBrowserDelegate.isHovered && !_fileBrowserDelegate.isSelected

                                    PropertyChanges {
                                        target: _fileBrowserDelegateFilenameLabel
                                        color: Components.Style.colorTextHighlighted
                                    }

                                    PropertyChanges {
                                        target: _fileBrowserDelegateIcon
                                        color: _fileBrowserModel.itemColor(fileIsDir, fileSuffix, true)
                                    }

                                    PropertyChanges {
                                        target: _fileBrowserDelegateBackground
                                        color: Components.Style.colorSection
                                    }
                                },

                                State {
                                    name: "selected"
                                    when: _fileBrowserDelegate.isSelected

                                    PropertyChanges {
                                        target: _fileBrowserDelegateFilenameLabel
                                        color: Components.Style.colorTextHighlighted
                                    }

                                    PropertyChanges {
                                        target: _fileBrowserDelegateIcon
                                        color: _fileBrowserModel.itemColor(fileIsDir, fileSuffix, true)
                                    }

                                    PropertyChanges {
                                        target: _fileBrowserDelegateBackground
                                        color: Components.Style.colorAccent
                                    }
                                }
                            ]

                            transitions: [
                                Transition {
                                    from: "hover"
                                    to: "default"

                                    ColorAnimation {
                                        target: _fileBrowserDelegateFilenameLabel
                                        duration: Components.Style.animationTime
                                    }

                                    ColorAnimation {
                                        target: _fileBrowserDelegateIcon
                                        duration: Components.Style.animationTime
                                    }

                                    ColorAnimation {
                                        target: _fileBrowserDelegateBackground
                                        duration: Components.Style.animationTime
                                    }
                                }
                            ]
                        }
                    }

                    Item {
                        anchors.left: _fileListGridView.left
                        anchors.right: _fileListGridView.visible ? _fileListGridView.right : _fileListTableView.right
                        anchors.top: _fileListGridView.top
                        height: lines[0] + lines[1]
                        clip: true

                        property var lines: [
                            Components.Style.margins / 2,
                            Components.Style.margins / 6
                        ]

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            color: Components.Style.colorFrame
                            height: parent.lines[0]
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: parent.lines[1]

                            visible: {
                                if (_fileListGridView.visible) {
                                    return _fileListGridViewScrollBar.position > 0;
                                }

                                if (_fileListTableView.visible) {
                                    return _fileListTableViewScrollBar.position > 0;
                                }

                                return false;
                            }

                            anchors.bottomMargin: {
                                var offset;

                                if (_fileListGridView.visible) {
                                    offset = height - _fileListGridView.contentY;
                                } else if (_fileListTableView.visible) {
                                    offset = height - _fileListTableView.contentY;
                                }

                                if (offset <= 0) {
                                    return 0;
                                }

                                return offset;
                            }

                            gradient: Gradient {
                                GradientStop {
                                    position: 0
                                    color: Components.Style.colorFrame
                                }

                                GradientStop {
                                    position: 1
                                    color: Components.Style.colorTransparent
                                }
                            }
                        }
                    }
                }

                /*
                    Material list
                */
                Item {
                    id: _materialsLayoutFrame

                    ListView {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: Components.Style.margins
                        anchors.rightMargin: Components.Style.margins
                        anchors.right: _materialListScrollBar.visible ? _materialListScrollBar.left : parent.right
                        id: _materialList
                        spacing: Components.Style.margins
                        clip: true
                        ScrollBar.vertical: _materialListScrollBar

                        header: Item {
                            height: Components.Style.margins / 2
                        }

                        footer: Item {
                            height: Components.Style.margins
                        }

                        function updateList() {
                            var list = [];

                            for (var i = 0; i < _model.materials.length; i++) {
                                const material = _model.materials[i];

                                list.push({
                                    name: material.name,
                                    diffuseName: material.diffuseName,
                                    diffuseFilename: material.diffuseFilename,
                                    diffuseIsAlpha: material.diffuseIsAlpha,
                                    specularName: material.specularName,
                                    specularFilename: material.specularFilename,
                                    specularIsAlpha: material.specularIsAlpha,
                                    normalName: material.normalName,
                                    normalFilename: material.normalFilename,
                                    normalIsAlpha: material.normalIsAlpha
                                });
                            }

                            model = list;
                        }

                        delegate: Item {
                            width: _materialList.width
                            id: _materialListDelegate

                            height: {
                                const value = Math.round(_materialList.height -
                                    (Components.Style.margins + Components.Style.margins / 2));

                                if (value > 256) {
                                    return 256;
                                }

                                return value;
                            }

                            property real itemWidth: {
                                const itemCount = 3;

                                var maxValue = (_materialListDelegateMapsLayout.width -
                                    Components.Style.margins * itemCount) / itemCount;

                                var value = height - Components.Style.margins * 5;

                                if (value > maxValue) {
                                    return maxValue;
                                }

                                if (value < 164) {
                                    return 164;
                                }

                                return value;
                            }

                            RowLayout {
                                anchors.left: parent.left
                                anchors.right: _materialListDelegateNameLayout.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                id: _materialListDelegateMapsLayout
                                spacing: 0

                                Components.MaterialComponent {
                                    mapIsAlpha: modelData.diffuseIsAlpha
                                    mapName: modelData.diffuseName
                                    filename: modelData.diffuseFilename
                                    implicitWidth: _materialListDelegate.itemWidth
                                    socketColor: Components.Style.materialMapColors[0]
                                    Layout.fillHeight: true
                                    Layout.alignment: Qt.AlignLeft
                                    text: "Diffuse"

                                    onOpenImage: function(filename) {
                                        var material = _model.materials[index];
                                        if (material.diffuseMapTextureData.loadByFilename(filename, material.diffuseName)) {
                                            resetSource();
                                            filename = material.diffuseMapTextureData.filename();
                                            material.diffuseFilename = filename;
                                        }
                                    }
                                }

                                ColumnLayout {
                                    spacing: 3
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.minimumWidth: Components.Style.margins

                                    Repeater {
                                        model: 1

                                        Rectangle {
                                            height: parent.spacing
                                            color: Components.Style.materialMapColors[index]
                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignVCenter
                                        }
                                    }
                                }

                                Components.MaterialComponent {
                                    mapIsAlpha: modelData.specularIsAlpha
                                    mapName: modelData.specularName
                                    filename: modelData.specularFilename
                                    implicitWidth: _materialListDelegate.itemWidth
                                    socketColor: Components.Style.materialMapColors[1]
                                    Layout.fillHeight: true
                                    Layout.alignment: Qt.AlignCenter
                                    text: "Specular"

                                    onOpenImage: function(filename) {
                                        var material = _model.materials[index];
                                        if (material.specularMapTextureData.loadByFilename(filename, material.specularName)) {
                                            resetSource();
                                            filename = material.specularMapTextureData.filename();
                                            material.specularFilename = filename;
                                        }
                                    }
                                }

                                ColumnLayout {
                                    spacing: 3
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.minimumWidth: Components.Style.margins

                                    Repeater {
                                        model: 2

                                        Rectangle {
                                            height: parent.spacing
                                            color: Components.Style.materialMapColors[index]
                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignVCenter
                                        }
                                    }
                                }

                                Components.MaterialComponent {
                                    mapIsAlpha: modelData.normalIsAlpha
                                    mapName: modelData.normalName
                                    filename: modelData.normalFilename
                                    implicitWidth: _materialListDelegate.itemWidth
                                    socketColor: Components.Style.materialMapColors[2]
                                    Layout.fillHeight: true
                                    Layout.alignment: Qt.AlignRight
                                    text: "Normal"

                                    onOpenImage: function(filename) {
                                        var material = _model.materials[index];
                                        if (material.normalMapTextureData.loadByFilename(filename, material.normalName)) {
                                            resetSource();
                                            filename = material.normalMapTextureData.filename();
                                            material.normalFilename = filename;
                                        }
                                    }
                                }

                                ColumnLayout {
                                    spacing: 3
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.minimumWidth: Components.Style.margins

                                    Repeater {
                                        model: 3

                                        Rectangle {
                                            height: parent.spacing
                                            color: Components.Style.materialMapColors[index]
                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignVCenter
                                        }
                                    }
                                }
                            }

                            Components.Frame {
                                id: _materialListDelegateNameLayout
                                shadow: false
                                color: Components.Style.colorBlock
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: _materialListDelegateNameLabel.height +
                                    _materialListDelegateNameSockets.width + (Components.Style.margins / 2) * 3
                                border.width: 0

                                Item {
                                    anchors.right: parent.right
                                    anchors.rightMargin: Components.Style.margins / 2 +
                                        _materialListDelegateNameLabel.height / 2
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 0
                                    height: 0
                                    rotation: -270

                                    Components.Label {
                                        id: _materialListDelegateNameLabel
                                        anchors.centerIn: parent
                                        width: _materialListDelegateNameLayout.height - Components.Style.margins * 2
                                        elide: Text.ElideMiddle
                                        font.bold: true
                                        text: modelData.name
                                        horizontalAlignment: Qt.AlignHCenter
                                        verticalAlignment: Qt.AlignVCenter
                                    }
                                }

                                ColumnLayout {
                                    id: _materialListDelegateNameSockets
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: 12
                                    spacing: 0
                                    anchors.leftMargin: Components.Style.margins / 2

                                    Repeater {
                                        model: Components.Style.materialMapColors

                                        delegate: Rectangle {
                                            Layout.alignment: Qt.AlignVCenter
                                            color: modelData
                                            width: _materialListDelegateNameSockets.width
                                            height: width
                                            radius: height / 2
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Components.ScrollBar {
                        id: _materialListScrollBar
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.margins: Components.Style.margins
                        anchors.topMargin: Components.Style.margins / 2
                        visible: size < 1 && _materialList.visible
                        implicitWidth: Math.round(Components.Style.margins / 2)
                    }

                    Image {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.topMargin: -2
                        source: "qrc:/Assets/DarkShadow.png"
                        height: Components.Style.margins
                        fillMode: Image.TileHorizontally
                        verticalAlignment: Image.AlignLeft
                    }
                }
            }

            Components.NoiseLayer {
                anchors.fill: parent
            }
        }
    }
}
