import QtQuick
import QtCore
import QtQuick3D
import Qt3D.Extras
import "." as Components

PrincipledMaterial {
    id: _material

    property var materialDirectories: []
    property string name
    property string diffuseName
    property string diffuseFilename
    property string specularName
    property string specularFilename
    property string normalName
    property string normalFilename
    property alias diffuseIsAlpha: _diffuseMapTextureData.isAlpha
    property alias specularIsAlpha: _diffuseMapTextureData.isAlpha
    property alias normalIsAlpha: _diffuseMapTextureData.isAlpha
    property alias diffuseMapTextureData: _diffuseMapTextureData
    property alias specularMapTextureData: _normalMapTextureData
    property alias normalMapTextureData: _specularMapTextureData

    Settings {
        id: _settings
    }

    function textureMapMaskList(name, maskList, isDiffuse) {
        var list = [];

        if (isDiffuse) {
            list.push(name);
        }

        for (var suffix of maskList.split(';')) {
            suffix = suffix.trim();
            if (suffix.length === 0) {
                continue;
            }

            list.push(name + suffix);
        }

        return list;
    }

    function find(name, materialDirectories) {
        _material.name = name;
        _material.diffuseName = name + "_diffuse";
        _material.specularName = name + "_specular";
        _material.normalName = name + "_normal";
        _material.materialDirectories = materialDirectories;

        var targetDirectory;

        for (var textureMapMask of textureMapMaskList(name, _settings.value("textureMapSuffixesDiffuse"), true)) {
            for (var directory of materialDirectories) {
                if (_diffuseMapTextureData.load(directory, textureMapMask, _material.diffuseName)) {
                    targetDirectory = directory;
                    _material.diffuseFilename = _diffuseMapTextureData.filename();
                    break;
                }
            }
        }

        if (!targetDirectory) {
            return;
        }

        for (textureMapMask of textureMapMaskList(name, _settings.value("textureMapSuffixesSpecular"))) {
            if (_specularMapTextureData.load(targetDirectory, textureMapMask, _material.specularName)) {
                _material.specularFilename = _specularMapTextureData.filename();
                break;
            }
        }

        for (textureMapMask of textureMapMaskList(name, _settings.value("textureMapSuffixesNormal"))) {
            if (_normalMapTextureData.load(targetDirectory, textureMapMask, _material.normalName)) {
                _material.normalFilename = _normalMapTextureData.filename();
                break;
            }
        }
    }

    alphaMode: _diffuseMapTextureData.isAlpha ? PrincipledMaterial.Blend : PrincipledMaterial.Default

    baseColorMap: Texture {
        id: _diffuseMapTexture
        generateMipmaps: true

        textureData: Components.Texture {
            id: _diffuseMapTextureData
        }
    }

    normalMap: Texture {
        id: _normalMapTexture
        generateMipmaps: true

        textureData: Components.Texture {
            id: _normalMapTextureData
        }
    }

    specularMap: Texture {
        id: _specularMapTexture
        generateMipmaps: true

        textureData: Components.Texture {
            id: _specularMapTextureData
        }
    }
}
