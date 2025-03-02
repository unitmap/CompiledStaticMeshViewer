#include "ImageProvider.h"

QMap<QString, QPixmap *> ImageProvider::m_images;

ImageProvider::ImageProvider() :
    QQuickImageProvider(QQuickImageProvider::Pixmap)
{

}

QPixmap ImageProvider::requestPixmap(const QString &name, QSize *size, const QSize &requestedSize)
{
    Q_UNUSED(requestedSize)

    if (size != nullptr) {
        size->setWidth(0);
        size->setHeight(0);
    }

    const QPixmap *image = nullptr;

    if (m_images.contains(name) ) {
        image = m_images[name];
    }

    if (image == nullptr) {
        return QPixmap();
    }

    if (image->isNull()) {
        return QPixmap();
    }

    if (size != nullptr) {
        size->setWidth(image->width());
        size->setHeight(image->height());
    }

    return *image;
}

void ImageProvider::appendImage(const QString &name, QPixmap *image)
{
    if (m_images.contains(name)) {
        delete m_images[name];
    }

    m_images[name] = image;
}

void ImageProvider::clear()
{
    QStringList keys = m_images.keys();

    for (qsizetype i = 0; i < keys.size(); i++) {
        delete m_images[keys[i]];
    }

    m_images.clear();
}
