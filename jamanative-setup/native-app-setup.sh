#!/bin/bash

# script that runs all the setup steps from the following documents:
#
# - https://help.jamasoftware.com/ah/en/installing-jama-connect--traditional-/things-to-do-before-installation--traditional-/prepare-your-application-server--traditional-.html


log_file="log_file.txt"

# start of error handler as single-function test.

# to verify the log functions are working, at the end of the error handler is a self-test.
# if you run this as is and see the echoed string, it's working as expected. Your function 
# to test goes after the error handler, and the function call at the second to last line, 
# with the last line verifying it proceeded.

function create_log_file() {
  if [[ ! -f "$log_file" ]]; then
    touch "$log_file"
    echo "Created log file: $log_file"
    return 0
  fi
}

function error_handler() {
  local function_name="${FUNCNAME[1]}"
  local error_message="$1"
  
  echo "Error in function: $function_name"
  echo "Error message: $error_message"
  
  # Append to log file
  echo "Function: $function_name, Error: $error_message" >> "$log_file"
}

function check_file_existence() {
  local x="$1"
  if [[ -f "$x" ]]; then
    echo "File exists: $x"
  else
    error_handler "${FUNCNAME[0]}" "File does not exist: $x"
    return 0
  fi
}

# End of error handler

# open port checking
open_port_checker() {
    echo "Verifying required TCP/IP ports are open and accessible"
    # Define the array of ports to check
    ports=(80 443 22 8080)

    # Loop through the ports and check accessibility
    for port in "${ports[@]}"; do
        if nc -z -v -w5 127.0.0.1 "$port" &>/dev/null; then
            echo "Port $port is accessible."
        else
            port_not_accessible="Port $port is not accessible."
            # calls the error handler function and gives an error code, then writes it to a log file and proceeds.
            error_handler "port_not_accessible"
            return 0
        fi

    done
    event_handler "All ports passed tests"
    }

# skipping or only running if there's a GUI on this server/VM
output_replicated_api_creds() {
    local env_file=".env.creds"

    read -p "Enter the value for REPLICATED_APP: " replicated_app
    read -p "Enter the value for REPLICATED_API_TOKEN: " replicated_api_token

    echo "REPLICATED_APP=$replicated_app" >"$env_file"
    echo "REPLICATED_API_TOKEN=$replicated_api_token" >>"$env_file"

    echo "Credentials have been written to $env_file"
    echo "Full path to the credentials file: $(pwd)/$env_file"
}

# checks to make sure required linux user ids are available
user_id_checker() {
    # Array of Linux user IDs used by Jama
    user_ids=(91 480 481 482 483 484 485 486 487 488 489 490 491 492 493 494 495 496 497 498 499)

    # Loop through the user IDs and check availability
    for uid in "${user_ids[@]}"; do
        if ! id -u "$uid" &>/dev/null; then
            echo "User ID $uid OK."
            return 0
        else
            uids_in_use="User ID $uid is already in use. ERROR 2"
            # calls the error handler function and gives an error code, then writes it to a log file and proceeds.
            error_handler "$uids_in_use"
            return 0
        fi
    done
}

check_create_ntpdate_cronjob() {
    local cron_command="ntpdate pool.ntp.org"
    local cron_schedule="0 0 * * *"

    # Check if the cron job for ntpdate already exists
    if crontab -l | grep -q "$cron_command"; then
        cronjob_already_exists="Cron job for ntpdate already exists."
        # calls the error handler function and gives an error code, then writes it to a log file and proceeds.
        error_handler "$cronjob_already_exists"
    else
        # Add the cron job using crontab
        (
            crontab -l 2>/dev/null
            echo "$cron_schedule $cron_command"
        ) | crontab -
        cron_updated="Cron job for ntpdate created successfully."
        error_handler "$cron_updated"
    fi
}

# Function to checks and set up the hard disks and volume group as described in the Jama users guide if not already set up on /dev/sdb
check_setup_disks() {
    local os_disk="/dev/sda"
    local data_disk="/dev/sdb"
    local vg_name="vg_jama"

    # Check if there are two hard disks
    local num_disks=$(lsblk -d -o name | wc -l)
    if [[ $num_disks -lt 2 ]]; then
        two_volumes_required="Error: At least two volumes are required."
        error_handler "$two_volumes_required."
        exit 1
    fi

    # Check if OS is installed on /dev/sda
    if [[ "$(readlink -f /)" != "$os_disk" ]]; then
        os_not_installed="Error: OS is not installed on $os_disk."
        error_handler "$os_not_installed. Stopping script so partitions can be reviewed."
        exit 1
    fi

    # Check if /dev/sdb exists
    if [[ ! -b "$data_disk" ]]; then
        disk_doesnt_exist="Error: $data_disk does not exist. Stopping script so disk can be deleted and rebuilt."
        error_handler "$disk_too_small"
        exit 1
    fi

    # Check if /dev/sdb is 100GB or larger
    local data_disk_size=$(lsblk -b -n -o size "$data_disk")
    local min_size=$((100 * 1024 * 1024 * 1024)) # 100GB
    if [[ $data_disk_size -lt $min_size ]]; then
        disk_too_small="Error: $data_disk size is less than 100GB. Stopping script so disk can be deleted and rebuilt."
        error_handler "$disk_too_small"
        exit 1
    fi

    # Check if volume group exists on /dev/sdb
    if ! vgdisplay "$vg_name" &>/dev/null; then
        echo "Creating volume group $vg_name on $data_disk..."

        # Delete existing volumes on /dev/sdb
        lvremove -f "/dev/$vg_name" &> /dev/null

        # Create volume group and logical volumes
        vgcreate "$vg_name" "$data_disk"
        lvcreate -L 30G -n lv_docker "$vg_name"
        lvcreate -L 20G -n lv_replicated "$vg_name"
        lvcreate -L 10G -n lv_logs "$vg_name"
        lvcreate -l 100%FREE -n lv_data "$vg_name"

        volume_success="Volume group $vg_name and logical volumes created successfully."
        error_handler "$volume_success"
        return 0
    else
        vg_name_already_exists="Volume group $vg_name already exists on $data_disk. Stopping script; please review the disk partitions before continuing"
        error_handler "$vg_name_already_exists"
        exit 1
    fi
}

warn_and_confirm() {
    local device="/dev/sdb"
    # Warns the user they are about to wipe /dev/sdb and lets them quit if they aren't backed up or ready to lose it.
    read -p "Warning: This operation may be destructive and will be performed on $device. Are you sure you want to continue? (Type 'yes' to confirm, anything else ends the installer.): " response

    if [[ "$response" != "yes" ]]; then
        echo "Operation canceled. Restart the script to start again."
        exit 1
    fi
}

check_add_lines_to_fstab() {
    local fstab_lines=(
        "LABEL=docker /var/lib/docker xfs defaults 0 0"
        "LABEL=replicated /var/lib/replicated ext4 defaults 0 0"
        "LABEL=data /data ext4 defaults 0 0"
        "LABEL=logs /logs ext4 defaults 0 0"
    )

    local fstab_content
    if [[ -f "/etc/fstab" ]]; then
        fstab_content=$(cat /etc/fstab)
    else
        fstab_file_doesnt_exist="Error: /etc/fstab does not exist."
        error_handler
        return 0
    fi

    local added_lines=0

    # Check if each line already exists in /etc/fstab
    for line in "${fstab_lines[@]}"; do
        if grep -Fxq "$line" <<<"$fstab_content"; then
            line_already_exists="Line already exists in /etc/fstab: $line"
            error_handler "$line_already_exists"
            return 0
        else
            echo "$line" | sudo tee -a /etc/fstab
            fstab_message="Added line to /etc/fstab: $line"
            error_handler="$fstab_message"
            ((added_lines++))

        fi
    done

    if [[ $added_lines -eq 0 ]]; then
        fstab_failed="No new lines added to /etc/fstab."
        echo "$fstab_failed"
        error_handler "$fstab_failed"
    else
        echo "Added $added_lines new line(s) to /etc/fstab."
        error_handler "fstab success; added $added_lines lines to /etc/fstab."
    fi
}

check_configure_elasticsearch() {
    local sysctl_file="/etc/sysctl.conf"
    local elasticsearch_setting="vm.max_map_count=262144"
    local elasticsearch_ready_message="Elasticsearch is ready."
    local elasticsearch_not_ready_message="Elasticsearch was not set up properly. Please check the settings in the guide: https://help.jamasoftware.com/ah/en/installing-jama-connect--traditional-/things-to-do-before-installation--traditional-/configure-custom-memory-settings-for-elasticsearch--traditional-.html"

    # Check if the setting already exists in /etc/sysctl.conf
    if grep -q "$elasticsearch_setting" "$sysctl_file"; then
        elasticsearch_msg="The Elasticsearch setting is already present in $sysctl_file."
        error_handler "$elasticsearch_msg"
        return 0
    else
        # Add the setting to /etc/sysctl.conf
        echo "$elasticsearch_setting" | sudo tee -a "$sysctl_file"

        # Reload sysctl settings
        sudo sysctl -p

        echo "The Elasticsearch setting has been added and sysctl settings have been reloaded."
        echo "You should see the line 'vm.max_map_count=262144' in the following output:"

        # Check if the setting is applied
        test_settings = { sudo sysctl -a | grep "max_map_count" }
        echo $test_settings
        if [[ "$test_settings" != "vm.max_map_count=262144"]]
            error_handler "max_map_count test failed"
            return 0
        # Prompt the user to confirm if the setting is applied
        read -p "Did you see 'vm.max_map_count=262144' in the output above? (Y/N): " response

        if [[ "$response" == [Yy] ]]; then
            error_handler "$elasticsearch_ready_message"
            return 0
        else
            error_handler "$elasticsearch_not_ready_message"
            return 0
        fi
    fi
}

get_replicated_app_api_token() {
    urls=(
        "https://vendor.replicated.com/apps"
        "https://vendor.replicated.com/team/serviceaccounts"
        "https://vendor.replicated.com/account-settings"
    )

    # Open URLs in Chrome tabs

    local message_replicated_app="REPLICATED_APP should be set to the name of your application, as shown in the URL path at https://vendor.replicated.com/apps."
    local message_replicated_api_token="REPLICATED_API_TOKEN should be set to a service account token created at https://vendor.replicated.com/team/serviceaccounts, or a user token created in the vendor portal. To create a user token, go to https://vendor.replicated.com/account-settings."

    # Open URLs in new Chrome tabs
    for url in "${urls[@]}"; do
        google-chrome-stable "$url" &
    done

    # prompts user for the environment variables
    read -p "Check those websites for the app name and the api_token and input them in that order next. Press any key when ready to proceed."
    echo "$message_replicated_app" >.env.creds
    echo "$message_replicated_api_token" >>.env.creds

    # adds variables to the environment's current session
    export REPLICATED_APP=my_kots_app
    export REPLICATED_API_TOKEN=d5cdf814bae01b211a8e891593dc12e1158238d27932d082a32b98706e576216

}

install_docker_20_10_7() {
    sudo apt-get remove docker docker.io containerd runc -y
    wget https://download.docker.com/linux/static/stable/x86_64/docker-20.10.7.tgz
    tar xzvf ./docker-20.10.7.tgz
    sudo cp docker/* /usr/bin/ -f
    sudo groupadd docker
    sudo usermod -aG docker $USER
    sudo docker -v
    echo "If you don't see the docker version 20.10.7, go to https://jamaservice.atlassian.net/wiki/spaces/~63bd282b0a1b5442166a493b/pages/1880064752/Rolling+back+Docker+Engine+to+20.10.7+from+the+latest+version+in+a+self-hosted+environment"
}

install_replicated_cli() {
    curl -s https://api.github.com/repos/replicatedhq/replicated/releases/latest |
        grep "browser_download_url.*linux_amd64.tar.gz" |
        cut -d : -f 2,3 |
        tr -d \" |
        wget -O replicated.tar.gz -qi -
    tar xf replicated.tar.gz replicated && rm replicated.tar.gz
    mv replicated /usr/local/bin/replicated
}

main_funct() {
    sudo apt-get update
    sudo apt install curl -y
    # starting first phase - preflight checks
    open_port_checker
    user_id_checker
    check_create_ntpdate_cronjob
    # starting second phase
    echo "Preflights and Prerequisites complete. Proceeding to set up mountpoints..."
    sleep 5
    warns the user, and if they want to proceed, creates volume groups and writes filesystems to /dev/sdb
    echo "Please note that this script performs potentially destructive operations, such as"
    echo "deleting volumes. Double-check the disk configuration and ensure you have proper backups before running it."
    warn_and_confirm
    check_setup_disks
    check_add_lines_to_fstab
    check_configure_elasticsearch
    # if all other functions succeeded, mounts all volumes.
    echo "Preparation complete. Mounting volumes and performing software installation..."
    sleep 10
    mount -a
    #echo "Next you need credentials and a license file from Replicated's vendor dashboard, don't proceed until you have them."
    # get_replicated_app_api_token
    # install_docker_20_10_7
    echo "Installing replicated, and then Jama Connect. Almost done..."
    sleep 10
    install_replicated_cli
    install_jama_curl
}

install_jama_curl() {
    read -p "Did everything else run successfully? If so, type yes to install Jama. Otherwise the script will end and you can review the console here for errors and troubleshooting. " response
    if [[ "$response" != "yes" ]]; then
        echo "Operation canceled. Exiting."
        err_msg = "User failed to type 'yes' to continue."
        exit 12
    else
        curl -sSL "https://get.replicated.com/docker?replicated_tag=2.53.2&replicated_ui_tag=2.53.2&replicated_operator_tag=2.53.2" | sudo bash -s no-auto
        clear
        echo "Jama Connect should now be completely installed. See above for Admin/Setup URL at port 8800."
    fi

}

sudo echo "Jama Connect Docker Native - App Server Setup"
sleep 5
main_funct
