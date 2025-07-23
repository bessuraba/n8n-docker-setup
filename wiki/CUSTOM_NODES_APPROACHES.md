# Custom Nodes Management Approaches

This document outlines various approaches to manage custom n8n nodes without using `.gitmodules`, keeping the parent repository independent of child repositories.

## Overview

The main goal is to have a parent repository (docker setup) that doesn't need to know about specific child repositories (custom nodes), while still being able to install and use custom nodes based on environment configuration.

## Approach 1: Environment-Based Node Discovery (Recommended)

### How it works
- Uses environment variables to specify which nodes to install
- Supports multiple installation sources (local, npm, GitHub)
- Parent repo remains independent of child repos

### Configuration
```bash
# .env file
CUSTOM_NODES=pulseapi,other-node
CUSTOM_NODES_SOURCE=local
CUSTOM_NODES_GITHUB_ORG=your-org
CUSTOM_NODES_NPM_SCOPE=@your-scope
```

### Usage
```bash
# Install specific nodes
CUSTOM_NODES=pulseapi npm run start

# Install from npm
CUSTOM_NODES=pulseapi CUSTOM_NODES_SOURCE=npm npm run start

# Install from GitHub
CUSTOM_NODES=pulseapi CUSTOM_NODES_SOURCE=github CUSTOM_NODES_GITHUB_ORG=your-org npm run start
```

### Advantages
- ✅ Parent repo doesn't know about child repos
- ✅ Flexible installation sources
- ✅ Environment-specific configuration
- ✅ Easy to add/remove nodes

### Disadvantages
- ❌ Requires environment setup
- ❌ Node names must be known in advance

## Approach 2: Configuration File Approach

### How it works
- Uses a JSON configuration file to define nodes and their sources
- Supports multiple installation methods
- Can be version controlled or generated dynamically

### Configuration
```json
{
  "nodes": [
    {
      "name": "pulseapi",
      "source": "local",
      "path": "./nodes/pulseapi"
    },
    {
      "name": "other-node",
      "source": "npm",
      "package": "@your-scope/other-node"
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
```

### Usage
```bash
# Use default config
./scripts/discover-nodes.sh

# Use custom config
NODES_CONFIG_FILE=my-nodes.json ./scripts/discover-nodes.sh
```

### Advantages
- ✅ Structured configuration
- ✅ Supports complex node definitions
- ✅ Can be generated programmatically
- ✅ Version control friendly

### Disadvantages
- ❌ Requires configuration file maintenance
- ❌ More complex setup

## Approach 3: Dynamic Node Discovery

### How it works
- Automatically discovers nodes in local directories
- Scans for `package.json` files to identify nodes
- No manual configuration required

### Usage
```bash
# Auto-discover all local nodes
./scripts/discover-nodes.sh --auto-discover

# Discover from custom path
./scripts/discover-nodes.sh --auto-discover --local-path ./custom-nodes
```

### Advantages
- ✅ Zero configuration required
- ✅ Automatic discovery
- ✅ Easy to add new nodes

### Disadvantages
- ❌ Only works with local nodes
- ❌ Less control over installation process
- ❌ No support for external sources

## Approach 4: Package Manager Integration

### How it works
- Uses npm/yarn to manage custom nodes
- Nodes are published to npm registry
- Installation via package manager

### Configuration
```bash
# Install nodes via npm
npm install n8n-nodes-pulseapi n8n-nodes-other

# Or use a package.json with dependencies
{
  "dependencies": {
    "n8n-nodes-pulseapi": "^1.0.0",
    "n8n-nodes-other": "^1.0.0"
  }
}
```

### Usage
```bash
# Install all dependencies
npm install

# Add new node
npm install n8n-nodes-new-node
```

### Advantages
- ✅ Standard package management
- ✅ Version control
- ✅ Easy distribution
- ✅ Dependency resolution

### Disadvantages
- ❌ Requires publishing to npm
- ❌ More complex for development
- ❌ Less flexible for local development

## Approach 5: Hybrid Approach (Best of All Worlds)

### How it works
- Combines multiple approaches
- Environment variables for basic configuration
- Configuration file for complex setups
- Auto-discovery as fallback
- Package manager for production

### Configuration
```bash
# Environment variables for basic setup
CUSTOM_NODES=pulseapi
CUSTOM_NODES_SOURCE=auto

# Configuration file for complex setups
NODES_CONFIG_FILE=nodes-config.json
```

### Usage
```bash
# Simple setup
CUSTOM_NODES=pulseapi npm run start

# Complex setup
NODES_CONFIG_FILE=production-nodes.json npm run start

# Development
npm run dev:discover
```

### Advantages
- ✅ Maximum flexibility
- ✅ Multiple fallback options
- ✅ Works for all use cases
- ✅ Easy migration between approaches

### Disadvantages
- ❌ More complex implementation
- ❌ Multiple configuration methods to understand

## Implementation Examples

### Environment-Based Setup
```bash
# .env file
CUSTOM_NODES=pulseapi,datavalidator
CUSTOM_NODES_SOURCE=local

# Start with custom nodes
docker-compose up -d
```

### Configuration File Setup
```json
// nodes-config.json
{
  "nodes": [
    {
      "name": "pulseapi",
      "source": "local",
      "path": "./nodes/pulseapi"
    },
    {
      "name": "datavalidator",
      "source": "github",
      "repo": "your-org/n8n-nodes-datavalidator"
    }
  ]
}
```

### Auto-Discovery Setup
```bash
# Just run the discovery script
./scripts/discover-nodes.sh --auto-discover
```

## Migration from .gitmodules

This project has been migrated from `.gitmodules` to the new approaches described above. The migration involved:

1. **Removed submodules**: All git submodules have been converted to regular directories
2. **Updated scripts**: Replaced submodule management with dynamic node discovery
3. **Simplified workflow**: No more complex submodule management required

If you're migrating your own project from `.gitmodules`, follow these steps:

1. **Remove submodules**:
   ```bash
   git submodule deinit nodes/your-node
   git rm nodes/your-node
   rm -rf .git/modules/nodes/your-node
   ```

2. **Clone repositories manually**:
   ```bash
   cd nodes
   git clone https://github.com/your-org/n8n-nodes-your-node.git your-node
   ```

3. **Choose an approach**:
   - For simple setups: Use environment variables
   - For complex setups: Use configuration files
   - For development: Use auto-discovery

4. **Update your workflow**:
   ```bash
   # Instead of git submodule update
   npm run dev:discover
   ```

## Best Practices

### For Development
- Use auto-discovery for local development
- Keep nodes in `./nodes/` directory
- Use environment variables for quick testing

### For Production
- Use configuration files for complex setups
- Publish nodes to npm for distribution
- Use environment variables for deployment-specific configuration

### For Teams
- Document node requirements in README
- Use consistent naming conventions
- Provide clear installation instructions

## Troubleshooting

### Common Issues

1. **Node not found**:
   - Check node name spelling
   - Verify node exists in specified path
   - Check environment variable syntax

2. **Build failures**:
   - Ensure node has proper `package.json`
   - Check for missing dependencies
   - Verify TypeScript configuration

3. **Installation issues**:
   - Check file permissions
   - Verify Docker volume mounts
   - Check network connectivity for external sources

### Debug Commands
```bash
# Check node discovery
./scripts/discover-nodes.sh --auto-discover --local-path ./nodes

# Check Docker logs
docker-compose logs n8n

# Verify node installation
ls -la /home/node/.n8n/custom/
```

## Conclusion

The **Environment-Based Node Discovery** approach is recommended for most use cases as it provides the best balance of simplicity and flexibility. For complex setups, consider the **Hybrid Approach** that combines multiple methods.

Choose the approach that best fits your workflow and team structure. All approaches maintain the independence of the parent repository while providing flexible custom node management. 