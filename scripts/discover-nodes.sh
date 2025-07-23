#!/bin/bash

# Dynamic Node Discovery and Installation Script
# This script discovers and installs custom nodes from various sources

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Configuration
NODES_CONFIG_FILE="${NODES_CONFIG_FILE:-$PROJECT_ROOT/nodes-config.json}"
N8N_CUSTOM_DIR="${N8N_CUSTOM_DIR:-/home/node/.n8n/custom}"

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

# Function to create default config if it doesn't exist
create_default_config() {
    if [ ! -f "$NODES_CONFIG_FILE" ]; then
        log_info "Creating default nodes configuration file..."
        cat > "$NODES_CONFIG_FILE" << EOF
{
  "nodes": [
    {
      "name": "pulseapi",
      "source": "local",
      "path": "./nodes/pulseapi"
    }
  ],
  "sources": {
    "local": {
      "base_path": "./nodes"
    },
    "npm": {
      "scope": "@your-scope"
    },
    "github": {
      "organization": "your-org"
    }
  }
}
EOF
        log_success "Created default configuration at $NODES_CONFIG_FILE"
    fi
}

# Function to install a node from local directory
install_local_node() {
    local node_name="$1"
    local node_path="$2"
    
    if [ ! -d "$node_path" ]; then
        log_warning "Local node path not found: $node_path"
        return 1
    fi
    
    log_info "Installing local node: $node_name from $node_path"
    
    # Build if needed
    if [ -f "$node_path/package.json" ] && grep -q "\"build\"" "$node_path/package.json"; then
        log_info "Building $node_name..."
        cd "$node_path"
        npm run build
        cd "$SCRIPT_DIR"
    fi
    
    # Copy to custom directory
    local target_dir="$N8N_CUSTOM_DIR/$node_name"
    if [ -d "$target_dir" ]; then
        rm -rf "$target_dir"
    fi
    
    cp -r "$node_path" "$target_dir"
    
    # Install dependencies
    cd "$target_dir"
    npm install --production
    cd "$SCRIPT_DIR"
    
    log_success "Installed local node: $node_name"
}

# Function to install a node from npm
install_npm_node() {
    local node_name="$1"
    local npm_scope="$2"
    
    local package_name="$node_name"
    if [ -n "$npm_scope" ]; then
        package_name="$npm_scope/$node_name"
    fi
    
    log_info "Installing npm node: $package_name"
    
    cd "$N8N_CUSTOM_DIR"
    npm install "$package_name"
    cd "$SCRIPT_DIR"
    
    log_success "Installed npm node: $package_name"
}

# Function to install a node from GitHub
install_github_node() {
    local node_name="$1"
    local github_org="$2"
    
    if [ -z "$github_org" ]; then
        log_error "GitHub organization not specified for node: $node_name"
        return 1
    fi
    
    local repo_url="https://github.com/$github_org/$node_name.git"
    log_info "Installing GitHub node: $repo_url"
    
    cd "$N8N_CUSTOM_DIR"
    git clone "$repo_url" "$node_name"
    cd "$node_name"
    
    # Build if needed
    if [ -f "package.json" ] && grep -q "\"build\"" "package.json"; then
        log_info "Building $node_name..."
        npm run build
    fi
    
    # Install dependencies
    npm install --production
    cd "$SCRIPT_DIR"
    
    log_success "Installed GitHub node: $node_name"
}

# Function to discover nodes from directory
discover_local_nodes() {
    local base_path="$1"
    local discovered_nodes=()
    
    if [ ! -d "$base_path" ]; then
        return
    fi
    
    for node_dir in "$base_path"/*/; do
        if [ -d "$node_dir" ] && [ -f "$node_dir/package.json" ]; then
            local node_name=$(basename "$node_dir")
            discovered_nodes+=("$node_name")
        fi
    done
    
    echo "${discovered_nodes[@]}"
}

# Function to install nodes from configuration
install_from_config() {
    if [ ! -f "$NODES_CONFIG_FILE" ]; then
        log_error "Configuration file not found: $NODES_CONFIG_FILE"
        return 1
    fi
    
    log_info "Installing nodes from configuration: $NODES_CONFIG_FILE"
    
    # Parse JSON and install nodes
    # This is a simplified version - in production you might want to use jq
    local nodes=$(grep -o '"name": "[^"]*"' "$NODES_CONFIG_FILE" | cut -d'"' -f4)
    local sources=$(grep -o '"source": "[^"]*"' "$NODES_CONFIG_FILE" | cut -d'"' -f4)
    local paths=$(grep -o '"path": "[^"]*"' "$NODES_CONFIG_FILE" | cut -d'"' -f4)
    
    # Convert to arrays
    IFS=$'\n' read -d '' -r -a node_names <<< "$nodes"
    IFS=$'\n' read -d '' -r -a source_types <<< "$sources"
    IFS=$'\n' read -d '' -r -a node_paths <<< "$paths"
    
    for i in "${!node_names[@]}"; do
        local node_name="${node_names[$i]}"
        local source_type="${source_types[$i]}"
        local node_path="${node_paths[$i]}"
        
        case "$source_type" in
            "local")
                install_local_node "$node_name" "$node_path"
                ;;
            "npm")
                local npm_scope=$(grep -o '"scope": "[^"]*"' "$NODES_CONFIG_FILE" | cut -d'"' -f4 | head -1)
                install_npm_node "$node_name" "$npm_scope"
                ;;
            "github")
                local github_org=$(grep -o '"organization": "[^"]*"' "$NODES_CONFIG_FILE" | cut -d'"' -f4 | head -1)
                install_github_node "$node_name" "$github_org"
                ;;
            *)
                log_warning "Unknown source type: $source_type for node: $node_name"
                ;;
        esac
    done
}

# Function to auto-discover and install local nodes
auto_discover_local() {
    local base_path="${1:-$PROJECT_ROOT/nodes}"
    
    log_info "Auto-discovering local nodes in: $base_path"
    
    local discovered_nodes=($(discover_local_nodes "$base_path"))
    
    if [ ${#discovered_nodes[@]} -eq 0 ]; then
        log_warning "No local nodes found in: $base_path"
        return
    fi
    
    log_info "Found ${#discovered_nodes[@]} local nodes: ${discovered_nodes[*]}"
    
    for node_name in "${discovered_nodes[@]}"; do
        local node_path="$base_path/$node_name"
        install_local_node "$node_name" "$node_path"
    done
}

# Function to show help
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --config <file>     Use specific configuration file (default: nodes-config.json)"
    echo "  --auto-discover     Auto-discover and install all local nodes"
    echo "  --local-path <path> Path for local node discovery (default: ./nodes)"
    echo "  --help              Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 --config my-nodes.json"
    echo "  $0 --auto-discover"
    echo "  $0 --auto-discover --local-path ./custom-nodes"
}

# Main execution
main() {
    local use_config=false
    local auto_discover=false
    local local_path="$PROJECT_ROOT/nodes"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --config)
                NODES_CONFIG_FILE="$2"
                use_config=true
                shift 2
                ;;
            --auto-discover)
                auto_discover=true
                shift
                ;;
            --local-path)
                local_path="$2"
                shift 2
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Create custom directory if it doesn't exist
    if [ ! -d "$N8N_CUSTOM_DIR" ]; then
        log_info "Creating custom nodes directory: $N8N_CUSTOM_DIR"
        mkdir -p "$N8N_CUSTOM_DIR"
    fi
    
    if [ "$auto_discover" = true ]; then
        auto_discover_local "$local_path"
    elif [ "$use_config" = true ] || [ -f "$NODES_CONFIG_FILE" ]; then
        install_from_config
    else
        create_default_config
        log_info "No configuration specified. Use --config or --auto-discover"
        show_help
    fi
    
    log_success "Node discovery and installation complete!"
}

# Run main function with all arguments
main "$@" 