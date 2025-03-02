#ifndef IMAGEPROVIDER_H
#define IMAGEPROVIDER_H

#include <QImage>
#include <QQuickImageProvider>
#include <QString>

class ImageProvider: public QQuickImageProvider
{

private:
    static QMap<QString, QPixmap *> m_images;

public:
    ImageProvider();
    QPixmap requestPixmap(const QString &name, QSize *size, const QSize &requestedSize) override;
    static void appendImage(const QString &name, QPixmap *image);
    static void clear();

};

#endif // IMAGEPROVIDER_H
