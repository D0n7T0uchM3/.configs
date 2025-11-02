#!/bin/bash

# Node Exporter Quick Start Script
# This script will install (if needed) and start Prometheus Node Exporter
# Supports: systemd service installation, direct execution, and macOS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default configuration
NODE_EXPORTER_PORT="${NODE_EXPORTER_PORT:-9100}"
NODE_EXPORTER_VERSION="${NODE_EXPORTER_VERSION:-1.8.2}"
INSTALL_AS_SERVICE="${INSTALL_AS_SERVICE:-}"

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --service|--systemd)
            INSTALL_AS_SERVICE="yes"
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --service, --systemd    Install as systemd service (requires sudo)"
            echo "  --help, -h              Show this help message"
            echo ""
            echo "Environment variables:"
            echo "  NODE_EXPORTER_PORT      Port to listen on (default: 9100)"
            echo "  NODE_EXPORTER_VERSION   Version to install (default: 1.8.2)"
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

echo -e "${GREEN}=== Prometheus Node Exporter Quick Start ===${NC}"
echo ""

# Function to check if node_exporter is installed
check_node_exporter() {
    if command -v node_exporter &> /dev/null; then
        echo -e "${GREEN}✓${NC} Node Exporter is already installed"
        return 0
    elif [ -f "$HOME/.local/bin/node_exporter" ]; then
        echo -e "${GREEN}✓${NC} Node Exporter found in ~/.local/bin"
        export PATH="$HOME/.local/bin:$PATH"
        return 0
    else
        return 1
    fi
}

# Function to install node_exporter via Homebrew (macOS/Linux)
install_with_brew() {
    if command -v brew &> /dev/null; then
        echo -e "${YELLOW}→${NC} Installing Node Exporter via Homebrew..."
        brew install node_exporter
        return 0
    else
        return 1
    fi
}

# Function to download and install node_exporter manually
install_manual() {
    local INSTALL_DIR="$1"
    echo -e "${YELLOW}→${NC} Downloading Node Exporter v${NODE_EXPORTER_VERSION}..."
    
    # Detect OS and architecture
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    
    case $ARCH in
        x86_64)
            ARCH="amd64"
            ;;
        aarch64|arm64)
            ARCH="arm64"
            ;;
        armv7l)
            ARCH="armv7"
            ;;
        *)
            echo -e "${RED}✗${NC} Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac
    
    DOWNLOAD_URL="https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.${OS}-${ARCH}.tar.gz"
    
    echo -e "${YELLOW}→${NC} Downloading from: $DOWNLOAD_URL"
    
    # Create temporary directory
    TMP_DIR=$(mktemp -d)
    cd "$TMP_DIR"
    
    # Download and extract
    if ! curl -fLsS "$DOWNLOAD_URL" -o node_exporter.tar.gz; then
        echo -e "${RED}✗${NC} Failed to download Node Exporter"
        rm -rf "$TMP_DIR"
        exit 1
    fi
    
    tar xzf node_exporter.tar.gz
    
    # Install to specified directory
    mkdir -p "$INSTALL_DIR"
    cp "node_exporter-${NODE_EXPORTER_VERSION}.${OS}-${ARCH}/node_exporter" "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/node_exporter"
    
    # Cleanup
    cd -
    rm -rf "$TMP_DIR"
    
    if [ "$INSTALL_DIR" = "$HOME/.local/bin" ]; then
        export PATH="$HOME/.local/bin:$PATH"
    fi
    echo -e "${GREEN}✓${NC} Node Exporter installed to $INSTALL_DIR/node_exporter"
}

# Function to install as systemd service
install_systemd_service() {
    echo -e "${BLUE}=== Installing Node Exporter as systemd service ===${NC}"
    echo ""
    
    # Check if systemd is available
    if ! command -v systemctl &> /dev/null; then
        echo -e "${RED}✗${NC} systemd is not available on this system"
        echo "Try running without --service flag for direct execution"
        exit 1
    fi
    
    # Check if running with sudo
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}✗${NC} This operation requires sudo privileges"
        echo "Please run: sudo $0 --service"
        exit 1
    fi
    
    # Install node_exporter to /usr/local/bin if not present
    if [ ! -f "/usr/local/bin/node_exporter" ]; then
        echo -e "${YELLOW}→${NC} Installing Node Exporter to /usr/local/bin..."
        install_manual "/usr/local/bin"
    else
        echo -e "${GREEN}✓${NC} Node Exporter already exists at /usr/local/bin/node_exporter"
    fi
    
    # Create node_exporter user if doesn't exist
    if ! id -u node_exporter &> /dev/null; then
        echo -e "${YELLOW}→${NC} Creating node_exporter user..."
        useradd --no-create-home --shell /bin/false node_exporter
        echo -e "${GREEN}✓${NC} User created"
    else
        echo -e "${GREEN}✓${NC} node_exporter user already exists"
    fi
    
    # Copy service file
    echo -e "${YELLOW}→${NC} Installing systemd service..."
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    if [ -f "$SCRIPT_DIR/node-exporter.service" ]; then
        cp "$SCRIPT_DIR/node-exporter.service" /etc/systemd/system/
        echo -e "${GREEN}✓${NC} Service file installed to /etc/systemd/system/node-exporter.service"
    else
        # Create service file if it doesn't exist
        cat > /etc/systemd/system/node-exporter.service << 'EOF'
[Unit]
Description=Prometheus Node Exporter
Documentation=https://github.com/prometheus/node_exporter
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=node_exporter
Group=node_exporter
ExecStart=/usr/local/bin/node_exporter \
    --collector.cpu \
    --collector.diskstats \
    --collector.filesystem \
    --collector.loadavg \
    --collector.meminfo \
    --collector.netdev \
    --collector.stat \
    --collector.time \
    --collector.uname \
    --collector.vmstat

SyslogIdentifier=node_exporter
Restart=always
RestartSec=5

# Security hardening
NoNewPrivileges=true
ProtectHome=true
ProtectSystem=strict
ProtectControlGroups=true
ProtectKernelModules=true
ProtectKernelTunables=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
        echo -e "${GREEN}✓${NC} Service file created at /etc/systemd/system/node-exporter.service"
    fi
    
    # Reload systemd and enable service
    echo -e "${YELLOW}→${NC} Reloading systemd daemon..."
    systemctl daemon-reload
    
    echo -e "${YELLOW}→${NC} Enabling Node Exporter service..."
    systemctl enable node-exporter.service
    
    echo -e "${YELLOW}→${NC} Starting Node Exporter service..."
    systemctl start node-exporter.service
    
    echo ""
    echo -e "${GREEN}✓✓✓ Node Exporter installed and started as systemd service! ✓✓✓${NC}"
    echo ""
    echo "Useful commands:"
    echo "  Status:  systemctl status node-exporter"
    echo "  Stop:    systemctl stop node-exporter"
    echo "  Start:   systemctl start node-exporter"
    echo "  Restart: systemctl restart node-exporter"
    echo "  Logs:    journalctl -u node-exporter -f"
    echo ""
    echo -e "${GREEN}Metrics available at:${NC} http://localhost:9100/metrics"
    echo ""
    
    # Show status
    systemctl status node-exporter --no-pager
    
    exit 0
}

# If --service flag is provided, install as systemd service
if [ "$INSTALL_AS_SERVICE" = "yes" ]; then
    install_systemd_service
fi

# Check if already running as systemd service
if command -v systemctl &> /dev/null && systemctl is-active --quiet node-exporter 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Node Exporter is running as a systemd service"
    echo ""
    echo "Use these commands to manage it:"
    echo "  Status:  systemctl status node-exporter"
    echo "  Stop:    systemctl stop node-exporter"
    echo "  Start:   systemctl start node-exporter"
    echo "  Restart: systemctl restart node-exporter"
    echo "  Logs:    journalctl -u node-exporter -f"
    echo ""
    echo -e "${GREEN}Metrics available at:${NC} http://localhost:9100/metrics"
    echo ""
    systemctl status node-exporter --no-pager
    exit 0
fi

# Check if already running (direct process)
if lsof -Pi :${NODE_EXPORTER_PORT} -sTCP:LISTEN -t >/dev/null 2>&1; then
    PID=$(lsof -Pi :${NODE_EXPORTER_PORT} -sTCP:LISTEN -t)
    echo -e "${YELLOW}!${NC} Node Exporter is already running on port ${NODE_EXPORTER_PORT} (PID: $PID)"
    echo ""
    echo "Options:"
    echo "  1. Stop it with: kill $PID"
    echo "  2. Access metrics at: http://localhost:${NODE_EXPORTER_PORT}/metrics"
    echo "  3. Install as systemd service: sudo $0 --service"
    exit 0
fi

# Check/Install Node Exporter
if ! check_node_exporter; then
    echo -e "${YELLOW}!${NC} Node Exporter not found. Installing..."
    echo ""
    
    if install_with_brew; then
        echo -e "${GREEN}✓${NC} Installation complete via Homebrew"
    else
        echo -e "${YELLOW}→${NC} Homebrew not available, installing manually..."
        install_manual "$HOME/.local/bin"
    fi
    echo ""
fi

# Get node_exporter path
NODE_EXPORTER_BIN=$(command -v node_exporter)
echo -e "${GREEN}✓${NC} Using: $NODE_EXPORTER_BIN"
echo ""

# Start Node Exporter
echo -e "${GREEN}→${NC} Starting Node Exporter on port ${NODE_EXPORTER_PORT}..."
echo ""
echo -e "${GREEN}Metrics available at:${NC} http://localhost:${NODE_EXPORTER_PORT}/metrics"
echo -e "${GREEN}Health check at:${NC} http://localhost:${NODE_EXPORTER_PORT}/health"
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
echo ""
echo "---"
echo ""

# Start node_exporter with common useful collectors enabled
exec node_exporter \
    --web.listen-address=":${NODE_EXPORTER_PORT}" \
    --collector.cpu \
    --collector.diskstats \
    --collector.filesystem \
    --collector.loadavg \
    --collector.meminfo \
    --collector.netdev \
    --collector.stat \
    --collector.time \
    --collector.uname \
    --collector.vmstat

