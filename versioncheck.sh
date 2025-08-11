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
agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36"
echo -n "Checking latest version..."

#get version and put in version file
file_version=$(cat version)
new_version=$(curl -A "$agent" -sL "https://net-secondary.web.minecraft-services.net/api/v1.0/download/latest" | jq '.result' | tr -d '"')

if [ "$file_version" != "$new_version" ]; then
    echo -n "Version mismatch - Stopping server..."
    sudo systemctl stop minecraft_server.service
    echo "Server stopped."

    echo -n "Backing up old jar..."
    rm server.jar.old
    mv server.jar server.jar.old
    echo "server.jar moved to server.jar.old"

	echo -n "Downloading latest version..."
	#grab the download URL and download
	download_link=$(curl -A "$agent" -sL "https://net-secondary.web.minecraft-services.net/api/v1.0/download/links" | jq '.result | .links[] | select(.downloadType=="serverJar") | .downloadUrl' | tr -d '"')
	wget -q $download_link
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
