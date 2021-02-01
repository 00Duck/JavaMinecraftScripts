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
echo -n "Checking prerequisites..."

if [ ! -x "$systemctl_inst" ]; then
    exit_early 'systemctl not found. This script uses systemd to manage Minecraft server.'
fi

if [ -x "$screen_inst" ]; then
    echo -e "\nFound screen"
else
    exit_early "\nMissing screen. Please install screen, wget, and java before proceeding. \nEx: sudo apt install screen wget openjdk-14-jre-headless"
fi

if [ -x "$java_inst" ]; then
    echo -e "\nFound java"
else
    exit_early "\nMissing java. Please install screen, wget, and java before proceeding. \nEx: sudo apt install screen wget openjdk-14-jre-headless"
fi

if [ -x "$wget_inst" ]; then
    echo -e "\nFound wget"
else
    exit_early "\nMissing wget. Please install screen, wget, and java before proceeding. \nEx: sudo apt install screen wget openjdk-14-jre-headless"
fi


echo " Done."

# Setup
echo -n "Creating directory..."
sudo mkdir $MC_HOME -p

if [ ! -d $MC_HOME ]; then
    exit_early "Could not create $MC_HOME directory - aborting."
fi
echo " Done."

# Download other scripts
echo -n "Getting utility scripts..."
cd $MC_HOME
wget -b "https://raw.githubusercontent.com/00Duck/JavaMinecraftScripts/main/warn.sh"
wget -b "https://raw.githubusercontent.com/00Duck/JavaMinecraftScripts/main/versioncheck.sh"
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
echo `
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
` | sudo tee -a /etc/systemd/system/multi-user.target.wants/minecraft-server.service
echo " Done."

# Install Minecraft
echo -n "Installing Vanilla Minecraft Server..."
server_page=$(curl -L https://www.minecraft.net/en-us/download/server)
mcs_url=$(grep -o "https://.*server\.jar" <<<$server_page)
wget $mcs_url
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
echo "Your Vanilla Minecraft Server has finished installing."
echo "\nCommon commands:"
echo "   Start Server: sudo systemctl start minecraft-server.service"
echo "   Stop Server: sudo systemctl stop minecraft-server.service"
echo "   Restart Server: sudo systemctl restart minecraft-server.service"
echo "   Server status: systemctl status minecraft-server.service"
echo "\nYour server is running on a separate screen. Type `screen -r` to resume the background screen session. Please note that, in order to do this, you must be echoged in using screen with the same user that is running the service. To exit screen, type `ctrl + a` and then `ctrl + d`.\n"
echo `Your server will shutdown nightly with a 10 minute warning every minute. 
By default, the countdown starts at 2:20am and the server reboots at 2:30am. This 
is configured to help prevent memory corruption issues when running the server on 
non-ecc, consumer hardware. You can modify this behavior by typing sudo su - to switch to root, followed by crontab -e.`
echo "\nYou can automatically check for and download new versions of the server by running versioncheck.sh in $MC_HOME"
echo "Enjoy. :)"