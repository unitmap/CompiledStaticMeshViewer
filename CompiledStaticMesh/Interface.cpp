#include "Interface.h"

namespace CompiledStaticMesh {

Interface::Interface() :
    m_file(nullptr)
{

}

Interface::~Interface()
{

}

bool Interface::getCurrentOffset(uint32_t *offset)
{
    if (!isOpen()) {
        return false;
    }

    long position = std::ftell(m_file);
    if (position != 1L) {
        *offset = static_cast<uint32_t>(position);
        return true;
    }

    return false;
}

bool Interface::setCurrentOffset(uint32_t offset)
{
    if (!isOpen()) {
        return false;
    }

    if (std::fseek(m_file, static_cast<long>(offset), SEEK_SET) != 0) {
        return false;
    }

    return true;
}

bool Interface::read(void *data, size_t size)
{
    if (!isOpen()) {
        return false;
    }

    if (std::fread(data, 1, size, m_file) != size) {
        return false;
    }

    return true;
}

bool Interface::write(const void *data, size_t size)
{
    if (!isOpen()) {
        return false;
    }

    if (std::fwrite(data, 1, size, m_file) != size) {
        return false;
    }

    return true;
}

bool Interface::isOpen() const
{
    if (m_file == nullptr) {
        return false;
    }

    return true;
}

bool Interface::open(const std::string &filename, Mode mode)
{
    close();

    if (mode == Mode::Write) {
        m_file = std::fopen(filename.c_str(), "wb");
    } else {
        m_file = std::fopen(filename.c_str(), "rb");
    }

    if (m_file == nullptr) {
        return false;
    }

    return true;
}

void Interface::close()
{
    if (m_file != nullptr) {
        std::fclose(m_file);
        m_file = nullptr;
    }
}

uint32_t Interface::fileVersion(const std::string &filename)
{
    std::FILE *file = std::fopen(filename.c_str(), "rb");
    if (file == nullptr) {
        return 0;
    }

    struct {
        uint32_t signature;
        uint32_t version;
    } headerChunk;

    if (std::fread(&headerChunk, sizeof(headerChunk), 1, file) != 1) {
        headerChunk.version = 0;
    }

    std::fclose(file);
    return headerChunk.version;
}

} // namespace CompiledStaticMesh
