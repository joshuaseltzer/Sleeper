TARGET=iphone:clang:11.2:8.0

include theos/makefiles/common.mk

TWEAK_NAME = Sleeper
$(TWEAK_NAME)_FILES = iOS12/SLMTUserNotificationCenter.x iOS12/SLMTAlarmStorage.x iOS12/SLMTAlarmManager.x \
iOS10/SLMTSleepAlarmOptionsController.x iOS10/SLMTSleepAlarmViewController.x iOS9/SLUNLocalNotificationClient.x iOS8/SLSBApplication.x \
common/SLAlarmManager.x common/SLEditAlarmViewController.x common/SLMTAAlarmEditViewController.x common/SLUNSNotificationSchedulingService.x common/SLMTABedtimeOptionsViewController.x \
common/SLMTABedtimeViewController.x common/SLSBClockDataProvider.x common/SLSBLockScreenManager.x common/SLSBLockScreenViewController.x common/SLUNSNotificationSchedulingService.x \
SLAlarmPrefs.m SLCompatibilityHelper.m SLEditDateViewController.m SLHolidaySelectionTableViewController.m SLPartialModalPresentationController.m SLPickerTableViewController.m \
SLPrefsManager.m SLSkipDatesViewController.m SLSkipTimeViewController.m SLSnoozeTimeViewController.m
$(TWEAK_NAME)_PRIVATE_FRAMEWORKS = MobileTimer
ADDITIONAL_OBJCFLAGS = -fobjc-arc

THEOS_PACKAGE_BASE_VERSION = 5.0.0
_THEOS_INTERNAL_PACKAGE_VERSION = 5.0.0

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 MobileTimer; killall -9 mobiletimerd; killall -9 SpringBoard;"
