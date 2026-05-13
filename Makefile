ARCHS = arm64
DEBUG = 0
FINALPACKAGE = 1
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SERFCN

SERFCN_FILES = Tweak.x src/menu.m src/FloatingSwitch.m

SERFCN_FRAMEWORKS = UIKit Foundation

SERFCN_CFLAGS = -fobjc-arc

# -undefined dynamic_lookup: linker won't error on hidden ObjC symbols in APIKey.dylib.
# The dylib is still linked so dyld loads it; APIClient class resolves at runtime via ObjC runtime.
SERFCN_LDFLAGS = -undefined dynamic_lookup \
                 $(THEOS_PROJECT_DIR)/API/APIKey.dylib \
                 -Wl,-rpath,/var/jb/usr/lib \
                 -lc++ -lc++abi

include $(THEOS_MAKE_PATH)/tweak.mk
