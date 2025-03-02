#include "WindowsHelper.h"

WindowsHelper::WindowsHelper(QObject *parent) :
    QObject(parent)
{

}

void WindowsHelper::registerQmlType()
{
    qmlRegisterType<WindowsHelper>("Components.WindowsHelper", 1, 0, "WindowsHelper");
}

QString WindowsHelper::normalizePath(const QString &path, bool native)
{
    QString result = path;
    result.replace('\\', '/');
    result = QDir::cleanPath(result);

    if (native) {
        if (QDir::separator() != '/') {
            result.replace('/', QDir::separator());
        }
    }

    return result;
}

void WindowsHelper::showInExplorer(const QString &filename)
{
    ShellExecuteW(nullptr, L"open", L"explorer.exe",
        std::wstring(std::wstring(L"/select,") + normalizePath(filename, true).toStdWString()).c_str(),
        nullptr, SW_SHOWNORMAL);
}

void WindowsHelper::copyFilenameToClipBoard(const QString &filename)
{
    QGuiApplication::clipboard()->setText(normalizePath(filename, true));
}

void WindowsHelper::openFilePropertyDialog(const QString &filename)
{
    SHObjectProperties(nullptr, SHOP_FILEPATH,
        normalizePath(filename, true).toStdWString().c_str(), nullptr);
}

void WindowsHelper::setWindowCaptionColor(const QColor &captionColor,
    const QColor &borderColor, const QColor &textColor)
{
    QWindowList windows = qobject_cast<QGuiApplication*>(QCoreApplication::instance())->allWindows();

    for (const QWindow *window : windows) {
        if (window == nullptr) {
            return;
        }

        HWND handle = reinterpret_cast<HWND>(window->winId());
        if (handle == nullptr) {
            return;
        }

        COLORREF colorData;

        if (captionColor.isValid()) {
            colorData = RGB(captionColor.red(), captionColor.green(), captionColor.blue());
            DwmSetWindowAttribute(handle, DWMWA_CAPTION_COLOR, &colorData, sizeof(COLORREF));
        }

        if (borderColor.isValid()) {
            colorData = RGB(borderColor.red(), borderColor.green(), borderColor.blue());
            DwmSetWindowAttribute(handle, DWMWA_BORDER_COLOR, &colorData, sizeof(COLORREF));
        }

        if (textColor.isValid()) {
            colorData = RGB(textColor.red(), textColor.green(), textColor.blue());
            DwmSetWindowAttribute(handle, DWMWA_TEXT_COLOR, &colorData, sizeof(COLORREF));
        }
    }
}

QStringList WindowsHelper::driveList()
{
    QStringList list;

    for (const QFileInfo &fileInfo : QDir::drives()) {
        list.append(fileInfo.absolutePath());
    }

    return list;
}

void WindowsHelper::beep()
{
    MessageBeep(0xFFFFFFFF);
}

bool WindowsHelper::directoryExists(const QString &path)
{
    return QDir(path).exists();
}

void WindowsHelper::errorMessageBox(const QString &text)
{
    MessageBoxW(nullptr, text.toStdWString().c_str(), L"Error", MB_ICONERROR | MB_OK);
}
