#!/bin/bash

##################################################################################
# version.sh
#
# The version file stores the current, last known version of the Minecraft Java server.
# When this script is executed, it downloads the Minecraft server download page in its 
# entirety, parses it for the latest version, and compares to the number in the version 
# file. If there is a mismatch, the script will download the server.jar package, copy 
# your current server.jar to server.jar.old, and move in the new server.jar. It then 
# restarts the Minecraft server.
#
##################################################################################

#download the latest page
echo -n "Downloading latest server page..."
server_page=$(curl -sL https://www.minecraft.net/en-us/download/server)

#get version and put in version file
file_version=$(cat version)
new_version=$(grep -o -m 1 minecraft_server.*\.jar <<<$server_page | sed "s/minecraft_server.//g;s/\.jar//g")

echo "Done"

if [ "$file_version" != "$new_version" ]; then
    echo -n "Version mismatch - Stopping server..."
    sudo systemctl stop minecraft_server.service
    echo "Done"

    echo -n "Backing up old jar as server.jar.old..."
    mv server.jar server.jar.old
    echo "Done"

	echo -n "Downloading latest version..."
	#grab the download URL and download
	url=$(grep -o "https://.*server\.jar" <<<$server_page)
	wget -q $url
    echo "Done"

	#Update version file to latest version
	echo "Updating version file..."
	echo $new_version > version
    echo "Done"

	#restart server
    echo -n "Starting Minecraft Server..."
	sudo systemctl start minecraft-server.service
    echo "Done"
else
	echo "Version is up to date"
fi

echo "Finished!"
