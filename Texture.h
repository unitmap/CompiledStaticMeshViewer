#ifndef TEXTURE_H
#define TEXTURE_H

#include <QFile>
#include <QObject>
#include <QQuick3DTextureData>
#include <QSize>
#include <qqml.h>
#include "ImageProvider.h"

#undef _UNICODE
#include "DevIL/include/IL/il.h"

class Texture: public QQuick3DTextureData
{
    Q_OBJECT
    Q_PROPERTY(bool isAlpha READ isAlpha NOTIFY isAlphaChanged)
    QML_ELEMENT

private:
    bool m_isAlpha;
    QString m_filename;

public:
    explicit Texture(QQuick3DTextureData *parent = nullptr);
    static void registerQmlType();
    bool isAlpha();
    Q_INVOKABLE bool load(const QString &directory, const QString &name, const QString &mapName);
    Q_INVOKABLE bool loadByFilename(const QString &filename, const QString &mapName);
    Q_INVOKABLE QString filename() const;

signals:
    void isAlphaChanged();

};

#endif // TEXTURE_H
