#!/bin/bash

##########
# Version 2.0
#
# This script gives the user the following options for working with CrowdStrike's Next-Gen SIEM log collecter
# 0) EXIT - Exit script
# 1) INSTALLATION - Install the log collector
# 2) SETUP - Allow recommended settings and permissions for the log collector on Linux
# 3) BACKUP - Create a backup of the current configuration file
# 4) CONFIGURATION - Manually edit the configuration file (uses Nano)
# 5) CONFIGURATION - Use a backup configuration as the active configuration
# 6) TROUBLESHOOTING - Restart the log collector service
# 7) TROUBLESHOOTING - Quick view of the currently active configuration
# 8) TROUBLESHOOTING - Show debug logs (Stops the collector service if it is running, and attempts to restart it when it is finished)
##########

##### Disclaimer
echo ""
echo "DISCLAIMER:"
echo "This is not an officially supported project. User assumes all"
echo "responsibility for any changes made due to the use of this script."
echo ""
sleep 1s
read -n 1 -s -r -p "Press any key to continue"

##### Variables
FLEET_MANAGED="no"
SERVICE_USER="log collector not installed"
LOG_COLLECTOR_VERSION="log collector not installed"

##### While loop to allow multiple options to be ran during use
while [ 1 == 1 ];
do
    ##### Set/Reset LOOP_VARIABLE
    LOOP_VARIABLE=100

    ##### Check if log collector is already installed and set variables accordingly
    if [ -f  /usr/bin/humio-log-collector ]; then
        SERVICE_USER="humio-log-collector"
        LOG_COLLECTOR_VERSION=$($SERVICE_USER --version | grep -oP "\d+\.\d+\.\d+")
        if grep -q "fleetManagement:" /etc/$SERVICE_USER/config.yaml; then
            FLEET_MANAGED="yes"
        fi
    elif [ -f  /usr/bin/logscale-collector ]; then
        SERVICE_USER="logscale-collector"
        LOG_COLLECTOR_VERSION=$($SERVICE_USER --version | grep -oP "\d+\.\d+\.\d+")
        if grep -q "fleetManagement:" /etc/$SERVICE_USER/config.yaml; then
            FLEET_MANAGED="yes"
        fi
    fi

    if [ "$SERVICE_USER" != "log collector not installed" ]; then
        CONFIG_FILE_PATH="/etc/"$SERVICE_USER"/config.yaml"
        SERVICE_NAME=$SERVICE_USER".service"
        EXE_LOCATION="/usr/bin/"$SERVICE_USER
        SYSTEMD_SERVICE_OVERRIDE_DIR="/etc/systemd/system/"$SERVICE_USER".service.d"
        SYSTEMD_SERVICE_OVERRIDE_FILE="/etc/systemd/system/"$SERVICE_USER".service.d/override.conf"
        SERVICE_STATE=$(systemctl show $SERVICE_NAME | grep ActiveState | grep -oP "\w+$")
    fi

    ##### Output the options to the user and ask them to pick one
    echo ""
    echo ""

    if [ "$LOG_COLLECTOR_VERSION" = "log collector not installed" ]; then
        echo "***** Next-Gen SIEM Log Collector Helper *****"
        echo " 0) EXIT - Exit script"
        echo " 1) INSTALLATION - Install the log collector"
        echo ""
        read -p "Type the number of an option and press 'ENTER': " LOOP_VARIABLE
    else
        echo "***** Next-Gen SIEM Log Collector Helper *****"
        echo " LOG COLLECTOR VERSION: "$LOG_COLLECTOR_VERSION
        echo " FLEET MANAGED: "$FLEET_MANAGED
        echo " SERVICE STATE: "$SERVICE_STATE
        echo ""
        echo " 0) EXIT - Exit script"
        echo " 1) INSTALLATION - Install/Update the log collector"
        echo " 2) SETUP - Allow recommended settings and permissions for the log collector"
        echo " 3) BACKUP - Create a backup of the current configuration file"
        echo " 4) CONFIGURATION - Manually edit the configuration file (uses Nano)"
        echo " 5) CONFIGURATION - Use a backup configuration as the active configuration"
        echo " 6) TROUBLESHOOTING - Restart the log collector service"
        echo " 7) TROUBLESHOOTING - Quick view of the currently active configuration"
        echo " 8) TROUBLESHOOTING - Show debug logs"
        echo ""
        read -p "Type the number of an option and press 'ENTER': " LOOP_VARIABLE
    fi

    ##### Start 'if' statements for different options
    if [ $LOOP_VARIABLE == 1 ]; then
        # Install the log collector
        echo ""
        echo "===================="
        echo "NOTE: If installing the CrowdStrike log collector,"
        echo "the installation file must be in the same directory"
        echo "as this script."
        echo ""
        read -p "Do you want to install the log collector? [y,n] " yn10

        if [ $yn10 == "y" ]; then
            # Install the log collector using either "dpkg" or "rpm"
            if ls humio-log-collector_*_linux_*.* >/dev/null 2>&1; then
                # Check if dpkg is installed on this host
                if [ -n "$(command -v dpkg)" ]; then
                    echo ""
                    echo "===================="
                    echo "Select the installer file you wish to use by typing the number"
                    echo "of the file listed below and press 'ENTER':"
                    echo ""
                    select INSTALLER_FILE in humio-log-collector_*_linux_*.deb; do
                        echo "You selected $INSTALLER_FILE"
                        break
                    done
                    dpkg -i $INSTALLER_FILE
                # Check if rpm is installed on this host
                elif [ -n "$(command -v rpm)" ]; then
                    echo ""
                    echo "===================="
                    echo "Select the installer file you wish to use by typing the number"
                    echo "of the file listed below and press 'ENTER':"
                    echo ""
                    select INSTALLER_FILE in humio-log-collector_*_linux_*.rpm; do
                        echo "You selected $INSTALLER_FILE"
                        break
                    done
                    rpm -i $INSTALLER_FILE
                # Output message if unable to determine installation utility
                else
                    echo ""
                    echo "===================="
                    echo "Unable to determine installation utility."
                    echo "Please make sure either 'dpkg' or 'rpm' is"
                    echo "installed on this Linux host."
                    echo "You can attempt installing the log collector"
                    echo "without using this script as an alternative."
                fi
            else
                echo ""
                echo "===================="
                echo "Missing installation file. Please download"
                echo "from your Falcon Console and place the file in the"
                echo "same working directory as this script."
                echo "Then you can run this to install the log collector."
            fi

        else
            # Continue without installation
            echo ""
            echo "===================="
            echo "Continuing without installing the log collector."
        fi
        echo ""
        read -n 1 -s -r -p "Press any key to return to the main menu"

    elif [ $LOOP_VARIABLE == 2 ]; then
        # Allow recommended settings and permissions for the log collector on Linux
        # SOURCE: https://library.humio.com/falcon-logscale-collector/log-collector-install-custom-linux.html#log-collector-granting-access
        echo ""
        echo "===================="
        echo "The following options are recommended additional steps"
        echo "for setting up the log collector on a Linux host."
        echo "You can read more about these in the documentation:"
        echo "https://library.humio.com/falcon-logscale-collector/log-collector-install-custom-linux.html#log-collector-granting-access"

        # Configure log collector service to start-up on boot
        echo ""
        echo ""
        read -p "(Recommended) Set the log collector service to start-up on boot? [y,n] " yn20

        if [ $yn20 == "y" ]; then
            systemctl enable $SERVICE_NAME
            echo ""
            echo "===================="
            echo $SERVICE_NAME" set to start-up on boot"
            echo ""
            read -n 1 -s -r -p "Press any key to continue"
        else
            echo ""
            echo "===================="
            echo "No changes made to the current setup"
            echo ""
            read -n 1 -s -r -p "Press any key to continue"
        fi

        # Add permisions to the log collector user ("adm" group) 
        # to allow access to a majority of the log files in the /var/log directory
        echo ""
        echo ""
        echo "===================="
        read -p "(Recommended) Add the log collector user to the 'adm' group? [y,n] " yn21

        if [ $yn21 == "y" ]; then
            usermod -a -G adm $SERVICE_USER
            echo ""
            echo "===================="
            echo $SERVICE_USER" added to the 'adm' group"
            echo ""
            read -n 1 -s -r -p "Press any key to continue"
        else
            echo ""
            echo "===================="
            echo "No changes made to the current setup"
            echo ""
            read -n 1 -s -r -p "Press any key to continue"
        fi

        # Grant permissions to the log collector service allowing it 
        # to bind to ports < 1024 (ie. network ports 0-1023)
        echo ""
        echo ""
        echo "===================="
        read -p "(Recommended) Allow log collector to bind to standard ports (ie. Network ports 0-1023)? [y,n] " yn22

        if [ $yn22 == "y" ]; then
            if ! [ -d $SYSTEMD_SERVICE_OVERRIDE_DIR ]; then
                mkdir -p $SYSTEMD_SERVICE_OVERRIDE_DIR
            fi
            if ! [ -f $SYSTEMD_SERVICE_OVERRIDE_FILE ]; then
                echo "[Service]" > $SYSTEMD_SERVICE_OVERRIDE_FILE
                echo "AmbientCapabilities=CAP_NET_BIND_SERVICE" >> $SYSTEMD_SERVICE_OVERRIDE_FILE
                systemctl daemon-reload
                echo ""
                echo "===================="
                echo "log collector allowed to bind to standard ports (ie. Network ports 0-1023)"
                echo ""
            else
                echo ""
                echo "===================="
                echo "An override file for the "$SERVICE_USER" service already exists. Refer"
                echo "to the instructions on the Falcon LogScale Documentation site to edit this"
                echo "further than it already has been to allow access to standard ports."
                echo ""
                echo "SOURCE:"
                echo "https://library.humio.com/falcon-logscale-collector/log-collector-install-custom-linux.html#log-collector-install-linux-binding"
            fi
        else
            echo ""
            echo "===================="
            echo "No changes made to the current setup"
        fi
        echo ""
        read -n 1 -s -r -p "Press any key to return to the main menu"

    elif [ $LOOP_VARIABLE == 3 ]; then
        # Check if a config file already exists, and ask the user if they would like to make a backup of it should one exist
        if [ -f $CONFIG_FILE_PATH ]; then
            # Check if the user would like to make a backup of the current configuration
            echo ""
            echo "===================="
            echo "A configuration file for the log collector already exists."
            echo "In case of any future concerns, a backup of the current"
            echo "configuration can be saved to the current directory with"
            echo "the name 'BACKUP_config.yaml'."
            echo ""
            read -p "Would you like to make a backup of the current configuration? [y,n] " yn30

            # If the user says yes, create a backup of the config and save it to the current directory
            if [ $yn30 == "y" ]; then
                # Check if a backup file already exists
                if [ -f BACKUP_config.yaml ]; then
                    echo ""
                    echo "===================="
                    echo "A backup configuration already exists in the current directory"
                    echo "with the name \"BACKUP_config.yaml\"."
                    echo "Saving a new backup of the current configuration will overwrite"
                    echo "the existing backup."
                    echo ""
                    read -p "Do you still wish to save a backup of the current configuration? [y,n] " yn31

                    if [ $yn31 == "y" ]; then
                        cp $CONFIG_FILE_PATH BACKUP_config.yaml
                        echo""
                        echo "===================="
                        echo "BACKUP_config.yaml was saved to the current directory."
                    else
                        echo ""
                        echo "===================="
                        echo "Continuing without saving a backup."
                    fi
                else
                    cp $CONFIG_FILE_PATH BACKUP_config.yaml
                    echo""
                    echo "===================="
                    echo "BACKUP_config.yaml was saved to the current directory."
                    echo ""
                fi
            # If the user didn't say yes, continue without saving a backup
            else
                echo ""
                echo "===================="
                echo "Continuing without saving a backup."
            fi
        else
            echo ""
            echo "===================="
            echo "There isn't a configuration file in the expected location"
            echo "for the log collector."
        fi
        echo ""
        read -n 1 -s -r -p "Press any key to return to the main menu"

    elif [ $LOOP_VARIABLE == 4 ]; then
        # Manually edit the configuration file
        # Let the user know this uses Nano and ask if they want to edit the config file
        echo ""
        echo "===================="
        echo "This uses the Linux utility 'Nano' to manually edit the"
        echo "configuration file. Nano is a command-line text editor"
        echo "designed to be user-friendly, with a simple interface"
        echo "that resembles popular graphical text editors."
        echo ""
        read -p "Do you want to edit the configuration file? [y,n] " yn40

        # If the user says yes, edit the config file using Nano after checking if a config file exists
        if [ $yn40 == "y" ]; then
            # Check to see if the device is fleet managed
            yn41="y"
            if [ "$FLEET_MANAGED" = "yes" ]; then
                echo ""
                echo "===================="
                echo "This log collector appears to be part of a fleet. Manual editing of"
                echo "the config file on this host is not recommended. Instead, you should"
                echo "sign into the Falcon console to make configuration changes there."
                echo ""
                read -p "Do you still wish to manually edit the configuration file? [y,n] " yn41
            fi
            # Check to see if a configuration file already exists
            if  [ $yn41 == "y" ]; then
                if [ -f $CONFIG_FILE_PATH ]; then
                    # Check if the user would like to make a backup of the current configuration
                    echo ""
                    echo "===================="
                    echo "If you haven't done so already, it is recommended that a backup"
                    echo "of the active configuration be saved to avoid any potential"
                    echo "loss of information that may arise from editing this. This can"
                    echo "be done using OPTION 3 in the main menu."
                    echo ""
                    read -p "Do you wish to continue to the editor? [y,n] " yn42

                    # If the user says yes, open the config file in Nano
                    if [ $yn42 == "y" ]; then
                        # Open the config file in Nano
                        nano $CONFIG_FILE_PATH
                        # Output to the user that any changes made will require the service to be restarted
                        echo ""
                        echo "===================="
                        echo "If you made any changes to the configuration, the log"
                        echo "collector service will need to be restarted. To do this,"
                        echo "use OPTION 6 in the main menu."
                        sleep 1s
                    # If the user said no, return to the main menu
                    else
                        echo ""
                        echo "===================="
                        echo "Continuing without editing the configuration file."
                    fi
                fi
            else
                echo ""
                echo "===================="
                echo "Continuing without editing the configuration file."
            fi

        else
            echo ""
            echo "===================="
            echo "Continuing without editing the configuration file."
        fi
        echo ""
        read -n 1 -s -r -p "Press any key to return to the main menu"

    elif [ $LOOP_VARIABLE == 5 ]; then
        # Ask the user if they wish to use the current BACKUP_config.yaml as the active configuration
        echo ""
        echo "===================="
        echo "CAUTION: "
        echo "The following command will replace the currently active"
        echo "configuration for the log collector with a backup of a"
        echo "previous version."
        echo ""
        echo "Would you like to use a previous backup of the configuration"
        read -p "as the active configuration for the log collector? [y,n] " yn50

        if [ $yn50 == "y" ]; then
            if ! [ -f BACKUP_config.yaml ]; then
                echo ""
                echo "===================="
                echo "A backup configuration file does not exist in the"
                echo "current working directory. If this is unexpected,"
                echo "see if there is a file named"
                echo "     BACKUP_config.yaml"
                echo "in a different directory or if there is a backup"
                echo "of a configuration file that was renamed to"
                echo "something different."
            else
                cp BACKUP_config.yaml $CONFIG_FILE_PATH
                echo ""
                echo "===================="
                echo "The contents of \"BACKUP_config.yaml\" have been copied to the"
                echo "active configuration for the log collector."
                echo "The log collector service will need to be restarted."
                echo "To do this, use OPTION 6 in the main menu."
            fi
        else
            echo ""
            echo "===================="
            echo "The active configuration for the log collector has not"
            echo "been changed."
        fi
        echo ""
        read -n 1 -s -r -p "Press any key to return to the main menu"

    elif [ $LOOP_VARIABLE == 6 ]; then
        # Restart the log collector service
        # Ask the user if they want to restart the log collector service
        echo ""
        echo "===================="
        read -p "Would you like to restart the log collector service? [y,n] " yn60
        # If the user says yes, restart the service and then check its status
        if [ $yn60 == "y" ]; then
            echo ""
            echo "Restarting the log collector service"
            systemctl restart $SERVICE_NAME
            sleep 1s
            echo "Checking the status of the log collector service"
            echo "[-   ]"
            sleep 1s
            echo "[--  ]"
            sleep 1s
            echo "[--- ]"
            sleep 1s
            echo "[----]"
            sleep 1s

            # Check the ActiveState of the collector
            checkActiveState=$(systemctl show $SERVICE_NAME | grep ActiveState)
            if [ $checkActiveState == "ActiveState=active" ]; then
                echo "The log collector is running."
                echo "If your log source is already sending logs to this device,"
                echo "then you can sign in to the Falcon console to confirm that"
                echo "logs are being received."
            else
                echo "Try restarting the log collector service again."
                echo "If further troubleshooting is needed, you can start by checking"
                echo "the service info for any messages about the service. To do so,"
                echo "exit this script and run the following command:"
                echo ""
                echo "systemctl status "$SERVICE_NAME
            fi
        else
            echo ""
            echo "===================="
            echo "Continuing without restarting the log collector service."
        fi
        echo ""
        read -n 1 -s -r -p "Press any key to return to the main menu"

    elif [ $LOOP_VARIABLE == 7 ]; then
        # Output the current active configuration of the log collector in the terminal window
        echo ""
        echo "===================="
        echo "This will output the currently active configuration for the"
        echo "log collector. If you wish to edit the configuration, use"
        echo "OPTION 4 in the main menu."
        echo ""
        read -p "Would you like to view the currently active configuration? [y,n] " yn70

        if [ $yn70 == "y" ]; then
            echo ""
            echo "===================="
            cat $CONFIG_FILE_PATH | more -e
            echo ""
            echo "===================="
        else
            echo ""
            echo "===================="
        fi
        echo ""
        read -n 1 -s -r -p "Press any key to return to the main menu"

    elif [ $LOOP_VARIABLE == 8 ]; then
        # Stop the log collector service, run debug logs, attempt to start the log collector service once finished
        echo ""
        echo "===================="
        echo "To help troubleshoot the log collector, this can be"
        echo "ran to output debug logs that show what actions the"
        echo "log collector is taking. This will also show any error"
        echo "messages that may indicate issues with the collector."
        echo ""
        read -p "Would you like to run the debug logs process for the log collector? [y,n] " yn80

        if [ $yn80 == "y" ]; then
            # Check if the collector is already running
            checkActiveState=$(systemctl show $SERVICE_NAME | grep ActiveState)
            if [ $checkActiveState == "ActiveState=active" ]; then
                echo ""
                echo "===================="
                echo "Stopping the log collector service to allow debug logs to be ran."
                systemctl stop $SERVICE_NAME
            fi

            # Ask if they would like to save the output to a separate file
            echo ""
            echo "===================="
            echo "The debug logs will be output to the terminal window"
            echo "for you to review as they occur. Alternatively, the"
            echo "logs can be written into a file for static review after"
            echo "this process has ran. This file would be saved in the"
            echo "current working directory."
            echo ""
            echo "Would you like to save the output debug logs to a file"
            read -p "for review outside this active session? [y,n] " yn81
            echo ""

            if [ $yn81 == "y" ]; then
                echo ""
                echo "===================="
                echo "Once running, press \"CTRL+c\" on your keyboard to end the"
                echo "debug logs process for the collector."
                echo ""
                read -n 1 -s -r -p "Press any key to begin "
                echo ""
                echo "===================="
                echo "Starting log collector debug logs and saving to a file."
                sleep 1s
                #create output file to save to
                outputFilename="debug-logs-$(date +%Y%m%d_%H%M%S).log"
                sudo -u $SERVICE_USER $EXE_LOCATION --cfg $CONFIG_FILE_PATH --log-level debug > $outputFilename 2>&1
                echo ""
                echo "Debug logs have been saved to $outputFilename"
            else
                echo ""
                echo "===================="
                echo "Once running, press \"CTRL+c\" on your keyboard to end the"
                echo "debug logs process for the collector."
                echo ""
                read -n 1 -s -r -p "Press any key to begin "
                echo ""
                echo "===================="
                echo "Starting log collector debug logs"
                sleep 1s
                sudo -u $SERVICE_USER $EXE_LOCATION --cfg $CONFIG_FILE_PATH --log-level debug
                sleep 1s
                echo ""
                echo "===================="
                echo "Stopping debug logs process"
            fi

            if [ $checkActiveState == "ActiveState=active" ]; then
                echo ""
                echo "===================="
                echo "Attempting to restart the log collector service"
                systemctl start $SERVICE_NAME
                # Check the ActiveState of the collector
                sleep 1s
                echo "[-   ]"
                sleep 1s
                echo "[--  ]"
                sleep 1s
                echo "[--- ]"
                sleep 1s
                echo "[----]"
                sleep 1s
                newestActiveState=$(systemctl show $SERVICE_NAME | grep ActiveState)
                if [ $newestActiveState == "ActiveState=active" ]; then
                    echo ""
                    echo "The log collector service is running."

                else
                    echo ""
                    echo "The log collector service was unable to run."
                    echo "Try restarting the service again using OPTION 6"
                    echo "in the main menu."
                fi
            else
                echo ""
                echo "===================="
                echo "Debug logs troubleshooting process complete."
            fi
        else
            echo ""
            echo "===================="
            echo "Continuing without running debug logs process."
        fi
        echo ""
        read -n 1 -s -r -p "Press any key to return to the main menu"

    elif [ $LOOP_VARIABLE == 0 ]; then
        # Exit the while loop and finish running the script
        echo ""
        echo "===================="
        echo "Exiting script"
        echo "===================="
        echo ""
        break

    else
        # Output to the user that they didn't enter a valid number
        echo "===================="
        echo "It appears you didn't enter a valid number. Please try again."
        sleep 1s

    fi
done
