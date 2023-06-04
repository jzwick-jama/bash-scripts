#!/bin/bash

function InstallXRDP() {
    echo "Installing xrdp. Press enter to continue."
    sudo apt install -y xrdp;
    sudo systemctl status xrdp;
    sudo adduser xrdp ssl-cert;
    sudo systemctl restart xrdp;
    echo "installation complete"
}

InstallXRDP


function WhileTrue() {
    while true; then
        
}