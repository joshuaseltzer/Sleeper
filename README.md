**This package is for iOS 8 - iOS 14 jailbreaks. For iOS 15+ and rootless jailbreak compatibility, please see [SleeperX](https://havoc.app/package/sleeperx).**

Sleeper is a tweak designed to give you more functionality around your stock iOS alarms. The goal of Sleeper is to allow you to sleep more using the stock iOS alarms.

*   Change the snooze time of the alarm
*   Using a system prompt upon unlocking the device, optionally skip an alarm within a particular set time
*   Skip an alarm completely by specifying a specific date or holiday
*   Auto-set: Configure alarms to automatically update based on the sunrise or sunset time
*   Supports both standalone alarms as well as the Bedtime Alarm introduced with iOS 10
*   Compatible with iOS 8 - iOS 14 (note: the auto-set feature is only supported on iOS 10+)
*   Compatible with iPhones, iPads, and iPod Touches

## *Snooze Time*

Editing or creating a new alarm will now show a new option: Snooze Time. Entering this view will allow you specify the hours, minutes, and seconds you'd like your alarm to perform the snooze. This interface was designed to integrate seamlessly with the stock iOS Clock application.

## *Skipping*

Use the Skip Toggle to enable or disable the ability to skip the particular alarm. Skipping an alarm can be achieved via a prompt that is displayed upon unlocking the device within a specific period of time or by specifying a particular date/holiday to skip.

**Skip Time**

Skip Time is the threshold that is used to determine if you will be prompted to skip the given alarm. The prompt to skip an eligible alarm will show up after unlocking the device. As an example, if you have an alarm set to go off at 8:00am and your Skip Time is 30 minutes, then if you unlock the device between 7:30am and 8:00am, you will be asked if you'd like to skip that alarm. Only one prompt will be shown each time the device is unlocked; the earliest alarm that can be skipped is what will be shown. This feature can be very useful if you frequently find yourself waking up before an alarm is going to go off.

**Skip Dates / Away Dates**

The Skip Dates interface allows you to pick specific dates and/or holidays in which the particular alarm will be completely skipped/silenced. Know you'll be taking a vacation or a day off from work? Add that date to your alarm so you can sleep in on those days. Do you work on Thanksgiving or Christmas? Probably not, so be sure to add those holidays to the selected holidays for your alarm. This prevents you from having to remember to turn off an alarm when you don't need to wake up early.

## *Auto-Set (iOS 10+)*

You can use the auto-set feature to automatically update alarms based on the sunrise/sunset times. To use this feature, please ensure that you have the Weather application installed with a valid location set. Once enabled, the alarms will automatically update periodically to adjust to the sunrise/sunset times based on the first location you configured in the Weather application.

## *Source Code*

[This project is open source.](https://github.com/joshuaseltzer/Sleeper)