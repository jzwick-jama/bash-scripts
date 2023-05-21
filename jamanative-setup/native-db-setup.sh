#!/bin/bash

log_file="log_file.txt"
pfc_file="db_schema_preflight_checks.sh"

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
    return 1
  fi
}

# End of error handler
install_mysql_server() {
  mysql_install_failed=0
  mysql_install_complete=0
  { sudo apt-get update && sudo apt install mysql-server -y } ||   error_handler "mysql_install_failed"
  mysql_secure_installation
}

# checks what version of My/MSSQL they have or the test fails if neither is detected.
check_database_service() {
    if systemctl is-active --quiet mysql.service; then
        mysql_version=$(mysql --version | awk '{print $5}')
        mysql_ver_msg="MySQL version $mysql_version detected."
        # reports success to console and error log to be sure we know.
        backup_and_update_mysql_config || error_handler "cant find my.cnf, check MySQL installation."        
    elif systemctl is-active --quiet mssql; then
        mssql_version=$(mssql-conf -Q 'SELECT @@VERSION' | grep -o 'Microsoft SQL Server [0-9]\+\.[0-9]\+\.[0-9]\+')
        mssql_ver_msg="MSSQL version $mssql_version detected."
        # reports success to console and error log to be sure we know.
        echo $mssql_ver_msg && error_handler "$mssql_ver_msg"
    else
        echo "Error: Neither MySQL nor MSSQL installed on localhost."
        # Test absolutely fails here, with no SQL on server there's no point in continuing.
        # for now, verify version with console or logfile. No version test yet.
        exit 1
    fi
    read -P ""
    test_sql_connection_bothversions ||
}

backup_and_update_mysql_config() {
  if [ -f "/etc/mysql/my.cnf" ]; then
    # Backup the original my.cnf file
    sudo cp /etc/mysql/my.cnf /etc/mysql/my.cnf.old

    # Check if [mysqld] is present in my.cnf
    if grep -q "\[mysqld\]" /etc/mysql/my.cnf; then
      # Check if wait_timeout=259200 is present in my.cnf
      if ! grep -q "wait_timeout=259200" /etc/mysql/my.cnf; then
        # Append the block to my.cnf
        printf "\n[mysqld]\nbind-address=0.0.0.0\nkey_buffer_size=16M\nmax_allowed_packet=1G\nthread_stack=192K\nthread_cache_size=8\ntmp_table_size=2G\nmax_heap_table_size=2G\ntable_open_cache=512\ninnodb_buffer_pool_size=12G\ninnodb_log_file_size=256M\ninnodb_log_buffer_size=12M\ninnodb_thread_concurrency=16\nmax_connections=351\nwait_timeout=259200\n" | sudo tee -a /etc/mysql/my.cnf > /dev/null
      fi
    else
      # Append the entire block to my.cnf
      printf "\n[mysqld]\nbind-address=0.0.0.0\nkey_buffer_size=16M\nmax_allowed_packet=1G\nthread_stack=192K\nthread_cache_size=8\ntmp_table_size=2G\nmax_heap_table_size=2G\ntable_open_cache=512\ninnodb_buffer_pool_size=12G\ninnodb_log_file_size=256M\ninnodb_log_buffer_size=12M\ninnodb_thread_concurrency=16\nmax_connections=351\nwait_timeout=259200\n" | sudo tee -a /etc/mysql/my.cnf > /dev/null
    fi
  else
    echo "The my.cnf file does not exist."
    return 1
  fi
}

# Checks the SQL connection depending on the type that was detected earlier. 
# If none was detected theoretically this should never appear, but just in case...
function test_sql_connection_bothversions() {
    if [ -n "$mysql_version" ]; then
        # Define MySQL credentials and script path
        MYSQL_USER=(read -p "Enter username:")
        MYSQL_PASSWORD=(read -p "Enter password:")
        SCRIPT_PATH=(read -p "Please type the full path and filename of the SQL Configuration Scripts. Default is ./")
        # Call the SQL script using the mysql command-line tool
        mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" < "$SCRIPT_PATH"
        return 0
    elif [ -n "$mssql_version" ]; then
        SQL_SERVER=(read -p "What is the hostname of your SQL server?")
        SQL_USER=(read -p "Enter username:")
        SQL_PASSWORD=(read -p "Enter password:")
        SCRIPT_PATH=(read -p "Please type the full path and filename of the SQL Configuration Scripts. Default is ./")
        # Call the script using the sqlcmd command-line tool
        sqlcmd -S "$SQL_SERVER" -U "$SQL_USER" -P "$SQL_PASSWORD" -i "$SCRIPT_PATH"
        return 0
    else
        error_handler "Unable to test SQL connection, neither supported version was detected."
        exit 1
}
# and here

# Example of a command being called checking that a file exists, and if not creates it and proceeds
check_file_existence "$log_file" || { create_log_file && error_handler "log_file did not exist, created log_file.txt in current working dir."; }
check_database_service
# test fails here if no SQL installed.

# calling backup_and_update_mysql_config IF MySQL was detected so it won't error incorrectly on MSSQL servers 
# (called during the version test):

# backup_and_update_mysql_config || error_handler "cant find my.cnf, check MySQL installation."
# (called if the version test passed but connection failed.)
echo "Success! All functions have run as expected."

