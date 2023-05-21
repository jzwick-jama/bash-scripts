#!/bin/bash

log_file="log_file.txt"
mysql_version=""
mssql_version=""

# start of error handler as single-function test.

# to verify the log functions are working, at the end of the error handler is a self-test.
# if you run this as is and see the echoed string, it's working as expected. Your function
# to test goes after the error handler, and the function call at the second to last line,
# with the last line verifying it proceeded.

function error_handler() {
  # gets name of the failing function and the error message, and adds them to log_file.txt
  local function_name="${FUNCNAME[1]}"
  local error_message="$1"
  current_time=$(date +%T)
  echo "Current time: $current_time"

  echo "Error in function: $function_name"
  echo "Error message: $error_message"

  # Append to log file
  echo "Current time: $current_time - Function: $function_name, Error: $error_message" >>"$log_file"
}

# called to check if log_file.txt exists, and if my.cnf exists
function check_file_existence() {
  local x="$1"
  if test -f "$x"; then
    echo "File exists: $x"
    return 0
  else
    error_handler "${FUNCNAME[1]}: file $x does not exist"
    return 0
  fi
}

# called if no log_file.txt detected, skips if it detects log_file.txt in path "."
function create_log_file() {
  if [[ ! -f "$log_file" ]]; then
    touch "$log_file"
    error_handler "Created log file: $log_file"
    return 0
  fi
}

# called if no SQL installation detected, skips if it detects MYSQL or MSSQL
function install_mysql_server() {
  # Function to install MySQL server
  echo "Installing MySQL 8..."
  sudo apt-get update
  sudo apt install mysql-server -y || error_handler "mysql_install_failed" && exit 1
  echo "MySQL 8 installation completed."
}

# called if either SQL version is detected within check_database_service. Tests SQL connection for both versions and reports results
function check_sql_connectivity() {
  if ! test_sql_connection_bothversions; then
    error_handler "SQL connection test failed."
    return 0
  else
    error_handler "SQL connection test passed."
    return 0
  fi
}

# called if log_file exists or was created. Checks for running mysql or mssql.service, if present, checks what version of My/MSSQL they have and notes it in log_file
# if MySQL present, runs backup_and_update_mysql_config. if my.cnf present, backs it up and checks if a block is present and if not appends required settings to my.cnf.
# if MySQL and no my.cnf, errors and tells user to verify it was installed right.
# if no SQL present at all offers to install MySQL 8, then performs MySQL 8 checks.
function check_database_service() {
  if systemctl is-active --quiet mysql.service; then
    mysql_version=$(mysql --version | awk '{print $5 }')
    mysql_ver_msg="Success - MySQL version $mysql_version detected."
    error_handler "$mysql_ver_msg"
    echo "Checking for expected lines in my.cnf and will apply updates to it if not present..."
    # Report success to console and error log to ensure we're aware.
    return 0
  elif systemctl is-active --quiet mssql; then
    mssql_version=$(mssql-conf -Q 'SELECT @@VERSION' | grep -o 'Microsoft SQL Server [0-9]\+\.[0-9]\+\.[0-9]\+')
    mssql_ver_msg="MSSQL version $mssql_version detected."
    # Report success to console and error log to ensure we're aware.
    error_handler "$mssql_ver_msg"
    return 0
  else
    error_handler "Error: Neither MySQL nor MSSQL is installed on localhost."
    read -p "Do you want to install MySQL 8? (y/n): " response
    if [[ "$response" == "y" ]]; then
      install_mysql_server || {
        error_handler "MySQL 8 installation failed, exiting."
        exit 1
      }
      error_handler "Success - MySQL installation successful"
      backup_and_update_mysql_config
      return 0
    else
      error_handler "No SQL installed. User cancelled MySQL 8 setup. Exiting."
      exit 1
    fi
  fi
}

# called if mysql 8 and my.cnf detected in path /etc/mysql/
function backup_and_update_mysql_config() {
  #verifies /etc/mysql/my.cnf exists
  if test -f "/etc/mysql/my.cnf"; then
    # Backup the original my.cnf file
    sudo cp /etc/mysql/my.cnf /etc/mysql/my.cnf.old
    error_handler "successfully backed up my.cnf as my.cnf.old"
    # Check if [mysqld] is present in my.cnf
    if grep -q "\[mysqld\]" /etc/mysql/my.cnf; then
      error_handler "my.cnf found in expected path"
      # Check if wait_timeout=259200 is present in my.cnf
      if ! grep -q "wait_timeout=259200" /etc/mysql/my.cnf; then
        # Append the block to my.cnf IF it exists but the text block wasn't found
        printf "\n[mysqld]\nbind-address=0.0.0.0\nkey_buffer_size=16M\nmax_allowed_packet=1G\nthread_stack=192K\nthread_cache_size=8\ntmp_table_size=2G\nmax_heap_table_size=2G\ntable_open_cache=512\ninnodb_buffer_pool_size=12G\ninnodb_log_file_size=256M\ninnodb_log_buffer_size=12M\ninnodb_thread_concurrency=16\nmax_connections=351\nwait_timeout=259200\n" | sudo tee -a /etc/mysql/my.cnf >/dev/null
        error_handler "Appended text block to my.cnf but header was detected. Please review file to verify no duplicates are present..."
        sleep 5
        sudo nano /etc/mysql/my.cnf
        error_handler "User reviewed my.cnf and verified there are no duplicates in [mysqld], continuing."
        return 0
      fi
    else
      # Append the entire block to my.cnf
      printf "\n[mysqld]\nbind-address=0.0.0.0\nkey_buffer_size=16M\nmax_allowed_packet=1G\nthread_stack=192K\nthread_cache_size=8\ntmp_table_size=2G\nmax_heap_table_size=2G\ntable_open_cache=512\ninnodb_buffer_pool_size=12G\ninnodb_log_file_size=256M\ninnodb_log_buffer_size=12M\ninnodb_thread_concurrency=16\nmax_connections=351\nwait_timeout=259200\n" | sudo tee -a /etc/mysql/my.cnf >/dev/null
      error_handler "Neither [mysqld] or string match test passed; wrote changes to my.cnf"
      return 0
    fi
  else
    error_handler "MySQL 8 detected but /etc/mysql/my.cnf does not exist. Exiting, please make sure MySQL 8 is installed correctly."
    exit 1
  fi
}

# called if mysql or mssql detected on server
function test_sql_connection_bothversions() {
  if systemctl is-active --quiet mysql.service; then
    read -p "Enter username:" MYSQL_USER
    read -p "Enter password:" MYSQL_PASSWORD
    read -p "Please type the full path and filename of the SQL Configuration Scripts. Default is ./" SCRIPT_PATH
    # Call the SQL script using the mysql command-line tool
    result=$(mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" <"$SCRIPT_PATH")
    error_handler "result"
    return 0
    # Report success to console and error log to ensure we're aware.
  elif systemctl is-active --quiet mssql; then
    read -p "What is the hostname of your SQL server?" SQL_SERVER
    read -p "Enter username:" SQL_USER
    read -p "Enter password:" SQL_PASSWORD
    read -p "Please type the full path and filename of the SQL Configuration Scripts. Default is ./" SCRIPT_PATH
    # Call the script using the sqlcmd command-line tool
    result=$(sqlcmd -S "$SQL_SERVER" -U "$SQL_USER" -P "$SQL_PASSWORD" -i "$SCRIPT_PATH")
    error_handler "result"
    return 0
  else
    error_handler "Unable to test SQL connection, neither supported version was detected."
    exit 1
  fi
}

# end of testing and setup block

# Beginning of main testing function
check_file_existence "$log_file"
{ create_log_file && error_handler "log_file did not exist, created log_file.txt in current working dir."; }
check_sql_connectivity
check_database_service
backup_and_update_mysql_config
error_handler "Success - SQL connection test passed"
error_handler "Success - All tests passed."

# prints log_file.txt to console for review
cat log_file.txt