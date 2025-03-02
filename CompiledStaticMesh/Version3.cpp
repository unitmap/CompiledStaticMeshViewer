#include "Version3.h"

namespace CompiledStaticMesh {

Version3::Version3() :
    Interface()
{
    std::memset(&m_header, 0, sizeof(Header));
}

Version3::~Version3()
{
    Version3::close();
}

bool Version3::open(const std::string &filename, Interface::Mode mode)
{
    Version3::close();

    if (!Interface::open(filename, mode)) {
        return false;
    }

    if (mode == Interface::Read) {
        if (!Interface::read(&m_header, sizeof(Header))) {
            return false;
        }
    }

    return true;
}

void Version3::close()
{
    Interface::close();
    std::memset(&m_header, 0, sizeof(Header));
}

uint32_t Version3::version() const
{
    if (!Interface::isOpen()) {
        return false;
    }

    return m_header.version;
}

void Version3::setVersion(uint32_t version)
{
    m_header.version = version;
}

uint32_t Version3::flags() const
{
    return m_header.flags;
}

void Version3::setFlags(uint32_t flags)
{
    m_header.flags = flags;
}

uint32_t Version3::faceCount() const
{
    return m_header.facesCount;
}

uint32_t Version3::faceSize() const
{
    return sizeof(Face);
}

uint16_t Version3::faceMaterialIndex(const void *faceData, uint32_t faceIndex) const
{
    return reinterpret_cast<const Face *>(faceData)[faceIndex].material;
}

uint32_t Version3::vertexCount() const
{
    return m_header.vertexCount;
}

uint32_t Version3::vertexSize() const
{
    return sizeof(Vertex);
}

void Version3::vertex(const void *faceData, uint32_t faceIndex, const void *vertexData,
    uint32_t vertexIndex, float *position, float *textureCoord, float *normal) const
{
    const Face *face = &reinterpret_cast<const Face *>(faceData)[faceIndex];
    textureCoord[0] = face->textureCoord[vertexIndex].x;
    textureCoord[1] = face->textureCoord[vertexIndex].y;

    const Vertex *vertex = &reinterpret_cast<const Vertex *>(vertexData)[face->index[vertexIndex]];
    position[0] = vertex->position.x;
    position[1] = vertex->position.z;
    position[2] = vertex->position.y;
    normal[0] = vertex->normal.x;
    normal[1] = vertex->normal.z;
    normal[2] = vertex->normal.y;
}


bool Version3::beginWriteMaterials()
{
    if (!Interface::getCurrentOffset(&m_header.materialDataOffset)) {
        return false;
    }

    return true;
}

bool Version3::writeMaterial(const std::string &name)
{
    if (!Interface::write(name.c_str(), name.size())) {
        return false;
    }

    return true;
}

bool Version3::endWriteMaterials()
{
    if (!Interface::write("\0", 1)) {
        return false;
    }

    uint32_t currentOffset;

    if (!Interface::getCurrentOffset(&currentOffset)) {
        return false;
    }

    if (m_header.materialDataOffset > currentOffset) {
        return false;
    }

    m_header.materialDataEnd = currentOffset;

    return true;
}

bool Version3::readMaterials(std::vector<std::string> *materials)
{
    materials->clear();

    if (!Interface::setCurrentOffset(m_header.materialDataOffset)) {
        return false;
    }

    std::string material;

    while (true) {
        char c;
        if (!Interface::read(&c, sizeof(char))) {
            return false;
        }

        if (c == ' ') {
            if (!material.empty()) {
                materials->push_back(material);
                material.clear();
            }

            continue;
        }

        if (c == '\0') {
            break;
        }

        material.push_back(c);
    }

    return true;
}

bool Version3::beginWriteFaces()
{
    if (!Interface::getCurrentOffset(&m_header.facesDataOffset)) {
        return false;
    }

    return true;
}

bool Version3::writeFace(void *face)
{
    if (!Interface::isOpen()) {
        return false;
    }

    m_header.facesCount++;

    if (!Interface::write(face, sizeof(Face))) {
        return false;
    }

    return true;
}

bool Version3::endWriteFaces()
{
    uint32_t currentOffset;

    if (!Interface::getCurrentOffset(&currentOffset)) {
        return false;
    }

    if (m_header.facesDataOffset > currentOffset) {
        return false;
    }

    return true;
}

bool Version3::readFaces(void *faces)
{
    if (!Interface::setCurrentOffset(m_header.facesDataOffset)) {
        return false;
    }

    if (!Interface::read(faces, sizeof(Face) * m_header.facesCount)) {
        return false;
    }

    return true;
}

bool Version3::beginWriteVertices()
{
    if (!Interface::getCurrentOffset(&m_header.vertexDataOffset)) {
        return false;
    }

    return true;
}

bool Version3::writeVertex(void *vertex)
{
    m_header.vertexCount++;

    if (!Interface::write(vertex, sizeof(Vertex))) {
        return false;
    }

    return true;
}

bool Version3::endWriteVertices()
{
    uint32_t currentOffset;

    if (!Interface::getCurrentOffset(&currentOffset)) {
        return false;
    }

    if (m_header.vertexDataOffset > currentOffset) {
        return false;
    }

    return true;
}

bool Version3::readVertices(void *vertices)
{
    if (!Interface::setCurrentOffset(m_header.vertexDataOffset)) {
        return false;
    }

    if (!Interface::read(vertices, sizeof(Vertex) * m_header.vertexCount)) {
        return false;
    }

    return true;
}

bool Version3::writeHeader()
{
    if (!Interface::setCurrentOffset(0)) {
        return false;
    }

    if (!Interface::write(&m_header, sizeof(Header))) {
        return false;
    }

    return true;
}

} // namespace CompiledStaticMesh
