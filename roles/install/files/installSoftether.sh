#!/usr/bin/env bash 
 
# Error handling 
set -euo pipefail 
 
# Logging function 
log() { 
    echo "$(date) - $1" 
} 
 
# Constants 
SOFTETHER_VERSION="4.43" 
SOFTETHER_BUILD="9799" 
SOFTETHER_DOWNLOAD_URL="https://www.softether-download.com/files/softether/v${SOFTETHER_VERSION}-${SOFTETHER_BUILD}-beta-2023.08.31-tree/Linux/SoftEther_VPN_Server/64bit_-_Intel_x64_or_AMD64/softether-vpnserver-v${SOFTETHER_VERSION}-${SOFTETHER_BUILD}-linux-x64-64bit.tar.gz" 
 
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
    apt-get install -y wget tar make gcc 
    # Additional dependencies can be added here 
} 
 
# Download and install SoftEther 
download_and_install_softether() { 
    log "Downloading and installing SoftEther VPN Server." 
    wget "$SOFTETHER_DOWNLOAD_URL" -P /tmp 
    tar xvf /tmp/softether-vpnserver-v${SOFTETHER_VERSION}-${SOFTETHER_BUILD}-linux-x64-64bit.tar.gz -C /tmp 
    cd /tmp/vpnserver 
    make 
    make install -y || exit
    sleep 5
    make || exit
    sleep 2
    cd .. || exit
    sleep 2
    sudo mkdir /opt/softether
    sudo mv vpnserver /opt/softether || exit
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
Description=SoftEther VPN Server 
After=network.target 
 
[Service] 
Type=forking 
ExecStart=/opt/vpnserver/vpnserver start 
ExecStop=/opt/vpnserver/vpnserver stop 
ExecReload=/opt/vpnserver/vpnserver restart 
 
[Install] 
WantedBy=multi-user.target 
EOF 
} 
 
# Enable and start the SoftEther service 
enable_and_start_service() { 
    log "Enabling and starting SoftEther VPN service." 
    systemctl daemon-reload 
    systemctl enable softether-vpnserver 
    systemctl start softether-vpnserver 
} 
 
# Main script logic 
main() { 
    backup_existing_installation 
    update_script
    install_dependencies 
    download_and_install_softether 
    create_service_file 
    enable_and_start_service 
    log "SoftEther VPN server installation and configuration completed successfully." 
} 
 
# Run the main script 
main 