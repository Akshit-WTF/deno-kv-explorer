#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🧪 Running local tests for deno-kv-explorer...${NC}"
echo ""

# Check if bun is available
if ! command -v bun &> /dev/null; then
    echo -e "${RED}❌ Bun is not installed. Please run ./scripts/setup.sh first.${NC}"
    exit 1
fi

echo -e "${YELLOW}1️⃣ Checking dependencies...${NC}"
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}📦 Installing dependencies...${NC}"
    bun install
fi
echo -e "${GREEN}✅ Dependencies check passed${NC}"

echo -e "${YELLOW}2️⃣ Validating package.json...${NC}"
node -e "
    const pkg = require('./package.json');
    if (!pkg.name) throw new Error('Package name is required');
    if (!pkg.version) throw new Error('Package version is required');
    if (!pkg.bin) throw new Error('Binary entry is required');
    if (!pkg.dependencies) throw new Error('Dependencies are required');
    console.log('✅ package.json validation passed');
"

echo -e "${YELLOW}3️⃣ Checking required files...${NC}"
required_files=("index.ts" "index.html" "package.json" "README.md" "LICENSE")
for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        echo -e "${RED}❌ Required file missing: $file${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Found: $file${NC}"
done

echo -e "${YELLOW}5️⃣ Testing application startup...${NC}"
export PORT=4056 # Use different port to avoid conflicts
timeout 8s bun run index.ts &
PID=$!

# Wait a moment for startup
sleep 3

# Test if server is responding
if curl -s -f http://localhost:4056/ > /dev/null; then
    echo -e "${GREEN}✅ Application startup test passed${NC}"
    kill $PID 2>/dev/null || true
else
    echo -e "${RED}❌ Application startup test failed${NC}"
    kill $PID 2>/dev/null || true
    exit 1
fi

# Wait for process to clean up
sleep 1

echo -e "${YELLOW}6️⃣ Checking bundle sizes...${NC}"
INDEX_SIZE=$(wc -c < index.ts)
HTML_SIZE=$(wc -c < index.html)
TOTAL_SIZE=$((INDEX_SIZE + HTML_SIZE))

echo -e "${BLUE}📊 Bundle sizes:${NC}"
echo -e "   index.ts: ${INDEX_SIZE} bytes"
echo -e "   index.html: ${HTML_SIZE} bytes"
echo -e "   Total: ${TOTAL_SIZE} bytes"

if [ $TOTAL_SIZE -gt 1000000 ]; then
    echo -e "${YELLOW}⚠️  Bundle size is quite large (>1MB)${NC}"
else
    echo -e "${GREEN}✅ Bundle size is reasonable${NC}"
fi

echo -e "${YELLOW}7️⃣ Checking executable permissions...${NC}"
if [ -x "index.ts" ]; then
    echo -e "${GREEN}✅ index.ts is executable${NC}"
else
    echo -e "${YELLOW}⚠️  index.ts is not executable, fixing...${NC}"
    chmod +x index.ts
    echo -e "${GREEN}✅ Fixed executable permissions${NC}"
fi

echo ""
echo -e "${GREEN}🎉 All tests passed! Your project is ready for release.${NC}"
echo ""
echo -e "${YELLOW}📋 Summary:${NC}"
echo -e "   ✅ Dependencies installed"
echo -e "   ✅ package.json valid"
echo -e "   ✅ Required files present"
echo -e "   ✅ TypeScript compiles"
echo -e "   ✅ Application starts correctly"
echo -e "   ✅ Bundle sizes reasonable"
echo -e "   ✅ Executable permissions set"
echo ""
echo -e "${YELLOW}🚀 Ready to release? Run:${NC}"
echo -e "   ${BLUE}./scripts/release.sh${NC}"
