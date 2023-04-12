#!/bin/bash

# use the Xcode 11 toolchain to ensure arm64e compatibility on iOS 12 and iOS 13 for rootful builds
export PREFIX=$THEOS/toolchain/Xcode11.xctoolchain/usr/bin/

# move the default development and Havoc control files temporarily
mv -n control control_dev
mv -n control_Havoc control

# build the Havoc package
make clean
make package FINALPACKAGE=1

# return the Havoc control file to the original name, and prep the BigBoss control file for build
mv -n control control_Havoc
mv -n control_BigBoss control

# build the BigBoss package (this should produce an error when trying to build arm64e)
make clean
make package FINALPACKAGE=1

# return the BigBoss and development control files back to their original states
mv -n control control_BigBoss
mv -n control_dev control