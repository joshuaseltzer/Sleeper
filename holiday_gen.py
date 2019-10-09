#!/usr/bin/env python3

import sys
import os
import datetime
import pytz
import holidays
import plistlib

# define the years which will be generated for any given country
START_YEAR = 2019
END_YEAR = 2099

# define constants used to modify holidays upon generation
OBSERVED_TEXT = "(Observed)"
THANKSGIVING_TEXT = "Thanksgiving"
DAY_AFTER_THANKSGIVING_TEXT = "Day After Thanksgiving"
CHRISTMAS_DAY_TEXT = "Christmas Day"
CHRISTMAS_EVE_TEXT = "Christmas Eve"
NEW_YEARS_DAY_TEXT = "New Year's Day"
NEW_YEARS_EVE_TEXT = "New Year's Eve"

# define the path to the Sleeper bundle which is used to store the holidays and localized strings
SLEEPER_BUNDLE_PATH = "layout/Library/Application Support/Sleeper.bundle"

# entry point for creating the holidays for a particular country
def gen_country_holidays(country_code):
    print("Generating holiday plist file for {0}".format(country_code))

    # define the high-level plist file and holiday mapping which will be generated for this country
    plist_root = []
    holiday_map = {}

    # iterate through each year one by one
    years = list(range(START_YEAR, END_YEAR))
    for year in years:
        # generate the list of holidays for the given country code (if valid) for the iterated year
        try:
            global holidays_for_year
            exec("holidays_for_year = holidays.{0}(observed=True, expand=False, years=[{1}])".format(country_code, year), globals())
        except AttributeError:
            print("Entered invalid country code, exiting.")
            exit(1)

        # iterate through the generated holidays to potentially remove holidays
        holidays_to_remove = []
        for date, name in holidays_for_year.items():
            # mark any non-observed holidays for removal
            if OBSERVED_TEXT in name:
                holidays_to_remove.append(name.replace(OBSERVED_TEXT, "").strip())
        holidays_for_year = {date:name.replace(OBSERVED_TEXT, "").strip() for date, name in holidays_for_year.items() if name not in holidays_to_remove or date.weekday() < 5}

        # add additional holidays for particular countries
        holidays_for_year.update(generate_additional_holidays(country_code, year, holidays_for_year))

        # final pass of the holidays for the given year to add them to the plist
        for date, name in sorted(holidays_for_year.items()):
            # update the holiday map with the added holiday
            date_time = datetime.datetime.combine(date, datetime.time(0, 0)).astimezone(pytz.utc)
            dates = holiday_map.get(name)
            if not dates:
                dates = [date_time]
            elif date_time not in dates:
                dates.append(date_time)
            holiday_map.update({name:dates})

    # generate the plist
    for name in holiday_map.keys():
        # get all of the parts for the dictionary that will be added to the plist
        dates = holiday_map.get(name)

        # add a new entry to the plist
        plist_root.append({'name':name, 'dates':dates, 'selected':False})

        # write the plist to file
        with open(os.path.join(SLEEPER_BUNDLE_PATH, "holidays-{0}.plist".format(country_code)), 'wb') as fp:
            plistlib.dump(plist_root, fp, sort_keys=False)

# creates new holidays for particular countries
def generate_additional_holidays(country_code, year, holidays_for_year):
    new_holidays = {}

    if country_code == 'US':
        # add new holidays which have different dates each year
        for date, name in holidays_for_year.items():
            if THANKSGIVING_TEXT in name:
                new_holidays.update({date + datetime.timedelta(days=1):DAY_AFTER_THANKSGIVING_TEXT})

        # add New Year's Eve and Christmas Eve which are static each year
        new_holidays.update({datetime.date(year, 12, 24):CHRISTMAS_EVE_TEXT, datetime.date(year, 12, 31):NEW_YEARS_EVE_TEXT})

    return new_holidays

# function that will remove x number of lines from the end of the localized string files (to remove the unnecessary holiday names)
def update_localized_strings(num_lines):
    # list all of the directories in the Sleeper bundle
    for (dirpath, dirnames, filenames) in os.walk(SLEEPER_BUNDLE_PATH):
        for dirname in dirnames:
            # each lproj directory should only contain one file, the localized strings file
            string_file_path = os.path.join(SLEEPER_BUNDLE_PATH, dirname, "Localizable.strings")
            with open(string_file_path, 'r') as fp:
                existing_lines = fp.readlines()
            with open(string_file_path, 'w') as fp:
                fixed_lines = existing_lines[:-num_lines]
                fixed_lines[-1] = fixed_lines[-1].rstrip()
                fp.writelines(fixed_lines)
  
if __name__== "__main__":
    if len(sys.argv) == 2:
        # generate the plist 
        gen_country_holidays(sys.argv[1])

        # update the localized string files to remove unused localization strings
        # this includes files from Releases 5.0.0 and 5.0.1 (this code was used in Release 5.1.0)
        #update_localized_strings(14)
    else:
        print("Incorrect usage!  Please supply a valid country code.")