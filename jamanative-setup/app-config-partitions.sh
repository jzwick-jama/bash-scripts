#!/bin/bash

# Set up dedicated volumes for the data Jama Native is going to write. Use this example to partition the logical volumes on your application server.
# Start with a 110 GB disk, or simply run all 7 steps to write to disk and exit.

# Used for counting completed steps; quits the function if all 7 steps are run in one run-through. Otherwise whits on Ctrl-C or q.

functions_array=()

function CreateMountpoints() {
    read -p "Create mountpoints? (Ctrl-c to cancel)  "
    sudo mkdir /data
    sudo mkdir /logs
    sudo mkdir /var/lib/docker || echo "Failed to create docker folder, you may need to uninstall Docker. "
    sudo mkdir /var/lib/replicated
    if [[ ! " ${functions_array[@]} " =~ "CreateMountpoints" ]]; then
        functions_array+=("CreateMountpoints")
    fi
}

# Create a physical volume:
function CreatePhysicalVolume() {
    echo " "
    read -p "Create physical volume? (Ctrl-c to cancel)  "
    pvcreate /dev/sdb
    if [[ ! " ${functions_array[@]} " =~ "CreatePhysicalVolume" ]]; then
        functions_array+=("CreatePhysicalVolume")
    fi
}
# Create a volume group:

function CreateVolumeGroup() {
    echo " "
    read -p "Create volume group? (Ctrl-c to cancel)  "
    vgcreate vg_jama /dev/sdb
    if [[ ! " ${functions_array[@]} " =~ "CreateVolumeGroup" ]]; then
        functions_array+=("CreateVolumeGroup")
    fi
}

function AddLinesToFstab() {
    echo " "
    read -p "Check if /etc/fstab is already modified and modify it with new partitions if not? (Ctrl-c to cancel)  "
    etcfstabstring="logs /logs ext4 defaults 0 0"
    last_line=$(tail -n 1 "/etc/fstab")
    if [[ $last_line == *"$etcfstabstring"* ]]; then
        echo "Match found: $search_string, skipping."
    else
        echo "No match found; addling lines..."
        sudo echo "LABEL=docker /var/lib/docker xfs defaults 0 0" >> /etc/fstab
        sudo echo "LABEL=replicated /var/lib/replicated ext4 defaults 0 0" >> /etc/fstab
        sudo echo "LABEL=data /data ext4 defaults 0 0" >> /etc/fstab
        sudo echo "LABEL=logs /logs ext4 defaults 0 0" >> /etc/fstab
    fi

    if [[ ! " ${functions_array[@]} " =~ "AddLinesToFstab" ]]; then
        functions_array+=("AddLinesToFstab")
    fi
}

function MountPartitions() {
    echo " "
    read -p "Mount partitions? (Ctrl-c to cancel)  "
    mount -a
    if [[ ! " ${functions_array[@]} " =~ "MountPartitions" ]]; then
        functions_array+=("MountPartitions")
    fi
}

# Create logical volumes:
function CreateLogicalVolumes() {
    echo " "
    read -p "Create logical volumes in group? (Ctrl-c to cancel)  "
    lvcreate -L 30G -n lv_docker vg_jama
    lvcreate -L 20G -n lv_replicated vg_jama
    lvcreate -L 10G -n lv_logs vg_jama
    lvcreate -l 100%FREE -n lv_data vg_jama
    if [[ ! " ${functions_array[@]} " =~ "CreateLogicalVolumes" ]]; then
        functions_array+=("CreateLogicalVolumes")
    fi
}

# Write file systems:
function WriteFileSystems() {
    echo " "
    read -p "Write filesystems to storage? (Ctrl-c to cancel)  "
    mkfs.xfs -L docker -n ftype=1 /dev/vg_jama/lv_docker
    mkfs.ext4 -L replicated /dev/vg_jama/lv_replicated
    mkfs.ext4 -L data /dev/vg_jama/lv_data
    mkfs.ext4 -L logs /dev/vg_jama/lv_logs
    if [[ ! " ${functions_array[@]} " =~ "WriteFileSystems" ]]; then
        functions_array+=("WriteFileSystems")
    fi
}

function quit() {
    echo "Exiting..."
    exit
}

function menu() {
    while true; do
        echo "To exit, run all 7 steps, or press Ctrl-C or q."
        echo "----------------------------------   "
        echo "1) Create mountpoints as folders"
        echo "2) Create physical volume"
        echo "3) Create volume group"
        echo "4) Create logical volumes in group"
        echo "5) Write filesystem to disk"
        echo "6) Add lines to /etc/fstab"
        echo "7) Mount newly created partitions"
        echo "q) Exit"
        echo " "
        read -p "Choose an option (1-7) or; choose q or press Ctrl-C to quit: " choice
        case "$choice" in
        1)
            CreateMountPoints
            menu
            ;;
        2)
            CreatePhysicalVolume
            menu
            ;;
        3)
            CreateVolumeGroup
            menu
            ;;
        4)
            CreateLogicalVolumes
            menu
            ;;
        5)
            WriteFileSystem
            menu
            ;;
        6)
            AddLinesToFstab
            menu
            ;;
        7)
            MountPartitions
            menu
            ;;
        q)
            quit
            break
            ;;
        *)
            echo "Invalid choice. Only options 1-3 are allowed. Press Ctrl-C to quit."
            menu
            ;;
        esac
        if [[ ${#functions_array[@]} -ge 7 ]]; then
            echo "Array length is 7 or greater. Quitting."
            break
        fi
    done
}

menu
