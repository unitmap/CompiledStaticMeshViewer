#ifndef WINDOWSHELPER_H
#define WINDOWSHELPER_H

#include <windows.h>
#include <dwmapi.h>
#include <shellapi.h>
#include <shlobj.h>
#include <QClipboard>
#include <QColor>
#include <QCoreApplication>
#include <QDir>
#include <QGuiApplication>
#include <QObject>
#include <QWindow>
#include <qqml.h>

#define DWMWA_BORDER_COLOR 34
#define DWMWA_TEXT_COLOR 36
#define DWMWA_CAPTION_COLOR 35

class WindowsHelper: public QObject
{
    Q_OBJECT
    QML_ELEMENT

public:
    WindowsHelper(QObject *parent = nullptr);
    static void registerQmlType();
    Q_INVOKABLE static QString normalizePath(const QString &path, bool native = false);
    Q_INVOKABLE static void showInExplorer(const QString &filename);
    Q_INVOKABLE static void copyFilenameToClipBoard(const QString &filename);
    Q_INVOKABLE static void openFilePropertyDialog(const QString &filename);
    Q_INVOKABLE static void setWindowCaptionColor(const QColor &captionColor,
        const QColor &borderColor = QColor(), const QColor &textColor = QColor());
    Q_INVOKABLE static QStringList driveList();
    Q_INVOKABLE static void beep();
    Q_INVOKABLE static bool directoryExists(const QString &path);
    Q_INVOKABLE static void errorMessageBox(const QString &text);

};

#endif // WINDOWSHELPER_H
