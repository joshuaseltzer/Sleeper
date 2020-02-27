TARGET=iphone:clang:11.2:8.0
ARCHS=armv7 arm64 arm64e

include theos/makefiles/common.mk

LIBRARY_NAME = libSleeper
TWEAK_NAME = SleeperCore SleeperCoreLegacy SleeperUI

libSleeper_FILES = $(wildcard common/*.m) $(wildcard common/*.xm)
libSleeper_PRIVATE_FRAMEWORKS = MobileTimer
libSleeper_OBJCFLAGS = -fobjc-arc
libSleeper_LDFLAGS = -llockdown -weak-lMobileGestalt -lsubstrate -Wno-deprecated

SleeperCore_LIBRARIES = Sleeper
SleeperCore_FILES = $(wildcard core/*.x)
SleeperCore_OBJCFLAGS = -fobjc-arc
SleeperCore_LDFLAGS = -L$(THEOS_OBJ_DIR) -Wno-deprecated

SleeperCoreLegacy_LIBRARIES = Sleeper
SleeperCoreLegacy_FILES = $(wildcard core_legacy/*.[x])
SleeperCoreLegacy_OBJCFLAGS = -fobjc-arc
SleeperCoreLegacy_LDFLAGS = -L$(THEOS_OBJ_DIR) -Wno-deprecated

SleeperUI_LIBRARIES = Sleeper
SleeperUI_FILES = $(wildcard ui/*.x) $(wildcard ui/custom/*.m)
SleeperUI_OBJCFLAGS = -fobjc-arc
SleeperUI_LDFLAGS = -L$(THEOS_OBJ_DIR) -Wno-deprecated

THEOS_PACKAGE_BASE_VERSION = 6.0.2
_THEOS_INTERNAL_PACKAGE_VERSION = 6.0.2

include $(THEOS_MAKE_PATH)/library.mk
include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 MobileTimer; killall -9 mobiletimerd; killall -9 SpringBoard;"
