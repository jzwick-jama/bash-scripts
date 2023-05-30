#!/bin/bash
sudo apt-get update;
sudo apt-get install docker-compose -y;
sudo nano /etc/hostname;
read -p "Please copy the following code and paste into a new 00-installer-config.yaml file if not present   ";
cat example.00-installer-config.yaml;
read -p "Press Enter when ready to continue   ";
sudo nano /etc/netplan/00-intaller-config.yaml;
read -p "Set up github globals"
sudo apt-get install git -y; git config --global user.email "jennazwick888@gmail.com"; git config --global user.name "Jenna Zwick";
echo "Setup complete."
