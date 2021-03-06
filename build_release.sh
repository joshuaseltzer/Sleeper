#!/bin/bash

# move the default development and Packix control files temporarily
mv -n control control_dev
mv -n control_Packix control

# build the Packix package
make clean
make package FINALPACKAGE=1

# return the Packix control file to the original name, and prep the BigBoss control file for build
mv -n control control_Packix
mv -n control_BigBoss control

# build the BigBoss package (this should produce an error when trying to build arm64e)
make clean
make package FINALPACKAGE=1

# return the BigBoss and development control files back to their original states
mv -n control control_BigBoss
mv -n control_dev control