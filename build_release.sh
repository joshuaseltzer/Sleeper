#!/bin/bash

# move the default development and Packix control files temporarily
mv -n control control_dev
mv -n control_Packix control

# select the Xcode 9.4.1 (to support iOS 8 with arm64e)
sudo xcode-select -s /Applications/Xcode941.app

# build the Packix package (this should produce an error when trying to build arm64e)
make clean
make package

# move back to the latest Xcode to finish linking for arm64e support
sudo xcode-select -s /Applications/Xcode.app

# finish making the Packix package
make package

# return the Packix control file to the original name, and prep the BigBoss control file for build
mv -n control control_Packix
mv -n control_BigBoss control

# select the Xcode 9.4.1 (to support iOS 8 with arm64e)
sudo xcode-select -s /Applications/Xcode941.app

# build the BigBoss package (this should produce an error when trying to build arm64e)
make clean
make package

# move back to the latest Xcode to finish linking for arm64e support
sudo xcode-select -s /Applications/Xcode.app

# finish making the Bigboss package
make package

# return the BigBoss and development control files back to their original states
mv -n control control_BigBoss
mv -n control_dev control