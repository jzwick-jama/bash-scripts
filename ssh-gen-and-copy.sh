#!/bin/bash

# v1 by: J Zwick - 
# A quick bash script to copy ssh keys over to remote hosts in a local trusted network.

known_hosts_file="$HOME/.ssh/known_hosts"

function additional_commands() {
    # Saves the key's passphrase locally before copying the ssh id multiple times.
    ssh-add -K ~/.ssh/id_ed25519
    echo "Saved local passphrase, starting to copy ssh key..."    
    ssh-copy-id docker@10.0.0.204
    echo "Completed (1/6)..."
    ssh-copy-id docker@10.0.0.207
    echo "Completed (2/6)..."
    ssh-copy-id docker@10.0.0.6
    echo "Completed (3/6)..."    
    ssh-copy-id docker@10.0.0.29
    echo "Completed (4/6)..."    
    ssh-copy-id docker@10.0.0.25
    echo "Completed (5/6)..."    
    ssh-copy-id docker@10.0.0.202
    echo "Completed (6/6)..."    
}

# If no ssh key, it will prompt the user to make one.
# If they do, it will back up the current known_hosts file and generate a new one.
function setup_or_startover() {
    if [[ -f "$known_hosts_file" ]]; then
        cp "$known_hosts_file" "$known_hosts_file.old"
        rm "$known_hosts_file"
        echo "The file '$known_hosts_file' has been renamed to '$known_hosts_file.old'."
        echo "Please copy any previously authorized systems from the old file to the new file."
        sleep 5
        additional_commands
    else
        ssh-keygen -t ed25519 -f "$HOME/.ssh/id_ed25519"
        echo "The ssh-ed25519 key has been generated and installed."
        echo "Please copy the following public key and authorize it on remote systems:"
        cat "$HOME/.ssh/id_ed25519.pub"
        echo "Press Enter to continue..."
        read -r
        additional_commands
    fi
}

# defines the order the script runs in.
start_script() {
    setup_or_startover
    echo "Generating ssh key or creating a new known_hosts file..."
    sleep 5
    echo "Key generation complete. Starting the copy process."
    additional_commands
    echo "Script execution completed."
}

# confirms whether they want to wipe out their configuration before starting.
read -p "Do you want to start the script? (yes/no): " choice

if [[ $choice == "yes" ]]; then
    start_script
elif [[ $choice == "no" ]]; then
    echo "Script execution aborted."
    exit 0
else
    echo "Invalid choice. Please enter 'yes' or 'no'."
    exit 1
fi