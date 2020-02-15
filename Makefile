TARGET=iphone:clang:11.2:8.0
ARCHS=armv7 arm64 arm64e

include theos/makefiles/common.mk

TWEAK_NAME = SleeperCore SleeperCoreDaemon SleeperUI

SleeperCore_FILES = common/SLAlarmPrefs.m common/SLPrefsManager.m common/SLCompatibilityHelper.m \
core/SLSkipAlarmAlertItem.xm core/SLSBDashBoardLockScreenEnvironment.x core/SLSBLockScreenViewControllerBase.x \
core/SLAlarmManager.x core/SLSBApplication.x core/SLSBClockDataProvider.x core/SLSBLockScreenManager.x core/SLSBLockScreenViewController.x \
core/SLSBLockScreenViewControllerBase.x core/SLUNLocalNotificationClient.x core/SLUNSNotificationSchedulingService.x
SleeperCore_PRIVATE_FRAMEWORKS = MobileTimer
SleeperCore_OBJCFLAGS = -fobjc-arc

SleeperCoreDaemon_FILES = common/SLAlarmPrefs.m common/SLPrefsManager.m common/SLCompatibilityHelper.m \
core_daemon/SLMTAlarmManager.x core_daemon/SLMTAlarmStorage.x core_daemon/SLMTUserNotificationCenter.x
SleeperCoreDaemon_PRIVATE_FRAMEWORKS = MobileTimer
SleeperCoreDaemon_OBJCFLAGS = -fobjc-arc

SleeperUI_FILES = common/SLAlarmPrefs.m common/SLPrefsManager.m common/SLCompatibilityHelper.m \
ui/SLEditDateViewController.m ui/SLHolidaySelectionTableViewController.m ui/SLPartialModalPresentationController.m \
ui/SLPickerTableViewController.m ui/SLSkipDatesViewController.m ui/SLSkipTimeViewController.m ui/SLSnoozeTimeViewController.m \
ui/SLEditAlarmViewController.x ui/SLMTAAlarmEditViewController.x ui/SLMTABedtimeOptionsViewController.x ui/SLMTABedtimeViewController.x \
ui/SLMTASleepDetailViewController.x ui/SLMTASleepOptionsViewController.x ui/SLMTSleepAlarmOptionsController.x ui/SLMTSleepAlarmViewController.x
SleeperUI_PRIVATE_FRAMEWORKS = MobileTimer
SleeperUI_OBJCFLAGS = -fobjc-arc

THEOS_PACKAGE_BASE_VERSION = 6.0.1
_THEOS_INTERNAL_PACKAGE_VERSION = 6.0.1

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 MobileTimer; killall -9 mobiletimerd; killall -9 SpringBoard;"
