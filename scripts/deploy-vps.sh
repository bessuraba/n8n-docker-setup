#!/bin/bash

# n8n VPS Deployment Script
# This script deploys n8n with custom nodes to a VPS

set -e

echo "🚀 Deploying n8n with custom nodes to VPS..."

# Configuration
N8N_PORT=${N8N_PORT:-5678}
N8N_USER=${N8N_USER:-n8n}
N8N_DIR=${N8N_DIR:-/opt/n8n}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "This script must be run as root"
    exit 1
fi

# Update system
print_status "Updating system packages..."
apt update && apt upgrade -y

# Install Node.js and npm
print_status "Installing Node.js and npm..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# Create n8n user
print_status "Creating n8n user..."
if ! id "$N8N_USER" &>/dev/null; then
    useradd -m -s /bin/bash "$N8N_USER"
    usermod -aG sudo "$N8N_USER"
fi

# Create n8n directory
print_status "Creating n8n directory..."
mkdir -p "$N8N_DIR"
chown "$N8N_USER:$N8N_USER" "$N8N_DIR"

# Install n8n globally
print_status "Installing n8n globally..."
npm install -g n8n

# Install custom nodes (if any)
if [ -d "nodes" ]; then
    print_status "Installing custom nodes..."
    cd nodes
    
    # Find all package.json files and install them
    for node_dir in */; do
        if [ -d "$node_dir" ] && [ -f "$node_dir/package.json" ]; then
            node_name=$(basename "$node_dir")
            print_status "Installing node: $node_name"
            
            cd "$node_dir"
            
            # Build the node if build script exists
            if grep -q "\"build\"" package.json; then
                npm run build
            fi
            
            # Install globally
            npm install -g .
            cd ..
        fi
    done
    
    cd ..
fi

# Create systemd service
print_status "Creating systemd service..."
cat > /etc/systemd/system/n8n.service << EOF
[Unit]
Description=n8n
After=network.target

[Service]
Type=simple
User=$N8N_USER
WorkingDirectory=$N8N_DIR
ExecStart=/usr/bin/n8n start
Restart=always
RestartSec=10
Environment=NODE_ENV=production
Environment=N8N_PORT=$N8N_PORT
Environment=N8N_HOST=0.0.0.0
Environment=N8N_BASIC_AUTH_ACTIVE=true
Environment=N8N_BASIC_AUTH_USER=admin
Environment=N8N_BASIC_AUTH_PASSWORD=CHANGE_THIS_PASSWORD
Environment=N8N_ENCRYPTION_KEY=CHANGE_THIS_ENCRYPTION_KEY
Environment=N8N_LOG_LEVEL=info
Environment=N8N_TIMEZONE=UTC

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
systemctl daemon-reload

# Enable and start n8n
print_status "Starting n8n service..."
systemctl enable n8n
systemctl start n8n

# Configure firewall
print_status "Configuring firewall..."
if command -v ufw &> /dev/null; then
    ufw allow $N8N_PORT/tcp
    ufw --force enable
fi

# Create nginx configuration (optional)
if command -v nginx &> /dev/null; then
    print_status "Creating nginx configuration..."
    cat > /etc/nginx/sites-available/n8n << EOF
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:$N8N_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF

    ln -sf /etc/nginx/sites-available/n8n /etc/nginx/sites-enabled/
    nginx -t && systemctl reload nginx
fi

print_status "Deployment complete!"
echo ""
echo "Next steps:"
echo "1. Edit /etc/systemd/system/n8n.service to set your password and encryption key"
echo "2. Restart n8n: systemctl restart n8n"
echo "3. Check status: systemctl status n8n"
echo "4. View logs: journalctl -u n8n -f"
echo "5. Access n8n at: http://your-server-ip:$N8N_PORT"
echo ""
echo "Default credentials:"
echo "Username: admin"
echo "Password: CHANGE_THIS_PASSWORD (please change this!)" 