#!/bin/bash

# This script runs a series of pre-flight checks on the client's DB server to make sure it is within our specs, then
# checks to see if any of the steps before installing mysql haven't been completed yet, if so it completes them, if not
# it proceeds to install mysql 8 and either comes with scripts that can be run from mysqlworkbench or from the command
# line.

# also, uses ./error_handler.sh starting at error 14 for logging and debugging.
#
# Version 1.0

# Declaring script-scoped variables
required_docker_version="20.10.7"
error_handler_script="./error_handler.sh"
exit_code=0

preflight_docker() {
    echo "Checking if Docker is installed and the correct version..."
    sleep 3
    if ! command -v docker &>/dev/null; then
        echo "Docker is not installed"
        exit_code=14
        ./error_handler.sh "14"
    else
        # Get Docker version
        docker_version=$(docker --version | awk '{print $3}')
        if [[ "$docker_version" == "$required_docker_version" ]]; then
            echo "Docker version is $required_docker_version - Success!"
        else
            echo "Docker version is not $required_docker_version"
            exit_code=14
            ./error_handler.sh "14"
        fi
    fi
}

preflight_linux_kernel() {
    echo "Checking Linux kernel version; requires > 3.10 and Jama recommends upgrading to version 4.x of the Linux kernel."
    required_version="4.0"
    kernel_version=$(uname -r)

    if [[ $(echo -e "$required_version\n$kernel_version" | sort -V | head -n1) == "$required_version" ]]; then
        echo "Kernel version is $kernel_version - Pass"
    elif [[ $(echo -e "$required_version\n$kernel_version" | sort -V | head -n1) == "$kernel_version" ]]; then
        if [[ $(echo -e "$kernel_version\n3.10" | sort -V | head -n1) == "3.10" ]]; then
            echo "Kernel version is $kernel_version - Warning: Consider upgrading to 4.x"
        else
            echo "Kernel version is $kernel_version - Error: Please upgrade to a kernel version >= 4.x"
            exit_code=15
            ./error_handler.sh "$exit_code"
        fi
    fi
}

preflight_linux_distribution() {
    linux_distribution=$(cat /etc/*-release | grep "^ID=" | cut -d'=' -f2)

    if [[ $linux_distribution != "ubuntu" && $linux_distribution != "centos" && $linux_distribution != "rhel" ]]; then
        echo "Unsupported Linux distribution: $linux_distribution"
        echo "This distribution may be compatible with Docker CE, but it is not explicitly tested."
        echo "Consider using Ubuntu, Red Hat (RHEL), or CentOS for better compatibility."
        exit_code=16
        ./error_handler.sh "$exit_code"
    fi

    case $linux_distribution in
    ubuntu)
        ubuntu_version=$(lsb_release -rs)
        if [[ $ubuntu_version == "18.04" || $ubuntu_version == "20."* ]]; then
            echo "Test succeeded: Ubuntu $ubuntu_version"
        else
            echo "Unsupported Ubuntu version: $ubuntu_version"
            echo "Please use Ubuntu 18.04.5 or a version not newer than 20.x."
            exit_code=16
            ./error_handler.sh "$exit_code"
        fi
        ;;
    centos)
        centos_version=$(rpm -q --queryformat '%{VERSION}' centos-release)
        if [[ $centos_version != "7.8" ]]; then
            echo "Unsupported CentOS version: $centos_version"
            echo "Please use CentOS 7.8 for better compatibility."
            exit_code=16
            ./error_handler.sh "$exit_code"
        else
            echo "Test succeeded: CentOS $centos_version"
        fi
        ;;
    rhel)
        rhel_version=$(rpm -q --queryformat '%{VERSION}' redhat-release)
        if [[ $rhel_version != "7.8" && $rhel_version != "8.4" ]]; then
            echo "Unsupported Red Hat (RHEL) version: $rhel_version"
            echo "Please use Red Hat (RHEL) 7.8 or 8.4 for better compatibility."
            exit_code=16
            ./error_handler.sh "$exit_code"
        else
            echo "Test succeeded: Red Hat (RHEL) $rhel_version"
        fi
        ;;
    esac
}

preflight_db_server_version() {
    # Check if MSSQL Server is running
    mssql_server=$(systemctl is-active mssql-server)
    if [[ $mssql_server == "active" ]]; then
        mssql_version=$(sqlcmd -Q "SELECT SERVERPROPERTY('ProductVersion') AS Version" -t 1 | awk -F "." '{print $1}')
        if [[ $mssql_version == "14" || $mssql_version == "15" ]]; then
            echo "MSSQL Server $mssql_version - Success!"
        else
            echo "Unsupported MSSQL Server version: $mssql_version"
            exit_code=17
            ./error_handler.sh "$exit_code"
        fi
        return
    fi

    # Check if MySQL Server is running
    mysql_server=$(systemctl is-active mysql)
    if [[ $mysql_server == "active" ]]; then
        mysql_version=$(mysql -V | awk '{print $5}')
        if [[ $mysql_version == "8."* ]]; then
            echo "MySQL Server $mysql_version - Success!"
        else
            echo "Unsupported MySQL Server version: $mysql_version"
            exit_code=17
            ./error_handler.sh "$exit_code"
        fi
        return
    fi

    echo "No MSSQL Server or MySQL Server found."
    exit_code=17
    ./error_handler.sh "$exit_code"
}

preflight_scp_db_tests_to_db_server() {
    read -p "Enter SQL server IP address: " sql_server_ip
    read -p "Enter SQL server port: " sql_port
    read -p "Enter SQL server root password: " -s root_password
    echo

    # Encrypt root password using base64
    encrypted_password=$(echo "$root_password" | base64)
}

# Function to generate db_schema_preflight_checks.sh file
generate_preflight_checks_script() {
    # Create db_schema_preflight_checks.sh file
    cat <<EOF >db_schema_preflight_checks.sh
#!/bin/bash

# Function to decrypt and store root password
decrypt_and_store_password() {
    encrypted_password="$encrypted_password"
    root_password=\$(echo "\$encrypted_password" | base64 -d)
}

# Store SQL server IP address and port
sql_server_ip="$sql_server_ip"
sql_port="$sql_port"

# Function to check SQL server type and establish test connection
check_sql_server_type() {
    if [[ \$sql_server_ip == *"://"* ]]; then
        server_type="mssql"
    else
        server_type="mysql"
    fi

    if [[ \$server_type == "mssql" ]]; then
        echo "Detected MSSQL server"
        # Your MSSQL test connection command here
    elif [[ \$server_type == "mysql" ]]; then
        echo "Detected MySQL server"
        # Your MySQL test connection command here
    else
        echo "Unknown SQL server type"
        exit_code=18
        ./error_handler.sh "\$exit_code"
    fi
}

# Call the decrypt_and_store_password function
decrypt_and_store_password

# Call the check_sql_server_type function
check_sql_server_type
EOF

    # Set permissions for the script file
    chmod +x db_schema_preflight_checks.sh
}

# Call the prompt_sql_server_details function
prompt_sql_server_details

# Call the generate_preflight_checks_script function
generate_preflight_checks_script

# Print success message
echo "db_schema_preflight_checks.sh file generated successfully."

# Verify db_schema_preflight_checks.sh file exists
if [ -f "db_schema_preflight_checks.sh" ]; then
    read -p "Enter the name of a user account on the DB server: " user_account
    # Copy the script file to the user's home directory on the DB server using scp
    scp db_schema_preflight_checks.sh "$user_account@$sql_server_ip:~/"

    # Check if scp command exited successfully
    if [ $? -eq 0 ]; then
        echo "db_schema_preflight_checks.sh file copied to $user_account@$sql_server_ip:~/"
        echo "To complete testing, please SSH to the DB server, run 'chmod 777 db_schema_preflight_checks.sh' and execute the script."
        echo "SSH Command: ssh $user_account@$sql_server_ip"
    else
        exit_code=20
        ./error_handler.sh "$exit_code"
    fi
else
    echo "db_schema_preflight_checks.sh file not found."
    exit_code=21
    ./error_handler.sh "$exit_code"
fi

main() {
    echo "Starting preflight test sequence..."
    preflight_docker
    preflight_linux_kernel
    preflight_linux_distribution
    echo "Basic preflight test sequence complete."
    sleep 3
    echo "Starting DB server-specific preflight check sequence..."
    preflight_db_server_version
    echo "Generating db_schema_preflight_checks.sh locally and copying to DB server via SCP..."
    preflight_scp_db_tests_to_db_server
    echo "Copy complete. Please connect to the database server via SSH and run db_schema_preflight_checks.sh from your home directory to complete testing."
    echo "If any errors were reported while running this script, please check ./error.log for more details"
}

main
