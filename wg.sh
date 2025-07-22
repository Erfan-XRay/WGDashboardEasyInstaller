#!/bin/bash

# Define colors
RED='\033[0;31m'    # Red
GREEN='\033[0;32m'  # Green
YELLOW='\033[0;33m' # Yellow
BLUE='\033[0;34m'   # Blue
PURPLE='\033[0;35m' # Purple
CYAN='\033[0;36m'   # Cyan
WHITE='\033[0;37m'  # White
NC='\033[0m'        # No Color (reset to default)

# Function to display a beautiful menu
display_menu() {
    clear
    echo -e "${CYAN}----------------------------------------------------${NC}"
    echo -e "${YELLOW}       WGDashboard Easy Installer by ErfanXRay            ${NC}"
    echo -e "${CYAN}----------------------------------------------------${NC}"
    echo -e "${GREEN}1. Install WGDashboard${NC}"
    echo -e "${BLUE}2. WGDashboard Management${NC}" # New option
    echo -e "${RED}3. Uninstall WGDashboard${NC}"
    echo -e "${WHITE}4. Exit${NC}"
    echo -e "${CYAN}----------------------------------------------------${NC}"
    read -p "$(echo -e "${BLUE}Please enter your choice: ${NC}")" choice
}

# Function to manage WGDashboard service
manage_wgdashboard() {
    SERVICE_FILE="/etc/systemd/system/wg-dashboard.service"

    if [ ! -f "$SERVICE_FILE" ]; then
        echo -e "${RED}WGDashboard service file not found. WGDashboard might not be installed.${NC}"
        read -p "$(echo -e "${BLUE}Press Enter to continue...${NC}")"
        return
    fi

    while true; do
        clear
        echo -e "${CYAN}----------------------------------------------------${NC}"
        echo -e "${YELLOW}       WGDashboard Service Management               ${NC}"
        echo -e "${CYAN}----------------------------------------------------${NC}"
        echo -e "${GREEN}1. Start WGDashboard Service${NC}"
        echo -e "${RED}2. Stop WGDashboard Service${NC}"
        echo -e "${PURPLE}3. Restart WGDashboard Service${NC}"
        echo -e "${WHITE}4. Back to Main Menu${NC}"
        echo -e "${CYAN}----------------------------------------------------${NC}"
        read -p "$(echo -e "${BLUE}Please enter your choice: ${NC}")" sub_choice

        case $sub_choice in
            1)
                echo -e "${YELLOW}Starting WGDashboard service...${NC}"
                sudo systemctl start wg-dashboard.service
                if sudo systemctl is-active --quiet wg-dashboard.service; then
                    echo -e "${GREEN}WGDashboard service started successfully.${NC}"
                else
                    echo -e "${RED}Failed to start WGDashboard service. Check logs with 'sudo systemctl status wg-dashboard.service'.${NC}"
                fi
                read -p "$(echo -e "${BLUE}Press Enter to continue...${NC}")"
                ;;
            2)
                echo -e "${YELLOW}Stopping WGDashboard service...${NC}"
                sudo systemctl stop wg-dashboard.service
                if ! sudo systemctl is-active --quiet wg-dashboard.service; then
                    echo -e "${GREEN}WGDashboard service stopped successfully.${NC}"
                else
                    echo -e "${RED}Failed to stop WGDashboard service. Check logs with 'sudo systemctl status wg-dashboard.service'.${NC}"
                fi
                read -p "$(echo -e "${BLUE}Press Enter to continue...${NC}")"
                ;;
            3)
                echo -e "${YELLOW}Restarting WGDashboard service...${NC}"
                sudo systemctl restart wg-dashboard.service
                if sudo systemctl is-active --quiet wg-dashboard.service; then
                    echo -e "${GREEN}WGDashboard service restarted successfully.${NC}"
                else
                    echo -e "${RED}Failed to restart WGDashboard service. Check logs with 'sudo systemctl status wg-dashboard.service'.${NC}"
                fi
                read -p "$(echo -e "${BLUE}Press Enter to continue...${NC}")"
                ;;
            4)
                echo -e "${PURPLE}Returning to main menu...${NC}"
                return
                ;;
            *)
                echo -e "${RED}Invalid option. Please enter a number between 1 and 4.${NC}"
                read -p "$(echo -e "${BLUE}Press Enter to continue...${NC}")"
                ;;
        esac
    done
}


# Function to install WGDashboard
install_wgdashboard() {
    echo -e "${YELLOW}Starting WGDashboard installation...${NC}"

    # Check for root access
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}This script must be run with root privileges. Please use sudo.${NC}"
        exit 1
    fi

    # Determine package manager (apt or yum)
    if command -v apt &> /dev/null; then
        PACKAGE_MANAGER="apt"
        UPDATE_CMD="sudo apt update"
        INSTALL_CMD="sudo apt install -y"
    elif command -v yum &> /dev/null; then
        PACKAGE_MANAGER="yum"
        UPDATE_CMD="sudo yum check-update" # yum update is not always needed before install
        INSTALL_CMD="sudo yum install -y"
    else
        echo -e "${RED}Supported package manager (apt or yum) not found. Please install manually.${NC}"
        read -p "$(echo -e "${BLUE}Press Enter to continue...${NC}")"
        return 1
    fi

    echo -e "${YELLOW}Checking and installing prerequisites...${NC}"

    # Perform package manager update first
    echo -e "${YELLOW}Updating package lists...${NC}"
    $UPDATE_CMD
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Package manager update failed. Please check your internet connection or repository configuration.${NC}"
        read -p "$(echo -e "${BLUE}Press Enter to continue...${NC}")"
        return 1
    fi

    # Install Python 3, git, wireguard-tools, net-tools
    # Check if python3 is installed
    if ! command -v python3 &> /dev/null; then
        echo -e "${YELLOW}Python 3 is not installed. Attempting to install the latest available version...${NC}"
        if [ "$PACKAGE_MANAGER" == "apt" ]; then
            $INSTALL_CMD python3 python3-venv python3-dev
            if [[ $? -ne 0 ]]; then
                echo -e "${RED}Python 3 installation failed. Please install it manually, then run the script again.${NC}"
                read -p "$(echo -e "${BLUE}Press Enter to continue...${NC}")"
                return 1
            fi
        elif [ "$PACKAGE_MANAGER" == "yum" ]; then
            $INSTALL_CMD python3 python3-devel
            if [[ $? -ne 0 ]]; then
                echo -e "${RED}Python 3 installation failed. Please install it manually, then run the script again.${NC}"
                read -p "$(echo -e "${BLUE}Press Enter to continue...${NC}")"
                return 1
            fi
        fi
    else
        PYTHON_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
        echo -e "${GREEN}Python ${PYTHON_VERSION} is already installed.${NC}"
    fi

    # Install other prerequisites
    $INSTALL_CMD git wireguard-tools net-tools
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Prerequisite installation failed. Please check for issues.${NC}"
        read -p "$(echo -e "${BLUE}Press Enter to continue...${NC}")"
        return 1
    fi

    echo -e "${GREEN}Prerequisites installed successfully.${NC}"

    # Clone WGDashboard repository
    echo -e "${YELLOW}Cloning WGDashboard repository...${NC}"
    # Assuming WGDashboard will be cloned in the current script directory
    if [ -d "WGDashboard" ]; then
        echo -e "${YELLOW}WGDashboard directory already exists. Removing it for a cleaner install...${NC}"
        sudo rm -rf WGDashboard
    fi
    git clone https://github.com/donaldzou/WGDashboard.git
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Cloning WGDashboard repository failed.${NC}"
        read -p "$(echo -e "${BLUE}Press Enter to continue...${NC}")"
        return 1
    fi

    # Enter the src directory
    WGDASHBOARD_BASE_DIR=$(pwd) # Directory from which the script was executed
    WGDASHBOARD_SRC_DIR="$WGDASHBOARD_BASE_DIR/WGDashboard/src"
    
    if [ ! -d "$WGDASHBOARD_SRC_DIR" ]; then
        echo -e "${RED}Directory ${WGDASHBOARD_SRC_DIR} not found. Check if the repository was cloned correctly.${NC}"
        read -p "$(echo -e "${BLUE}Press Enter to continue...${NC}")"
        return 1
    fi

    cd "$WGDASHBOARD_SRC_DIR"
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Failed to change directory to ${WGDASHBOARD_SRC_DIR}.${NC}"
        read -p "$(echo -e "${BLUE}Press Enter to continue...${NC}")"
        return 1
    fi

    echo -e "${YELLOW}Installing WGDashboard using wgd.sh...${NC}"
    sudo chmod u+x wgd.sh && sudo ./wgd.sh install
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}WGDashboard installation failed.${NC}"
        read -p "$(echo -e "${BLUE}Press Enter to continue...${NC}")"
        cd "$WGDASHBOARD_BASE_DIR" # Return to base directory
        return 1
    fi

    echo -e "${YELLOW}Setting permissions for /etc/wireguard...${NC}"
    sudo chmod -R 755 /etc/wireguard
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Setting permissions failed.${NC}"
        read -p "$(echo -e "${BLUE}Press Enter to continue...${NC}")"
        cd "$WGDASHBOARD_BASE_DIR" # Return to base directory
        return 1
    fi

    echo -e "${YELLOW}Starting WGDashboard...${NC}"
    sudo ./wgd.sh start
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Starting WGDashboard failed.${NC}"
        read -p "$(echo -e "${BLUE}Press Enter to continue...${NC}")"
        cd "$WGDASHBOARD_BASE_DIR" # Return to base directory
        return 1
    fi

    echo -e "${YELLOW}Enabling IP Forwarding for IPv4...${NC}"
    # Remove net.ipv6.ip_forward=1 if it exists in sysctl.conf to prevent errors on IPv4-only systems
    if grep -q "net.ipv6.ip_forward=1" /etc/sysctl.conf; then
        echo -e "${YELLOW}Removing 'net.ipv6.ip_forward=1' from /etc/sysctl.conf...${NC}"
        sudo sed -i '/net.ipv6.ip_forward=1/d' /etc/sysctl.conf
    fi

    if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf; then
        sudo sh -c 'echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf'
    fi
    
    sudo sysctl -p /etc/sysctl.conf
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Enabling IP Forwarding failed. Please check sysctl configuration.${NC}"
        read -p "$(echo -e "${BLUE}Press Enter to continue...${NC}")"
        cd "$WGDASHBOARD_BASE_DIR" # Return to base directory
        return 1
    fi

    echo -e "${YELLOW}Creating systemd service for WGDashboard...${NC}"
    # Create the service file in the current directory before copying
    TEMP_SERVICE_FILE="wg-dashboard.service"
    
    # systemd service file content (as per your provided instructions)
    cat <<EOF | tee "$TEMP_SERVICE_FILE"
[Unit]
Description=WGDashboard Service
After=syslog.target network-online.target
Wants=wg-quick.target
ConditionPathIsDirectory=/etc/wireguard

[Service]
Type=forking
PIDFile=$WGDASHBOARD_SRC_DIR/gunicorn.pid
WorkingDirectory=$WGDASHBOARD_SRC_DIR
ExecStart=$WGDASHBOARD_SRC_DIR/wgd.sh start
ExecStop=$WGDASHBOARD_SRC_DIR/wgd.sh stop
ExecReload=$WGDASHBOARD_SRC_DIR/wgd.sh restart
TimeoutSec=120
PrivateTmp=yes
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Creating systemd service file failed.${NC}"
        read -p "$(echo -e "${BLUE}Press Enter to continue...${NC}")"
        cd "$WGDASHBOARD_BASE_DIR" # Return to base directory
        return 1
    fi

    echo -e "${YELLOW}Copying service file to systemd directory...${NC}"
    sudo cp "$TEMP_SERVICE_FILE" /etc/systemd/system/wg-dashboard.service
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Copying service file failed.${NC}"
        read -p "$(echo -e "${BLUE}Press Enter to continue...${NC}")"
        cd "$WGDASHBOARD_BASE_DIR" # Return to base directory
        return 1
    fi

    echo -e "${YELLOW}Setting permissions for the service file...${NC}"
    sudo chmod 664 /etc/systemd/system/wg-dashboard.service
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Failed to set permissions for the service file.${NC}"
        read -p "$(echo -e "${BLUE}Press Enter to continue...${NC}")"
        cd "$WGDASHBOARD_BASE_DIR" # Return to base directory
        return 1
    fi

    echo -e "${YELLOW}Reloading systemd daemon, enabling and starting service...${NC}"
    sudo systemctl daemon-reload
    sudo systemctl enable wg-dashboard.service
    sudo systemctl start wg-dashboard.service

    # Get the server's IPv4 address
    SERVER_IP=$(hostname -I | awk '{print $1}')

    if sudo systemctl is-active --quiet wg-dashboard.service; then
        echo -e "${GREEN}WGDashboard has been successfully installed and its service is active.${NC}"
        echo -e "${GREEN}You can connect to WGDashboard with the following details:${NC}"
        echo -e "${GREEN}  IPv4 Server: ${NC}${CYAN}${SERVER_IP}:10086${NC}" # Display actual IP with CYAN color
        echo -e "${GREEN}  Username : ${NC}${WHITE}admin${NC}"
        echo -e "${GREEN}  Password : ${NC}${WHITE}admin${NC}"
        echo -e "${GREEN}You can check the service status with 'sudo systemctl status wg-dashboard.service'.${NC}"
    else
        echo -e "${RED}WGDashboard was installed, but its service failed to activate. Please check status with 'sudo systemctl status wg-dashboard.service' for more details.${NC}"
    fi
    echo -e "${GREEN}WGDashboard installation completed.${NC}"
    cd "$WGDASHBOARD_BASE_DIR" # Return to base directory
    read -p "$(echo -e "${BLUE}Press Enter to continue...${NC}")"
}

# Function to uninstall WGDashboard
uninstall_wgdashboard() {
    echo -e "${YELLOW}Starting WGDashboard uninstallation...${NC}"

    # Check for root access
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}This script must be run with root privileges. Please use sudo.${NC}"
        exit 1
    fi

    echo -e "${YELLOW}Stopping and disabling wg-dashboard service...${NC}"
    sudo systemctl stop wg-dashboard.service &> /dev/null
    sudo systemctl disable wg-dashboard.service &> /dev/null

    echo -e "${YELLOW}Removing wg-dashboard.service file...${NC}"
    sudo rm -f /etc/systemd/system/wg-dashboard.service
    sudo systemctl daemon-reload

    echo -e "${YELLOW}Removing WGDashboard directory...${NC}"
    # Assuming WGDashboard was cloned in the directory from which the script was executed
    if [ -d "WGDashboard" ]; then # The main WGDashboard directory name
        sudo rm -rf WGDashboard
        echo -e "${GREEN}WGDashboard directory removed.${NC}"
    else
        echo -e "${YELLOW}WGDashboard directory not found. It might have been removed already.${NC}"
    fi

    echo -e "${GREEN}WGDashboard uninstallation completed.${NC}"
    read -p "$(echo -e "${BLUE}Press Enter to continue...${NC}")"
}

# Main script logic
while true; do
    display_menu
    case $choice in
        1)
            install_wgdashboard
            ;;
        2) # New case for WGDashboard Management
            manage_wgdashboard
            ;;
        3)
            uninstall_wgdashboard
            ;;
        4)
            echo -e "${PURPLE}Exiting script. Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please enter a number between 1 and 4.${NC}"
            read -p "$(echo -e "${BLUE}Press Enter to continue...${NC}")"
            ;;
    esac
done
