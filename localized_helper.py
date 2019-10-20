#!/usr/bin/env python3

import sys
import os

# path to the Sleeper bundle which is used to store the holidays and localized strings
SLEEPER_BUNDLE_PATH = "layout/Library/Application Support/Sleeper.bundle"

# function that will remove x number of lines from the end of the localized string files (to remove the unnecessary holiday names)
def remove_trailing_localized_strings(num_lines):
    # list all of the directories in the Sleeper bundle
    for (dirpath, dirnames, filenames) in os.walk(SLEEPER_BUNDLE_PATH):
        for dirname in dirnames:
            # each lproj directory should only contain one file, the localized strings file
            string_file_path = os.path.join(SLEEPER_BUNDLE_PATH, dirname, LOCALIZED_STRINGS_FILE)
            with open(string_file_path, 'r') as fp:
                existing_lines = fp.readlines()
            with open(string_file_path, 'w') as fp:
                fixed_lines = existing_lines[:-num_lines]
                fixed_lines[-1] = fixed_lines[-1].rstrip()
                fp.writelines(fixed_lines)
  
if __name__== "__main__":
    if len(sys.argv) == 3:
        if sys.argv[1] == "-r":
            # update the localized string files to remove unused localization strings
            # e.g. this includes files from v5.0.0 and v5.0.1 (this code was used to fix the files in v5.1.0)
            remove_trailing_localized_strings(sys.argv[2])
    else:
        print("Incorrect usage!")