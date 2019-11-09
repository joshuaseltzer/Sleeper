#!/usr/bin/env python3

import sys
import os
import re
import datetime
import holidays
import plistlib

# years which will be generated for any given country
START_YEAR = 2019
END_YEAR = 2050

# constants used to modify holidays upon generation
OBSERVED_TEXT = "(Observed)"
THANKSGIVING_TEXT = "Thanksgiving"
DAY_AFTER_THANKSGIVING_TEXT = "Day After Thanksgiving"
MARTIN_LUTHER_KING_JR_TEXT = "Martin Luther King, Jr. Day"
CHRISTMAS_DAY_TEXT = "Christmas Day"
CHRISTMAS_EVE_TEXT = "Christmas Eve"
NEW_YEARS_DAY_TEXT = "New Year's Day"
NEW_YEARS_EVE_TEXT = "New Year's Eve"

# path to the Sleeper bundle which is used to store the holidays and localized strings
SLEEPER_BUNDLE_PATH = "layout/Library/Application Support/Sleeper.bundle"

# name of the localized string files included in the Sleeper bundle
LOCALIZED_STRINGS_FILE = "Localizable.strings"

# names of the keys that will be used when creating the plist
DATE_CREATED_KEY = "dateCreated"
HOLIDAYS_KEY = "holidays"
NAME_KEY = "name"
DATES_KEY = "dates"

# entry point for creating the holidays for a particular country
def gen_country_holidays(country_code):
    print("Generating holiday plist file for \"{0}\" from years {1} to {2}.".format(country_code, START_YEAR, END_YEAR))

    # define the high-level plist file and holiday mapping which will be generated for this country
    country_holidays = []
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

        if year == START_YEAR:
            print(holidays_for_year)
            print("This country has {0} holidays.".format(len(holidays_for_year)))

        # iterate through the generated holidays to potentially remove holidays
        holidays_to_remove = []
        for date, name in holidays_for_year.items():
            # mark any non-observed holidays for removal
            if OBSERVED_TEXT in name:
                holiday_to_remove = name.replace(OBSERVED_TEXT, "").strip()
                holidays_to_remove.append(holiday_to_remove)
                print("Attempting to remove holiday \"{0}\" since this is an observed holiday in {1}.".format(holiday_to_remove, year))
        holidays_for_year = {date:name.replace(OBSERVED_TEXT, "").strip() for date, name in holidays_for_year.items() if name not in holidays_to_remove or date.weekday() < 5}

        if year == START_YEAR:
            print("After removing observed holidays, this country has {0} holidays.".format(len(holidays_for_year)))

        # add additional holidays for particular countries
        holidays_for_year.update(generate_additional_holidays(country_code, year, holidays_for_year))

        # final pass of the holidays for the given year to add them to the plist
        for date, combined_names in sorted(holidays_for_year.items()):
            # remove some extra text in between brackets from the name
            combined_names = re.sub(r"\[.*?\]", "", combined_names)

            # check to see if the name needs to be split (the holidays library will combine the same dates with a combined name)
            for name in combined_names.split(', '):
                # remove any additional leading and trailing whitespace
                name = name.strip()

                # update the holiday map with the added holiday
                date_time = datetime.datetime.combine(date, datetime.time(0, 0)).astimezone(datetime.timezone.utc)
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
        country_holidays.append({NAME_KEY:name, DATES_KEY:dates})

    # create the root of the plist
    plist_root = {DATE_CREATED_KEY:datetime.datetime.now().astimezone(datetime.timezone.utc), "holidays":country_holidays}

    # write the final plist to file
    plist_file_path = os.path.join(SLEEPER_BUNDLE_PATH, "{0}_holidays.plist".format(country_code.lower()))
    with open(plist_file_path, 'wb') as fp:
        plistlib.dump(plist_root, fp, sort_keys=False)

    print("Wrote results to file: {0}".format(plist_file_path))
    print("Holiday list generation completed for \"{0}\" from years {1} to {2}.".format(country_code, START_YEAR, END_YEAR))

# creates new holidays for particular countries
def generate_additional_holidays(country_code, year, holidays_for_year):
    new_holidays = {}

    if country_code == 'US':
        # add new holidays which have different dates each year
        for date, name in holidays_for_year.items():
            if THANKSGIVING_TEXT in name:
                print("Adding additional holiday, \"{0}\" for {1}.".format(DAY_AFTER_THANKSGIVING_TEXT, year))
                new_holidays.update({date + datetime.timedelta(days=1):DAY_AFTER_THANKSGIVING_TEXT})

            if MARTIN_LUTHER_KING_JR_TEXT in name:
                print("Fixing Martin Luther King Jr. Day")
                new_holidays.update({date:"Martin Luther King Jr. Day"})

        # add New Year's Eve and Christmas Eve which are static each year
        print("Adding additional holiday, \"{0}\" for {1}.".format(CHRISTMAS_EVE_TEXT, year))
        print("Adding additional holiday, \"{0}\" for {1}.".format(NEW_YEARS_EVE_TEXT, year))
        new_holidays.update({datetime.date(year, 12, 24):CHRISTMAS_EVE_TEXT, datetime.date(year, 12, 31):NEW_YEARS_EVE_TEXT})

    return new_holidays
  
if __name__== "__main__":
    if len(sys.argv) == 2:
        # generate the plist 
        gen_country_holidays(sys.argv[1])
    else:
        print("Incorrect usage!  Please supply a valid country code.")