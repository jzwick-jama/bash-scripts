#!/bin/bash

#!/bin/bash

# This is the deployment script for ubuntu golden images
# writtem May 31st 2023 by Jenna Zwick

function EditHostname() {
	echo " "
	read -p "Do you want to run the command? (y/n): " choice
    case "$choice" in
        [Yy])
            echo "Running EditHostname. Save and quit to continue."
            echo " "
            sleep 3
            sudo nano /etc/hostname
            ;;
        [Nn])
            echo "Quitting."
            ;;
        *)
            echo "Invalid selection. Please choose (y) or (n)."
            sleep 5
            EditHostname
            ;;
    esac
}

function PrintNetplanExample() {
	echo "# This is the network config written by 'subiquity'"
	echo "network:"
	echo "  ethernets:"
	echo "    ens160:"
	echo "      addresses:"
	echo "      - 10.0.0.13/24"
	echo "      gateway4: 10.0.0.1"
	echo "      nameservers:"
	echo "        addresses:"
	echo "        - 8.8.8.8"
	echo "        - 1.1.1.1"
	echo "        - 75.75.75.75"
	echo "        search: []"
	echo "  version: 2"
}

function EditNetplan() {
	echo " "
	read -p "Do you want to run the command? (y/n): " choice
    case "$choice" in
        [Yy])
            echo "Running EditNetplan. Save and quit to continue."
            echo " "
            sleep 3
            PrintNetplanExample
            sleep 10
            echo "Opening 00-installer-config in 5 seconds..."
            echo " "
            sleep 5 
            sudo nano /etc/netplan/00-installer-config.yml
            ;;
        [Nn])
            echo "Quitting."
            ;;
        *)
            echo "Invalid selection. Please choose (y) or (n)."
            sleep 5
            EditNetplan
            ;;
    esac	
}

function GenerateSSHKey() {
	echo " "
	read -p "Do you want to run the command? (y/n): " choice
    case "$choice" in
        [Yy])
            echo "Running GenerateSSHKey. Open the Github link and copy the public key to the clipboard quickly, it will display for 15 seconds."
            echo " "
            sleep 3
            ssh-keygen
            cat ~/.ssh/id_rsa.pub
            ;;
        [Nn])
            echo "Quitting."
            ;;
        *)
            echo "Invalid selection. Please choose (y) or (n)."
            sleep 5
            GenerateSSHKey
            ;;
    esac
}

function GitConfig() {
	echo " "
	read -p "Do you want to run the command? (y/n): " choice
    case "$choice" in
        [Yy])
            echo "Running GitConfig. "
            echo " "
            sleep 3
			git config --global user.email "jennazwick888@gmail.com"
    		git config --global user.name "Jenna Zwick"
    		;;
        [Nn])
            echo "Quitting."
            ;;
        *)
            echo "Invalid selection. Please choose (y) or (n)."
            sleep 5
            GitConfig
            ;;
    esac	

}

function InstallDockerCompose() {
	echo " "
	read -p "Do you want to run the command? (y/n): " choice
    case "$choice" in
        [Yy])
            echo "Running InstallDockerCompose. "
            echo " "
            sleep 3
			sudo apt-get update && sudo apt-get install docker-compose -y
    		;;
        [Nn])
            echo "Quitting."
            quit
            ;;
        *)
            echo "Invalid selection. Please choose (y) or (n)."
            sleep 5
            InstallDockerCompose
            ;;
    esac	

}

function quit() {
    echo "Exiting..."
    exit
}

function menu_function() {
    echo "1 - Edit Hostname"
    echo "2 - Edit Netplan"
    echo "3 - Generate SSH Key and copy to other machines"
    echo "4 - Configure Git"
    echo "5 - Install Docker Compose"
    echo "6 - Continue with XRDP install"
    echo "q - Quit"
    
    read -p "To run a function, enter the corresponding number.  "  choice
    case "$choice" in
        1)
            EditHostname
            ;;
        2)
            EditNetplan
            ;;
        3)
            GenerateSSHKey
            ;;
        4)
            GitConfig
            ;;
        5)
            InstallDockerCompose
            ;;
        6)
            ContinueDeployProcess
            ;;
        q)
            quit
            ;;
        *)
            echo "Invalid selection. Please choose (y) or (n)."
            menu_function
            ;;
    esac
}
menu_function