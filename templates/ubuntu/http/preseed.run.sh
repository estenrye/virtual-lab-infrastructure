#!/bin/bash

# Although preseeding the network configuration is normally not possible when using network preseeding (using “preseed/url”),
# you can use the following hack to work around that, for example if you'd like to set a static address for the network interface.
# The hack is to force the network configuration to run again after the preconfiguration file has been loaded by creating a “preseed/run”
# script containing the following commands:
kill-all-dhcp; netcfg