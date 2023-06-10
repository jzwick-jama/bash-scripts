#!/bin/bash

function InstallXRDP() {
  echo "Installing xrdp. Press enter to continue."
  sudo apt install -y xrdp
  echo "Installing xrdp. Press enter to continue."
  sudo systemctl status xrdp
  read -p "Did xrdp start? (Y/N)  " didxrdpstart
  case $didxrdpstart in
  [Yy])
    #action
    ;;
  [Nn])
    #second action
    ;;
  Qq])
    exit
    ;;
  *)
    echo "Invalid selection"
    sleep 2
    InstallXRDP
    ;;
  esac
  echo "Adding user xrdp to ssl-cert group..."
  sudo adduser xrdp ssl-cert
  echo "Restarting XRDP service..."
  sudo systemctl restart xrdp
  echo "installation complete"
}

while true; do
  InstallXRDP
  exit
done
