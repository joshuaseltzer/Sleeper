import sys
import os
import datetime
import pytz
import holidays
import plistlib

# define the years which will be generated for any given country
START_YEAR = 2019
END_YEAR = 2030

# define some string constants that will be used when parsing holidays for our use case
OBSERVED_TEXT = " (Observed)"
NEW_YEARS_TEXT = "New Year's Day"

# define constants used to generate custom holidays
THANKSGIVING_DAY = "Thanksgiving Day"
DAY_AFTER_THANKSGIVING = "Day After Thanksgiving"

# define the path to the Sleeper bundle which is used to store the holidays and localized strings
SLEEPER_BUNDLE_PATH = "layout/Library/Application Support/Sleeper.bundle"

def gen_country_holidays(country_code):
    # define the high-level plist file which will be generated for this country
    plist_root = []
    holiday_map = {}

    '''
    # modify the country code with a custom class if necessary
    holiday_class = "holidays.{0}"
    if country_code == 'US':
        holiday_class = "CustomUSHolidays"
    else:
        holiday_class = "holidays.{0}".format(country_code)
    '''

    # generate the list of holidays for the given country code (if valid) for the iterated year
    try:
        exec("all_holidays = sorted(holidays.{0}(observed=True, expand=False, years=list(range({1}, {2}))).items())".format(country_code, START_YEAR, END_YEAR), globals())
    except AttributeError:
        print("Entered invalid country code, exiting.")
        exit(1)

    # remap the holidays by year
    holidays_by_year = {}
    for date, name in all_holidays:
        dates_by_year = holidays_by_year.get(date.year)
        if not dates_by_year:
            dates_by_year = {date:name}
        else:
            dates_by_year.update({date:name})
        holidays_by_year.update({date.year:dates_by_year})

    # iterate through the sorted holidays to remove any non-observed holidays first
    for year in holidays_by_year.keys():
        # get all of the holidays for the iterated year
        holidays_for_year = holidays_by_year.get(year)

        # iterate through the sorted holidays to remove any non-observed holidays first
        items_to_remove = []
        new_holidays = {}
        for date, name in holidays_for_year.items():
            if OBSERVED_TEXT in name and NEW_YEARS_TEXT not in name:
                items_to_remove.append(name.replace(OBSERVED_TEXT, ""))

            # use this opportunity to add additional holidays for a particular country
            if country_code == 'US':
                new_holiday = generate_additional_US_holiday(date, name)
                print(new_holiday)
                if new_holiday:
                    new_holidays.update(new_holiday)

        holidays_for_year.update(new_holidays)
        holidays_for_year = {date:name.replace(OBSERVED_TEXT, "") for date, name in holidays_for_year.items() if name not in items_to_remove}
        print(holidays_for_year)

        for date, name in holidays_for_year.items():
            # check if we have already defined the localized string for the name of the given holiday
            if name not in lz_name_map:
                # ask the user to input the localized name used for this name
                print("Please enter the localized key for holiday \"{0}\":".format(name))
                lz_name = input()
                lz_name_map.update({name:lz_name})
            else:
                lz_name = lz_name_map.get(name)
            
            # update the holiday map with the added holiday
            date_time = datetime.datetime.combine(date, datetime.time(0, 0)).astimezone(pytz.utc)
            dates = holiday_map.get(lz_name)
            if not dates:
                dates = [date_time]
            else:
                dates.append(date_time)
            holiday_map.update({lz_name:dates})

    # generate the plist
    for lz_name in holiday_map.keys():
        # get all of the parts for the dictionary that will be added to the plist
        dates = holiday_map.get(lz_name)

        # add a new entry to the plist
        plist_root.append({'lz_key':lz_name, 'dates':dates, 'selected':False})

        # write the plist to file
        with open("{0}/holidays-{1}.plist".format(SLEEPER_BUNDLE_PATH, country_code), 'wb') as fp:
            plistlib.dump(plist_root, fp, sort_keys=False)

def update_localized_strings():
    # list all of the directories in the Sleeper bundle
    for (dirpath, dirnames, filenames) in os.walk(SLEEPER_BUNDLE_PATH):
        for dirname in dirnames:
            if 'en.lproj' in dirname:
                # each lproj directory should only contain one file, the localized strings file
                with open("{0}/{1}/Localizable.strings".format(SLEEPER_BUNDLE_PATH, dirname), 'r+') as fp:
                    existing_strings = fp.read()
                    
                    # iterate through all of the localized strings to see if the file needs modifications
                    first_change = True
                    for name, lz_name in lz_name_map.items():
                        if lz_name not in existing_strings:
                            if first_change:
                                fp.write("\n\n")
                                first_change = False
                            fp.write("\"{0}\" = \"{1}\";\n".format(lz_name, name))

# add additional holidays for the United State country
def generate_additional_US_holiday(date, name):
    if THANKSGIVING_DAY in name:
        return {date + datetime.timedelta(days=1):DAY_AFTER_THANKSGIVING}

# custom class for additional United States holidays
'''
class CustomUSHolidays(holidays.UnitedStates):
    def _populate(self, year):
        # use the default United states holidays as a base
        holidays.UnitedStates._populate(self, year)

        # add the Day After Thanksgiving (credit: https://codegolf.stackexchange.com/a/64803)
        day_after_thanksgiving = lambda x:28.11-(x-2+x/4-x/100+x/400)%7
        self[datetime.date(year, 11, round(day_after_thanksgiving(year)) + 1)] = "Day After Thanksgiving"

        # add Christmas Eve
        print(self.
        self[datetime.date(year, 12, 24)] = "Christmas Eve"
'''
  
if __name__== "__main__":
    if len(sys.argv) > 1:
        lz_name_map = {}

        # generate the plist 
        for country_code in sys.argv[1:]:
            print("Generating holiday plist file for {0}".format(country_code))
            gen_country_holidays(country_code)

        # update the localized string files
        print("Updating the localized string files if needed.")
        update_localized_strings()
    else:
        print("Incorrect usage!  Please supply a valid country code.")