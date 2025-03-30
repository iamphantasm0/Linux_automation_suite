#!/bin/bash
# user_management.sh - Script for managing users and groups

# Colors for better output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Display usage information
function show_help() {
    echo -e "${BOLD}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║               LINUX USER MANAGEMENT TOOL               ║${NC}"
    echo -e "${BOLD}╚════════════════════════════════════════════════════════╝${NC}"
    echo -e "${BLUE}Usage:${NC} $0 [OPTIONS]"
    echo -e "${BLUE}Description:${NC} Streamlined user and group management for Linux systems"
    echo ""
    echo -e "${YELLOW}${BOLD}Options:${NC}"
    echo -e "  ${GREEN}-a, --add${NC} USERNAME       Add a new user"
    echo -e "  ${RED}-d, --delete${NC} USERNAME    Delete a user"
    echo -e "  ${BLUE}-l, --list${NC}               List all users"
    echo -e "  ${GREEN}-g, --add-group${NC} NAME     Add a new group"
    echo -e "  ${GREEN}-m, --add-to-group${NC} USER GROUP  Add user to group"
    echo -e "  ${YELLOW}-p, --reset-password${NC} USER  Reset user password"
    echo -e "  ${RED}-s, --lock${NC} USERNAME      Lock a user account"
    echo -e "  ${GREEN}-u, --unlock${NC} USERNAME    Unlock a user account"
    echo -e "  ${BLUE}-h, --help${NC}               Display this help message"
    echo ""
    echo -e "${YELLOW}${BOLD}Examples:${NC}"
    echo -e "  ${GREEN}$0 --add jsmith${NC}          Create a new user 'jsmith'"
    echo -e "  ${RED}$0 --delete jsmith${NC}       Delete user 'jsmith'"
    echo -e "  ${GREEN}$0 --add-to-group jsmith developers${NC}  Add 'jsmith' to 'developers' group"
}

# Function to add a new user
function add_user() {
    local username=$1
    echo -e "\n${BOLD}┌─ Adding New User ─┐${NC}"
    
    # Check if user already exists
    if id "$username" &>/dev/null; then
        echo -e "${RED}✘ Error: User '$username' already exists${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}⟳ Creating user account for '$username'...${NC}"
    
    # Create the user with home directory and bash shell
    if sudo useradd -m -s /bin/bash "$username"; then
        echo -e "${GREEN}✓ User '$username' created successfully${NC}"
        
        # Set initial password
        echo -e "${YELLOW}⟳ Setting password for '$username'...${NC}"
        echo -e "${BLUE}Please enter a secure password when prompted${NC}"
        sudo passwd "$username"
        
        # Show new user details
        echo -e "\n${GREEN}✓ User account created:${NC}"
        echo -e "  ${BOLD}Username:${NC} $username"
        echo -e "  ${BOLD}UID:${NC} $(id -u "$username")"
        echo -e "  ${BOLD}Home:${NC} $(eval echo ~$username)"
        echo -e "  ${BOLD}Groups:${NC} $(groups "$username" | cut -d: -f2)"
    else
        echo -e "${RED}✘ Failed to create user '$username'${NC}"
        return 1
    fi
}

# Function to delete a user
function delete_user() {
    local username=$1
    if ! id "$username" &>/dev/null; then
        echo "Error: User '$username' does not exist"
        return 1
    fi
    
    read -p "Delete home directory for '$username'? (y/n): " delete_home
    if [[ "$delete_home" =~ ^[Yy]$ ]]; then
        sudo userdel -r "$username"
    else
        sudo userdel "$username"
    fi
    
    if [ $? -eq 0 ]; then
        echo "User '$username' deleted successfully"
    else
        echo "Error: Failed to delete user '$username'"
        return 1
    fi
}

# Function to list all users
function list_users() {
    echo -e "${BOLD}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║                    SYSTEM USERS LIST                   ║${NC}"
    echo -e "${BOLD}╚════════════════════════════════════════════════════════╝${NC}"
    
    # Print header
    printf "${BOLD}%-15s %-8s %-20s %-15s %s${NC}\n" "USERNAME" "UID" "HOME" "SHELL" "GROUPS"
    echo -e "${YELLOW}────────────────────────────────────────────────────────────────────────${NC}"
    
    # Get all real users
    cut -d: -f1,3,6,7 /etc/passwd | sort | while IFS=: read -r user uid home shell; do
        if [ "$uid" -ge 1000 ] && [ "$shell" != "/usr/sbin/nologin" ] && [ "$shell" != "/bin/false" ]; then
            groups=$(groups "$user" 2>/dev/null | cut -d: -f2)
            shell_name=$(basename "$shell")
            
            # Alternate row colors for better readability
            if (( uid % 2 == 0 )); then
                COLOR="${GREEN}"
            else
                COLOR="${BLUE}"
            fi
            
            printf "${COLOR}%-15s %-8s %-20s %-15s %s${NC}\n" "$user" "$uid" "$home" "$shell_name" "$groups"
        fi
    done
    
    echo -e "\n${YELLOW}Total users:${NC} $(cut -d: -f1,3 /etc/passwd | grep -c ":[0-9]\{4\}:")"
}

# Function to add a new group
function add_group() {
    local groupname=$1
    if grep -q "^$groupname:" /etc/group; then
        echo "Error: Group '$groupname' already exists"
        return 1
    fi
    
    sudo groupadd "$groupname"
    if [ $? -eq 0 ]; then
        echo "Group '$groupname' created successfully"
    else
        echo "Error: Failed to create group '$groupname'"
        return 1
    fi
}

# Function to add user to a group
function add_to_group() {
    local username=$1
    local groupname=$2
    
    if ! id "$username" &>/dev/null; then
        echo "Error: User '$username' does not exist"
        return 1
    fi
    
    if ! grep -q "^$groupname:" /etc/group; then
        echo "Error: Group '$groupname' does not exist"
        return 1
    fi
    
    sudo usermod -aG "$groupname" "$username"
    if [ $? -eq 0 ]; then
        echo "User '$username' added to group '$groupname' successfully"
    else
        echo "Error: Failed to add user '$username' to group '$groupname'"
        return 1
    fi
}

# Function to reset user password
function reset_password() {
    local username=$1
    
    if ! id "$username" &>/dev/null; then
        echo "Error: User '$username' does not exist"
        return 1
    fi
    
    sudo passwd "$username"
}

# Function to lock a user account
function lock_user() {
    local username=$1
    
    if ! id "$username" &>/dev/null; then
        echo "Error: User '$username' does not exist"
        return 1
    fi
    
    sudo passwd -l "$username"
    if [ $? -eq 0 ]; then
        echo "User account '$username' locked successfully"
    else
        echo "Error: Failed to lock user account '$username'"
        return 1
    fi
}

# Function to unlock a user account
function unlock_user() {
    local username=$1
    
    if ! id "$username" &>/dev/null; then
        echo "Error: User '$username' does not exist"
        return 1
    fi
    
    sudo passwd -u "$username"
    if [ $? -eq 0 ]; then
        echo "User account '$username' unlocked successfully"
    else
        echo "Error: Failed to unlock user account '$username'"
        return 1
    fi
}

# Main script logic
echo "Script is running..."
echo "Number of arguments: $#"
echo "Arguments: $@"

if [ $# -eq 0 ]; then
    echo "No arguments provided, showing help..."
    show_help
    exit 0
fi

case "$1" in
    -a|--add)
        [ -z "$2" ] && { echo "Error: Username required"; exit 1; }
        add_user "$2"
        ;;
    -d|--delete)
        [ -z "$2" ] && { echo "Error: Username required"; exit 1; }
        delete_user "$2"
        ;;
    -l|--list)
        list_users
        ;;
    -g|--add-group)
        [ -z "$2" ] && { echo "Error: Group name required"; exit 1; }
        add_group "$2"
        ;;
    -m|--add-to-group)
        [ -z "$2" ] && { echo "Error: Username required"; exit 1; }
        [ -z "$3" ] && { echo "Error: Group name required"; exit 1; }
        add_to_group "$2" "$3"
        ;;
    -p|--reset-password)
        [ -z "$2" ] && { echo "Error: Username required"; exit 1; }
        reset_password "$2"
        ;;
    -s|--lock)
        [ -z "$2" ] && { echo "Error: Username required"; exit 1; }
        lock_user "$2"
        ;;
    -u|--unlock)
        [ -z "$2" ] && { echo "Error: Username required"; exit 1; }
        unlock_user "$2"
        ;;
    -h|--help)
        show_help
        ;;
    *)
        echo "Error: Unknown option '$1'"
        show_help
        exit 1
        ;;
esac

exit 0