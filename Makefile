ARCHS = armv7 armv7s arm64

include theos/makefiles/common.mk

TWEAK_NAME = Sleeper
Sleeper_FILES = Tweak.xm Sleeper/Sleeper/JSSnoozeTimeViewController.m Sleeper/Sleeper/JSPrefsManager.m
Sleeper_FRAMEWORKS = UIKit
Sleeper_PRIVATE_FRAMEWORKS = MobileTimer
ADDITIONAL_OBJCFLAGS = -fobjc-arc

THEOS_PACKAGE_BASE_VERSION = 1.0.1
_THEOS_INTERNAL_PACKAGE_VERSION = 1.0.1

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard; killall -9 MobileTimer"
