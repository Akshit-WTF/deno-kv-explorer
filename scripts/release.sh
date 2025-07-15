#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🚀 Release Script for deno-kv-explorer${NC}"
echo ""

# Check if we're on main branch
current_branch=$(git branch --show-current)
if [ "$current_branch" != "main" ]; then
    echo -e "${RED}❌ Please switch to main branch before releasing${NC}"
    echo "Current branch: $current_branch"
    exit 1
fi

# Check for uncommitted changes
if [[ -n $(git status -s) ]]; then
    echo -e "${RED}❌ You have uncommitted changes. Please commit or stash them first.${NC}"
    git status -s
    exit 1
fi

# Pull latest changes
echo -e "${YELLOW}📥 Pulling latest changes...${NC}"
git pull origin main

# Check if npm is logged in
if ! npm whoami > /dev/null 2>&1; then
    echo -e "${RED}❌ You are not logged in to npm. Please run 'npm login' first.${NC}"
    exit 1
fi

# Ask for version type
echo -e "${YELLOW}📝 What type of release is this?${NC}"
PS3="Please select: "
options=("patch" "minor" "major" "quit")
select version_type in "${options[@]}"; do
    case $version_type in
        "patch"|"minor"|"major")
            break
            ;;
        "quit")
            echo "Release cancelled."
            exit 0
            ;;
        *) 
            echo "Please select a valid option."
            ;;
    esac
done

# Get current version
current_version=$(node -p "require('./package.json').version")
echo -e "${BLUE}Current version: ${current_version}${NC}"

# Calculate new version (preview)
case $version_type in
    "patch")
        new_version=$(node -p "
            const v = require('./package.json').version.split('.');
            v[2] = parseInt(v[2]) + 1;
            v.join('.');
        ")
        ;;
    "minor")
        new_version=$(node -p "
            const v = require('./package.json').version.split('.');
            v[1] = parseInt(v[1]) + 1;
            v[2] = '0';
            v.join('.');
        ")
        ;;
    "major")
        new_version=$(node -p "
            const v = require('./package.json').version.split('.');
            v[0] = parseInt(v[0]) + 1;
            v[1] = '0';
            v[2] = '0';
            v.join('.');
        ")
        ;;
esac

echo -e "${GREEN}New version will be: ${new_version}${NC}"
echo ""

# Confirm release
read -p "$(echo -e ${YELLOW}Are you sure you want to release v${new_version}? [y/N]: ${NC})" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Release cancelled."
    exit 0
fi

echo ""
echo -e "${YELLOW}🔄 Starting release process...${NC}"

# Update version
echo -e "${YELLOW}📝 Updating version in package.json...${NC}"
npm version $version_type --no-git-tag-version

# Verify version was updated
actual_new_version=$(node -p "require('./package.json').version")
echo -e "${GREEN}✅ Version updated to: ${actual_new_version}${NC}"

# Commit changes
echo -e "${YELLOW}💾 Committing version bump...${NC}"
git add package.json
git commit -m "chore: bump version to ${actual_new_version}"

# Create and push tag
echo -e "${YELLOW}🏷️ Creating and pushing tag...${NC}"
git tag "v${actual_new_version}"
git push origin main
git push origin "v${actual_new_version}"

echo ""
echo -e "${GREEN}✅ Release v${actual_new_version} has been created!${NC}"
echo -e "${YELLOW}🔗 GitHub Actions will automatically:${NC}"
echo -e "   - Run tests and validation"
echo -e "   - Publish to npm registry"
echo -e "   - Build and push Docker images to GHCR"
echo -e "   - Create GitHub release with changelog"
echo ""
echo -e "${YELLOW}📦 Monitor progress at:${NC}"
echo -e "   ${BLUE}https://github.com/akshit-wtf/deno-kv-explorer/actions${NC}"
echo ""
echo -e "${YELLOW}📋 After publishing, your package will be available as:${NC}"
echo -e "   ${GREEN}bunx deno-kv-explorer${NC}"
echo -e "   ${GREEN}npx deno-kv-explorer${NC}"
echo -e "   ${GREEN}npm install -g deno-kv-explorer${NC}"
echo ""
echo -e "${YELLOW}🐳 Docker image will be available at:${NC}"
echo -e "   ${GREEN}ghcr.io/akshit-wtf/deno-kv-explorer:${actual_new_version}${NC}"
echo -e "   ${GREEN}ghcr.io/akshit-wtf/deno-kv-explorer:latest${NC}"
