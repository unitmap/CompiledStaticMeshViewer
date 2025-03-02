#include "Model.h"

Model::Model(QObject *parent) :
    QObject(parent),
    m_compiledStaticMesh(nullptr)
{
    build();
}

Model::~Model()
{
    release();
}

void Model::registerQmlType()
{
    qmlRegisterType<Model>("Components.Model", 1, 0, "Model");
}

const QQuick3DGeometry *Model::modelGeometry() const
{
    return &m_modelGeometry;
}

const QQuick3DGeometry *Model::normalGeometry() const
{
    return &m_normalGeometry;
}

const QQuick3DGeometry *Model::gridGeometry() const
{
    return &m_gridGeometry;
}

uint32_t Model::materialCount() const
{
    return m_materials.count();
}

QStringList Model::materials() const
{
    return m_materials;
}

uint32_t Model::version() const
{
    if (m_compiledStaticMesh == nullptr) {
        return 0;
    }

    return m_compiledStaticMesh->version();
}

uint32_t Model::faceCount() const
{
    if (m_compiledStaticMesh == nullptr) {
        return 0;
    }

    return m_compiledStaticMesh->faceCount();
}

uint32_t Model::faceDataSize() const
{
    if (m_compiledStaticMesh == nullptr) {
        return 0;
    }

    return m_compiledStaticMesh->faceCount() * m_compiledStaticMesh->faceSize();
}

uint32_t Model::vertexCount() const
{
    if (m_compiledStaticMesh == nullptr) {
        return 0;
    }

    return m_compiledStaticMesh->vertexCount();
}

uint32_t Model::vertexDataSize() const
{
    if (m_compiledStaticMesh == nullptr) {
        return 0;
    }

    return m_compiledStaticMesh->vertexCount() * m_compiledStaticMesh->vertexSize();
}

QString Model::path() const
{
    return m_path;
}

QStringList Model::materialDirectories() const
{
    return m_materialDirectories;
}

QVector3D Model::boundingBoxMin() const
{
    return m_boundingBox.min;
}

QVector3D Model::boundingBoxMax() const
{
    return m_boundingBox.max;
}

void Model::release()
{
    if (m_compiledStaticMesh != nullptr) {
        delete m_compiledStaticMesh;
        m_compiledStaticMesh = nullptr;
    }

    m_materials.clear();
    m_boundingBox.min = QVector3D();
    m_boundingBox.max = QVector3D();
    m_materialDirectories.clear();
    m_filename.clear();
    m_path.clear();
    m_modelGeometry.clear();
    m_normalGeometry.clear();
    m_gridGeometry.clear();
    ImageProvider::clear();

    emit boundingBoxChanged();
    emit geometryChanged();
}

void Model::build()
{
    m_modelGeometry.addAttribute(QQuick3DGeometry::Attribute::PositionSemantic,
        sizeof(float) * 0, QQuick3DGeometry::Attribute::F32Type);
    m_modelGeometry.addAttribute(QQuick3DGeometry::Attribute::TexCoordSemantic,
        sizeof(float) * 3, QQuick3DGeometry::Attribute::F32Type);
    m_modelGeometry.addAttribute(QQuick3DGeometry::Attribute::NormalSemantic,
        sizeof(float) * 5, QQuick3DGeometry::Attribute::F32Type);
    m_modelGeometry.setPrimitiveType(QQuick3DGeometry::PrimitiveType::Triangles);
    m_modelGeometry.setStride(sizeof(float) * 8);
    m_modelGeometry.update();

    m_normalGeometry.addAttribute(QQuick3DGeometry::Attribute::PositionSemantic,
        sizeof(float) * 0, QQuick3DGeometry::Attribute::F32Type);
    m_normalGeometry.setPrimitiveType(QQuick3DGeometry::PrimitiveType::Lines);
    m_normalGeometry.setStride(sizeof(float) * 3);
    m_normalGeometry.update();

    m_gridGeometry.addAttribute(QQuick3DGeometry::Attribute::PositionSemantic,
        sizeof(float) * 0, QQuick3DGeometry::Attribute::F32Type);
    m_gridGeometry.setPrimitiveType(QQuick3DGeometry::PrimitiveType::Lines);
    m_gridGeometry.setStride(sizeof(float) * 3);
    m_gridGeometry.update();

    emit boundingBoxChanged();
    emit geometryChanged();
}

bool Model::loadCompiledStaticMesh(const QUrl &filename)
{
    release();

    /*
        Load file
    */
    m_filename = filename.toLocalFile();
    m_path = QFileInfo(m_filename).dir().path() + QDir::separator();
    m_materialDirectories.append(m_path);

    switch (CompiledStaticMesh::fileVersion(m_filename.toStdString())) {
    case 2:
        m_compiledStaticMesh = new CompiledStaticMesh::Version2;
        break;

    case 3:
        m_compiledStaticMesh = new CompiledStaticMesh::Version3;
        break;

    default:
        return false;
    }

    if (!m_compiledStaticMesh->open(filename.toLocalFile().toStdString(),
        CompiledStaticMesh::Interface::Read)) {
        return false;
    }

    if (m_compiledStaticMesh->vertexCount() == 0 ||
        m_compiledStaticMesh->faceCount() == 0) {
        return false;
    }

    /*
        Read materials
    */
    std::vector<std::string> materialNames;
    if (!m_compiledStaticMesh->readMaterials(&materialNames)) {
        return false;
    }

    for (const std::string &materialName : materialNames) {
        QString name = QString(materialName.c_str()).trimmed();
        if (name.startsWith('"')) {
            name = name.mid(1);
        }

        if (name.endsWith('"')) {
            name = name.mid(0, name.length() - 1);
        }

        m_materials.append(name);
    }

    /*
        Allocate vertex data
    */
    uint32_t geometryVertexCount = m_compiledStaticMesh->faceCount() * 3;

    QByteArray modelGeometryData;
    modelGeometryData.resize(geometryVertexCount * sizeof(Vertex));
    Vertex *modelGeometryVertices = reinterpret_cast<Vertex *>(modelGeometryData.data());

    QByteArray normalGeometryData;
    normalGeometryData.resize(geometryVertexCount * 2 * sizeof(Vector3));
    Vector3 *normalGeometryVertices = reinterpret_cast<Vector3 *>(normalGeometryData.data());

    QByteArray gridGeometryData;
    gridGeometryData.resize(geometryVertexCount  * 3 * sizeof(Vector3));
    Vector3 *gridGeometryVertices = reinterpret_cast<Vector3 *>(gridGeometryData.data());

    /*
        Read faces
    */
    QVector<uint8_t> faces;
    faces.resize(m_compiledStaticMesh->faceCount() * m_compiledStaticMesh->faceSize());

    if (!m_compiledStaticMesh->readFaces(faces.data())) {
        return false;
    }

    /*
        Read vertices
    */
    QVector<uint8_t> vertices;
    vertices.resize(m_compiledStaticMesh->vertexCount() * m_compiledStaticMesh->vertexSize());

    if (!m_compiledStaticMesh->readVertices(vertices.data())) {
        return false;
    }

    /*
            Parse faces
    */
    uint32_t meshCount = static_cast<uint32_t>(m_materials.size());
    if (meshCount < 1) {
        meshCount = 1;
    }

    m_boundingBox.min = QVector3D(std::numeric_limits<float>::max(),
        std::numeric_limits<float>::max(), std::numeric_limits<float>::max());
    m_boundingBox.max = QVector3D(std::numeric_limits<float>::min(),
        std::numeric_limits<float>::min(), std::numeric_limits<float>::min());

    uint32_t meshOffset = 0;
    uint32_t meshSize;

    for (uint32_t i = 0; i < meshCount; i++) {
        meshSize = 0;

        for (uint32_t j = 0; j < m_compiledStaticMesh->faceCount(); j++) {
            uint16_t materialIndex = m_compiledStaticMesh->faceMaterialIndex(faces.data(), j);
            if (materialIndex != i) {
                continue;
            }

            const Vertex *gridVertices = modelGeometryVertices;

            for (uint32_t k = 0; k < 3; k++) {
                /*
                    Model geometry
                */
                m_compiledStaticMesh->vertex(faces.data(), j, vertices.data(), k,
                    modelGeometryVertices->position.data, modelGeometryVertices->textureCoord.data,
                    modelGeometryVertices->normal.data);

                /*
                    Normal geometry
                */
                normalGeometryVertices->x = modelGeometryVertices->position.x;
                normalGeometryVertices->y = modelGeometryVertices->position.y;
                normalGeometryVertices->z = modelGeometryVertices->position.z;
                normalGeometryVertices++;

                normalGeometryVertices->x = modelGeometryVertices->position.x +
                    modelGeometryVertices->normal.x * Model::NormalGeometryOffset;
                normalGeometryVertices->y = modelGeometryVertices->position.y +
                    modelGeometryVertices->normal.y * Model::NormalGeometryOffset;
                normalGeometryVertices->z = modelGeometryVertices->position.z +
                    modelGeometryVertices->normal.z * Model::NormalGeometryOffset;
                normalGeometryVertices++;

                /*
                    Bounding box
                */
                if (m_boundingBox.min.x() > modelGeometryVertices->position.x) {
                    m_boundingBox.min.setX(modelGeometryVertices->position.x);
                }

                if (m_boundingBox.min.y() > modelGeometryVertices->position.y) {
                    m_boundingBox.min.setY(modelGeometryVertices->position.y);
                }

                if (m_boundingBox.min.z() > modelGeometryVertices->position.z) {
                    m_boundingBox.min.setZ(modelGeometryVertices->position.z);
                }

                if (m_boundingBox.max.x() < modelGeometryVertices->position.x) {
                    m_boundingBox.max.setX(modelGeometryVertices->position.x);
                }

                if (m_boundingBox.max.y() < modelGeometryVertices->position.y) {
                    m_boundingBox.max.setY(modelGeometryVertices->position.y);
                }

                if (m_boundingBox.max.z() < modelGeometryVertices->position.z) {
                    m_boundingBox.max.setZ(modelGeometryVertices->position.z);
                }

                modelGeometryVertices++;
                meshSize++;
            }

            /*
                Grid geometry
            */
            for (uint32_t k = 0; k < 3; k++) {
                const Vertex *gridVertex[2];

                switch (k) {
                case 0:
                    gridVertex[0] = &gridVertices[0];
                    gridVertex[1] = &gridVertices[1];
                    break;
                case 1:
                    gridVertex[0] = &gridVertices[1];
                    gridVertex[1] = &gridVertices[2];
                    break;

                case 2:
                    gridVertex[0] = &gridVertices[2];
                    gridVertex[1] = &gridVertices[0];
                    break;
                }

                gridGeometryVertices->x = gridVertex[0]->position.x +
                    gridVertex[0]->normal.x * Model::GridGeometryOffset;
                gridGeometryVertices->y = gridVertex[0]->position.y +
                    gridVertex[0]->normal.y * Model::GridGeometryOffset;
                gridGeometryVertices->z = gridVertex[0]->position.z +
                    gridVertex[0]->normal.z * Model::GridGeometryOffset;
                gridGeometryVertices++;

                gridGeometryVertices->x = gridVertex[1]->position.x +
                    gridVertex[1]->normal.x * Model::GridGeometryOffset;
                gridGeometryVertices->y = gridVertex[1]->position.y +
                    gridVertex[1]->normal.y * Model::GridGeometryOffset;
                gridGeometryVertices->z = gridVertex[1]->position.z +
                    gridVertex[1]->normal.z * Model::GridGeometryOffset;
                gridGeometryVertices++;
            }
        }

        m_modelGeometry.addSubset(meshOffset, meshSize, m_boundingBox.min, m_boundingBox.max);
        meshOffset += meshSize;
    }

    m_modelGeometry.setVertexData(modelGeometryData);
    m_normalGeometry.setVertexData(normalGeometryData);
    m_gridGeometry.setVertexData(gridGeometryData);
    build();

    return true;
}
