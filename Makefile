TARGET=iphone:clang:11.2:8.0

include theos/makefiles/common.mk

TWEAK_NAME = Sleeper
Sleeper_FILES = SLCompatibilityHelper.m SLPrefsManager.m SLAlarmPrefs.m SLPickerTableViewController.m SLSkipTimeViewController.m SLSnoozeTimeViewController.m SLHolidaySelectionTableViewController.m SLEditDateViewController.m SLPartialModalPresentationController.m SLSkipDatesViewController.m SLSkipAlarmAlertItem.xm common/SLAlarmManager.x common/SLEditAlarmViewController.x common/SLSBClockDataProvider.x common/SLSBLockScreenViewController.x common/SLUNSNotificationSchedulingService.x common/SLSBLockScreenManager.x iOS8/SLSBApplication.x iOS9/SLUNLocalNotificationClient.x iOS10/SLMTSleepAlarmOptionsController.x iOS10/SLMTSleepAlarmViewController.x iOS11/SLMTAAlarmEditViewController.x iOS11/SLMTABedtimeViewController.x iOS11/SLMTABedtimeOptionsViewController.x
Sleeper_PRIVATE_FRAMEWORKS = MobileTimer
ADDITIONAL_OBJCFLAGS = -fobjc-arc

THEOS_PACKAGE_BASE_VERSION = 4.1.0
_THEOS_INTERNAL_PACKAGE_VERSION = 4.1.0

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 MobileTimer; killall -9 SpringBoard"
