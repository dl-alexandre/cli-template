#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Template placeholders
DEFAULT_OWNER="yourusername"
DEFAULT_APPNAME="mycli"
DEFAULT_DESCRIPTION="A modern Go CLI application"

# Get new values from user
echo -e "${GREEN}=== Go CLI Template Setup ===${NC}"
echo ""

# GitHub/GitLab username
read -p "GitHub/GitLab username/organization [$DEFAULT_OWNER]: " owner
owner=${owner:-$DEFAULT_OWNER}

# Application name
read -p "Application name (single word, lowercase) [$DEFAULT_APPNAME]: " appname
appname=${appname:-$DEFAULT_APPNAME}

# Repository name
read -p "Repository name (usually '${appname}' or '${appname}-cli') [${appname}]: " reponame
reponame=${reponame:-$appname}

# Description
read -p "Short description [$DEFAULT_DESCRIPTION]: " description
description=${description:-$DEFAULT_DESCRIPTION}

echo ""
echo -e "${YELLOW}Setting up project with:${NC}"
echo "  Owner:        $owner"
echo "  App Name:     $appname"
echo "  Repo Name:    $reponame"
echo "  Description:  $description"
echo ""

# Confirmation
read -p "Is this correct? (y/N): " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo -e "${RED}Setup cancelled.${NC}"
    exit 1
fi

# Uppercase version for env var prefix
appname_upper=$(echo "$appname" | tr '[:lower:]' '[:upper:]')

echo ""
echo -e "${YELLOW}Replacing placeholders...${NC}"

# Function to replace in files
replace_in_files() {
    local placeholder="$1"
    local value="$2"
    
    # Find and replace in all files except this script
    find . -type f \
        -not -path "./.git/*" \
        -not -path "./scripts/setup.sh" \
        -not -path "./dist/*" \
        -not -path "./bin/*" \
        -exec grep -l "$placeholder" {} \; | while read -r file; do
        
        # Handle different OS sed commands
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' "s/$placeholder/$value/g" "$file"
        else
            # Linux
            sed -i "s/$placeholder/$value/g" "$file"
        fi
    done
}

# Replace placeholders
replace_in_files "{{OWNER}}" "$owner"
replace_in_files "{{APPNAME}}" "$appname"
replace_in_files "{{REPO_NAME}}" "$reponame"
replace_in_files "{{DESCRIPTION}}" "$description"

# Rename cmd directory
if [ -d "cmd/{{APPNAME}}" ]; then
    mv "cmd/{{APPNAME}}" "cmd/$appname"
    echo -e "${GREEN}Renamed cmd/{{APPNAME}} to cmd/$appname${NC}"
fi

echo ""
echo -e "${GREEN}Setup complete!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Initialize git repository: git init"
echo "  2. Add remote: git remote add origin https://github.com/$owner/$reponame.git"
echo "  3. Download dependencies: go mod download"
echo "  4. Install git hooks: make install-hooks"
echo "  5. Build and test: make build && make test"
echo "  6. Customize internal/api/client.go for your API"
echo "  7. Add your commands to internal/cli/cli.go"
echo ""
echo -e "${YELLOW}Optional:${NC}"
echo "  - Uncomment Homebrew section in .goreleaser.yml for tap releases"
echo "  - Uncomment Scoop section in .goreleaser.yml for Windows package manager"
echo "  - Update .github/workflows/*.yml with your repository information"
echo ""

# Remove setup script
read -p "Remove setup script? (y/N): " remove_script
if [[ $remove_script =~ ^[Yy]$ ]]; then
    rm "$0"
    echo -e "${GREEN}Setup script removed.${NC}"
fi

echo ""
echo -e "${GREEN}Happy coding! 🚀${NC}"
