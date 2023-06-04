#!/bin/bash
sudo ./apt-update.sh -y;
read -p "Update complete. Continue with setup? (Enter to continue)"
sudo ./ubuntu-setup.sh -y;
read -p "Ubuntu-setup complete. Continue with setup? (Enter to continue)"
sudo ./generate-netplan-file.sh
read -p "Netplan setup complete. Continue with setup? (Enter to continue)";
ssh-keygen;
cat ~/.ssh/id_rsa.pub;
echo "Please go to https://github.com/settings/keys to add this new ssh key to Github";

read -p "Press enter to continue once you have copied your SSH key and added it to Github.";
sudo apt-get install git -y; 
git config --global user.email "jennazwick888@gmail.com"; 
git config --global user.name "Jenna Zwick";
echo "Go to https://gitlab.com/jennazwick888/deploy/-/runners/new and generate a new runner token"
read -p "Hit enter when you have your token and you're ready to install it.";
sudo ./gitlab-installer.sh;
