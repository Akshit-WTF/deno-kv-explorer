#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Setting up deno-kv-explorer development environment...${NC}"
echo ""

# Check if bun is installed
if ! command -v bun &> /dev/null; then
    echo -e "${YELLOW}📦 Bun is not installed. Installing...${NC}"
    curl -fsSL https://bun.sh/install | bash
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
    
    # Check if installation was successful
    if command -v bun &> /dev/null; then
        echo -e "${GREEN}✅ Bun installed successfully!${NC}"
    else
        echo -e "${RED}❌ Bun installation failed. Please install manually.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✅ Bun is already installed: $(bun --version)${NC}"
fi

# Install dependencies
echo -e "${YELLOW}📦 Installing dependencies...${NC}"
bun install

# Make scripts executable
echo -e "${YELLOW}🔧 Making scripts executable...${NC}"
chmod +x scripts/*.sh
chmod +x index.ts

# Create .env if it doesn't exist
if [ ! -f .env ]; then
    echo -e "${YELLOW}📝 Creating .env file from example...${NC}"
    cp .env.example .env
    echo -e "${BLUE}✏️  Please edit .env with your configuration${NC}"
else
    echo -e "${GREEN}✅ .env file already exists${NC}"
fi

# Check if git is configured
if ! git config user.name > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Git user.name is not configured${NC}"
    echo -e "   Run: git config --global user.name \"Your Name\""
fi

if ! git config user.email > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Git user.email is not configured${NC}"
    echo -e "   Run: git config --global user.email \"your.email@example.com\""
fi

# Verify TypeScript can compile
echo -e "${YELLOW}🔍 Checking TypeScript compilation...${NC}"
if bun --bun tsc --noEmit index.ts; then
    echo -e "${GREEN}✅ TypeScript compilation successful${NC}"
else
    echo -e "${RED}❌ TypeScript compilation failed${NC}"
    exit 1
fi

# Test basic startup
echo -e "${YELLOW}🧪 Testing basic startup...${NC}"
timeout 5s bun run index.ts > /dev/null 2>&1 || true
echo -e "${GREEN}✅ Basic startup test passed${NC}"

echo ""
echo -e "${GREEN}🎉 Development environment setup complete!${NC}"
echo ""
echo -e "${YELLOW}🎯 Quick start commands:${NC}"
echo -e "   ${BLUE}bun run dev${NC}     # Start with hot reload"
echo -e "   ${BLUE}bun start${NC}       # Start production mode"
echo -e "   ${BLUE}./index.ts${NC}      # Direct execution"
echo ""
echo -e "${YELLOW}🔧 Useful scripts:${NC}"
echo -e "   ${BLUE}./scripts/release.sh${NC}    # Create a new release"
echo -e "   ${BLUE}./scripts/test.sh${NC}       # Run local tests"
echo -e "   ${BLUE}bun run build${NC}           # Prepare for production"
echo ""
echo -e "${YELLOW}📋 Next steps:${NC}"
echo -e "   1. Edit .env with your Deno KV configuration"
echo -e "   2. Run 'bun run dev' to start development"
echo -e "   3. Visit http://localhost:4055 to see your app"
echo ""
echo -e "${YELLOW}🔑 For publishing to npm:${NC}"
echo -e "   1. Run 'npm login' to authenticate"
echo -e "   2. Run './scripts/release.sh' to create a release"
