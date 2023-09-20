# circadian_openrgb - automatic day/night RGB cycles,
# Copyright (C) 2023 rniem379349
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

#!/bin/bash

# Dependencies
if [[ $(which openrgb) = "" ]]; then
	echo "Unable to find OpenRGB."
	echo "Please install OpenRGB and ensure the executable is in your PATH environment variable."
	exit 1
fi
if [[ $(which hdate) = "" ]]; then
	echo "Unable to find hdate."
	echo "Please install it by running:"
	echo "sudo apt-get install hdate"
	exit 1
fi

# Config
conffile_dir=/home/$USER/.config/circadian_openrgb/
conffile_name=crcdn_openrgb.config
conffile_path=$conffile_dir$conffile_name

if ! [[ -f $conffile_path ]]; then
	echo "Config file not found - initializing..."
	echo "First, to fetch the most accurate sunet/sunrise times I need the geographical coordinates of your location."
	echo "You can choose not to provide these, in which case I will try and guess your location based on system timezone."
	read -p "Please enter your latitude (in the following format, e.g. N25.150), or leave blank (press enter):" latitude
	read -p "Please enter your longitude (in the following format, e.g. W82.420), or leave blank (press enter):" longitude
	echo "Provided coordinates: $latitude, $longitude"
	echo "You can also provide your timezone, in case hdate's timezone autodetection doesn't work as expected."
	read -p "Please enter your timezone (in hours +/-UTC, e.g. 2, -5):" tzone
	echo "Finally, you need to provide the paths to your OpenRGB day/night profiles."
	echo "NOTE: to prevent strange bugs, please enter the absolute paths to your profiles, e.g. /home/user/profile, not ~/profile etc."
	read -p "Please enter the absolute path to your OpenRGB day profile (e.g. /path/to/day/profile.orp):" day_mode_rgb_profile
	read -p "Please enter the absolute path to your OpenRGB night profile (e.g. /path/to/night/profile.orp):" night_mode_rgb_profile
	echo "Now I'm going to create a config file to store this data."
	mkdir -p $conffile_dir && touch $conffile_path
	echo "latitude=$latitude"$'\n'"longitude=$longitude"$'\n'"tzone=$tzone" >> $conffile_path
	echo "day_mode_rgb_profile=$day_mode_rgb_profile"$'\n'"night_mode_rgb_profile=$night_mode_rgb_profile" >> $conffile_path
	echo "Created config file ($conffile_path) and added the location and OpenRGB day/night profile paths."
	echo "Ready."
fi

# load config file
. $conffile_path

# hdate command setup
hdate_latitude="-l $latitude"
hdate_longitude="-L $longitude"
hdate_tz="-z$tzone"
if [[ $latitude = "" ]] || [[ $longitude = "" ]]; then
	hdate_latitude=""
	hdate_longitude=""
fi
if [[ $tzone = "" ]]; then
	hdate_tz=""
fi

# Fetch sunrise/sunset times
current_time=$(date +%H:%M)
sunrise=$(hdate -s $hdate_latitude $hdate_longitude $hdate_tz 2> /dev/null | grep "sunrise" | cut -d " " -f 2)
sunset=$(hdate -s $hdate_latitude $hdate_longitude $hdate_tz 2> /dev/null | grep "sunset" | cut -d " " -f 2)

echo "current time: $current_time"
echo "sunrise time: $sunrise"
echo "sunset time: $sunset"

if [[ $sunset > $current_time ]] && [[ $current_time > $sunrise ]]; then
	echo "Daytime - loading RGB day mode"
	$(which openrgb) -p $day_mode_rgb_profile > /tmp/circadian_openrgb.log
else
	echo "Nighttime - loading RGB night mode"
	$(which openrgb) -p $night_mode_rgb_profile > /tmp/circadian_openrgb.log
fi

# OpenRGB error handling
openrgb_output=$(cat /tmp/circadian_openrgb.log)
if [[ $openrgb_output == *"Profile failed to load"* ]]; then
	echo "OpenRGB profile failed to load!"
	echo $openrgb_output
	exit 1
fi
