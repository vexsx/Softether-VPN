# SoftEther VPN Ansible Role

This Ansible role installs and configures the SoftEther VPN server on a target machine running a Debian-based distribution.

## Requirements

- Ansible 2.9 or higher
- Target machine running a Debian-based distribution (e.g., Ubuntu)
- Root privileges on the target machine

## Repository Structure

- **inventory**: Contains the inventory files for Ansible.
- **roles/install/tasks**: Contains the Ansible tasks for installing Softether VPN.
- **installSoftether.sh**: Shell script for installing Softether VPN.
- **main.yaml**: Main Ansible playbook.


### Installation

1. **Clone the repository**

    ```bash
    git clone https://github.com/vexsx/Softether-VPN.git
    cd Softether-VPN
    ```

2. **Run the Ansible playbook**

    Ensure your inventory file is correctly configured, then run:

    ```bash
    ansible-playbook -i inventory main.yaml
    ```

### Using the install script

Alternatively, you can use the provided shell script to install Softether VPN:

```bash
chmod +x installSoftether.sh
./installSoftether.sh
```

## Role Variables

You can configure the following variables to customize the role:

```yaml
softether_download_url: "https://www.softether-download.com/files/softether/v4.42-9798-rtm-2023.06.30-tree/Linux/SoftEther_VPN_Server/64bit_-_Intel_x64_or_AMD64/softether-vpnserver-v4.42-9798-rtm-2023.06.30-linux-x64-64bit.tar.gz"