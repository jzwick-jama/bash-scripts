#!/bin/bash

# Function to handle the exit code and provide error definitions for the Jama Native installer scripts.

handle_error() {
    log_file="native-app-error.log"
    # Dictionary of error codes and their definitions
    declare -A error_codes=(
        [1]="Error 1: File not found"
        [2]="Error 2: Invalid input"
        [3]="Error 3: Permission denied"
        [4]="Error 4: Network unreachable"
        [5]="Error 5: Division by zero"
        [6]="Error 6: File not found"
        [7]="Error 7: Invalid input"
        [8]="Error 8: Permission denied"
        [9]="Error 9: Network unreachable"
        [10]="Error 10: Division by zero"
        [11]="Error 11: File not found"
        [12]="Error 12: Invalid input"
        [13]="Error 13: Permission denied"
    )

    local exit_code="$1"
    local error_definition=${error_codes[$exit_code]}

    log_error() {
        local error_code="$1"
        local error_description="$2"

        if [[ ! -f "$log_file" ]]; then
            touch "$log_file"
            echo "Log file created: $log_file"
        else
            echo "Log file exists, skipping..."
        fi

        local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
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
