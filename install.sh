#!/bin/bash

MC_HOME='/srv/minecraft-server'
USER=$(whoami)
mem='2G'
screen_inst=$(command -v screen)
systemctl_inst=$(command -v systemctl)
java_inst=$(command -v java)
wget_inst=$(command -v wget)

echo -e 'Starting install.\n\nPlease note that sudo is required to configure the systemctl service and crontabs.\n'

exit_early() {
    echo -e "$1\n"
    exit 1
}


# Check prerequisites
echo "Checking prerequisites..."
end_early=false

if [ ! -x "$systemctl_inst" ]; then
    exit_early 'systemctl not found. This script uses systemd to manage Minecraft server.'
fi

if [ -x "$screen_inst" ]; then
    echo -e "   [ \033[32m\u2713\033[0m ] screen"
else
    end_early=true
    echo -e "   [ \033[31m\u03a7\033[0m ] screen"
fi

if [ -x "$java_inst" ]; then
    echo -e "   [ \033[32m\u2713\033[0m ] java"
else
    end_early=true
    echo -e "   [ \033[31m\u03a7\033[0m ] java"
fi

if [ -x "$wget_inst" ]; then
    echo -e "   [ \033[32m\u2713\033[0m ] wget"
else
    end_early=true
    echo -e "   [ \033[31m\u03a7\033[0m ] wget"
fi

if [ "$end_early" = true ]; then
    exit_early "\nPlease install the missing requirements before proceeding. \nEx: sudo apt install screen wget openjdk-14-jre-headless"
fi


echo "Done."

# Setup
echo -n "Creating server directory..."
sudo mkdir $MC_HOME -p
sudo chown $USER $MC_HOME

if [ ! -d $MC_HOME ]; then
    exit_early "Could not create $MC_HOME directory - aborting."
fi
echo " Done."

# Download other scripts
echo -n "Getting utility scripts..."
cd $MC_HOME
wget -q "https://raw.githubusercontent.com/00Duck/JavaMinecraftScripts/main/warn.sh"
wget -q "https://raw.githubusercontent.com/00Duck/JavaMinecraftScripts/main/versioncheck.sh"
echo "Done."

echo -n "Enter amount of memory for server to use. Ex: 256M, 2G, 4G. (Default 2G): "
read inputMemory

if [ $inputMemory ]
then
    mem=$inputMemory
fi

echo ""

# Install Service
echo -n "Installing Service..."
EXECUTE="/usr/bin/screen -dm -S minecraft-server bash -c 'java -Xms$mem -Xmx$mem -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -jar server.jar nogui'"
SERVICE="
[Unit]
Description=Vanilla Minecraft Server

[Service]
WorkingDirectory=$MC_HOME
User=$USER
Restart=on-failure
RestartSec=20s
ExecStart=$EXECUTE
Type=forking

[Install]
WantedBy=multi-user.target
" | sudo dd of=/etc/systemd/system/multi-user.target.wants/minecraft-server.service
echo " Done."

# Install Minecraft
echo -n "Installing Vanilla Minecraft Server..."
server_page=$(curl -L https://www.minecraft.net/en-us/download/server)
mcs_url=$(grep -o "https://.*server\.jar" <<<$server_page)
wget -q $mcs_url
echo " Done."

# Install Crontabs
echo -n "Configuring root crontabs..."
cronjob="20 2 * * * /bin/bash $MC_HOME/warn.sh"
(sudo crontab -u root -l; echo "$cronjob" ) | sudo crontab -u root -
cronjob="30 2 * * * systemctl stop minecraft-server && /usr/sbin/reboot"
(sudo crontab -u root -l; echo "$cronjob" ) | sudo crontab -u root -
echo " Done."

# Enable Minecraft
echo -n "Enabling Minecraft Server start on boot..."
sudo systemctl enable minecraft-server.service
echo " Done."

# Start Minecraft
echo "Starting Minecraft Server."
sudo systemctl start minecraft-server.service

# FINN
echo -e "Your Vanilla Minecraft Server has finished installing.\n
Common commands:
   Start Server: sudo systemctl start minecraft-server.service
   Stop Server: sudo systemctl stop minecraft-server.service
   Restart Server: sudo systemctl restart minecraft-server.service
   Server status: systemctl status minecraft-server.service
\nYour server is running on a separate screen. Type `screen -r` to resume the background screen session. Please note that, in order to do this, you must be logged in using screen with the same user that is running the service. To exit screen, type `ctrl + a` and then `ctrl + d`.\n
\nYour server will shutdown nightly with a 10 minute warning every minute. 
By default, the countdown starts at 2:20am and the server reboots at 2:30am. This 
is configured to help prevent memory corruption issues when running the server on 
non-ecc, consumer hardware. You can modify this behavior by typing sudo su - to switch to root, followed by crontab -e.
\nYou can automatically check for and download new versions of the server by running versioncheck.sh in $MC_HOME
\nEnjoy. :)"