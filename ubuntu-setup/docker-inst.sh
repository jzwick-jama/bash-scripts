#!/bin/bash

# Docker 20.10.7 Rollback Script (v1.0)
# By: Jenna Zwick
# Technical Support Engineer (TSE) at Jama Software

# To run this script, make it executable with: 'sudo chmod 777 ./docker_rollback.sh && sudo ./docker_rollback.sh'
 
echo "outputs Docker version so you can verify the backed up sandbox still needs to be rolled back. Please cancel if it returns v20.10.7."

dock_ver=(docker -v)

read -p "Currently installed Docker runtime is $dock_ver. You should still proceed to roll back to 20.10.7 if you have a newer version installed. " response
sudo read -p "Uninstall current version of Docker and roll back to 20.10.7? Press any key to continue, Ctrl-C to cancel."

# updates repositories
sudo apt-get update

# attempts to uninstall all historic components of docker; many companies don't use docker-engine any more though. 
# If the below command on the left fails because you don't have it either it will fail. If it does, bash will 
# attempt to run the one on the right, which should complete successfully.
sudo apt-get remove docker docker-engine docker.io containerd runc -y || sudo apt-get remove docker docker.io containerd runc -y

# Downloads Docker 20.10.7 from their website with wget, and extracts the archive to the current working directory.
wget https://download.docker.com/linux/static/stable/x86_64/docker-20.10.7.tgz
tar xzvf ./docker-20.10.7.tgz

# Copies docker files to the /usr/bin directory; will force the operation if it fails because a text file in the directory is busy.
sudo cp docker/* /usr/bin/ || sudo cp docker/* /usr/bin/ -f

# Suggests an optional setup step that makes Docker easier to use 
echo "Check if 'docker' user group exists; If not, creating one is optional, but if you add current user $USER to it will help you avoid"
echo "having to use sudo to run Docker commands. If you don't want to add this group the next prompt will let you skip to the last step "
echo "and restart the Docker Daemon."
read -p "Press any key to continue..."

# Check if 'docker' user group exists. If yes, skip. If no, asks the user if they want to create one and add the current user to it.
if getent group docker >/dev/null; then
    echo "User group 'docker' already exists."
else
    # Prompt user to create 'docker' user group
    read -p "User group 'docker' does not exist. Do you want to create it and add your current user? (yes/no): " response

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

# Restart Docker daemon
sudo dockerd &
