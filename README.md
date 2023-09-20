# circadian_openrgb
A bash script to switch OpenRGB color profiles depending on your local day/night cycle.
Simply create OpenRGB lighting modes for day and night, set up circadian_openrgb and your
day/night profiles will load automatically.
Tested on Linux Mint 21.1.

## Dependencies
- `hdate` - to fetch local sunrise/sunset times. Available on apt.
- `openrgb` (https://gitlab.com/CalcProgrammer1/OpenRGB) - to define and switch RGB lighting profiles. Make sure to have the executable in your `$PATH`, so it's accessible by `circadian_openrgb`.

## Setting up the script
1. `git clone` the repo
2. Copy the `circadian_openrgb.sh` executable to your directory of choice (e.g. `/usr/local/bin`)
3. Run the executable: `bash /path/to/circadian_openrgb.sh`. This will run you through
an initial setup. You will be asked to provide your location info (geographical coordinates), timezone info,
and the paths to your OpenRGB day/night profiles. A config file will be created in `/home/$USER/.config/circadian_openrgb`.
4. Once you have set up the script, you should be able to run it and have your day/night profile set. Check for OpenRGB or circadian_openrgb errors (a temporary log file should be found in `/tmp/circadian_openrgb.log`).

## Automation using a systemd user service
If everything is set up correctly, the script should have loaded your OpenRGB profile. The last step is to have `circadian_openrgb` working in the background, setting day/night modes automatically. This can be done by creating a `systemd` user service:
1. Edit the `circadian_openrg.service` file - the only thing that needs changing is the path to your script in the `ExecStart` field, e.g. `ExecStart=bash /usr/local/bin/circadian_openrgb.sh`. The service file is configured to run `circadian_openrgb` every five minutes - feel free to modify the service file to your liking
2. Copy this file to the `systemd` user service config directory, usually `/home/$USER/.config/systemd/user`
3. Install the service using `systemctl --user daemon-reload`
4. Start the service: `systemctl --user start circadian_openrgb.service`
5. Enable the service: `systemctl --user enable circadian_openrgb.service`

Now your service should run automatically after login and periodically in the background.