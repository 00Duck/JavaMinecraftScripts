#!/usr/bin/env bash
/usr/bin/screen -dm -S Minecraft bash -c '/usr/bin/java -Xmx2048M -Xms512M -XX:+UseG1GC -jar server.jar nogui'
