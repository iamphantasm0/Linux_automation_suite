#!/bin/bash
# backup.sh - Script for backing up important system files and directories

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration variables
BACKUP_DIR="/backup"
BACKUP_NAME="system_backup_$(hostname)_$(date +%Y%m%d_%H%M%S)"
BACKUP_DIRS=("/etc" "/home" "/var/www" "/var/log")
EXCLUDE_PATTERNS=("*.tmp" "*.log" "cache" "tmp" "*.swp" "node_modules")
MAX_BACKUPS=7  # Keep only the last 7 backups
LOG_FILE="/var/log/backup.log"

# Check if script is run as root
function check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}${BOLD}Error: This script must be run as root${NC}" | tee -a "$LOG_FILE"
        exit 1
    fi
}

# Create backup directory if it doesn't exist
function create_backup_dir() {
    if [ ! -d "$BACKUP_DIR" ]; then
        echo -e "${YELLOW}Creating backup directory: $BACKUP_DIR${NC}" | tee -a "$LOG_FILE"
        mkdir -p "$BACKUP_DIR"
        if [ $? -ne 0 ]; then
            echo -e "${RED}${BOLD}Error: Failed to create backup directory $BACKUP_DIR${NC}" | tee -a "$LOG_FILE"
            exit 1
        fi
    fi
}

# Print header
function print_header() {
    clear
    echo -e "${BOLD}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║                 SYSTEM BACKUP UTILITY                  ║${NC}"
    echo -e "${BOLD}╚════════════════════════════════════════════════════════╝${NC}"
    echo -e "${BLUE}Running on:${NC} $(hostname)"
    echo -e "${BLUE}Date:${NC} $(date)"
    echo -e "${BLUE}Log file:${NC} $LOG_FILE"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Build exclude parameters for tar
function build_exclude_params() {
    EXCLUDE_PARAMS=""
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        EXCLUDE_PARAMS="$EXCLUDE_PARAMS --exclude='$pattern'"
    done
    echo "$EXCLUDE_PARAMS"
}

# Show progress bar
function show_progress() {
    local pid=$1
    local spin='-\|/'
    local i=0
    
    echo -ne "${YELLOW}Backup in progress...  ${NC}"
    
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) % 4 ))
        echo -ne "\r${YELLOW}Backup in progress...  ${spin:$i:1}${NC}"
        sleep 0.2
    done
    
    echo -e "\r${GREEN}Backup completed!       ${NC}"
}

# Create the backup
function create_backup() {
    EXCLUDE_PARAMS=$(build_exclude_params)
    BACKUP_FILE="$BACKUP_DIR/$BACKUP_NAME.tar.gz"
    
    echo -e "${BOLD}STARTING BACKUP PROCESS${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "$LOG_FILE"
    echo -e "${YELLOW}Time started:${NC} $(date)" | tee -a "$LOG_FILE"
    echo -e "${YELLOW}Backing up:${NC} ${BACKUP_DIRS[*]}" | tee -a "$LOG_FILE"
    echo -e "${YELLOW}Backup file:${NC} $BACKUP_FILE" | tee -a "$LOG_FILE"
    echo -e "${YELLOW}Excluding:${NC} ${EXCLUDE_PATTERNS[*]}" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    
    # Create backup command
    BACKUP_CMD="tar -czf $BACKUP_FILE $EXCLUDE_PARAMS ${BACKUP_DIRS[*]}"
    
    # Execute the backup command in background
    eval $BACKUP_CMD > /dev/null 2>&1 &
    backup_pid=$!
    
    # Show progress while backup is running
    show_progress $backup_pid
    
    # Wait for backup to complete
    wait $backup_pid
    backup_exit_code=$?
    
    if [ $backup_exit_code -eq 0 ]; then
        echo -e "${GREEN}${BOLD}✓ Backup completed successfully!${NC}" | tee -a "$LOG_FILE"
        echo -e "${BLUE}Time completed:${NC} $(date)" | tee -a "$LOG_FILE"
        echo -e "${BLUE}Backup file size:${NC} $(du -h $BACKUP_FILE | cut -f1)" | tee -a "$LOG_FILE"
    else
        echo -e "${RED}${BOLD}✗ Error: Backup failed!${NC}" | tee -a "$LOG_FILE"
        exit 1
    fi
}

# Rotate old backups
function rotate_backups() {
    echo -e "\n${BOLD}CHECKING OLD BACKUPS${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "$LOG_FILE"
    
    # Count existing backups
    BACKUP_COUNT=$(ls -1 $BACKUP_DIR/system_backup_*.tar.gz 2>/dev/null | wc -l)
    
    if [ $BACKUP_COUNT -gt $MAX_BACKUPS ]; then
        # Calculate how many backups to delete
        DELETE_COUNT=$((BACKUP_COUNT - MAX_BACKUPS))
        
        echo -e "${YELLOW}Found $BACKUP_COUNT backups, keeping $MAX_BACKUPS, deleting $DELETE_COUNT${NC}" | tee -a "$LOG_FILE"
        
        # Delete oldest backups
        ls -1t $BACKUP_DIR/system_backup_*.tar.gz | tail -n $DELETE_COUNT | while read file; do
            echo -e "${RED}Deleting old backup: $file${NC}" | tee -a "$LOG_FILE"
            rm "$file"
        done
    else
        echo -e "${GREEN}No backups need to be rotated (current count: $BACKUP_COUNT, max: $MAX_BACKUPS)${NC}" | tee -a "$LOG_FILE"
    fi
}

# Check backup integrity
function check_integrity() {
    echo -e "\n${BOLD}VERIFYING BACKUP INTEGRITY${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "$LOG_FILE"
    
    # Check if the backup file exists
    if [ ! -f "$BACKUP_FILE" ]; then
        echo -e "${RED}${BOLD}Error: Backup file not found: $BACKUP_FILE${NC}" | tee -a "$LOG_FILE"
        return 1
    fi
    
    echo -e "${YELLOW}Testing archive integrity...${NC}" | tee -a "$LOG_FILE"
    
    # Test the tar archive
    tar -tzf "$BACKUP_FILE" > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}${BOLD}✓ Backup integrity check passed${NC}" | tee -a "$LOG_FILE"
    else
        echo -e "${RED}${BOLD}✗ Error: Backup integrity check failed${NC}" | tee -a "$LOG_FILE"
        return 1
    fi
}

# Display usage information
function show_help() {
    print_header
    echo -e "${BOLD}BACKUP SCRIPT USAGE${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Usage:${NC} $0 [OPTIONS]"
    echo -e "${BLUE}Description:${NC} Backup important system files and directories"
    echo ""
    echo -e "${YELLOW}${BOLD}Options:${NC}"
    echo -e "  ${GREEN}-d, --directory DIR${NC}       Specify backup destination directory"
    echo -e "  ${RED}-r, --rotate${NC}              Rotate old backups only (don't create new backup)"
    echo -e "  ${GREEN}-k, --keep NUM${NC}            Keep specified number of backups (default: $MAX_BACKUPS)"
    echo -e "  ${BLUE}-l, --list${NC}                List available backups"
    echo -e "  ${BLUE}-h, --help${NC}                Display this help message"
    echo ""
    echo -e "${YELLOW}${BOLD}Examples:${NC}"
    echo -e "  ${GREEN}$0${NC}                        Create backup with default settings"
    echo -e "  ${GREEN}$0 -d /mnt/external${NC}       Create backup in specified directory"
    echo -e "  ${GREEN}$0 -k 10${NC}                  Keep last 10 backups"
    echo -e "  ${GREEN}$0 -r${NC}                     Rotate old backups without creating new one"
}

# List available backups
function list_backups() {
    print_header
    echo -e "${BOLD}AVAILABLE BACKUPS${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if [ ! -d "$BACKUP_DIR" ]; then
        echo -e "${YELLOW}Backup directory does not exist: $BACKUP_DIR${NC}"
        return
    fi
    
    # Check if there are any backups
    BACKUP_COUNT=$(ls -1 $BACKUP_DIR/system_backup_*.tar.gz 2>/dev/null | wc -l)
    
    if [ $BACKUP_COUNT -eq 0 ]; then
        echo -e "${YELLOW}No backups found in $BACKUP_DIR${NC}"
        return
    fi
    
    echo -e "${BOLD}Found $BACKUP_COUNT backups in $BACKUP_DIR:${NC}"
    echo ""
    
    # Print table header
    printf "${BOLD}%-40s %-10s %-20s${NC}\n" "BACKUP NAME" "SIZE" "DATE"
    echo -e "${YELLOW}────────────────────────────────────────────────────────────────────────${NC}"
    
    # List backups with size and date
    ls -lt $BACKUP_DIR/system_backup_*.tar.gz | while read permissions links owner group size month day time file; do
        filename=$(basename "$file")
        printf "%-40s %-10s %-20s\n" "$filename" "$size" "$month $day $time"
    done
}

# Main script logic
if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    show_help
    exit 0
fi

# Process command line options
ROTATE_ONLY=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d|--directory)
            BACKUP_DIR="$2"
            shift 2
            ;;
        -r|--rotate)
            ROTATE_ONLY=true
            shift
            ;;
        -k|--keep)
            MAX_BACKUPS="$2"
            shift 2
            ;;
        -l|--list)
            list_backups
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Main execution
check_root
print_header
create_backup_dir

if [ "$ROTATE_ONLY" = false ]; then
    create_backup
    check_integrity
fi

rotate_backups

echo -e "\n${GREEN}${BOLD}Backup process completed!${NC}" | tee -a "$LOG_FILE"
echo -e "${BLUE}Log file:${NC} $LOG_FILE\n" | tee -a "$LOG_FILE"