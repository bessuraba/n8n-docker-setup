# n8n Docker Setup 🚀

This repository contains a **ready-to-deploy setup for n8n**, the open-source workflow automation tool.  
You can run it locally for development or deploy it to a VPS for production.

---

## 📂 Features
✅ Docker-based setup (portable & easy)  
✅ Basic authentication enabled by default  
✅ Environment variables managed with `.env`  
✅ Persists workflows & credentials via a Docker volume  
✅ Ready for VPS deployment  
✅ NPM scripts for easy management  
✅ Node.js version management with `.nvmrc`  

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

## 📋 Available Commands

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

---

## ⚙️ Configuration

### Environment Variables
Copy `env.example` to `.env` and configure:

```bash
# Required settings
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=your_secure_password

# Optional settings
N8N_HOST=localhost
N8N_PORT=5678
WEBHOOK_URL=http://localhost:5678/
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

## 📁 Project Structure
```
n8n-docker-setup/
├── docker-compose.yml    # Docker configuration
├── env.example          # Environment template
├── package.json         # NPM scripts and metadata
├── .nvmrc              # Node.js version
├── LICENSE             # MIT License
└── README.md           # This file
```

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
