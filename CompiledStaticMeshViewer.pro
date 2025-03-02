QT += quick qml quick3d

SOURCES += \
    CompiledStaticMesh.cpp \
    CompiledStaticMesh/Interface.cpp \
    CompiledStaticMesh/Version2.cpp \
    CompiledStaticMesh/Version3.cpp \
    ImageProvider.cpp \
    Model.cpp \
    Main.cpp \
    Texture.cpp \
    WindowsHelper.cpp

RESOURCES += Assets.qrc

HEADERS += \
    CompiledStaticMesh.h \
    CompiledStaticMesh/Interface.h \
    CompiledStaticMesh/Version2.h \
    CompiledStaticMesh/Version3.h \
    ImageProvider.h \
    Model.h \
    Texture.h \
    WindowsHelper.h

LIBS += -L"$$_PRO_FILE_PWD_/DevIL/lib/x64/" -lDevIL -ldwmapi -lUser32

windows {
    RC_FILE = Application.rc
}
