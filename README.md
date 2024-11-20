# CrowdStrike Log Collector Helper

## Purpose
Not everyone is a wizard with Linux commands. This project attempts to make interacting with CrowdStrike's Next-Gen SIEM log collector on Linux easier. The options provided here are not an exhaustive list of interations with the log collector. Instead, these are meant to provide enough for basic setup, use, and troubleshooting while using it.

This provides you the following options:
- **INSTALLATION**
  - Installs the log collector using either dpkg or rpm (depending on which is available on the distro)
    - ***NOTE***: The installation filename should be unchanged from when it was downloaded and it must be in the same directory as this script when ran
- **SETUP**
  - Apply some recommended settings for allowing the log collector on Linux, as mentioned in the LogScale documentation site
    1. Set the log collector service to start-up on boot
    2. Add the log collector to the 'adm' group
    3. Allow log collector to bind to standard ports (ie. Network ports 0-1023)
- **BACKUP**
  - Create a backup of the current configuration file
    - This is saved into the same directory as this script with the name "BACKUP_config.yaml"
- **CONFIGURATION**
  - Manually edit the configuration file
    - This uses the Linux utility Nano. Nano is meant to be user friendly for those unfamiliar with terminal-based editors. If you are used to working in Word, Notepad, or other similar graphical editors, then this will be an approachable way to interact with the configuration file.
  - Use a backup configuration as the active configuration
    - This looks for a previously created "BACKUP_config.yaml" file in the current working directory. If such a file exists, it can copy the contents of this to the configuration file that the log collector uses.
    - ***NOTE***: This overwrites the entirety of the contents from the backup file into the configuration file used by the log collector.
- **TROUBLESHOOTING**
  - Restart the log collector service
    - Attempts to restart the log collector service. This also checks the status to let you know whether or not the service is running after the attempt.
  - Quick view of the currently active configuration
    - Displays the configuration that the log collector is set to use in the output of the screen. Press the spacebar or 'ENTER' on your keyboard if this is more lines than your terminal window can show.
    - ***NOTE***: This is for display purposes only. Use the configuration option to make changes to the configuration file.
  - Show debug logs (Stops the collector service if it is running, and attempts to restart it when it is finished)
    - This allows you to either display debug logs for the log collector within your terminal window, or save debug logs to a file in the current working directory with the date and time in the filename.
    - If the log collector service is already running, this stops it before running the debug logs process and then attempts to restart it once this is finished.

## How to use this
Use this command to pull this file from Github onto your Linux host:
`curl -O "https://raw.githubusercontent.com/cs-APreston-ghAccount/CSLogCollectorHelper/refs/heads/main/CSLogCollectorHelper.sh"`

Use this command to run the script:
`sudo bash CSLogCollectorHelper.sh`
- Some of the actions taken within this script require elevated permissions. Because of this, you should always run this script using 'sudo'.
- If you are unfamiliar with Linux commands, know that this command attempts to run the helper script from the current working directory. This command will not run the script if you are in a different directory.

## Resource(s)
[Falcon LogScale Documentation Site](https://library.humio.com/)

