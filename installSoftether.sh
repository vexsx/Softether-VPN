#!/usr/bin/env bash 
 
# Error handling 
set -euo pipefail 
 
# Logging function 
log() { 
    echo "$(date) - $1" 
} 
 
# Constants 
SOFTETHER_DOWNLOAD_URL="https://www.softether-download.com/files/softether/v4.42-9798-rtm-2023.06.30-tree/Linux/SoftEther_VPN_Server/64bit_-_Intel_x64_or_AMD64/softether-vpnserver-v4.42-9798-rtm-2023.06.30-linux-x64-64bit.tar.gz" 
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'


# Check if script is run as root 
if [ "$EUID" -ne 0 ]; then 
    log "Please run this script as root." 
    exit 1 
fi 
 
#remove needrestart for less interruption 
sudo sed -i "s/#\$nrconf{restart} = 'i';/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf


# Backup existing SoftEther installation 
backup_existing_installation() { 
    if [ -d "/opt/vpnserver" ]; then 
        log "Existing SoftEther installation found. Performing backup." 
        echo -e "${yellow}Softether is already installed. The script is attempting to create a backup.${plain}"
        echo -e "${red}USE 'Ctrl + C' to cancel it.${plain}"
        sudo systemctl stop softether-vpnserver.service
        sleep 2
        sudo mkdir /opt/softether_backup
        sleep 2
        sudo cp -f /opt/vpnserver/vpn_server.config /opt/softether_backup/vpn_server.config.bak
        sleep 2
        sudo cp -rf /opt/vpnserver/backup.vpn_server.config /opt/softether_backup/backup.vpn_server.config 
        sleep 2
        sudo rm -rf /opt/vpnserver
        sudo systemctl disable vpnserver
    fi 
} 
 
 # Check for Update script
 update_script() {

    if [ -d "/opt/softether" ]; then
        echo -e "${yellow}Softether is already installed. The script is attempting to create a backup.${plain}"
        echo -e "${red}USE 'Ctrl + C' to cancel it.${plain}"
        sudo systemctl stop softether-vpnserver
        sleep 2
        sudo mkdir /opt/softether_backup
        sleep 2
        sudo cp -f /opt/softether/vpn_server.config /opt/softether_backup/vpn_server.config.bak
        sleep 2
        sudo cp -rf /opt/softether/backup.vpn_server.config /opt/softether_backup/backup.vpn_server.config 
        sleep 2
        sudo rm -rf /opt/softether
        sudo systemctl disable softether-vpnserver
    fi
 }

# Install necessary tools and dependencies 
install_dependencies() { 
    log "Installing necessary tools and dependencies." 
    apt-get update -y 
    sudo apt-get update -y && sudo apt-get -o Dpkg::Options::="--force-confold" -y full-upgrade -y && sudo apt-get autoremove -y 
    apt-get install -y wget tar make gcc 
    sudo apt-get install -y certbot && sudo apt-get install -y ncat && sudo apt-get install -y net-tools
    sudo apt install -y gcc binutils gzip libreadline-dev libssl-dev libncurses5-dev libncursesw5-dev libpthread-stubs0-dev || exit

} 
 
# Download and install SoftEther 
download_and_install_softether() { 
    log "Downloading and installing SoftEther VPN Server." 
    wget "$SOFTETHER_DOWNLOAD_URL" -P /tmp 
    tar xvf /tmp/softether-vpnserver-v4.42-9798-rtm-2023.06.30-linux-x64-64bit.tar.gz -C /tmp 
    cd /tmp/vpnserver 
    make || exit
    sleep 2
    cd .. || exit
    sleep 2
    sudo mkdir /opt/softether
    sudo sudo mv /tmp/vpnserver/* /opt/softether/ || exit
    sleep 2
    sudo /opt/softether/vpnserver start || exit
    sleep 5
    sudo /opt/softether/vpnserver stop || exit
    sleep 5
} 
 
# Create service file 
create_service_file() { 
  log "Creating the service file."
  cat <<EOF > /etc/systemd/system/softether-vpnserver.service
[Unit]
Description=SoftEther VPN server
After=network-online.target
After=dbus.service

[Service]
Type=forking
ExecStart=/opt/softether/vpnserver start
ExecReload=/bin/kill -HUP \$MAINPID

[Install]
WantedBy=multi-user.target
EOF
} 
 
# Enable and start the SoftEther service 
enable_and_start_service() { 
    log "Enabling and starting SoftEther VPN service." 
    systemctl daemon-reload 
    systemctl enable softether-vpnserver.service
    systemctl start softether-vpnserver.service
    # enable IPv4 forwadring 
    echo 1 > /proc/sys/net/ipv4/ip_forward || exit
    sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf 
    sysctl -p 
    sleep 2
} 

# Restore backup
 restore_backup() {

    if [ -d "/opt/softether_backup" ]; then
    clear
    echo -e "${green}Restoring backup.${plain}.\n"
    sudo systemctl stop softether-vpnserver
    sudo cp -f /opt/softether_backup/vpn_server.config.bak /opt/softether/vpn_server.config
    sudo cp -rf /opt/softether_backup/backup.vpn_server.config /opt/softether/
    sudo systemctl restart softether-vpnserver
    fi
 }

# Add need-restart back again
sudo sed -i "s/#\$nrconf{restart} = 'a';/\$nrconf{restart} = 'i';/" /etc/needrestart/needrestart.conf

#Adding shortcut for Softether setting
# alias vpncmd='sudo /opt/softether/vpncmd 127.0.0.1:5555'
echo "alias vpncmd='sudo /opt/softether/vpncmd 127.0.0.1:5555'" >> ~/.bashrc

install_BBR() {

    echo -e "${red}BBR is a congestion control system that optimizes the transmission of data packets over a network. ${plain}.\n"

    if [[ 1 = 1 ]]
        then
        # installing
            echo "net.core.default_qdisc=fq" | tee -a /etc/sysctl.conf
            echo "net.ipv4.tcp_congestion_control=bbr" | tee -a /etc/sysctl.conf
            # Apply changes
            sysctl -p
            clear
            echo -e "${red} USE 'vpncmd' FOR Softether Setting ${plain}"
            echo "Have FUN ;)."
            echo "REBOOT Recommended."
        else
        # Exit the script
        clear
        echo -e "${red} USE 'vpncmd' FOR Softether Setting ${plain}"
        echo "Have FUN ;)."
        echo "REBOOT Recommended."
        exit 0
    fi
}

# Main script logic 
main() { 
    backup_existing_installation 
    update_script
    install_dependencies 
    download_and_install_softether 
    create_service_file 
    enable_and_start_service 
    restore_backup
    install_BBR
    log "SoftEther VPN server installation and configuration completed successfully." 
} 
 
# Run the main script 
main 

