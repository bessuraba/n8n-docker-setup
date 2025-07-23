#!/bin/bash

# n8n Custom Nodes Publishing Script
# This script publishes all custom nodes to npm

set -e

echo "📦 Publishing custom n8n nodes to npm..."

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if user is logged in to npm
if ! npm whoami > /dev/null 2>&1; then
    echo "❌ You must be logged in to npm to publish packages"
    echo "Run: npm login"
    exit 1
fi

# Function to publish a node
publish_node() {
    local node_dir="$1"
    local node_name=$(basename "$node_dir")
    
    if [ -f "$node_dir/package.json" ]; then
        echo "📦 Publishing node: $node_name"
        
        cd "$node_dir"
        
        # Check if package.json has required fields
        if ! grep -q '"name"' package.json; then
            echo "❌ $node_name: package.json missing 'name' field"
            cd "$SCRIPT_DIR"
            return 1
        fi
        
        if ! grep -q '"version"' package.json; then
            echo "❌ $node_name: package.json missing 'version' field"
            cd "$SCRIPT_DIR"
            return 1
        fi
        
        # Build the node if build script exists
        if grep -q "\"build\"" package.json; then
            echo "🔨 Building $node_name..."
            npm run build
        fi
        
        # Check if package is already published
        local package_name=$(node -p "require('./package.json').name")
        if npm view "$package_name" > /dev/null 2>&1; then
            echo "⚠️  $node_name: Package already exists on npm"
            read -p "Do you want to update the version? (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo "📈 Bumping version..."
                npm version patch
            else
                echo "⏭️  Skipping $node_name"
                cd "$SCRIPT_DIR"
                return 0
            fi
        fi
        
        # Publish the package
        echo "🚀 Publishing $node_name to npm..."
        npm publish
        
        echo "✅ Published $node_name"
        cd "$SCRIPT_DIR"
    fi
}

# Publish all nodes in the nodes directory
echo "🔍 Scanning for custom nodes to publish..."
for node_dir in "$SCRIPT_DIR"/*/; do
    if [ -d "$node_dir" ] && [ "$(basename "$node_dir")" != "node_modules" ]; then
        publish_node "$node_dir"
    fi
done

echo "🎉 Custom nodes publishing complete!"
echo ""
echo "Next steps:"
echo "1. Update your VPS deployment to install these packages"
echo "2. Add the published packages to your production n8n installation" 