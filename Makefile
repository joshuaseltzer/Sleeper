TARGET=iphone:clang:10.1:8.0

include theos/makefiles/common.mk

TWEAK_NAME = Sleeper
Sleeper_FILES = Tweak.xm JSSkipAlarmAlertItem.xm JSCompatibilityHelper.m JSPickerTableViewController.m JSSnoozeTimeViewController.m JSPrefsManager.m JSSkipTimeViewController.m
Sleeper_FRAMEWORKS = UIKit
Sleeper_PRIVATE_FRAMEWORKS = MobileTimer
ADDITIONAL_OBJCFLAGS = -fobjc-arc

THEOS_PACKAGE_BASE_VERSION = 2.2.0
_THEOS_INTERNAL_PACKAGE_VERSION = 2.2.0

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 MobileTimer; killall -9 SpringBoard"
