#!/bin/bash
read -p "Upgrade repositories, all apps, then autoremove redundant packages? Hit enter to continue and Ctrl-C to quit."
sudo apt-get update;
sudo apt-get full-upgrade;
sudo apt autoremove -y
echo "Update complete"
