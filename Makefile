TARGET=iphone:clang:9.3:8.0

include theos/makefiles/common.mk

TWEAK_NAME = Sleeper
Sleeper_FILES = SLCompatibilityHelper.m SLPrefsManager.m SLAlarmPrefs.m SLPickerTableViewController.m SLSkipTimeViewController.m SLSnoozeTimeViewController.m SLSkipAlarmAlertItem.xm SLAlarmManager.x SLEditAlarmViewController.x SLSBApplication.x SLUNLocalNotificationClient.x SLSBClockDataProvider.x SLSBLockScreenViewController.x SLUNSNotificationSchedulingService.x SLSBLockScreenManager.x SLMTSleepAlarmOptionsController.x
Sleeper_PRIVATE_FRAMEWORKS = MobileTimer
ADDITIONAL_OBJCFLAGS = -fobjc-arc

THEOS_PACKAGE_BASE_VERSION = 3.0.0
_THEOS_INTERNAL_PACKAGE_VERSION = 3.0.0

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 MobileTimer; killall -9 SpringBoard"
