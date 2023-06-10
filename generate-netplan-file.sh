#!/bin/bash

# Creates a new 00-installer-config.yml in /etc/netplan if one does not exist. If it does, 
function generate_new_config() {
  if [ ! -f /etc/netplan/00-installer-config.yml ]; then
    sudo tee /etc/netplan/00-installer-config.yml >/dev/null <<EOF
network:
  renderer: networkd
  ethernets:
    eth0:
      addresses:
        - 192.168.10.5/24
      nameservers:
        addresses: [1.1.1.1, 8.8.8.8]
      routes:
        - to: default
          via: 192.168.1.1
  version: 2
EOF
  else
    echo "The file /etc/netplan/00-installer-config.yml already exists."
  fi
}

function if_config_exists() {
  if [ -f /etc/netplan/00-installer-config.yml ]; then
    cat <<EOF > ./example.00-installer-config.yml
network:
  renderer: networkd
  ethernets:
    eth0:
      addresses:
        - 192.168.10.5/24
      nameservers:
        addresses: [1.1.1.1, 8.8.8.8]
      routes:
        - to: default
          via: 192.168.1.1
  version: 2
EOF
  echo "Copy the following bash script and make sure your 00-installer-config.yml file in /etc/netplan matches this one, except for having a unique IP address. "
  read -p "Hit enter when ready to open the existing file. Save when you're done and run 'sudo netplan apply'."
  echo " "
  sudo nano /etc/netplan/00-installer-config.yml
  else
    echo "The file /etc/netplan/00-installer-config.yml doesn't exist."
  fi
}

function ask_installation() {
  read -p "Do you want to install 00-installer-config.yml? (yes/no): " response
  case "$response" in
    [yY]|[yY][eE][sS])
      if_config_exists
      ;;
    [nN]|[nN][oO])
      generate_new_config
      ;;
    *)
      echo "Invalid response. Please enter 'yes' or 'no'."
      ;;
  esac
}

ask_installation