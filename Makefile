TARGET=iphone:clang:11.2:8.0

include theos/makefiles/common.mk

TWEAK_NAME = Sleeper
#$(TWEAK_NAME)_FILES = SLCompatibilityHelper.m SLPrefsManager.m SLAlarmPrefs.m SLPickerTableViewController.m SLSkipTimeViewController.m SLSnoozeTimeViewController.m SLHolidaySelectionTableViewController.m SLEditDateViewController.m SLPartialModalPresentationController.m SLSkipDatesViewController.m SLSkipAlarmAlertItem.xm common/SLAlarmManager.x common/SLEditAlarmViewController.x common/SLSBClockDataProvider.x common/SLSBLockScreenViewController.x common/SLUNSNotificationSchedulingService.x common/SLSBLockScreenManager.x iOS8/SLSBApplication.x iOS9/SLUNLocalNotificationClient.x iOS10/SLMTSleepAlarmOptionsController.x iOS10/SLMTSleepAlarmViewController.x common/SLMTAAlarmEditViewController.x iOS11/SLMTABedtimeViewController.x iOS11/SLMTABedtimeOptionsViewController.x
$(TWEAK_NAME)_FILES = common/SLMTAAlarmEditViewController.x SLAlarmPrefs.m SLCompatibilityHelper.m SLPrefsManager.m SLSkipDatesViewController.m SLEditDateViewController.m SLHolidaySelectionTableViewController.m SLPartialModalPresentationController.m SLSkipTimeViewController.m SLPickerTableViewController.m SLSnoozeTimeViewController.m
$(TWEAK_NAME)_PRIVATE_FRAMEWORKS = MobileTimer
ADDITIONAL_OBJCFLAGS = -fobjc-arc

THEOS_PACKAGE_BASE_VERSION = 5.0.0
_THEOS_INTERNAL_PACKAGE_VERSION = 5.0.0

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 MobileTimer; killall -9 SpringBoard"
