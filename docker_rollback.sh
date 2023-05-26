#!/bin/bash

# function error_handler() {
#     if [[ %1 -gt 0 ]]; then
#         echo
# }

### Start of functions in order of operations

function uninstall_previous_docker() {
    read -p "Uninstall previous Docker installation?  "
    sudo apt-get remove docker docker-engine docker.io containerd runc;
    sudo apt-get remove docker docker.io containerd runc
}

function apt_update_upgrade_autoremove() {
    read -p "Continue, and run sudo apt-get update?"

    sudo apt-get update
    apt-get full-upgrade
    sudo apt-get autoremove
}

function download_install_docker() {
    echo " "
    read -p "Install docker v20.10.7?  "

    wget https://download.docker.com/linux/static/stable/x86_64/docker-20.10.7.tgz
    tar xzvf ./docker-20.10.7.tgz

    # Copies docker files to the /usr/bin directory; will force the operation if it fails because a text file in the directory is busy.
    sudo cp docker/* /usr/bin/
}

function add_docker_user_group() {
    # Suggests an optional setup step that makes Docker easier to use
    echo "Check if 'docker' user group exists; If not, creating one is optional, but if you add current user $USER to it will help you avoid  "
    echo "having to use sudo to run Docker commands. If you don't want to add this group the next prompt will let you skip to the last step   "
    echo "and restart the Docker Daemon.  "
    read -p "Press any key to continue...  "

    # Check if 'docker' user group exists. If yes, skip. If no, asks the user if they want to create one and add the current user to it.
    if getent group docker >/dev/null; then
        echo "User group 'docker' already exists."
    else
        # Prompt user to create 'docker' user group
        read -p "User group 'docker' does not exist. Do you want to create it and add your current user? (yes/no):   " response

        if [ "$response" = "yes" ]; then
            # Create 'docker' user group and add current user
            sudo groupadd docker
            sudo usermod -aG docker "$(whoami)"
            echo "User group 'docker' created. Current user added to the group."
        else
            echo "Skipping creating 'docker' user group; restarting docker daemon."
            sudo dockerd &
            exit
        fi
    fi
}

echo "This script must be run as root. Hit enter to continue or Ctrl-C to quit."
echo " "
echo " "
uninstall_previous_docker
apt_update_upgrade_autoremove
download_install_docker
add_docker_user_group
echo " '"
echo "Script complete"
