#ifndef COMPILEDSTATICMESH_H
#define COMPILEDSTATICMESH_H

#include <string>
#include "CompiledStaticMesh/Interface.h"
#include "CompiledStaticMesh/Version2.h"
#include "CompiledStaticMesh/Version3.h"

namespace CompiledStaticMesh {

static constexpr const uint32_t MinVersion = 2;
static constexpr const uint32_t MaxVersion = 3;

uint32_t fileVersion(const std::string &filename);

} // namespace CompiledStaticMesh

#endif // COMPILEDSTATICMESH_H
