#!/bin/bash

# Function to handle the exit code and provide error definitions for the Jama Native installer scripts.
error_code="$1"
error_description=""

timestamp=$(date +"%Y-%m-%d %H:%M:%S")

handle_error() {
    log_file="native-app-error.log"
    # Dictionary of error codes and their definitions
    declare -A error_codes=(
        [1]="Error 1: One or more required inbound ports needed for Jama is not open or in use already."
        [2]="Error 2: One or more linux user ids needed for Jama is in use already."
        [3]="Error 3: Cron job for ntpdate already exists."
        [4]="Error 4: /dev/sdb size is less than 100GB, or has less than 100G free."
        [5]="Error 5: Volume group and/or logical volumes could not be created."
        # 
        [6]="Error 6: File not found"
        [7]="Error 7: Invalid input"
        [8]="Error 8: Permission denied"
        [9]="Error 9: Network unreachable"
        [10]="Error 10: Division by zero"
        [11]="Error 11: File not found"
        [12]="Error 12: Invalid input"
        [13]="Error 13: Permission denied"
    )

    log_error() {
        if [[ ! -f "$log_file" ]]; then
            touch "$log_file"
            echo "Log file created: $log_file"
        else
            echo "Log file exists, skipping..."
        fi

        echo "$timestamp Error Code: $error_code Error Description: $error_description" >>"$log_file"
        echo "Error logged to $log_file"
    }
}

# Check if an exit code is provided as a command-line argument
if [[ $# -eq 1 ]]; then
    handle_error "$1"
else
    echo "Please provide an exit code as a command-line argument."
fi
