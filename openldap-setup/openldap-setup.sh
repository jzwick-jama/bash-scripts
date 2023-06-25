#!/bin/bash

function InstallLDAPAccountManager() {
  echo "Installing prerequisites..."
  sudo apt-get install apache2 php-fpm php-imap php-mbstring \
  php-mysql php-json php-curl php-zip php-xml php-bz2 php-intl \
  php-gmp php-redis -y;
  echo "Install complete. Installing LAM..."
  sudo apt-get install ldap-account-manager -y
}

function CreateVirtualHost() {
  cat ./virtualhost.txt
  read -p "Pausing, please copy this text and paste it into the nano window opening next."
  sudo nano /etc/apache2/sites-available/lam.conf
}

function InstallOpenLDAP() {
  sudo apt-get install slapd ldap-utils -y
  echo "OpenLDAP installed."
  echo " "
  echo "Omit OpenLDAP Server Configuration: No" 
  echo "DNS Domain Name: The domain name used for your OpenLDAP server, which is used to create the base DN (Distinguished Name). "
  echo "Organization Name: The name of your organization "
  echo "Administrator Password: This is the password you set during the OpenLDAP installation. "
  echo "Do you want the database to be removed when slapd is purged? No "
  echo "Move old database? Yes"
  echo "Allow LDAPv2 protocol? No"
  read -p "Take note of the above settings when prompted next. Be sure to enter the same password in the setup screen coming up too."
  sudo dpkg-reconfigure slapd
}

function LinkToTheSourceGuide() {
  echo " "
  echo "https://www.techrepublic.com/article/how-to-install-openldap-ubuntu-server-22-04/"
  echo " "
  read -p "Hit enter to continue "
}

function ReloadApache() {
  sudo a2ensite lam.conf
  sudo systemctl reload apache2
  sudo mv /var/www/html/index.html ~/
  echo "Now, go to http://SERVER/lam where SERVER is either the IP address or domain of the OpenLDAP hosting server." 
  read -p "You should be greeted by the LAM login screen"
}

function menu() {
  while true; do
    echo "To exit, run all 7 steps, or press Ctrl-C or q."
        echo "----------------------------------   "
        echo "1) Get the URL to the guide this was based on"
        echo "2) Install OpenLDAP"
        echo "3) Install OpenLDAP Account Manager"
        echo "4) Create virtual host"
        echo "5) Reload Apache"
        echo "q) Exit"
        echo " "
        read -p "Choose an option (1-5) or; choose q or press Ctrl-C to quit: " choice
        case "$choice" in
        1)
            LinkToTheSourceGuide
            menu
            ;;
        2)
            InstallOpenLDAP
            menu
            ;;
        3)
            InstallLDAPAccountManager
            menu
            ;;
        4)
            CreateVirtualHost
            menu
            ;;
        5)
            ReloadApache
            menu
            ;;
        q)
            quit
            break
            ;;
        *)
            echo "Invalid choice. Only options 1-5 are allowed. Press Ctrl-C to quit."
            menu
            ;;
        esac
    done
}

menu
