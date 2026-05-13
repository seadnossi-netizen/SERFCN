ARCHS = arm64
DEBUG = 0
FINALPACKAGE = 1
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SERFCN

SERFCN_FILES = Tweak.x src/menu.m src/FloatingSwitch.m

SERFCN_FRAMEWORKS = UIKit Foundation

SERFCN_CFLAGS = -fobjc-arc

# APIKey.dylib is loaded at runtime via dlopen — no link-time dependency.
# It is bundled into the .deb via layout/var/jb/usr/lib/APIKey.dylib.
SERFCN_LDFLAGS = -lc++ -lc++abi

include $(THEOS_MAKE_PATH)/tweak.mk
