#include "CompiledStaticMesh.h"

namespace CompiledStaticMesh {

uint32_t fileVersion(const std::string &filename)
{
    return Interface::fileVersion(filename);
}

} // namespace CompiledStaticMesh
