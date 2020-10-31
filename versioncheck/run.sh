#!/bin/bash

#download the latest page
echo "Downloading latest server page..."
curl -L https://www.minecraft.net/en-us/download/server > server_page.html

#get version and put in version file
file_version=$(cat version)
new_version=$(grep -o -m 1 minecraft_server.*\.jar server_page.html | sed "s/minecraft_server.//g;s/\.jar//g")

if [ "$file_version" != "$new_version" ]; then
	echo "Version mismatch - downloading latest..."
	#grab the download URL and download
	url=$(grep -o "https://.*server\.jar" server_page.html)
	wget $url
	echo "Applying server"
	mv -f ../server.jar ../server.jar.old
	mv -f server.jar ..

	#Update version file to latest version
	echo "Updating version file"
	echo $new_version > version

	#restart server
	sudo systemctl restart mcserver.service
else
	echo "Version is up to date"
fi

echo "Done"
