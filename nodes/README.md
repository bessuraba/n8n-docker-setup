# Custom n8n Nodes

This directory contains custom n8n nodes for development and deployment.

## Structure

```
nodes/
├── README.md                 # This file
├── package.json             # Main package.json for all nodes
├── pulseapi/                # PulseAPI integration node
│   ├── package.json        # Node-specific package.json
│   ├── src/                # Source code
│   ├── README.md           # Node documentation
│   └── ...
└── ...                     # More custom nodes...
```

**Scripts are now located in the `../scripts/` directory:**
- `../scripts/install-nodes.sh` - Local installation script
- `../scripts/docker-entrypoint.sh` - Docker installation script
- `../scripts/discover-nodes.sh` - Node discovery script
- `../scripts/publish-nodes.sh` - npm publishing script

## Development Workflow

### Local Development
1. Create your custom node in a subfolder
2. Run `npm run dev:install` to install nodes locally
3. Start n8n with `npm start`
4. Your custom nodes will be available in n8n

### Production Deployment
1. Publish nodes to npm: `npm run publish:nodes`
2. Deploy to VPS: `npm run deploy`
3. Nodes will be installed via npm on the VPS

## Node Development Guidelines

Each node should follow this structure:
- `package.json` - Node metadata and dependencies
- `src/` - Source code
- `README.md` - Documentation
- `credentials/` - Custom credentials (if needed)
- `nodes/` - Node implementations

## Available Scripts

- `npm run dev:install` - Install nodes for local development
- `npm run dev:discover` - Auto-discover and install local nodes
- `npm run dev:create-node` - Create a new custom node
- `npm run dev:publish` - Publish nodes to npm

## Current Nodes

### PulseAPI Node
- **Repository**: [pulseapi-n8n-node](https://github.com/bessuraba/pulseapi-n8n-node)
- **Description**: Full HTTP API integration with authentication support
- **Features**: GET, POST, PUT, DELETE, PATCH operations with query parameters, headers, and request bodies 