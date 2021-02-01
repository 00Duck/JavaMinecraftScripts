#!/usr/bin/env bash

for ((count=10; count > 0; count--))
do
/usr/bin/screen -S minecraft-server -X stuff "say §6The server will be restarting in $count minutes. Please find a safe place to log out!\rtitle @a title {\"text\":\"\u00A76Server restart in $count minutes.\"}\r"
sleep 60
done
