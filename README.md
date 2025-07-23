# n8n Docker Setup 🚀

This repository contains a **ready-to-deploy setup for n8n**, the open-source workflow automation tool.  
You can run it locally for development or deploy it to a VPS for production.

**New Feature**: Multiple approaches for custom node management without `.gitmodules`! 🎉

---

## 📂 Features
✅ Docker-based setup (portable & easy)  
✅ Basic authentication enabled by default  
✅ Environment variables managed with `.env`  
✅ Persists workflows & credentials via a Docker volume  
✅ Ready for VPS deployment  
✅ NPM scripts for easy management  
✅ Node.js version management with `.nvmrc`  
✅ **Multiple custom node management approaches**  
✅ **Environment-based node discovery**  
✅ **Configuration file approach**  
✅ **Dynamic node discovery**  
✅ **Package manager integration**  
✅ **Hybrid approach for maximum flexibility**  

---

## 🚀 Quick Start

### 1️⃣ Clone the repo
```bash
git clone git@github.com:bessuraba/n8n-docker-setup.git
cd n8n-docker-setup
```

### 2️⃣ Setup environment
```bash
# Copy environment template and configure
npm run setup

# Edit .env file with your settings
nano .env
```

### 3️⃣ Start n8n
```bash
# Start in background
npm start

# Or start in foreground (for development)
npm run dev
```

### 4️⃣ Access n8n
Open your browser and go to: `http://localhost:5678`

---

## 🛠️ Custom Node Management

### 📁 Project Structure
```
n8n-docker-setup/
├── docker-compose.yml          # Docker configuration
├── env.example                # Environment template
├── package.json               # Main scripts and metadata
├── .nvmrc                     # Node.js version
├── LICENSE                    # MIT License
├── README.md                  # This file
├── wiki/                      # Documentation
│   └── CUSTOM_NODES_APPROACHES.md # Custom node approaches
├── scripts/                   # Bash scripts
│   ├── install-nodes.sh       # Local installation script
│   ├── docker-entrypoint.sh   # Docker installation script
│   ├── discover-nodes.sh      # Node discovery script
│   ├── create-node-repo.sh    # Node repository creation
│   ├── publish-nodes.sh       # npm publishing script
│   └── deploy-vps.sh          # VPS deployment script
├── nodes/                     # Custom nodes directory
│   └── pulseapi-n8n-node/    # PulseAPI integration node (cloned from GitHub)
└── n8n_data/                  # n8n data (created on first run)
```

### 🔧 Custom Node Management Approaches

#### Approach 1: Environment-Based Discovery (Recommended)
```bash
# Set environment variables for local nodes
CUSTOM_NODES=pulseapi,other-node
CUSTOM_NODES_SOURCE=local

# Or for GitHub-hosted nodes
CUSTOM_NODES=pulseapi
CUSTOM_NODES_SOURCE=github
CUSTOM_NODES_GITHUB_ORG=bessuraba

# Start n8n with custom nodes
npm start
```

#### Approach 2: Configuration File
```bash
# Create nodes-config.json
{
  "nodes": [
    {
      "name": "pulseapi",
      "source": "local",
      "path": "./nodes/pulseapi"
    }
  ]
}

# Use configuration file
NODES_CONFIG_FILE=nodes-config.json ./scripts/discover-nodes.sh
```

#### Approach 3: Auto-Discovery
```bash
# Automatically discover all local nodes
npm run dev:discover

# Or use the script directly
./scripts/discover-nodes.sh --auto-discover
```

#### Approach 4: Create New Node
```bash
# Create a new custom node
npm run dev:create-node myapi

# This creates the node structure and initializes git repository
```

### 🚀 Production Deployment Workflow

#### 1. Publish Nodes to npm
```bash
# Publish all custom nodes to npm
npm run publish:nodes
```

#### 2. Deploy to VPS
```bash
# Option A: Use the deployment script
./scripts/deploy-vps.sh

# Option B: Use npm scripts
npm run vps:deploy
```

---

## 📋 Available Commands

### Basic n8n Management
| Command | Description |
|---------|-------------|
| `npm start` | Start n8n in background |
| `npm run dev` | Start n8n in foreground (with logs) |
| `npm run stop` | Stop n8n |
| `npm run restart` | Restart n8n |
| `npm run logs` | View logs |
| `npm run status` | Check container status |
| `npm run deploy` | Build and start (production) |
| `npm run update` | Update to latest n8n version |
| `npm run backup` | Backup your n8n data |
| `npm run clean` | Clean up containers and volumes |

### Custom Node Management
| Command | Description |
|---------|-------------|
| `npm run dev:install` | Install nodes for local development |
| `npm run dev:discover` | Auto-discover and install local nodes |
| `npm run dev:create-node <name>` | Create a new custom node |
| `npm run dev:publish` | Publish nodes to npm |
| `npm run dev:deploy` | Deploy to VPS |
| `npm run docker:install` | Run Docker entrypoint script |

### Node Discovery Script
| Command | Description |
|---------|-------------|
| `./scripts/discover-nodes.sh --auto-discover` | Auto-discover local nodes |
| `./scripts/discover-nodes.sh --config <file>` | Use configuration file |
| `./scripts/discover-nodes.sh --local-path <path>` | Custom local path |

### Node Repository Management
| Command | Description |
|---------|-------------|
| `npm run dev:manage-repos list` | List all custom nodes and their status |
| `npm run dev:manage-repos init <name> <url>` | Initialize new node with repository |
| `npm run dev:manage-repos connect <name> <url>` | Connect existing node to repository |
| `npm run dev:manage-repos exclude <name>` | Exclude node from main repository |
| `npm run dev:manage-repos include <name>` | Include node in main repository |

---

## ⚙️ Configuration

### Environment Variables
Copy `env.example` to `.env` and configure:

```bash
# Required settings
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=your_secure_password

# n8n Configuration
N8N_HOST=localhost
N8N_PORT=5678
WEBHOOK_URL=http://localhost:5678/

# Custom Nodes Configuration
CUSTOM_NODES=pulseapi
CUSTOM_NODES_SOURCE=local
CUSTOM_NODES_GITHUB_ORG=your-org
CUSTOM_NODES_NPM_SCOPE=@your-scope
```

### Production Deployment
For production, update these variables:
- `N8N_HOST` - Your domain name
- `WEBHOOK_URL` - Your domain with protocol
- `N8N_BASIC_AUTH_PASSWORD` - Use a strong password

---

## 🔧 Development

### Node.js Version
This project uses Node.js 18.19.0. If you have nvm installed:
```bash
nvm use
```

### Custom Node Development
```bash
# Auto-discover and install local nodes
npm run dev:discover

# Create a new custom node
npm run dev:create-node myapi

# Start n8n with custom nodes
npm start
```

### Node Management
```bash
# Use environment variables
CUSTOM_NODES=pulseapi npm start

# Use configuration file
NODES_CONFIG_FILE=nodes-config.json ./scripts/discover-nodes.sh

# Auto-discover all local nodes
./scripts/discover-nodes.sh --auto-discover
```

### Manual Docker Commands
```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f n8n

# Stop services
docker-compose down
```

---

## 🚀 VPS Deployment

### Automated Deployment
```bash
# Deploy to VPS with custom nodes
./scripts/deploy-vps.sh
```

### Manual Deployment
```bash
# 1. Publish custom nodes
npm run publish:nodes

# 2. Deploy n8n
npm run vps:install
```

### VPS Requirements
- Ubuntu 18.04+ or Debian 10+
- Node.js 18+
- 2GB RAM minimum
- 10GB disk space

---

## 📁 Project Structure
```
n8n-docker-setup/
├── docker-compose.yml    # Docker configuration
├── env.example          # Environment template
├── package.json         # NPM scripts and metadata
├── .nvmrc              # Node.js version
├── LICENSE             # MIT License
├── README.md           # This file
├── wiki/               # Documentation
│   └── CUSTOM_NODES_APPROACHES.md # Custom node approaches
├── scripts/            # Bash scripts
│   ├── install-nodes.sh # Local installation
│   ├── docker-entrypoint.sh # Docker installation
│   ├── discover-nodes.sh # Node discovery
│   ├── create-node-repo.sh # Node creation
│   ├── publish-nodes.sh # npm publishing
│   └── deploy-vps.sh   # VPS deployment
└── nodes/              # Custom nodes directory
    └── pulseapi-n8n-node/ # PulseAPI integration node (cloned from GitHub)
```

---

## 📚 Documentation

- [Custom Nodes Approaches](wiki/CUSTOM_NODES_APPROACHES.md) - Complete guide to managing custom nodes without .gitmodules
- [n8n Node Development](https://docs.n8n.io/integrations/creating-nodes/) - Official n8n documentation

---

## 🤝 Contributing
1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

---

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
