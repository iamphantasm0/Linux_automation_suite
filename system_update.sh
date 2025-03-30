#!/bin/bash
# system_update.sh - Enhanced script to update the system based on distribution

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Progress bar function
function show_progress() {
    local duration=$1
    local steps=20
    local sleep_time=$(echo "scale=3; $duration/$steps" | bc)
    
    echo -ne "${YELLOW}["
    for ((i=0; i<steps; i++)); do
        echo -ne "▓"
        sleep $sleep_time
    done
    echo -e "]${NC} Done!"
}

function print_header() {
    clear
    echo -e "${BOLD}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║               SYSTEM UPDATE UTILITY                    ║${NC}"
    echo -e "${BOLD}╚════════════════════════════════════════════════════════╝${NC}"
    echo -e "${BLUE}Running on:${NC} $(hostname)"
    echo -e "${BLUE}Date:${NC} $(date)"
    echo -e "${BLUE}User:${NC} $(whoami)"
    echo
}

function detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        DISTRO_VERSION=$VERSION_ID
        DISTRO_NAME=$PRETTY_NAME
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        DISTRO=$DISTRIB_ID
    elif [ -f /etc/debian_version ]; then
        DISTRO="debian"
    elif [ -f /etc/redhat-release ]; then
        DISTRO="redhat"
    else
        DISTRO="unknown"
    fi
    echo $DISTRO
}

function check_disk_space() {
    echo -e "${YELLOW}${BOLD}Checking available disk space...${NC}"
    
    local root_space=$(df -h / | awk 'NR==2 {print $4}')
    local root_percent=$(df -h / | awk 'NR==2 {print $5}')
    
    echo -e "${BLUE}Available space on root (/) partition:${NC} $root_space ($root_percent used)"
    
    if [[ ${root_percent%?} -gt 90 ]]; then
        echo -e "${RED}${BOLD}WARNING:${NC} Your disk is almost full! This may cause issues during update."
        echo -e "${YELLOW}Consider freeing up some space before continuing.${NC}"
        read -p "Continue anyway? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${RED}Update canceled by user.${NC}"
            exit 1
        fi
    fi
    echo
}

function update_system() {
    DISTRO=$(detect_distro)
    print_header
    
    echo -e "${BOLD}SYSTEM UPDATE${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Detected distribution:${NC} ${BOLD}$DISTRO_NAME${NC}"
    echo
    
    check_disk_space
    
    case "$DISTRO" in
        "ubuntu"|"debian")
            echo -e "${YELLOW}${BOLD}[1/4]${NC} Updating package lists..."
            sudo apt update
            
            echo -e "\n${YELLOW}${BOLD}[2/4]${NC} Upgrading packages..."
            sudo apt upgrade -y
            
            echo -e "\n${YELLOW}${BOLD}[3/4]${NC} Performing distribution upgrade..."
            sudo apt dist-upgrade -y
            
            echo -e "\n${YELLOW}${BOLD}[4/4]${NC} Cleaning up unused packages..."
            sudo apt autoremove -y
            sudo apt clean
            ;;
            
        "fedora"|"rhel"|"centos"|"redhat")
            echo -e "${YELLOW}${BOLD}[1/2]${NC} Updating packages..."
            sudo dnf update -y
            
            echo -e "\n${YELLOW}${BOLD}[2/2]${NC} Cleaning up..."
            sudo dnf autoremove -y
            ;;
            
        "arch"|"manjaro")
            echo -e "${YELLOW}${BOLD}[1/2]${NC} Updating packages..."
            sudo pacman -Syu --noconfirm
            
            echo -e "\n${YELLOW}${BOLD}[2/2]${NC} Cleaning package cache..."
            sudo pacman -Sc --noconfirm
            ;;
            
        "opensuse"|"suse")
            echo -e "${YELLOW}${BOLD}[1/2]${NC} Updating packages..."
            sudo zypper update -y
            
            echo -e "\n${YELLOW}${BOLD}[2/2]${NC} Cleaning up..."
            sudo zypper clean
            ;;
            
        *)
            echo -e "${RED}${BOLD}Error:${NC} Unsupported distribution: $DISTRO"
            exit 1
            ;;
    esac
    
    echo
    echo -e "${GREEN}${BOLD}System update completed successfully!${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Show system info after update
    echo -e "\n${BOLD}SYSTEM INFORMATION AFTER UPDATE${NC}"
    echo -e "${BLUE}Kernel:${NC} $(uname -r)"
    echo -e "${BLUE}Last boot:${NC} $(uptime -s)"
    echo -e "${BLUE}Uptime:${NC} $(uptime -p)"
}

# Execute the update function
update_system