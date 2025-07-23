#!/bin/bash

# n8n Custom Nodes Local Installation Script
# This script installs custom nodes for local development

set -e

echo "🚀 Installing custom n8n nodes for local development..."

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Check if n8n_data directory exists
N8N_DATA_DIR="$PROJECT_ROOT/n8n_data"
if [ ! -d "$N8N_DATA_DIR" ]; then
    echo "📁 Creating n8n_data directory..."
    mkdir -p "$N8N_DATA_DIR"
fi

# Create custom nodes directory
CUSTOM_NODES_DIR="$N8N_DATA_DIR/custom"
if [ ! -d "$CUSTOM_NODES_DIR" ]; then
    echo "📁 Creating custom nodes directory..."
    mkdir -p "$CUSTOM_NODES_DIR"
fi

# Function to install a node
install_node() {
    local node_dir="$1"
    local node_name=$(basename "$node_dir")
    
    if [ -f "$node_dir/package.json" ]; then
        echo "📦 Installing node: $node_name"
        
        # Build the node if build script exists
        if grep -q "\"build\"" "$node_dir/package.json"; then
            echo "🔨 Building $node_name..."
            cd "$node_dir"
            npm run build
            cd "$SCRIPT_DIR"
        fi
        
        # Copy node to custom directory
        local target_dir="$CUSTOM_NODES_DIR/$node_name"
        if [ -d "$target_dir" ]; then
            rm -rf "$target_dir"
        fi
        
        cp -r "$node_dir" "$target_dir"
        
        # Install dependencies in the target directory
        cd "$target_dir"
        npm install --production
        cd "$SCRIPT_DIR"
        
        echo "✅ Installed $node_name"
    fi
}

# Install all nodes in the nodes directory
echo "🔍 Scanning for custom nodes..."
for node_dir in "$SCRIPT_DIR"/*/; do
    if [ -d "$node_dir" ] && [ "$(basename "$node_dir")" != "node_modules" ]; then
        install_node "$node_dir"
    fi
done

echo "🎉 Custom nodes installation complete!"
echo "📁 Nodes installed in: $CUSTOM_NODES_DIR"
echo ""
echo "Next steps:"
echo "1. Start n8n: npm start"
echo "2. Your custom nodes will be available in the n8n editor"
echo "3. To update nodes, run this script again" 