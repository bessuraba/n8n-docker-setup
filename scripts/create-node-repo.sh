#!/bin/bash

# Script to create a new custom n8n node repository
# This helps maintain separation between parent and child repos

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to show help
show_help() {
    echo "Usage: $0 <node-name> <repository-url>"
    echo ""
    echo "Arguments:"
    echo "  node-name        Name of the node (e.g., myapi, datavalidator)"
    echo "  repository-url   Git repository URL to clone"
    echo ""
    echo "Examples:"
    echo "  $0 myapi git@github.com:your-org/myapi-n8n-node.git"
    echo "  $0 datavalidator https://github.com/your-org/datavalidator-n8n-node.git"
    echo ""
    echo "Note: The script will clone the repository into nodes/<node-name>-n8n-node/"
}

if [ $# -lt 2 ]; then
    log_error "Node name and repository URL are required"
    show_help
    exit 1
fi

NODE_NAME="$1"
REPO_URL="$2"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Extract repository name from URL for validation
REPO_NAME=$(basename "$REPO_URL" .git)

log_info "🚀 Setting up custom n8n node: $NODE_NAME"

# Create node directory with -n8n-node suffix
NODE_DIR="$PROJECT_ROOT/nodes/$NODE_NAME-n8n-node"
if [ -d "$NODE_DIR" ]; then
    log_warning "Node directory already exists: $NODE_DIR"
    read -p "Do you want to remove it and re-clone? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Operation cancelled"
        exit 1
    fi
    rm -rf "$NODE_DIR"
fi

# Clone the repository
log_info "📥 Cloning repository: $REPO_URL"
cd "$PROJECT_ROOT/nodes"

if git clone "$REPO_URL" "$NODE_NAME-n8n-node"; then
    log_success "Repository cloned successfully"
else
    log_error "Failed to clone repository"
    exit 1
fi

cd "$NODE_DIR"

# Check if the cloned repository has the expected structure
if [ ! -f "package.json" ]; then
    log_warning "Repository doesn't contain package.json"
    log_info "This might not be a valid n8n node repository"
fi

# Check if it's already a git repository
if [ -d ".git" ]; then
    log_success "Git repository initialized"
    
    # Show repository info
    log_info "Repository information:"
    echo "  Remote: $(git remote get-url origin 2>/dev/null || echo 'None')"
    echo "  Branch: $(git branch --show-current 2>/dev/null || echo 'None')"
    echo "  Status: $(git status --porcelain | wc -l) changes"
else
    log_warning "No git repository found in cloned directory"
fi

# Check if the node is properly excluded from main repository
if git check-ignore "$NODE_DIR" >/dev/null 2>&1; then
    log_success "Node is properly excluded from main repository"
else
    log_warning "Node is not excluded from main repository"
    log_info "Adding to .gitignore..."
    
    # Add to .gitignore
    echo "nodes/$NODE_NAME-n8n-node/" >> "$PROJECT_ROOT/.gitignore"
    log_success "Added to .gitignore"
fi

log_success "✅ Custom node setup complete: $NODE_NAME"
echo ""
log_info "📁 Location: $NODE_DIR"
echo ""
log_info "Next steps:"
echo "1. cd $NODE_DIR"
echo "2. npm install"
echo "3. Implement your node logic"
echo "4. Test your node"
echo "5. Push changes to your repository"
echo ""
log_info "To use this node in n8n:"
echo "1. Add to .env: CUSTOM_NODES=$NODE_NAME"
echo "2. Start n8n: npm start"
echo ""
log_info "Available commands:"
echo "- npm run dev:discover    # Auto-discover and install nodes"
echo "- npm run dev:manage-repos list    # List all custom nodes" 