#ifndef MODEL_H
#define MODEL_H

#include <QFileInfo>
#include <QDir>
#include <QString>
#include <QObject>
#include <QQuick3DGeometry>
#include <QVector3D>
#include <qqml.h>
#include "CompiledStaticMesh.h"
#include "ImageProvider.h"

#undef min
#undef max

class Model: public QObject
{

public:
    static constexpr const float NormalGeometryOffset = 8.0f;
    static constexpr const float GridGeometryOffset = 0.001f;

    Q_OBJECT
    Q_PROPERTY(const QQuick3DGeometry *modelGeometry READ modelGeometry NOTIFY geometryChanged)
    Q_PROPERTY(const QQuick3DGeometry *gridGeometry READ gridGeometry NOTIFY geometryChanged)
    Q_PROPERTY(const QQuick3DGeometry *normalGeometry READ normalGeometry NOTIFY geometryChanged)
    Q_PROPERTY(uint32_t materialCount READ materialCount NOTIFY geometryChanged)
    Q_PROPERTY(QStringList materials READ materials NOTIFY geometryChanged)
    Q_PROPERTY(QStringList materialDirectories READ materialDirectories NOTIFY geometryChanged)
    Q_PROPERTY(uint32_t version READ version NOTIFY geometryChanged)
    Q_PROPERTY(uint32_t faceCount READ faceCount NOTIFY geometryChanged)
    Q_PROPERTY(uint32_t faceDataSize READ faceDataSize NOTIFY geometryChanged)
    Q_PROPERTY(uint32_t vertexCount READ vertexCount NOTIFY geometryChanged)
    Q_PROPERTY(uint32_t vertexDataSize READ vertexDataSize NOTIFY geometryChanged)
    Q_PROPERTY(QVector3D boundingBoxMin READ boundingBoxMin NOTIFY boundingBoxChanged)
    Q_PROPERTY(QVector3D boundingBoxMax READ boundingBoxMax NOTIFY boundingBoxChanged)
    Q_PROPERTY(QString path READ path NOTIFY geometryChanged)
    QML_ELEMENT

    struct Vector3 {
        union {
            struct {
                float x;
                float y;
                float z;
            };

            float data[3];
        };
    };

    struct Vector2 {
        union {
            struct {
                float x;
                float y;
            };

            float data[2];
        };
    };

    struct Vertex {
        Vector3 position;
        Vector2 textureCoord;
        Vector3 normal;
    };

    struct BoundingBox {
        QVector3D min;
        QVector3D max;
    };

private:
    CompiledStaticMesh::Interface *m_compiledStaticMesh;
    QStringList m_materials;
    BoundingBox m_boundingBox;
    QStringList m_materialDirectories;
    QString m_filename;
    QString m_path;
    QQuick3DGeometry m_modelGeometry;
    QQuick3DGeometry m_normalGeometry;
    QQuick3DGeometry m_gridGeometry;

public:
    explicit Model(QObject *parent = nullptr);
    ~Model();
    static void registerQmlType();
    const QQuick3DGeometry *modelGeometry() const;
    const QQuick3DGeometry *normalGeometry() const;
    const QQuick3DGeometry *gridGeometry() const;
    uint32_t materialCount() const;
    QStringList materials() const;
    uint32_t version() const;
    uint32_t faceCount() const;
    uint32_t faceDataSize() const;
    uint32_t vertexCount() const;
    uint32_t vertexDataSize() const;
    QString path() const;
    QStringList materialDirectories() const;
    QVector3D boundingBoxMin() const;
    QVector3D boundingBoxMax() const;
    void release();
    void build();
    Q_INVOKABLE bool loadCompiledStaticMesh(const QUrl &filename);

signals:
    void boundingBoxChanged();
    void geometryChanged();

};

#endif // MODEL_H
