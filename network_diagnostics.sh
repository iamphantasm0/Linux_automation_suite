#!/bin/bash
# network_diagnostics.sh - Network diagnostic and security scanning tool

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Log file
LOG_DIR="/var/log/network_diagnostics"
LOG_FILE="$LOG_DIR/network_scan_$(date +%Y%m%d_%H%M%S).log"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR" 2>/dev/null

# Check if script is run as root
function check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}${BOLD}This script must be run as root or with sudo privileges${NC}"
        echo -e "Please run: ${YELLOW}sudo $0${NC}"
        exit 1
    fi
}

# Print header
function print_header() {
    clear
    echo -e "${BOLD}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║              NETWORK DIAGNOSTIC UTILITY                ║${NC}"
    echo -e "${BOLD}╚════════════════════════════════════════════════════════╝${NC}"
    echo -e "${BLUE}Date:${NC} $(date)"
    echo -e "${BLUE}Log file:${NC} $LOG_FILE"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Check for required tools and install if missing
function check_requirements() {
    echo -e "${BOLD}Checking for required tools...${NC}" | tee -a "$LOG_FILE"
    
    # Array of required tools
    REQUIRED_TOOLS=("ping" "dig" "nmap" "traceroute" "whois" "curl" "host" "netstat" "ss")
    MISSING_TOOLS=()
    
    for tool in "${REQUIRED_TOOLS[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            MISSING_TOOLS+=("$tool")
        fi
    done
    
    # Install missing tools
    if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
        echo -e "${YELLOW}The following tools are missing and will be installed:${NC}" | tee -a "$LOG_FILE"
        for tool in "${MISSING_TOOLS[@]}"; do
            echo "  - $tool" | tee -a "$LOG_FILE"
        done
        
        echo -e "${YELLOW}Installing missing tools...${NC}" | tee -a "$LOG_FILE"
        
        if command -v apt &>/dev/null; then
            # Debian/Ubuntu
            apt update -qq
            apt install -y dnsutils iputils-ping nmap traceroute whois curl net-tools iproute2
        elif command -v dnf &>/dev/null; then
            # Fedora/RHEL
            dnf install -y bind-utils iputils nmap traceroute whois curl net-tools iproute
        elif command -v pacman &>/dev/null; then
            # Arch Linux
            pacman -S --noconfirm bind-tools iputils nmap traceroute whois curl net-tools iproute2
        else
            echo -e "${RED}${BOLD}Unable to install missing tools automatically.${NC}" | tee -a "$LOG_FILE"
            echo -e "${RED}Please install the following manually: ${MISSING_TOOLS[*]}${NC}" | tee -a "$LOG_FILE"
            exit 1
        fi
        
        echo -e "${GREEN}All required tools have been installed.${NC}" | tee -a "$LOG_FILE"
    else
        echo -e "${GREEN}All required tools are already installed.${NC}" | tee -a "$LOG_FILE"
    fi
    echo ""
}

# Get network interfaces
function get_network_interfaces() {
    echo -e "${BOLD}NETWORK INTERFACES${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "$LOG_FILE"
    
    echo -e "${BOLD}Available network interfaces:${NC}" | tee -a "$LOG_FILE"
    
    # Format and display interfaces with their details
    ip -br -c addr show | while read -r line; do
        if [[ $line == *"UP"* ]]; then
            interface=$(echo $line | awk '{print $1}')
            status=$(echo $line | awk '{print $2}')
            ip_addr=$(echo $line | awk '{print $3}')
            
            # Get MAC address
            mac=$(ip link show $interface | grep -oP 'link/ether \K[^ ]+')
            
            echo -e "${GREEN}✓ $interface${NC} ($status)" | tee -a "$LOG_FILE"
            echo -e "   IP Address: $ip_addr" | tee -a "$LOG_FILE"
            echo -e "   MAC Address: $mac" | tee -a "$LOG_FILE"
            
            # Get interface statistics
            rx_bytes=$(cat /sys/class/net/$interface/statistics/rx_bytes 2>/dev/null || echo "N/A")
            tx_bytes=$(cat /sys/class/net/$interface/statistics/tx_bytes 2>/dev/null || echo "N/A")
            
            if [ "$rx_bytes" != "N/A" ] && [ "$tx_bytes" != "N/A" ]; then
                rx_mb=$(echo "scale=2; $rx_bytes/1048576" | bc)
                tx_mb=$(echo "scale=2; $tx_bytes/1048576" | bc)
                echo -e "   Received: ${rx_mb} MB, Transmitted: ${tx_mb} MB" | tee -a "$LOG_FILE"
            fi
            
            echo "" | tee -a "$LOG_FILE"
        fi
    done
    
    # Show routing table
    echo -e "${BOLD}Routing Table:${NC}" | tee -a "$LOG_FILE"
    ip route | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
}

# Test internet connectivity
function test_connectivity() {
    echo -e "${BOLD}INTERNET CONNECTIVITY TEST${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "$LOG_FILE"
    
    # Define test targets
    targets=("8.8.8.8" "1.1.1.1" "amazon.com" "google.com" "cloudflare.com")
    
    for target in "${targets[@]}"; do
        echo -e "${YELLOW}Testing connectivity to ${BOLD}$target${NC}..." | tee -a "$LOG_FILE"
        
        # Ping test (3 packets)
        ping_result=$(ping -c 3 -W 2 "$target" 2>&1)
        ping_status=$?
        
        if [ $ping_status -eq 0 ]; then
            avg_time=$(echo "$ping_result" | tail -1 | awk -F '/' '{print $5}')
            packet_loss=$(echo "$ping_result" | grep -oP '\d+(?=% packet loss)')
            
            echo -e "  ${GREEN}✓ Ping successful${NC}" | tee -a "$LOG_FILE"
            echo -e "    Average latency: ${avg_time} ms" | tee -a "$LOG_FILE"
            echo -e "    Packet loss: ${packet_loss}%" | tee -a "$LOG_FILE"
        else
            echo -e "  ${RED}✗ Ping failed${NC}" | tee -a "$LOG_FILE"
        fi
        
        echo "" | tee -a "$LOG_FILE"
    done
    
    # Check default gateway
    gateway=$(ip route | grep default | awk '{print $3}')
    
    if [ -n "$gateway" ]; then
        echo -e "${BOLD}Testing connection to default gateway (${gateway}):${NC}" | tee -a "$LOG_FILE"
        ping_result=$(ping -c 3 -W 2 "$gateway" 2>&1)
        ping_status=$?
        
        if [ $ping_status -eq 0 ]; then
            avg_time=$(echo "$ping_result" | tail -1 | awk -F '/' '{print $5}')
            echo -e "  ${GREEN}✓ Gateway is responding${NC}" | tee -a "$LOG_FILE"
            echo -e "    Average latency: ${avg_time} ms" | tee -a "$LOG_FILE"
        else
            echo -e "  ${RED}✗ Gateway is not responding${NC}" | tee -a "$LOG_FILE"
        fi
    else
        echo -e "${RED}No default gateway found${NC}" | tee -a "$LOG_FILE"
    fi
    
    echo "" | tee -a "$LOG_FILE"
}

# DNS resolution test
function test_dns() {
    echo -e "${BOLD}DNS RESOLUTION TEST${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "$LOG_FILE"
    
    # Check resolv.conf
    echo -e "${BOLD}DNS Configuration:${NC}" | tee -a "$LOG_FILE"
    if [ -f /etc/resolv.conf ]; then
        nameservers=$(grep "^nameserver" /etc/resolv.conf | awk '{print $2}')
        search_domains=$(grep "^search" /etc/resolv.conf | awk '{$1=""; print $0}' | xargs)
        
        if [ -n "$nameservers" ]; then
            echo -e "DNS Servers:" | tee -a "$LOG_FILE"
            for ns in $nameservers; do
                echo -e "  - $ns" | tee -a "$LOG_FILE"
            done
        else
            echo -e "${RED}No DNS servers found in /etc/resolv.conf${NC}" | tee -a "$LOG_FILE"
        fi
        
        if [ -n "$search_domains" ]; then
            echo -e "Search Domains:" | tee -a "$LOG_FILE"
            echo -e "  $search_domains" | tee -a "$LOG_FILE"
        fi
    else
        echo -e "${RED}/etc/resolv.conf not found${NC}" | tee -a "$LOG_FILE"
    fi
    echo "" | tee -a "$LOG_FILE"
    
    # Test DNS resolution
    echo -e "${BOLD}DNS Resolution Tests:${NC}" | tee -a "$LOG_FILE"
    domains=("google.com" "amazon.com" "facebook.com" "github.com" "microsoft.com")
    
    printf "%-20s %-15s %-10s %-15s\n" "Domain" "Status" "Time(ms)" "IP Address" | tee -a "$LOG_FILE"
    echo -e "────────────────────────────────────────────────────────────" | tee -a "$LOG_FILE"
    
    for domain in "${domains[@]}"; do
        # Use dig to test resolution
        dig_result=$(dig +tries=1 +time=2 +stats "$domain" A +short)
        dig_status=$?
        dig_time=$(dig +tries=1 +time=2 +stats "$domain" A | grep "Query time:" | awk '{print $4}')
        
        if [ $dig_status -eq 0 ] && [ -n "$dig_result" ]; then
            ip_addr=$(echo "$dig_result" | head -1)
            printf "%-20s ${GREEN}%-15s${NC} %-10s %-15s\n" "$domain" "Resolved" "${dig_time:-N/A}" "${ip_addr:-N/A}" | tee -a "$LOG_FILE"
        else
            printf "%-20s ${RED}%-15s${NC} %-10s %-15s\n" "$domain" "Failed" "N/A" "N/A" | tee -a "$LOG_FILE"
        fi
    done
    
    echo "" | tee -a "$LOG_FILE"
    
    # Test reverse DNS lookup
    echo -e "${BOLD}Reverse DNS Lookup:${NC}" | tee -a "$LOG_FILE"
    ips=("8.8.8.8" "1.1.1.1" "208.67.222.222" "9.9.9.9")
    
    printf "%-15s %-20s %-10s\n" "IP Address" "Hostname" "Status" | tee -a "$LOG_FILE"
    echo -e "─────────────────────────────────────────────" | tee -a "$LOG_FILE"
    
    for ip in "${ips[@]}"; do
        # Use host for reverse lookup
        host_result=$(host "$ip" 2>&1)
        host_status=$?
        
        if [ $host_status -eq 0 ]; then
            hostname=$(echo "$host_result" | awk '{print $NF}' | sed 's/\.$//')
            printf "%-15s %-20s ${GREEN}%-10s${NC}\n" "$ip" "${hostname:-N/A}" "Resolved" | tee -a "$LOG_FILE"
        else
            printf "%-15s %-20s ${RED}%-10s${NC}\n" "$ip" "N/A" "Failed" | tee -a "$LOG_FILE"
        fi
    done
    
    echo "" | tee -a "$LOG_FILE"
}

# Network latency test
function test_latency() {
    echo -e "${BOLD}NETWORK LATENCY TEST${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "$LOG_FILE"
    
    # Define test targets with geographical regions
    declare -A targets=(
        ["North America"]="google.com"
        ["Europe"]="bbc.co.uk"
        ["Asia"]="baidu.com"
        ["Oceania"]="abc.net.au"
        ["South America"]="globo.com"
    )
    
    echo -e "${YELLOW}Running latency tests to global servers...${NC}" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    
    printf "%-15s %-25s %-10s %-10s %-10s %-10s\n" "Region" "Server" "Min(ms)" "Avg(ms)" "Max(ms)" "Loss(%)" | tee -a "$LOG_FILE"
    echo -e "──────────────────────────────────────────────────────────────────────" | tee -a "$LOG_FILE"
    
    for region in "${!targets[@]}"; do
        target="${targets[$region]}"
        
        # Ping the target (5 packets)
        ping_result=$(ping -c 5 -W 3 "$target" 2>&1)
        ping_status=$?
        
        if [ $ping_status -eq 0 ]; then
            min=$(echo "$ping_result" | tail -1 | awk -F '/' '{print $4}')
            avg=$(echo "$ping_result" | tail -1 | awk -F '/' '{print $5}')
            max=$(echo "$ping_result" | tail -1 | awk -F '/' '{print $6}')
            loss=$(echo "$ping_result" | grep -oP '\d+(?=% packet loss)')
            
            # Color code based on latency
            if (( $(echo "$avg < 50" | bc -l) )); then
                avg_color="${GREEN}$avg${NC}"
            elif (( $(echo "$avg < 100" | bc -l) )); then
                avg_color="${YELLOW}$avg${NC}"
            else
                avg_color="${RED}$avg${NC}"
            fi
            
            printf "%-15s %-25s %-10s %-10s %-10s %-10s\n" "$region" "$target" "$min" "$avg_color" "$max" "$loss" | tee -a "$LOG_FILE"
        else
            printf "%-15s %-25s ${RED}%-10s %-10s %-10s %-10s${NC}\n" "$region" "$target" "Failed" "Failed" "Failed" "100" | tee -a "$LOG_FILE"
        fi
    done
    
    echo "" | tee -a "$LOG_FILE"
    
    # Run traceroute to a major server
    echo -e "${BOLD}Traceroute to google.com:${NC}" | tee -a "$LOG_FILE"
    echo -e "${YELLOW}Analyzing network path...${NC}" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    
    traceroute -n -w 2 -q 1 -m 15 google.com | tee -a "$LOG_FILE"
    
    echo "" | tee -a "$LOG_FILE"
}

# Open ports scan
function scan_open_ports() {
    echo -e "${BOLD}OPEN PORTS SCAN${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "$LOG_FILE"
    
    echo -e "${YELLOW}Scanning for open ports on local system...${NC}" | tee -a "$LOG_FILE"
    
    # Check if netstat or ss is available
    if command -v ss &>/dev/null; then
        echo -e "${BOLD}Listening TCP ports:${NC}" | tee -a "$LOG_FILE"
        ss -tuln | grep "LISTEN" | sort -n -k 4 | tee -a "$LOG_FILE"
    elif command -v netstat &>/dev/null; then
        echo -e "${BOLD}Listening TCP ports:${NC}" | tee -a "$LOG_FILE"
        netstat -tuln | grep "LISTEN" | tee -a "$LOG_FILE"
    else
        echo -e "${RED}Neither ss nor netstat is available${NC}" | tee -a "$LOG_FILE"
    fi
    
    # Run nmap scan on localhost
    echo "" | tee -a "$LOG_FILE"
    echo -e "${BOLD}Detailed port scan (localhost):${NC}" | tee -a "$LOG_FILE"
    
    nmap -sT -p 1-1000 localhost | tee -a "$LOG_FILE"
    
    echo "" | tee -a "$LOG_FILE"
}

# Security scan
function security_scan() {
    echo -e "${BOLD}NETWORK SECURITY SCAN${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "$LOG_FILE"
    
    # Get local network range
    local_ip=$(ip -o -4 addr show | grep -v "127.0.0.1" | awk '{print $4}' | head -1)
    network_range=$(echo $local_ip | sed 's/\.[0-9]*\/.*/.0\/24/')
    
    echo -e "${YELLOW}Running security scan on network: $network_range${NC}" | tee -a "$LOG_FILE"
    echo -e "${RED}Note: This scan is for diagnostic purposes only and should be used only on networks you own or have permission to scan.${NC}" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    
    # Confirm before proceeding
    read -p "Do you want to proceed with the network scan? (y/n): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "${YELLOW}Network scan aborted by user.${NC}" | tee -a "$LOG_FILE"
        return
    fi
    
    # First, check firewall status
    echo -e "${BOLD}Firewall Status:${NC}" | tee -a "$LOG_FILE"
    
    if command -v ufw &>/dev/null; then
        echo -e "UFW Status:" | tee -a "$LOG_FILE"
        ufw status | tee -a "$LOG_FILE"
    elif command -v firewalld &>/dev/null; then
        echo -e "Firewalld Status:" | tee -a "$LOG_FILE"
        firewall-cmd --state | tee -a "$LOG_FILE"
        echo -e "Active Zones:" | tee -a "$LOG_FILE"
        firewall-cmd --list-all | tee -a "$LOG_FILE"
    elif command -v iptables &>/dev/null; then
        echo -e "IPTables Rules:" | tee -a "$LOG_FILE"
        iptables -L -n | tee -a "$LOG_FILE"
    else
        echo -e "${RED}No firewall detected${NC}" | tee -a "$LOG_FILE"
    fi
    
    echo "" | tee -a "$LOG_FILE"
    
    # Quick scan of the network
    echo -e "${BOLD}Network Host Discovery:${NC}" | tee -a "$LOG_FILE"
    echo -e "${YELLOW}Scanning for active hosts on $network_range...${NC}" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    
    nmap -sn "$network_range" | tee -a "$LOG_FILE"
    
    echo "" | tee -a "$LOG_FILE"
    
    # Check for common vulnerabilities on the local machine
    echo -e "${BOLD}Local Security Check:${NC}" | tee -a "$LOG_FILE"
    
    # Check SSH configuration
    if [ -f /etc/ssh/sshd_config ]; then
        echo -e "${BOLD}SSH Security Configuration:${NC}" | tee -a "$LOG_FILE"
        
        root_login=$(grep "^PermitRootLogin" /etc/ssh/sshd_config | awk '{print $2}')
        password_auth=$(grep "^PasswordAuthentication" /etc/ssh/sshd_config | awk '{print $2}')
        
        if [ "$root_login" == "yes" ]; then
            echo -e "${RED}✗ Root login is allowed${NC}" | tee -a "$LOG_FILE"
        else
            echo -e "${GREEN}✓ Root login is disabled${NC}" | tee -a "$LOG_FILE"
        fi
        
        if [ "$password_auth" == "yes" ]; then
            echo -e "${YELLOW}⚠ Password authentication is enabled${NC}" | tee -a "$LOG_FILE"
        else
            echo -e "${GREEN}✓ Password authentication is disabled (key-based only)${NC}" | tee -a "$LOG_FILE"
        fi
    fi
    
    # Check for weak file permissions
    echo -e "\n${BOLD}File Permission Security:${NC}" | tee -a "$LOG_FILE"
    
    echo -e "${YELLOW}Checking for world-writable files in /etc...${NC}" | tee -a "$LOG_FILE"
    world_writable=$(find /etc -type f -perm -002 -not -path "*/\.*" 2>/dev/null | head -10)
    
    if [ -n "$world_writable" ]; then
        echo -e "${RED}✗ Found world-writable files in /etc (showing first 10):${NC}" | tee -a "$LOG_FILE"
        echo "$world_writable" | tee -a "$LOG_FILE"
    else
        echo -e "${GREEN}✓ No world-writable files found in /etc${NC}" | tee -a "$LOG_FILE"
    fi
    
    echo "" | tee -a "$LOG_FILE"
    
    # Generate security recommendations
    echo -e "${BOLD}Security Recommendations:${NC}" | tee -a "$LOG_FILE"
    
    # Check if any ports below 1024 are open
    low_ports=$(ss -tuln | grep "LISTEN" | grep -E ':[0-9]{1,3} ' | sort -n -k 4)
    
    if [ -n "$low_ports" ]; then
        echo -e "${YELLOW}⚠ You have services running on privileged ports (below 1024). Consider:${NC}" | tee -a "$LOG_FILE"
        echo -e "  - Ensuring these services are necessary" | tee -a "$LOG_FILE"
        echo -e "  - Configuring firewall rules to restrict access" | tee -a "$LOG_FILE"
    fi
    
    # Check for SSH on default port
    ssh_port=$(ss -tuln | grep "LISTEN" | grep ":22 ")
    
    if [ -n "$ssh_port" ]; then
        echo -e "${YELLOW}⚠ SSH is running on the default port (22). Consider:${NC}" | tee -a "$LOG_FILE"
        echo -e "  - Changing to a non-standard port" | tee -a "$LOG_FILE"
        echo -e "  - Implementing fail2ban to prevent brute force attacks" | tee -a "$LOG_FILE"
        echo -e "  - Using key-based authentication only" | tee -a "$LOG_FILE"
    fi
    
    echo -e "${GREEN}✓ General security recommendations:${NC}" | tee -a "$LOG_FILE"
    echo -e "  - Keep your system updated regularly" | tee -a "$LOG_FILE"
    echo -e "  - Use a firewall and configure it properly" | tee -a "$LOG_FILE"
    echo -e "  - Monitor system logs for suspicious activity" | tee -a "$LOG_FILE"
    echo -e "  - Use strong, unique passwords or key-based authentication" | tee -a "$LOG_FILE"
    echo -e "  - Limit access to administrative services to trusted IPs" | tee -a "$LOG_FILE"
    
    echo "" | tee -a "$LOG_FILE"
}

# Speed test
function speed_test() {
    echo -e "${BOLD}INTERNET SPEED TEST${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "$LOG_FILE"
    
    echo -e "${YELLOW}Testing download and upload speeds...${NC}" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    
    # Check if speedtest-cli is installed
    if ! command -v speedtest-cli &>/dev/null; then
        echo -e "${YELLOW}speedtest-cli is not installed. Installing...${NC}" | tee -a "$LOG_FILE"
        
        if command -v apt &>/dev/null; then
            apt update -qq
            apt install -y python3-pip
        elif command -v dnf &>/dev/null; then
            dnf install -y python3-pip
        elif command -v pacman &>/dev/null; then
            pacman -S --noconfirm python-pip
        fi
        
        pip3 install speedtest-cli
    fi
    
    # Run speed test
    if command -v speedtest-cli &>/dev/null; then
        # Get results from speedtest-cli
        output=$(speedtest-cli --simple)
        
        # Extract values and convert from Mbps to MB/s (divide by 8)
        ping=$(echo "$output" | grep "Ping" | awk '{print $2}')
        download_mbps=$(echo "$output" | grep "Download" | awk '{print $2}')
        upload_mbps=$(echo "$output" | grep "Upload" | awk '{print $2}')
        
        # Convert Mbps to MB/s (divide by 8)
        download_mbs=$(echo "scale=2; $download_mbps/8" | bc)
        upload_mbs=$(echo "scale=2; $upload_mbps/8" | bc)
        
        # Display results
        echo -e "Ping: ${ping} ms" | tee -a "$LOG_FILE"
        echo -e "Download: ${download_mbs} MB/s (${download_mbps} Mbps)" | tee -a "$LOG_FILE"
        echo -e "Upload: ${upload_mbs} MB/s (${upload_mbps} Mbps)" | tee -a "$LOG_FILE"
    else
        # Alternative speed test using curl if speedtest-cli fails
        echo -e "${YELLOW}Using alternative speed test method...${NC}" | tee -a "$LOG_FILE"
        
        # Download test
        echo -e "Download speed test:" | tee -a "$LOG_FILE"
        # Get bytes per second and convert to MB/s
        curl_result=$(curl -s -o /dev/null -w "%{speed_download}" https://speed.cloudflare.com/__down?bytes=100000000)
        megabytes_per_sec=$(echo "scale=2; $curl_result/1048576" | bc)
        echo -e "Speed: ${megabytes_per_sec} MB/s" | tee -a "$LOG_FILE"
    fi
    
    echo "" | tee -a "$LOG_FILE"
}

# Display main menu
function show_menu() {
    echo -e "${BOLD}NETWORK DIAGNOSTICS MENU${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}1.${NC} Run All Tests"
    echo -e "${GREEN}2.${NC} Network Interface Information"
    echo -e "${GREEN}3.${NC} Internet Connectivity Test"
    echo -e "${GREEN}4.${NC} DNS Resolution Test"
    echo -e "${GREEN}5.${NC} Network Latency Test"
    echo -e "${GREEN}6.${NC} Open Ports Scan"
    echo -e "${GREEN}7.${NC} Security Scan"
    echo -e "${GREEN}8.${NC} Internet Speed Test"
    echo -e "${RED}0.${NC} Exit"
    echo ""
    echo -e "${YELLOW}Enter your choice [0-8]:${NC} "
}

# Main function
function main() {
    check_root
    
    # Create a unique log file for this run
    mkdir -p "$LOG_DIR" 2>/dev/null
    LOG_FILE="$LOG_DIR/network_scan_$(date +%Y%m%d_%H%M%S).log"
    
    # Log basic system information at the start
    echo -e "NETWORK DIAGNOSTIC SCAN" | tee -a "$LOG_FILE"
    echo -e "==============================================" | tee -a "$LOG_FILE"
    echo -e "Date: $(date)" | tee -a "$LOG_FILE"
    echo -e "Hostname: $(hostname)" | tee -a "$LOG_FILE"
    echo -e "Kernel: $(uname -r)" | tee -a "$LOG_FILE"
    echo -e "==============================================" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    
    print_header
    check_requirements
    
    # If arguments are provided, run specific tests
    if [ $# -gt 0 ]; then
        for arg in "$@"; do
            case $arg in
                --all)
                    echo -e "${BOLD}RUNNING COMPLETE NETWORK DIAGNOSTIC SCAN${NC}" | tee -a "$LOG_FILE"
                    echo -e "${YELLOW}This will perform all tests and save results to: $LOG_FILE${NC}" | tee -a "$LOG_FILE"
                    echo "" | tee -a "$LOG_FILE"
                    
                    get_network_interfaces
                    test_connectivity
                    test_dns
                    test_latency
                    scan_open_ports
                    security_scan
                    speed_test
                    
                    # Summarize results at the end of the log
                    echo -e "\n${BOLD}SCAN SUMMARY${NC}" | tee -a "$LOG_FILE"
                    echo -e "==============================================" | tee -a "$LOG_FILE"
                    echo -e "Scan completed at: $(date)" | tee -a "$LOG_FILE"
                    echo -e "Log file: $LOG_FILE" | tee -a "$LOG_FILE"
                    echo -e "==============================================" | tee -a "$LOG_FILE"
                    
                    echo -e "\n${GREEN}${BOLD}Complete diagnostic scan finished.${NC}"
                    echo -e "${BLUE}Log file saved to:${NC} $LOG_FILE"
                    ;;
                --interfaces)
                    get_network_interfaces
                    ;;
                --connectivity)
                    test_connectivity
                    ;;
                --dns)
                    test_dns
                    ;;
                --latency)
                    test_latency
                    ;;
                --ports)
                    scan_open_ports
                    ;;
                --security)
                    security_scan
                    ;;
                --speed)
                    speed_test
                    ;;
                --help)
                    echo -e "Network Diagnostics Tool"
                    echo -e "Usage: $0 [OPTIONS]"
                    echo -e "\nOptions:"
                    echo -e "  --all         Run all diagnostic tests"
                    echo -e "  --interfaces  Show network interfaces"
                    echo -e "  --connectivity Test internet connectivity"
                    echo -e "  --dns         Test DNS resolution"
                    echo -e "  --latency     Test network latency"
                    echo -e "  --ports       Scan for open ports"
                    echo -e "  --security    Run security scan"
                    echo -e "  --speed       Run internet speed test"
                    echo -e "  --help        Display this help message"
                    exit 0
                    ;;
                *)
                    echo -e "${RED}Unknown option: $arg${NC}"
                    echo -e "Use --help to see available options"
                    exit 1
                    ;;
            esac
        done
        
        echo -e "\n${GREEN}${BOLD}Network diagnostics completed!${NC}"
        echo -e "${BLUE}Log file:${NC} $LOG_FILE"
        exit 0
    fi
    
    # Interactive menu
    while true; do
        print_header
        show_menu
        
        read -r choice
        
        # Create a new log file for each test run from the menu
        LOG_FILE="$LOG_DIR/network_scan_$(date +%Y%m%d_%H%M%S).log"
        
        # Log basic system information
        echo -e "NETWORK DIAGNOSTIC SCAN" | tee -a "$LOG_FILE"
        echo -e "==============================================" | tee -a "$LOG_FILE"
        echo -e "Date: $(date)" | tee -a "$LOG_FILE"
        echo -e "Hostname: $(hostname)" | tee -a "$LOG_FILE"
        echo -e "Kernel: $(uname -r)" | tee -a "$LOG_FILE"
        echo -e "==============================================" | tee -a "$LOG_FILE"
        echo "" | tee -a "$LOG_FILE"
        
        case $choice in
            1)
                print_header
                echo -e "${BOLD}RUNNING COMPLETE NETWORK DIAGNOSTIC SCAN${NC}" | tee -a "$LOG_FILE"
                echo -e "${YELLOW}This will perform all tests and save results to: $LOG_FILE${NC}" | tee -a "$LOG_FILE"
                echo "" | tee -a "$LOG_FILE"
                
                get_network_interfaces
                test_connectivity
                test_dns
                test_latency
                scan_open_ports
                security_scan
                speed_test
                
                # Summarize results at the end of the log
                echo -e "\n${BOLD}SCAN SUMMARY${NC}" | tee -a "$LOG_FILE"
                echo -e "==============================================" | tee -a "$LOG_FILE"
                echo -e "Scan completed at: $(date)" | tee -a "$LOG_FILE"
                echo -e "All tests completed successfully." | tee -a "$LOG_FILE"
                echo -e "Log file: $LOG_FILE" | tee -a "$LOG_FILE"
                echo -e "==============================================" | tee -a "$LOG_FILE"
                
                echo -e "\n${GREEN}${BOLD}All tests completed!${NC}"
                echo -e "${BLUE}Comprehensive log file saved to:${NC} $LOG_FILE"
                echo -e "\n${YELLOW}Press Enter to return to the main menu...${NC}"
                read
                ;;
            2)
                print_header
                get_network_interfaces
                echo -e "\n${YELLOW}Press Enter to return to the main menu...${NC}"
                read
                ;;
            3)
                print_header
                test_connectivity
                echo -e "\n${YELLOW}Press Enter to return to the main menu...${NC}"
                read
                ;;
            4)
                print_header
                test_dns
                echo -e "\n${YELLOW}Press Enter to return to the main menu...${NC}"
                read
                ;;
            5)
                print_header
                test_latency
                echo -e "\n${YELLOW}Press Enter to return to the main menu...${NC}"
                read
                ;;
            6)
                print_header
                scan_open_ports
                echo -e "\n${YELLOW}Press Enter to return to the main menu...${NC}"
                read
                ;;
            7)
                print_header
                security_scan
                echo -e "\n${YELLOW}Press Enter to return to the main menu...${NC}"
                read
                ;;
            8)
                print_header
                speed_test
                echo -e "\n${YELLOW}Press Enter to return to the main menu...${NC}"
                read
                ;;
            0)
                clear
                echo -e "${GREEN}${BOLD}Network diagnostics completed!${NC}"
                echo -e "${BLUE}Log files are saved in:${NC} $LOG_DIR"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                sleep 2
                ;;
        esac
    done
}

# Run the main function with any arguments
main "$@"