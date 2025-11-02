#!/bin/bash

# IPTables Firewall Configuration Script
# This script sets up iptables rules to allow only specified ports

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}✗${NC} This script must be run as root"
    echo "Please run: sudo $0"
    exit 1
fi

echo -e "${GREEN}=== IPTables Firewall Configuration ===${NC}"
echo ""

# Default ports to allow (modify as needed)
# Format: PORT/PROTOCOL (tcp or udp)
DEFAULT_PORTS=(
    "22/tcp"      # SSH
    "80/tcp"      # HTTP
    "443/tcp"     # HTTPS
    "9100/tcp"    # Node Exporter (Prometheus)
)

# Parse command line arguments for custom ports
CUSTOM_PORTS=()
RESET_RULES=false
DRY_RUN=false
SAVE_RULES=true

while [[ $# -gt 0 ]]; do
    case $1 in
        --ports|-p)
            IFS=',' read -ra CUSTOM_PORTS <<< "$2"
            shift 2
            ;;
        --reset)
            RESET_RULES=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --no-save)
            SAVE_RULES=false
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -p, --ports PORTS    Comma-separated list of ports to open (format: PORT/PROTOCOL)"
            echo "                       Example: --ports 22/tcp,80/tcp,443/tcp,9100/tcp"
            echo "  --reset              Reset all rules to default (accept all)"
            echo "  --dry-run            Show what would be done without applying"
            echo "  --no-save            Don't save rules (temporary until reboot)"
            echo "  -h, --help           Show this help message"
            echo ""
            echo "Default ports (if --ports not specified):"
            for port in "${DEFAULT_PORTS[@]}"; do
                echo "  - $port"
            done
            echo ""
            echo "Examples:"
            echo "  sudo $0                                    # Use default ports"
            echo "  sudo $0 --ports 22/tcp,80/tcp,443/tcp     # Custom ports"
            echo "  sudo $0 --reset                            # Reset all rules"
            echo ""
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Use custom ports if provided, otherwise use defaults
if [ ${#CUSTOM_PORTS[@]} -gt 0 ]; then
    PORTS=("${CUSTOM_PORTS[@]}")
else
    PORTS=("${DEFAULT_PORTS[@]}")
fi

# Function to reset iptables to accept all
reset_iptables() {
    echo -e "${YELLOW}→${NC} Resetting iptables to accept all traffic..."
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT
    iptables -F
    iptables -X
    echo -e "${GREEN}✓${NC} IPTables reset to default (accept all)"
}

# Function to apply iptables rules
apply_iptables_rules() {
    echo -e "${BLUE}→${NC} Configuring iptables rules..."
    echo -e "${RED}→${NC} Blocking ALL ports except specified..."
    echo ""
    
    # Flush existing rules
    iptables -F
    iptables -X
    iptables -Z
    
    # Set default policies to DROP (BLOCK EVERYTHING)
    echo -e "${YELLOW}→${NC} Setting default policy: DROP (block all)"
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT ACCEPT
    
    # Allow loopback interface (required for local processes)
    echo -e "${YELLOW}→${NC} Allowing loopback interface (localhost)"
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT
    
    # Allow established and related connections (replies to outgoing connections)
    echo -e "${YELLOW}→${NC} Allowing established connections"
    iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    
    # Allow specified ports ONLY
    echo ""
    echo -e "${GREEN}Opening ONLY these ports (all others BLOCKED):${NC}"
    for port_spec in "${PORTS[@]}"; do
        IFS='/' read -r port protocol <<< "$port_spec"
        echo -e "  ${GREEN}✓${NC} $port/$protocol - OPEN"
        iptables -A INPUT -p "$protocol" --dport "$port" -j ACCEPT
    done
    
    # Log dropped packets (optional, for debugging)
    # iptables -A INPUT -j LOG --log-prefix "IPTables-Dropped: " --log-level 4
    
    echo ""
    echo -e "${RED}✗${NC} All other ports: BLOCKED"
    echo -e "${GREEN}✓${NC} Firewall rules applied - ONLY specified ports are accessible"
}

# Function to display current rules
show_rules() {
    echo ""
    echo -e "${BLUE}=== Current IPTables Rules ===${NC}"
    echo ""
    iptables -L -n -v --line-numbers
    echo ""
}

# Function to save iptables rules
save_iptables_rules() {
    echo ""
    echo -e "${YELLOW}→${NC} Saving iptables rules..."
    
    # Detect the system and save accordingly
    if command -v netfilter-persistent &> /dev/null; then
        # Debian/Ubuntu with netfilter-persistent
        netfilter-persistent save
        echo -e "${GREEN}✓${NC} Rules saved with netfilter-persistent"
    elif command -v iptables-save &> /dev/null && [ -d /etc/iptables ]; then
        # Manual save to /etc/iptables/rules.v4
        mkdir -p /etc/iptables
        iptables-save > /etc/iptables/rules.v4
        echo -e "${GREEN}✓${NC} Rules saved to /etc/iptables/rules.v4"
    elif command -v service &> /dev/null && service iptables status &> /dev/null; then
        # RHEL/CentOS with iptables service
        service iptables save
        echo -e "${GREEN}✓${NC} Rules saved with iptables service"
    elif command -v iptables-save &> /dev/null; then
        # Fallback - save to a custom location
        mkdir -p /etc/iptables
        iptables-save > /etc/iptables/rules.v4
        echo -e "${GREEN}✓${NC} Rules saved to /etc/iptables/rules.v4"
        echo -e "${YELLOW}!${NC} You may need to configure your system to restore these rules on boot"
    else
        echo -e "${YELLOW}!${NC} Could not determine how to save rules on this system"
        echo -e "${YELLOW}!${NC} Rules will be lost on reboot"
    fi
}

# Function to setup persistent rules
setup_persistence() {
    echo ""
    echo -e "${YELLOW}→${NC} Setting up persistence..."
    
    # Check if netfilter-persistent is installed
    if ! command -v netfilter-persistent &> /dev/null; then
        echo -e "${YELLOW}!${NC} netfilter-persistent not found"
        
        # Try to install on Debian/Ubuntu
        if command -v apt-get &> /dev/null; then
            echo -e "${YELLOW}→${NC} Installing iptables-persistent..."
            DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent
            echo -e "${GREEN}✓${NC} iptables-persistent installed"
        fi
    fi
    
    # Enable service if available
    if command -v systemctl &> /dev/null; then
        if systemctl list-unit-files | grep -q netfilter-persistent; then
            systemctl enable netfilter-persistent
            echo -e "${GREEN}✓${NC} netfilter-persistent service enabled"
        fi
    fi
}

# Main execution
if [ "$DRY_RUN" = true ]; then
    echo -e "${BLUE}DRY RUN MODE - No changes will be made${NC}"
    echo ""
    echo "Would configure the following ports:"
    for port in "${PORTS[@]}"; do
        echo "  - $port"
    done
    exit 0
fi

if [ "$RESET_RULES" = true ]; then
    reset_iptables
    if [ "$SAVE_RULES" = true ]; then
        save_iptables_rules
    fi
    show_rules
    exit 0
fi

# Backup current rules
echo -e "${YELLOW}→${NC} Backing up current rules to /tmp/iptables.backup..."
iptables-save > /tmp/iptables.backup
echo -e "${GREEN}✓${NC} Backup saved"
echo ""

# Apply the rules
apply_iptables_rules

# Show the rules
show_rules

# Save the rules if requested
if [ "$SAVE_RULES" = true ]; then
    setup_persistence
    save_iptables_rules
    echo ""
    echo -e "${GREEN}✓✓✓ Firewall configured and rules saved! ✓✓✓${NC}"
else
    echo ""
    echo -e "${YELLOW}!${NC} Rules applied but NOT saved (will be lost on reboot)"
    echo -e "${YELLOW}!${NC} Run without --no-save to make changes persistent"
fi

echo ""
echo -e "${BLUE}Useful commands:${NC}"
echo "  View rules:    iptables -L -n -v"
echo "  Restore backup: iptables-restore < /tmp/iptables.backup"
echo "  Reset all:     $0 --reset"
echo ""
echo -e "${YELLOW}WARNING:${NC} If you locked yourself out, connect via console and run:"
echo "  sudo $0 --reset"
echo ""

