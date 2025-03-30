#!/bin/bash
# security_audit.sh - Script for performing security audits on Linux systems

output_file="security_audit_$(hostname)_$(date +%Y%m%d).txt"

function check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "This script must be run as root"
        exit 1
    fi
}

# Colors for better output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

function print_header() {
    echo -e "${BOLD}╔═════════════════════════════════════════════════════════════════════╗${NC}" | tee -a "$output_file"
    echo -e "${BOLD}║                     LINUX SECURITY AUDIT REPORT                     ║${NC}" | tee -a "$output_file"
    echo -e "${BOLD}╚═════════════════════════════════════════════════════════════════════╝${NC}" | tee -a "$output_file"
    echo -e "${BLUE}Generated on:${NC} $(date)" | tee -a "$output_file"
    echo -e "${BLUE}Hostname:${NC} $(hostname)" | tee -a "$output_file"
    echo -e "${BLUE}System:${NC} $(uname -a)" | tee -a "$output_file"
    echo -e "${BLUE}Report file:${NC} $output_file" | tee -a "$output_file"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "$output_file"
    echo "" | tee -a "$output_file"
}

function system_info() {
    echo -e "${BOLD}🖥️  SYSTEM INFORMATION${NC}" | tee -a "$output_file"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "$output_file"
    echo "Kernel Version:" | tee -a "$output_file"
    uname -a | tee -a "$output_file"
    echo "" | tee -a "$output_file"
    
    echo "OS Release:" | tee -a "$output_file"
    cat /etc/os-release | tee -a "$output_file"
    echo "" | tee -a "$output_file"
    
    echo "Uptime:" | tee -a "$output_file"
    uptime | tee -a "$output_file"
    echo "" | tee -a "$output_file"
}

function check_users() {
    echo "USER ACCOUNTS AUDIT" | tee -a "$output_file"
    echo "-------------------------------------------------------------------" | tee -a "$output_file"
    
    echo "Users with UID 0 (root access):" | tee -a "$output_file"
    grep 'x:0:' /etc/passwd | tee -a "$output_file"
    echo "" | tee -a "$output_file"
    
    echo "Users with login shell:" | tee -a "$output_file"
    grep -v '/nologin\|/false' /etc/passwd | tee -a "$output_file"
    echo "" | tee -a "$output_file"
    
    echo "User accounts with no password:" | tee -a "$output_file"
    cat /etc/shadow | awk -F: '($2==""){print $1}' | tee -a "$output_file"
    echo "" | tee -a "$output_file"
    
    echo "Last logins:" | tee -a "$output_file"
    last -n 20 | tee -a "$output_file"
    echo "" | tee -a "$output_file"
    
    echo "Currently logged-in users:" | tee -a "$output_file"
    who | tee -a "$output_file"
    echo "" | tee -a "$output_file"
}

function check_network() {
    echo "NETWORK CONFIGURATION AUDIT" | tee -a "$output_file"
    echo "-------------------------------------------------------------------" | tee -a "$output_file"
    
    echo "Network interfaces:" | tee -a "$output_file"
    ip addr | tee -a "$output_file"
    echo "" | tee -a "$output_file"
    
    echo "Open network connections:" | tee -a "$output_file"
    netstat -tuln | tee -a "$output_file"
    echo "" | tee -a "$output_file"
    
    echo "Active network connections:" | tee -a "$output_file"
    netstat -tan | tee -a "$output_file"
    echo "" | tee -a "$output_file"
    
    echo "Routing table:" | tee -a "$output_file"
    route -n | tee -a "$output_file"
    echo "" | tee -a "$output_file"
    
    echo "Firewall rules (iptables):" | tee -a "$output_file"
    iptables -L -n | tee -a "$output_file"
    echo "" | tee -a "$output_file"
}

function check_services() {
    echo "RUNNING SERVICES AUDIT" | tee -a "$output_file"
    echo "-------------------------------------------------------------------" | tee -a "$output_file"
    
    echo "Systemd services:" | tee -a "$output_file"
    systemctl list-units --type=service --state=running | tee -a "$output_file"
    echo "" | tee -a "$output_file"
    
    echo "All system services:" | tee -a "$output_file"
    systemctl list-unit-files --type=service | tee -a "$output_file"
    echo "" | tee -a "$output_file"
    
    echo "Enabled services at boot:" | tee -a "$output_file"
    systemctl list-unit-files --state=enabled | tee -a "$output_file"
    echo "" | tee -a "$output_file"
}

function check_filesystem() {
    echo "FILESYSTEM SECURITY AUDIT" | tee -a "$output_file"
    echo "-------------------------------------------------------------------" | tee -a "$output_file"
    
    echo "Disk usage:" | tee -a "$output_file"
    df -h | tee -a "$output_file"
    echo "" | tee -a "$output_file"
    
    echo "World-writable directories:" | tee -a "$output_file"
    find / -type d -perm -o+w -not -path "/proc/*" -not -path "/sys/*" 2>/dev/null | tee -a "$output_file"
    echo "" | tee -a "$output_file"
    
    echo "Files with SUID permission:" | tee -a "$output_file"
    find / -type f -perm -u+s -not -path "/proc/*" -not -path "/sys/*" 2>/dev/null | tee -a "$output_file"
    echo "" | tee -a "$output_file"
    
    echo "Files with SGID permission:" | tee -a "$output_file"
    find / -type f -perm -g+s -not -path "/proc/*" -not -path "/sys/*" 2>/dev/null | tee -a "$output_file"
    echo "" | tee -a "$output_file"
    
    echo "Checking for unauthorized SSH keys:" | tee -a "$output_file"
    find /home -name "authorized_keys" -o -name "id_rsa" -o -name "id_dsa" -o -name "identity" 2>/dev/null | tee -a "$output_file"
    echo "" | tee -a "$output_file"
}

function check_cron_jobs() {
    echo "CRON JOBS AUDIT" | tee -a "$output_file"
    echo "-------------------------------------------------------------------" | tee -a "$output_file"
    
    echo "System cron jobs:" | tee -a "$output_file"
    ls -la /etc/cron* | tee -a "$output_file"
    echo "" | tee -a "$output_file"
    
    echo "User cron jobs:" | tee -a "$output_file"
    for user in $(cut -f1 -d: /etc/passwd); do
      crontab -u $user -l 2>/dev/null | grep -v "^#" | grep -v "^$"
    done | tee -a "$output_file"
    echo "" | tee -a "$output_file"
}

function check_software() {
    echo "INSTALLED SOFTWARE AUDIT" | tee -a "$output_file"
    echo "-------------------------------------------------------------------" | tee -a "$output_file"
    
    if command -v apt &> /dev/null; then
        echo "Installed packages (Debian/Ubuntu):" | tee -a "$output_file"
        dpkg -l | tee -a "$output_file"
    elif command -v rpm &> /dev/null; then
        echo "Installed packages (RHEL/CentOS/Fedora):" | tee -a "$output_file"
        rpm -qa | sort | tee -a "$output_file"
    elif command -v pacman &> /dev/null; then
        echo "Installed packages (Arch):" | tee -a "$output_file"
        pacman -Q | tee -a "$output_file"
    else
        echo "Unknown package manager, skipping package list." | tee -a "$output_file"
    fi
    echo "" | tee -a "$output_file"
}

function check_logs() {
    echo "LOG FILES AUDIT" | tee -a "$output_file"
    echo "-------------------------------------------------------------------" | tee -a "$output_file"
    
    echo "Failed login attempts:" | tee -a "$output_file"
    grep "Failed password" /var/log/auth.log 2>/dev/null | tail -n 20 | tee -a "$output_file"
    grep "Failed password" /var/log/secure 2>/dev/null | tail -n 20 | tee -a "$output_file"
    echo "" | tee -a "$output_file"
    
    echo "SSH login attempts:" | tee -a "$output_file"
    grep "sshd" /var/log/auth.log 2>/dev/null | grep "Accepted" | tail -n 20 | tee -a "$output_file"
    grep "sshd" /var/log/secure 2>/dev/null | grep "Accepted" | tail -n 20 | tee -a "$output_file"
    echo "" | tee -a "$output_file"
    
    echo "Sudo usage:" | tee -a "$output_file"
    grep "sudo" /var/log/auth.log 2>/dev/null | tail -n 20 | tee -a "$output_file"
    grep "sudo" /var/log/secure 2>/dev/null | tail -n 20 | tee -a "$output_file"
    echo "" | tee -a "$output_file"
}

function check_security_configs() {
    echo "SECURITY CONFIGURATIONS AUDIT" | tee -a "$output_file"
    echo "-------------------------------------------------------------------" | tee -a "$output_file"
    
    echo "SSH configuration:" | tee -a "$output_file"
    grep -v "^#" /etc/ssh/sshd_config | grep -v "^$" | tee -a "$output_file"
    echo "" | tee -a "$output_file"
    
    echo "Password policy:" | tee -a "$output_file"
    grep -v "^#" /etc/login.defs | grep -v "^$" | tee -a "$output_file"
    echo "" | tee -a "$output_file"
    
    echo "PAM configuration:" | tee -a "$output_file"
    ls -la /etc/pam.d/ | tee -a "$output_file"
    echo "" | tee -a "$output_file"
    
    echo "Sudoers configuration:" | tee -a "$output_file"
    grep -v "^#" /etc/sudoers | grep -v "^$" | tee -a "$output_file"
    echo "" | tee -a "$output_file"
    
    echo "Checking for weak system passwords:" | tee -a "$output_file"
    echo "Note: This check requires root access to shadow file." | tee -a "$output_file"
    echo "Consider running a password strength audit separately." | tee -a "$output_file"
    echo "" | tee -a "$output_file"
}

function generate_recommendations() {
    echo -e "${BOLD}🔒 SECURITY RECOMMENDATIONS${NC}" | tee -a "$output_file"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "$output_file"
    
    # Critical security issues - RED
    echo -e "${RED}${BOLD}CRITICAL PRIORITY:${NC}" | tee -a "$output_file"
    echo -e "${RED}✓ Review all users with UID 0 (root privileges)${NC}" | tee -a "$output_file"
    echo -e "${RED}✓ Address any accounts with no password${NC}" | tee -a "$output_file"
    echo -e "${RED}✓ Fix world-writable directories${NC}" | tee -a "$output_file"
    echo -e "${RED}✓ Review SUID/SGID files for potential exploits${NC}" | tee -a "$output_file"
    echo "" | tee -a "$output_file"
    
    # High priority - YELLOW
    echo -e "${YELLOW}${BOLD}HIGH PRIORITY:${NC}" | tee -a "$output_file"
    echo -e "${YELLOW}✓ Configure and enable a firewall (iptables/ufw/firewalld)${NC}" | tee -a "$output_file"
    echo -e "${YELLOW}✓ Implement strong password policy in PAM configuration${NC}" | tee -a "$output_file"
    echo -e "${YELLOW}✓ Disable SSH password authentication (use key-based)${NC}" | tee -a "$output_file"
    echo -e "${YELLOW}✓ Close unnecessary open network ports${NC}" | tee -a "$output_file"
    echo -e "${YELLOW}✓ Set up automatic security updates${NC}" | tee -a "$output_file"
    echo "" | tee -a "$output_file"
    
    # Standard maintenance - GREEN
    echo -e "${GREEN}${BOLD}STANDARD MAINTENANCE:${NC}" | tee -a "$output_file"
    echo -e "${GREEN}✓ Remove or disable unused services${NC}" | tee -a "$output_file"
    echo -e "${GREEN}✓ Configure centralized system logging${NC}" | tee -a "$output_file"
    echo -e "${GREEN}✓ Set up monitoring for failed login attempts${NC}" | tee -a "$output_file"
    echo -e "${GREEN}✓ Review user sudo privileges regularly${NC}" | tee -a "$output_file"
    echo -e "${GREEN}✓ Implement regular security scans${NC}" | tee -a "$output_file"
    echo "" | tee -a "$output_file"
    
    # Additional recommendations
    echo -e "${BOLD}RECOMMENDED TOOLS:${NC}" | tee -a "$output_file"
    echo -e "• Lynis - Security auditing tool (https://cisofy.com/lynis/)" | tee -a "$output_file"
    echo -e "• Fail2ban - Intrusion prevention (https://www.fail2ban.org)" | tee -a "$output_file"
    echo -e "• ClamAV - Antivirus solution (https://www.clamav.net)" | tee -a "$output_file"
    echo -e "• Rootkit Hunter - Rootkit detector (http://rkhunter.sourceforge.net)" | tee -a "$output_file"
    echo "" | tee -a "$output_file"
}

# Main execution
check_root
print_header
system_info
check_users
check_network
check_services
check_filesystem
check_cron_jobs
check_software
check_logs
check_security_configs
generate_recommendations

echo "" | tee -a "$output_file"
echo "Security audit completed. Report saved to $output_file"
echo ""