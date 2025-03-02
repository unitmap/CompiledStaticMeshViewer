#ifndef COMPILEDSTATICMESH_INTERFACE_H
#define COMPILEDSTATICMESH_INTERFACE_H

#include <cstdint>
#include <cstdio>
#include <string>
#include <vector>

namespace CompiledStaticMesh {

class Interface
{

public:
    enum Mode {
        Read,
        Write
    };

protected:
    std::FILE *m_file;

    bool getCurrentOffset(uint32_t *offset);
    bool setCurrentOffset(uint32_t offset);
    bool read(void *data, size_t size);
    bool write(const void *data, size_t size);

public:
    Interface();
    virtual ~Interface();
    bool isOpen() const;
    virtual bool open(const std::string &filename, Mode mode);
    virtual void close();
    virtual uint32_t version() const = 0;
    virtual void setVersion(uint32_t version) = 0;
    virtual uint32_t flags() const = 0;
    virtual void setFlags(uint32_t flags) = 0;
    virtual uint32_t faceCount() const = 0;
    virtual uint32_t faceSize() const = 0;
    virtual uint16_t faceMaterialIndex(const void *faceData, uint32_t faceIndex) const = 0;
    virtual uint32_t vertexCount() const = 0;
    virtual uint32_t vertexSize() const = 0;
    virtual void vertex(const void *faceData, uint32_t faceIndex, const void *vertexData,
        uint32_t vertexIndex, float *position, float *textureCoord, float *normal) const = 0;
    virtual bool beginWriteMaterials() = 0;
    virtual bool writeMaterial(const std::string &name) = 0;
    virtual bool endWriteMaterials() = 0;
    virtual bool readMaterials(std::vector<std::string> *materials) = 0;
    virtual bool beginWriteFaces() = 0;
    virtual bool writeFace(void *face) = 0;
    virtual bool endWriteFaces() = 0;
    virtual bool readFaces(void *faces)= 0;
    virtual bool beginWriteVertices() = 0;
    virtual bool writeVertex(void *vertex) = 0;
    virtual bool endWriteVertices() = 0;
    virtual bool readVertices(void *vertices) = 0;
    virtual bool writeHeader() = 0;
    static uint32_t fileVersion(const std::string &filename);

};

} // namespace CompiledStaticMesh

#endif // COMPILEDSTATICMESH_INTERFACE_H
