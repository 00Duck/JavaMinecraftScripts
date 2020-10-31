# JavaMinecraftScripts
Scripts to start a Java Minecraft server using screen, warn users of impending shutdown (10 minute countdown), and automatically check for new versions of Minecraft Server.

### start.sh

Starts a Minecraft server. Technically not necessary as this command can be added directly to a service, but I found it easier to work with. The service simply calls this file. Add it to the top level in your Minecraft server folder (assumed /srv/minecraft-server).

### warn.sh

Runs once in a crontab to warn users that the server is coming down. Also add in the top level of your Minecraft server folder for convenience.

I added this because I have a crontab that restarts my server every night. I wanted to give users ample time to log out without being randomly disconnected by a reboot.

For reference, the crontab looks like this:

```bash
# m h  dom mon dow   command
20 2 * * * /bin/bash /srv/minecraft-server/warn.sh
30 2 * * * systemctl stop mcserver && /usr/sbin/reboot
```

### versioncheck/run.sh and the versioncheck/version file

Place the entire versioncheck folder in the top level of your Minecraft server folder.

The version file stores the current, last known version of the Minecraft Java server. When run.sh is executed, it downloads the Minecraft server download page in its entirety, parses it for the latest version, and compares to the number in the version file. If there is a mismatch, the script will download the server.jar package, copy your current server.jar to server.jar.old, and move in the new server.jar. It then restarts the Minecraft server.

I'm not sure if this is the best way to go about doing this, and certainly, the script can easily break if/when changes are made to the Minecraft website. I wasn't able to find an API endpoint I could just hit to consistently check for the latest version, so this is what I ended up doing. 

Please note that I am only using this script manually whenever I log into Minecraft and see that a new version is out. While you could technically write a crontab to fire this code automatically at some interval, *THIS IS VERY MUCH FROWNED UPON*. I am not liable for any idiocy on your part for running this script too often and getting yourself in trouble with Microsoft. Use at your own risk.

### mcserver.service

Add this file to /etc/systemd/system/. This is how you're going to start your Minecraft server. Make sure the values set in it correspond to how you have installed your server.

#### To enable at startup

`sudo systemctl enable mcserver`

#### To start

`sudo systemctl start mcserver`

#### To stop

`sudo systemctl stop mcserver`

#### To check status

Either run `systemctl status mcserver`

Or type `screen -r` to resume the background screen session. Please note that, in order to do this, you must be logged in using screen with the same user that is running the service. To exit screen, type `ctrl + a` and then `ctrl + d`.