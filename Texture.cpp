#include "Texture.h"

Texture::Texture(QQuick3DTextureData *parent) :
    QQuick3DTextureData(parent),
    m_isAlpha(false)
{

}

void Texture::registerQmlType()
{
    qmlRegisterType<Texture>("Components.Texture", 1, 0, "Texture");
}

bool Texture::isAlpha()
{
    return m_isAlpha;
}

QString Texture::filename() const
{
    return m_filename;
}

bool Texture::load(const QString &directory, const QString &name, const QString &mapName)
{
    static const char *ext[4] = {
        "dds",
        "png",
        "bmp",
        "jpg"
    };

    QString filename = directory + name;

    for (uint32_t i = 0; i < sizeof(ext) / sizeof(char *); i++) {
        QString path = filename + "." + QString(ext[i]);
        if (QFile::exists(path)) {
            filename = path;
            break;
        }
    }

    return loadByFilename(filename, mapName);
}

bool Texture::loadByFilename(const QString &filename, const QString &mapName)
{
    static bool ilIsInit = false;

    if (!ilIsInit) {
        ilInit();
        ilIsInit = true;
    }

    ILuint id;
    ilGenImages(1, &id);
    ilBindImage(id);

    if (ilLoadImage(filename.toStdString().c_str()) != IL_TRUE) {
        ilDeleteImages(1, &id);
        return false;
    }

    int width = ilGetInteger(IL_IMAGE_WIDTH);
    int height = ilGetInteger(IL_IMAGE_HEIGHT);
    int channels = ilGetInteger(IL_IMAGE_CHANNELS);
    int format;

    switch (channels) {
    case 3:
        format = IL_RGB;
        break;

    case 4:
        format = IL_RGBA;
        break;

    default:
        format = IL_FALSE;
        break;
    }

    if (width < 1 || height < 1 || format == IL_FALSE) {
        ilDeleteImages(1, &id);
        return false;
    }

    QByteArray data;

    if (ilConvertImage(IL_RGBA, IL_UNSIGNED_BYTE)) {
        char *pixels = reinterpret_cast<char *>(ilGetData());
        if (pixels != nullptr) {
            data.append(pixels, sizeof(char) * channels * width * height);
        }
    }

    ilDeleteImages(1, &id);

    if (data.isEmpty()) {
        return false;
    }

    setTextureData(data);
    setFormat(QQuick3DTextureData::Format::RGBA8);
    setSize(QSize(width, height));

    QImage imageProviderImage;

    if (width > 256 || height > 256) {
        if (width > height) {
            imageProviderImage = QImage(reinterpret_cast<const uchar *>(data.data()),
                                        width, height, QImage::Format::Format_RGBA8888).scaledToWidth(256);
        } else {
            imageProviderImage = QImage(reinterpret_cast<const uchar *>(data.data()),
                                        width, height, QImage::Format::Format_RGBA8888).scaledToHeight(256);
        }
    } else {
        imageProviderImage = QImage(reinterpret_cast<const uchar *>(data.data()),
                                    width, height, QImage::Format::Format_RGBA8888);
    }

    m_isAlpha = false;

    for (int x = 0; x < imageProviderImage.width(); x++) {
        for (int y = 0; y < imageProviderImage.height(); y++) {
            if (qAlpha(imageProviderImage.pixel(x, y)) != 255) {
                m_isAlpha = true;
                break;
            }
        }
    }

    emit isAlphaChanged();

    if (m_isAlpha) {
        setHasTransparency(true);
    } else {
        setHasTransparency(false);
    }

    ImageProvider::appendImage(mapName, new QPixmap(QPixmap::fromImage(imageProviderImage)));
    m_filename = filename;
    update();

    return true;
}
