#!/bin/bash

# move the default development and Packix control files temporarily
mv -n control control_dev
mv -n control_Packix control

# build the Packix package
make package

# return the Packix control file to the original name, and prep the BigBoss control file for build
mv -n control control_Packix
mv -n control_BigBoss control

# build the BigBoss package
make package

# return the BigBoss and development control files back to their original states
mv -n control control_BigBoss
mv -n control_dev control