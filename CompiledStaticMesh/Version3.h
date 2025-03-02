#ifndef COMPILEDSTATICMESH_VERSION3_H
#define COMPILEDSTATICMESH_VERSION3_H

#include <cstdint>
#include <cstdio>
#include <string>
#include <vector>
#include <memory>
#include "Interface.h"

namespace CompiledStaticMesh {

class Version3: public Interface
{

public:
    static constexpr const uint32_t Version = 3;
    static constexpr const uint32_t Signature = ('M' << 24) + ('S' << 16) + ('C' << 8) + 'I';
    static constexpr const uint32_t MaxMaterialNameLength = 260;
    static constexpr const uint32_t ChannelTexture = 0;
    static constexpr const uint32_t ChannelLightmap = 1;
    static constexpr const uint32_t ModelFlagsNone = 0x00000000;
    static constexpr const uint32_t ModelHasLightmapGroups = 0x00000001;
    static constexpr const uint32_t ModelBoundingBoxComputed = 0x00000002;
    static constexpr const uint32_t ModelCollapsed = 0x00000004;
    static constexpr const uint32_t ModelKeepNormals = 0x00000008;
    static constexpr const uint32_t ModelPortalsProcessed = 0x00000010;
    static constexpr const uint32_t FaceFlagsNone = 0x00000000;
    static constexpr const uint32_t FaceFromPlanarGroup = 0x00000001;
    static constexpr const uint32_t FaceFromPureAxialGroup = 0x00000002;
    static constexpr const uint32_t FaceDissolveFirstEdge = 0x00000004;
    static constexpr const uint32_t FaceDissolveSecondEdge = 0x00000008;
    static constexpr const uint32_t FaceDissolveThirdEdge = 0x00000010;
    static constexpr const uint32_t FaceHasSourceLightmapCoords = 0x00000020;
    static constexpr const uint32_t FaceLandscape = 0x00000040;
    static constexpr const uint32_t FaceStructural = 0x00000080;
    static constexpr const uint32_t FaceIsChecked = 0x00008000;
    static constexpr const uint32_t FaceWorldTarget = FaceFromPlanarGroup | FaceFromPureAxialGroup;

    struct Vector2 {
        float x;
        float y;
    };

    struct Vector3 {
        float x;
        float y;
        float z;
    };

    struct Color {
        uint8_t r;
        uint8_t g;
        uint8_t b;
        uint8_t a;
    };

    struct Vertex {
        Vector3 position;
        Vector3 normal;
        Color color;
    };

    struct Face {
        uint16_t material;
        uint16_t flags;
        uint32_t index[3];
        int32_t lightmapGroup;
        int32_t detailGroup;
        Vector2 textureCoord[3];
        Vector2 lightmapCoord[3];
    };

    struct Header {
        uint32_t signature;
        uint32_t version;
        uint32_t headerSize;
        uint32_t flags;
        char pathes[1024];
        uint32_t lightmapGroups;
        uint32_t detailGroups;

        struct {
            Vector3 min;
            Vector3 max;
        } boundingBox;

        uint32_t materialDataOffset;
        uint32_t materialDataEnd;
        uint32_t facesDataOffset;
        uint32_t faceSize;
        uint32_t facesCount;
        uint32_t vertexDataOffset;
        uint32_t vertexSize;
        uint32_t vertexCount;
        uint32_t sidesDataOffset;
        uint32_t sideSize;
        uint32_t sidesCount;
        uint32_t pointsDataOffset;
        uint32_t pointSize;
        uint32_t pointsCount;
    };

private:
    Header m_header;

public:
    Version3();
    ~Version3() override;
    bool open(const std::string &filename, Interface::Mode mode) override;
    void close() override;
    uint32_t version() const override;
    void setVersion(uint32_t version) override;
    uint32_t flags() const override;
    void setFlags(uint32_t flags) override;
    uint32_t faceCount() const override;
    uint32_t faceSize() const override;
    uint16_t faceMaterialIndex(const void *faceData, uint32_t faceIndex) const override;
    uint32_t vertexCount() const override;
    uint32_t vertexSize() const override;
    void vertex(const void *faceData, uint32_t faceIndex, const void *vertexData,
        uint32_t vertexIndex, float *position, float *textureCoord, float *normal) const override;
    bool beginWriteMaterials() override;
    bool writeMaterial(const std::string &name) override;
    bool endWriteMaterials() override;
    bool readMaterials(std::vector<std::string> *materials) override;
    bool beginWriteFaces() override;
    bool writeFace(void *face) override;
    bool endWriteFaces() override;
    bool readFaces(void *faces)override;
    bool beginWriteVertices() override;
    bool writeVertex(void *vertex) override;
    bool endWriteVertices() override;
    bool readVertices(void *vertices) override;
    bool writeHeader() override;

};

} //namespace CompiledStaticMesh


#endif // COMPILEDSTATICMESH_VERSION3_H
