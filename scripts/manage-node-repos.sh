#!/bin/bash

# Custom Node Repository Management Script
# This script helps manage custom node repositories and their git connections

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
NODES_DIR="$PROJECT_ROOT/nodes"

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
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  init <node-name> <repo-url>    Initialize a node with its own repository"
    echo "  connect <node-name> <repo-url> Connect existing node to repository"
    echo "  exclude <node-name>            Exclude node from main repository"
    echo "  include <node-name>            Include node in main repository"
    echo "  list                           List all custom nodes and their status"
    echo "  status <node-name>             Show status of specific node"
    echo "  help                           Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 init myapi git@github.com:your-org/n8n-nodes-myapi.git"
    echo "  $0 connect pulseapi git@github.com:bessuraba/pulseapi-n8n-node.git"
    echo "  $0 exclude myapi"
    echo "  $0 list"
}

# Function to initialize a new node with its own repository
init_node() {
    local node_name="$1"
    local repo_url="$2"
    local node_dir="$NODES_DIR/$node_name"
    
    if [ -z "$node_name" ] || [ -z "$repo_url" ]; then
        log_error "Node name and repository URL are required"
        show_help
        exit 1
    fi
    
    if [ -d "$node_dir" ]; then
        log_warning "Node directory already exists: $node_dir"
        read -p "Do you want to remove it and reinitialize? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
        rm -rf "$node_dir"
    fi
    
    log_info "Initializing node: $node_name"
    
    # Create node directory
    mkdir -p "$node_dir"
    cd "$node_dir"
    
    # Initialize git repository
    git init
    git remote add origin "$repo_url"
    
    # Create basic node structure
    mkdir -p src/nodes/$node_name
    mkdir -p src/credentials
    
    # Create package.json
    cat > package.json << EOF
{
  "name": "n8n-nodes-$node_name",
  "version": "1.0.0",
  "description": "Custom n8n node for $node_name",
  "keywords": [
    "n8n",
    "n8n-node",
    "n8n-custom-node",
    "$node_name"
  ],
  "license": "MIT",
  "main": "index.js",
  "scripts": {
    "build": "tsc && gulp build:icons",
    "dev": "tsc --watch",
    "format": "prettier nodes credentials --write",
    "lint": "eslint nodes credentials package.json",
    "prepublishOnly": "npm run build && npm run lint"
  },
  "files": [
    "dist"
  ],
  "n8n": {
    "n8nNodesApiVersion": 1,
    "nodes": [
      "dist/nodes/$node_name/$node_name.node.js"
    ]
  },
  "devDependencies": {
    "@types/express": "^4.17.6",
    "@typescript-eslint/parser": "^5.29.0",
    "eslint-plugin-n8n-nodes-base": "^1.0.0",
    "gulp": "^4.0.2",
    "n8n-core": "^0.125.0",
    "n8n-workflow": "^0.107.0",
    "prettier": "^2.7.1",
    "typescript": "~4.6.4"
  }
}
EOF
    
    # Create TypeScript config
    cat > tsconfig.json << EOF
{
  "compilerOptions": {
    "lib": ["es2019", "es2020.promise", "es2020.bigint", "es2020.string"],
    "module": "commonjs",
    "moduleResolution": "node",
    "removeComments": true,
    "sourceMap": true,
    "target": "es2019",
    "typeRoots": ["node_modules/@types"]
  },
  "include": ["src/**/*", "test/**/*"],
  "exclude": ["node_modules/**/*", "**/*.spec.ts"]
}
EOF
    
    # Create basic node file
    cat > "src/nodes/$node_name/$node_name.node.ts" << EOF
import { IExecuteFunctions } from 'n8n-core';
import {
	INodeExecutionData,
	INodeType,
	INodeTypeDescription,
} from 'n8n-workflow';

export class $node_name implements INodeType {
	description: INodeTypeDescription = {
		displayName: '$node_name',
		name: '$node_name',
		icon: 'file:$node_name.svg',
		group: ['transform'],
		version: 1,
		description: 'Custom node for $node_name',
		defaults: {
			name: '$node_name',
		},
		inputs: ['main'],
		outputs: ['main'],
		properties: [
			{
				displayName: 'Operation',
				name: 'operation',
				type: 'options',
				options: [
					{
						name: 'Example Operation',
						value: 'example',
						description: 'Example operation description',
					},
				],
				default: 'example',
				noDataExpression: true,
			},
		],
	};

	async execute(this: IExecuteFunctions): Promise<INodeExecutionData[][]> {
		const items = this.getInputData();
		const returnData: INodeExecutionData[] = [];

		for (let i = 0; i < items.length; i++) {
			const operation = this.getNodeParameter('operation', i) as string;

			if (operation === 'example') {
				// Add your node logic here
				const newItem: INodeExecutionData = {
					json: {
						...items[i].json,
						processed: true,
						timestamp: new Date().toISOString(),
					},
				};
				returnData.push(newItem);
			}
		}

		return [returnData];
	}
}
EOF
    
    # Create SVG icon
    cat > "src/nodes/$node_name/$node_name.svg" << EOF
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <circle cx="12" cy="12" r="10"/>
  <path d="M8 14s1.5 2 4 2 4-2 4-2"/>
  <line x1="9" y1="9" x2="9.01" y2="9"/>
  <line x1="15" y1="9" x2="15.01" y2="9"/>
</svg>
EOF
    
    # Create README
    cat > README.md << EOF
# $node_name Node for n8n

This is a custom n8n node for $node_name.

## Installation

Follow the installation instructions for custom n8n nodes.

## Usage

Describe how to use this node.

## Development

\`\`\`bash
npm install
npm run build
\`\`\`

## License

MIT
EOF
    
    # Create .gitignore
    cat > .gitignore << EOF
node_modules/
dist/
*.log
.env
.DS_Store
EOF
    
    # Initial commit
    git add .
    git commit -m "Initial commit: $node_name custom n8n node"
    
    # Exclude from main repository
    exclude_node "$node_name"
    
    log_success "Initialized node: $node_name"
    log_info "Repository URL: $repo_url"
    log_info "Next steps:"
    log_info "1. Push to remote: cd $node_dir && git push -u origin main"
    log_info "2. Update .env: CUSTOM_NODES=$node_name CUSTOM_NODES_SOURCE=github"
}

# Function to connect existing node to repository
connect_node() {
    local node_name="$1"
    local repo_url="$2"
    local node_dir="$NODES_DIR/$node_name"
    
    if [ -z "$node_name" ] || [ -z "$repo_url" ]; then
        log_error "Node name and repository URL are required"
        show_help
        exit 1
    fi
    
    if [ ! -d "$node_dir" ]; then
        log_error "Node directory not found: $node_dir"
        exit 1
    fi
    
    log_info "Connecting node: $node_name to $repo_url"
    
    cd "$node_dir"
    
    # Initialize git if not already done
    if [ ! -d ".git" ]; then
        git init
    fi
    
    # Add remote
    git remote add origin "$repo_url" 2>/dev/null || git remote set-url origin "$repo_url"
    
    # Add and commit files
    git add .
    git commit -m "Connect $node_name to repository" 2>/dev/null || true
    
    # Exclude from main repository
    exclude_node "$node_name"
    
    log_success "Connected node: $node_name"
    log_info "Next steps:"
    log_info "1. Push to remote: git push -u origin main"
    log_info "2. Update .env: CUSTOM_NODES=$node_name CUSTOM_NODES_SOURCE=github"
}

# Function to exclude node from main repository
exclude_node() {
    local node_name="$1"
    local gitignore_file="$PROJECT_ROOT/.gitignore"
    
    log_info "Excluding $node_name from main repository"
    
    # Add to .gitignore if not already there
    if ! grep -q "^nodes/$node_name/$" "$gitignore_file"; then
        echo "nodes/$node_name/" >> "$gitignore_file"
        log_success "Added $node_name to .gitignore"
    else
        log_info "$node_name already excluded"
    fi
    
    # Remove from git tracking if tracked
    if git ls-files "nodes/$node_name/" >/dev/null 2>&1; then
        git rm -r --cached "nodes/$node_name/" >/dev/null 2>&1 || true
        log_success "Removed $node_name from git tracking"
    fi
}

# Function to include node in main repository
include_node() {
    local node_name="$1"
    local gitignore_file="$PROJECT_ROOT/.gitignore"
    
    log_info "Including $node_name in main repository"
    
    # Remove from .gitignore
    sed -i.bak "/^nodes\/$node_name\/$/d" "$gitignore_file"
    rm -f "${gitignore_file}.bak"
    
    # Add to git tracking
    git add "nodes/$node_name/"
    
    log_success "Included $node_name in main repository"
}

# Function to list all custom nodes
list_nodes() {
    log_info "Custom nodes status:"
    echo
    
    if [ ! -d "$NODES_DIR" ]; then
        log_warning "No nodes directory found"
        return
    fi
    
    for node_dir in "$NODES_DIR"/*/; do
        if [ -d "$node_dir" ]; then
            local node_name=$(basename "$node_dir")
            local git_status=""
            local exclude_status=""
            
            # Check if it's a git repository
            if [ -d "$node_dir/.git" ]; then
                git_status="✅ Git repo"
            else
                git_status="❌ No git repo"
            fi
            
            # Check if excluded from main repo
            if grep -q "^nodes/$node_name/$" "$PROJECT_ROOT/.gitignore"; then
                exclude_status="🚫 Excluded"
            else
                exclude_status="📦 Included"
            fi
            
            echo "  $node_name: $git_status, $exclude_status"
        fi
    done
}

# Function to show status of specific node
show_node_status() {
    local node_name="$1"
    local node_dir="$NODES_DIR/$node_name"
    
    if [ -z "$node_name" ]; then
        log_error "Node name is required"
        show_help
        exit 1
    fi
    
    if [ ! -d "$node_dir" ]; then
        log_error "Node not found: $node_name"
        exit 1
    fi
    
    log_info "Status for node: $node_name"
    echo
    
    # Git status
    if [ -d "$node_dir/.git" ]; then
        log_success "✅ Git repository initialized"
        cd "$node_dir"
        echo "  Remote: $(git remote get-url origin 2>/dev/null || echo 'None')"
        echo "  Branch: $(git branch --show-current 2>/dev/null || echo 'None')"
        echo "  Status: $(git status --porcelain | wc -l) changes"
    else
        log_warning "❌ No git repository"
    fi
    
    # Exclusion status
    if grep -q "^nodes/$node_name/$" "$PROJECT_ROOT/.gitignore"; then
        log_info "🚫 Excluded from main repository"
    else
        log_info "📦 Included in main repository"
    fi
    
    # Files
    echo "  Files: $(find "$node_dir" -type f -name "*.ts" -o -name "*.js" -o -name "package.json" | wc -l) source files"
}

# Main execution
main() {
    case "${1:-help}" in
        "init")
            init_node "$2" "$3"
            ;;
        "connect")
            connect_node "$2" "$3"
            ;;
        "exclude")
            exclude_node "$2"
            ;;
        "include")
            include_node "$2"
            ;;
        "list")
            list_nodes
            ;;
        "status")
            show_node_status "$2"
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            log_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@" 