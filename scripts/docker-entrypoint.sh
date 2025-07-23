#!/bin/bash

# n8n Custom Nodes Docker Entrypoint Script
# This script installs custom nodes in the Docker container based on environment variables

set -e

echo "🐳 Installing custom n8n nodes in Docker container..."

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# n8n custom nodes directory in the container
N8N_CUSTOM_DIR="/home/node/.n8n/custom"

# Create custom nodes directory if it doesn't exist
if [ ! -d "$N8N_CUSTOM_DIR" ]; then
    echo "📁 Creating custom nodes directory..."
    mkdir -p "$N8N_CUSTOM_DIR"
fi

# Function to install a node from local directory
install_local_node() {
    local node_dir="$1"
    local node_name=$(basename "$node_dir")
    
    if [ -f "$node_dir/package.json" ]; then
        echo "📦 Installing local node: $node_name"
        
        # Build the node if build script exists
        if grep -q "\"build\"" "$node_dir/package.json"; then
            echo "🔨 Building $node_name..."
            cd "$node_dir"
            npm run build
            cd "$SCRIPT_DIR"
        fi
        
        # Copy node to custom directory
        local target_dir="$N8N_CUSTOM_DIR/$node_name"
        if [ -d "$target_dir" ]; then
            rm -rf "$target_dir"
        fi
        
        cp -r "$node_dir" "$target_dir"
        
        # Install dependencies in the target directory
        cd "$target_dir"
        npm install --production
        cd "$SCRIPT_DIR"
        
        echo "✅ Installed local node: $node_name"
    fi
}

# Function to install a node from npm
install_npm_node() {
    local node_name="$1"
    local npm_scope="${CUSTOM_NODES_NPM_SCOPE:-}"
    local package_name="$node_name"
    
    if [ -n "$npm_scope" ]; then
        package_name="$npm_scope/$node_name"
    fi
    
    echo "📦 Installing npm node: $package_name"
    
    # Install from npm
    cd "$N8N_CUSTOM_DIR"
    npm install "$package_name"
    cd "$SCRIPT_DIR"
    
    echo "✅ Installed npm node: $package_name"
}

# Function to install a node from GitHub
install_github_node() {
    local node_name="$1"
    local github_org="${CUSTOM_NODES_GITHUB_ORG:-}"
    
    if [ -z "$github_org" ]; then
        echo "❌ CUSTOM_NODES_GITHUB_ORG not set for GitHub installation"
        return 1
    fi
    
    local repo_url="https://github.com/$github_org/$node_name.git"
    echo "📦 Installing GitHub node: $repo_url"
    
    # Clone and install
    cd "$N8N_CUSTOM_DIR"
    git clone "$repo_url" "$node_name"
    cd "$node_name"
    
    # Build if needed
    if [ -f "package.json" ] && grep -q "\"build\"" "package.json"; then
        echo "🔨 Building $node_name..."
        npm run build
    fi
    
    # Install dependencies
    npm install --production
    cd "$SCRIPT_DIR"
    
    echo "✅ Installed GitHub node: $node_name"
}

# Main installation logic
echo "🔍 Processing custom nodes configuration..."

# Get custom nodes from environment variable
CUSTOM_NODES_LIST="${CUSTOM_NODES:-}"
CUSTOM_NODES_SOURCE="${CUSTOM_NODES_SOURCE:-local}"

if [ -z "$CUSTOM_NODES_LIST" ]; then
    echo "📝 No specific nodes specified, installing all available local nodes..."
    # Install all local nodes
    for node_dir in "$PROJECT_ROOT/nodes"/*/; do
        if [ -d "$node_dir" ] && [ "$(basename "$node_dir")" != "node_modules" ]; then
            install_local_node "$node_dir"
        fi
    done
else
    echo "📝 Installing specified nodes: $CUSTOM_NODES_LIST"
    # Install specific nodes
    IFS=',' read -ra NODES <<< "$CUSTOM_NODES_LIST"
    for node in "${NODES[@]}"; do
        node=$(echo "$node" | xargs) # trim whitespace
        
        case "$CUSTOM_NODES_SOURCE" in
            "local")
                local_node_dir="$PROJECT_ROOT/nodes/$node"
                if [ -d "$local_node_dir" ]; then
                    install_local_node "$local_node_dir"
                else
                    echo "⚠️  Local node '$node' not found in $PROJECT_ROOT/nodes/"
                fi
                ;;
            "npm")
                install_npm_node "$node"
                ;;
            "github")
                install_github_node "$node"
                ;;
            *)
                echo "❌ Unknown CUSTOM_NODES_SOURCE: $CUSTOM_NODES_SOURCE"
                echo "   Supported values: local, npm, github"
                exit 1
                ;;
        esac
    done
fi

echo "🎉 Custom nodes installation complete!"
echo "📁 Nodes installed in: $N8N_CUSTOM_DIR"

# Start n8n (this replaces the original entrypoint)
echo "🚀 Starting n8n..."
exec n8n 