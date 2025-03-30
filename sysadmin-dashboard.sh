#!/bin/bash
# sysadmin-dashboard.sh - Interactive dashboard for system administration tasks

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check if running as root
function check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}${BOLD}This script must be run as root or with sudo privileges${NC}"
        echo -e "Please run: ${YELLOW}sudo $0${NC}"
        exit 1
    fi
}

# Clear screen and display header
function show_header() {
    clear
    echo -e "${BOLD}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║              LINUX SYSTEM ADMIN DASHBOARD              ║${NC}"
    echo -e "${BOLD}╚════════════════════════════════════════════════════════╝${NC}"
    echo -e "${BLUE}System:${NC} $(uname -srmo)"
    echo -e "${BLUE}Hostname:${NC} $(hostname)"
    echo -e "${BLUE}Uptime:${NC} $(uptime -p)"
    echo -e "${BLUE}Current User:${NC} $(whoami)"
    echo -e "${BLUE}Date/Time:${NC} $(date)"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Show quick system stats
function show_quick_stats() {
    echo -e "${BOLD}SYSTEM QUICK STATS${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # CPU Usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
    echo -e "${BOLD}CPU Usage:${NC} ${cpu_usage}%"
    
    # Memory Usage
    mem_info=$(free -m | grep Mem)
    mem_total=$(echo $mem_info | awk '{print $2}')
    mem_used=$(echo $mem_info | awk '{print $3}')
    mem_usage=$((mem_used * 100 / mem_total))
    echo -e "${BOLD}Memory Usage:${NC} ${mem_usage}% (${mem_used}MB / ${mem_total}MB)"
    
    # Disk Usage
    disk_usage=$(df -h / | awk 'NR==2 {print $5}')
    echo -e "${BOLD}Disk Usage:${NC} ${disk_usage}"
    
    # Load Average
    load_avg=$(uptime | awk -F'load average:' '{print $2}' | xargs)
    echo -e "${BOLD}Load Average:${NC} ${load_avg}"
    
    # Active Users
    user_count=$(who | wc -l)
    echo -e "${BOLD}Active Users:${NC} ${user_count}"
    
    echo ""
}

# Display main menu
function show_menu() {
    echo -e "${BOLD}MAIN MENU${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}1.${NC} System Updates"
    echo -e "${GREEN}2.${NC} User Management"
    echo -e "${GREEN}3.${NC} Security Audit"
    echo -e "${GREEN}4.${NC} Backup System"
    echo -e "${GREEN}5.${NC} System Monitoring"
    echo -e "${GREEN}6.${NC} View System Logs"
    echo -e "${RED}0.${NC} Exit"
    echo ""
    echo -e "${YELLOW}Enter your choice [0-6]:${NC} "
}

# System Updates
function system_updates() {
    bash "${SCRIPT_DIR}/system_update.sh"
    echo -e "\n${YELLOW}Press Enter to return to the main menu...${NC}"
    read
}

# User Management submenu
function user_management() {
    while true; do
        show_header
        
        echo -e "${BOLD}USER MANAGEMENT MENU${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}1.${NC} List All Users"
        echo -e "${GREEN}2.${NC} Add New User"
        echo -e "${GREEN}3.${NC} Delete User"
        echo -e "${GREEN}4.${NC} Reset User Password"
        echo -e "${GREEN}5.${NC} Lock User Account"
        echo -e "${GREEN}6.${NC} Unlock User Account"
        echo -e "${GREEN}7.${NC} Add New Group"
        echo -e "${GREEN}8.${NC} Add User to Group"
        echo -e "${RED}9.${NC} Return to Main Menu"
        echo ""
        echo -e "${YELLOW}Enter your choice [1-9]:${NC} "
        
        read -r choice
        
        case $choice in
            1) 
                bash "${SCRIPT_DIR}/user_management.sh" --list
                echo -e "\n${YELLOW}Press Enter to continue...${NC}"
                read
                ;;
            2)
                echo -e "\n${YELLOW}Enter username to add:${NC} "
                read -r username
                bash "${SCRIPT_DIR}/user_management.sh" --add "$username"
                echo -e "\n${YELLOW}Press Enter to continue...${NC}"
                read
                ;;
            3)
                echo -e "\n${YELLOW}Enter username to delete:${NC} "
                read -r username
                bash "${SCRIPT_DIR}/user_management.sh" --delete "$username"
                echo -e "\n${YELLOW}Press Enter to continue...${NC}"
                read
                ;;
            4)
                echo -e "\n${YELLOW}Enter username to reset password:${NC} "
                read -r username
                bash "${SCRIPT_DIR}/user_management.sh" --reset-password "$username"
                echo -e "\n${YELLOW}Press Enter to continue...${NC}"
                read
                ;;
            5)
                echo -e "\n${YELLOW}Enter username to lock:${NC} "
                read -r username
                bash "${SCRIPT_DIR}/user_management.sh" --lock "$username"
                echo -e "\n${YELLOW}Press Enter to continue...${NC}"
                read
                ;;
            6)
                echo -e "\n${YELLOW}Enter username to unlock:${NC} "
                read -r username
                bash "${SCRIPT_DIR}/user_management.sh" --unlock "$username"
                echo -e "\n${YELLOW}Press Enter to continue...${NC}"
                read
                ;;
            7)
                echo -e "\n${YELLOW}Enter new group name:${NC} "
                read -r groupname
                bash "${SCRIPT_DIR}/user_management.sh" --add-group "$groupname"
                echo -e "\n${YELLOW}Press Enter to continue...${NC}"
                read
                ;;
            8)
                echo -e "\n${YELLOW}Enter username:${NC} "
                read -r username
                echo -e "${YELLOW}Enter group name:${NC} "
                read -r groupname
                bash "${SCRIPT_DIR}/user_management.sh" --add-to-group "$username" "$groupname"
                echo -e "\n${YELLOW}Press Enter to continue...${NC}"
                read
                ;;
            9)
                return
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                sleep 2
                ;;
        esac
    done
}

# Security Audit
function security_audit() {
    bash "${SCRIPT_DIR}/security_audit.sh"
    echo -e "\n${YELLOW}Press Enter to return to the main menu...${NC}"
    read
}

# Backup System
function backup_system() {
    bash "${SCRIPT_DIR}/backup.sh"
    echo -e "\n${YELLOW}Press Enter to return to the main menu...${NC}"
    read
}

# System Monitoring
function system_monitoring() {
    show_header
    echo -e "${BOLD}REAL-TIME SYSTEM MONITORING${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Press Ctrl+C to return to the main menu${NC}"
    echo ""
    
    # Run htop if available, otherwise use top
    if command -v htop &> /dev/null; then
        htop
    else
        top
    fi
}

# View System Logs
function view_logs() {
    while true; do
        show_header
        
        echo -e "${BOLD}SYSTEM LOGS VIEWER${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}1.${NC} Authentication Log (auth.log)"
        echo -e "${GREEN}2.${NC} System Log (syslog)"
        echo -e "${GREEN}3.${NC} Kernel Log (dmesg)"
        echo -e "${GREEN}4.${NC} Boot Log (boot.log)"
        echo -e "${GREEN}5.${NC} Application Logs"
        echo -e "${RED}9.${NC} Return to Main Menu"
        echo ""
        echo -e "${YELLOW}Enter your choice [1-9]:${NC} "
        
        read -r choice
        
        case $choice in
            1)
                if [ -f "/var/log/auth.log" ]; then
                    less "/var/log/auth.log"
                else
                    less "/var/log/secure"
                fi
                ;;
            2)
                less "/var/log/syslog" 2>/dev/null || less "/var/log/messages"
                ;;
            3)
                dmesg | less
                ;;
            4)
                less "/var/log/boot.log" 2>/dev/null
                ;;
            5)
                show_header
                echo -e "${YELLOW}Enter log file path:${NC} "
                read -r logfile
                if [ -f "$logfile" ]; then
                    less "$logfile"
                else
                    echo -e "${RED}Log file not found: $logfile${NC}"
                    sleep 2
                fi
                ;;
            9)
                return
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                sleep 2
                ;;
        esac
    done
}

# Main function
function main() {
    # Check if running as root
    check_root
    
    while true; do
        show_header
        show_quick_stats
        show_menu
        
        read -r choice
        
        case $choice in
            1) system_updates ;;
            2) user_management ;;
            3) security_audit ;;
            4) backup_system ;;
            5) system_monitoring ;;
            6) view_logs ;;
            0) 
                echo -e "${GREEN}Thank you for using the System Administration Dashboard!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                sleep 2
                ;;
        esac
    done
}

# Run the main function
main