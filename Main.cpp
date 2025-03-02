#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include "Model.h"
#include "Texture.h"
#include "WindowsHelper.h"

int main(int argc, char *argv[])
{
    QGuiApplication application(argc, argv);
    application.setOrganizationName("CompiledStaticMeshViewer");
    application.setOrganizationDomain("CompiledStaticMeshViewer");
    application.setWindowIcon(QIcon(":/Icon/Icon.ico"));

    QQmlApplicationEngine engine;
    engine.addImageProvider("imageprovider", new ImageProvider);

    QUrl path("qrc:/Main.qml");
    Model::registerQmlType();
    Texture::registerQmlType();
    WindowsHelper::registerQmlType();

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
        &application, [path](QObject *object, const QUrl &objectPath) {
        if (!object && path == objectPath) {
            QCoreApplication::exit(-1);
        }
    }, Qt::QueuedConnection);

    engine.load(path);
    return application.exec();
}
