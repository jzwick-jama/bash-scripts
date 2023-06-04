#!/bin/bash

function help_text() {
    echo "Updates package lists, upgrades all new packages and removes all autoremove packages."
    echo "Arguments: --help, -y"
    echo " --help: Displays this message."
    echo " -y: Runs this shortcut script with the -y switch on all commands. "

}

function noswitch() {
    read -p "Upgrade repositories, all apps, then autoremove redundant packages? Options: (Y)es, (N)o, or (Q)uit or Ctrl-C to quit. " choice

    sudo apt-get update
    sudo apt-get full-upgrade
    sudo apt autoremove
    echo "Update complete"
    quit
}

function yesswitch() {
    read -p "Updating with auto-accept ON, use Ctrl-C to quit."
    sleep 3
    sudo apt-get update
    sudo apt-get full-upgrade -y
    sudo apt autoremove -y
    echo "Update complete"
    quit
}

function quit() {
    echo "Exiting...";
    exit;
}

# function choice_handler() {
#     nameofthefunction="%1"

#     case "$option" in
#         [Yy])
#             echo "Continuing...";
#             sleep 1
#             ;;
#         [Nn])
#             return
#             ;;
#         [Qq]
#             quit;;
#         *)
#             echo "Please choose Y. N or Q."
#             read -p " "
#             "$nameofthefunction"
#             ;;
#     esac
# }

if [[ " $@ " =~ " --help " ]]; then
    help_text;
    quit
elif [[ " $@ " =~ " -y " ]]; then
    yesswitch
else
    noswitch
fi
