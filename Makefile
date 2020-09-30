TARGET=iphone:clang:12.4:8.0
ARCHS=armv7 arm64 arm64e

include theos/makefiles/common.mk

LIBRARY_NAME = libSleeper
TWEAK_NAME = SleeperCore SleeperCoreLegacy SleeperUI

libSleeper_FILES = $(filter-out common/SLSpringBoard.m, $(wildcard common/*.m)) $(wildcard common/*.xm ) $(wildcard common/*.x)
libSleeper_PRIVATE_FRAMEWORKS = MobileTimer
libSleeper_OBJCFLAGS = -fobjc-arc
libSleeper_LDFLAGS = -lsubstrate

SleeperCore_FILES = $(wildcard core/*.x)
SleeperCore_LIBRARIES = Sleeper
SleeperCore_OBJCFLAGS = -fobjc-arc
SleeperCore_LDFLAGS = -L$(THEOS_OBJ_DIR)

SleeperCoreLegacy_FILES = $(wildcard core_legacy/*.x)
SleeperCoreLegacy_LIBRARIES = Sleeper
SleeperCoreLegacy_OBJCFLAGS = -fobjc-arc
SleeperCoreLegacy_LDFLAGS = -L$(THEOS_OBJ_DIR)

SleeperUI_FILES = $(wildcard ui/*.x) $(wildcard ui/*.xm) $(wildcard ui/custom/*.m)
SleeperUI_PRIVATE_FRAMEWORKS = SleepHealthUI
SleeperUI_LIBRARIES = Sleeper
SleeperUI_OBJCFLAGS = -fobjc-arc
SleeperUI_LDFLAGS = -L$(THEOS_OBJ_DIR)

THEOS_PACKAGE_BASE_VERSION = 7.0.0
_THEOS_INTERNAL_PACKAGE_VERSION = 7.0.0

include $(THEOS_MAKE_PATH)/library.mk
include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 MobileTimer; killall -9 mobiletimerd; killall -9 SpringBoard;"
