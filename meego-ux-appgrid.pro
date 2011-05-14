VERSION = 0.2.5
TEMPLATE = subdirs

share.files += \
    *.qml \
    *.js \
    applications/ \
    virtual-applications/
share.path += $$INSTALL_ROOT/usr/share/$$TARGET

OTHER_FILES += *.qml *.js

INSTALLS += share

TRANSLATIONS += *.qml *.js
PROJECT_NAME = meego-ux-appgrid

dist.commands += rm -fR $${PROJECT_NAME}-$${VERSION} &&
dist.commands += git clone . $${PROJECT_NAME}-$${VERSION} &&
dist.commands += rm -fR $${PROJECT_NAME}-$${VERSION}/.git &&
dist.commands += mkdir -p $${PROJECT_NAME}-$${VERSION}/ts &&
dist.commands += lupdate $${TRANSLATIONS} -ts $${PROJECT_NAME}-$${VERSION}/ts/$${PROJECT_NAME}.ts &&
dist.commands += tar jcpvf $${PROJECT_NAME}-$${VERSION}.tar.bz2 $${PROJECT_NAME}-$${VERSION}
QMAKE_EXTRA_TARGETS += dist
