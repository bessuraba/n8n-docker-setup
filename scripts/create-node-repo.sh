#!/bin/bash

# Script to create a new custom n8n node repository
# This helps maintain separation between parent and child repos

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 <node-name> [github-org]"
    echo "Example: $0 my-custom-node my-org"
    exit 1
fi

NODE_NAME="$1"
GITHUB_ORG="${2:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🚀 Creating new custom n8n node: $NODE_NAME"

# Create node directory
NODE_DIR="$PROJECT_ROOT/nodes/$NODE_NAME"
if [ -d "$NODE_DIR" ]; then
    echo "❌ Node directory already exists: $NODE_DIR"
    exit 1
fi

mkdir -p "$NODE_DIR"
cd "$NODE_DIR"

# Initialize git repository
git init

# Create package.json
cat > package.json << EOF
{
  "name": "n8n-nodes-$NODE_NAME",
  "version": "1.0.0",
  "description": "Custom n8n node for $NODE_NAME",
  "keywords": [
    "n8n",
    "n8n-node",
    "n8n-custom-node",
    "$NODE_NAME"
  ],
  "license": "MIT",
  "homepage": "",
  "author": {
    "name": "Your Name",
    "email": "your.email@example.com"
  },
  "repository": {
    "type": "git",
    "url": "git+https://github.com/${GITHUB_ORG:-your-org}/n8n-nodes-$NODE_NAME.git"
  },
  "main": "index.js",
  "scripts": {
    "build": "tsc && gulp build:icons",
    "dev": "tsc --watch",
    "format": "prettier nodes credentials --write",
    "lint": "eslint nodes credentials package.json",
    "lintfix": "eslint nodes credentials package.json --fix",
    "prepublishOnly": "npm run build && npm run lint -c .eslintrc.prepublish.js nodes credentials package.json"
  },
  "files": [
    "dist"
  ],
  "n8n": {
    "n8nNodesApiVersion": 1,
    "nodes": [
      "dist/nodes/$NODE_NAME/$NODE_NAME.node.js"
    ]
  },
  "devDependencies": {
    "@types/express": "^4.17.6",
    "@types/request-promise-native": "~1.0.15",
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

# Create TypeScript configuration
mkdir -p src
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

# Create source directory structure
mkdir -p "src/nodes/$NODE_NAME"
mkdir -p "src/credentials"

# Create main node file
cat > "src/nodes/$NODE_NAME/$NODE_NAME.node.ts" << EOF
import { IExecuteFunctions } from 'n8n-core';
import {
	INodeExecutionData,
	INodeType,
	INodeTypeDescription,
} from 'n8n-workflow';

export class $NODE_NAME implements INodeType {
	description: INodeTypeDescription = {
		displayName: '$NODE_NAME',
		name: '$NODE_NAME',
		icon: 'file:$NODE_NAME.svg',
		group: ['transform'],
		version: 1,
		description: 'Custom node for $NODE_NAME',
		defaults: {
			name: '$NODE_NAME',
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

# Create SVG icon placeholder
cat > "src/nodes/$NODE_NAME/$NODE_NAME.svg" << EOF
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <circle cx="12" cy="12" r="10"/>
  <path d="M8 14s1.5 2 4 2 4-2 4-2"/>
  <line x1="9" y1="9" x2="9.01" y2="9"/>
  <line x1="15" y1="9" x2="15.01" y2="9"/>
</svg>
EOF

# Create README
cat > README.md << EOF
# $NODE_NAME Node for n8n

This is a custom n8n node for $NODE_NAME.

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

# Initialize git and make initial commit
git add .
git commit -m "Initial commit: $NODE_NAME custom n8n node"

echo "✅ Created custom node: $NODE_NAME"
echo "📁 Location: $NODE_DIR"
echo ""
echo "Next steps:"
echo "1. cd $NODE_DIR"
echo "2. npm install"
echo "3. Implement your node logic in src/nodes/$NODE_NAME/$NODE_NAME.node.ts"
echo "4. Test your node"
echo "5. Push to your repository"

if [ -n "$GITHUB_ORG" ]; then
    echo ""
    echo "To create GitHub repository:"
    echo "gh repo create $GITHUB_ORG/n8n-nodes-$NODE_NAME --private --source=$NODE_DIR"
fi 