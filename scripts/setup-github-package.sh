#!/bin/bash

# GitHub Package Setup Script for Backstage ULP
# This script helps you set up GitHub Container Registry permissions

set -e

echo "📦 Setting up GitHub Container Registry for Backstage ULP..."

# Configuration
PACKAGE_NAME="backstage-ulp"
REGISTRY="ghcr.io"
REPO_OWNER="pdaxh"

echo "🔍 Checking GitHub CLI installation..."
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed."
    echo "Please install it from: https://cli.github.com/"
    exit 1
fi

echo "🔐 Checking GitHub authentication..."
if ! gh auth status &> /dev/null; then
    echo "❌ Not authenticated with GitHub CLI."
    echo "Please run: gh auth login"
    exit 1
fi

echo "✅ GitHub CLI is authenticated"

# Check if package exists
echo "🔍 Checking if package exists..."
if gh api "user/packages/container/${PACKAGE_NAME}" &> /dev/null; then
    echo "✅ Package ${PACKAGE_NAME} exists"
else
    echo "⚠️  Package ${PACKAGE_NAME} does not exist yet"
    echo "It will be created automatically on first push"
fi

# Check repository permissions
echo "🔍 Checking repository permissions..."
REPO_PERMISSIONS=$(gh api "repos/${REPO_OWNER}/${PACKAGE_NAME}" --jq '.permissions' 2>/dev/null || echo "{}")

if echo "$REPO_PERMISSIONS" | jq -e '.admin' > /dev/null; then
    echo "✅ You have admin permissions on the repository"
else
    echo "⚠️  You may not have admin permissions on the repository"
    echo "Make sure you have write access to the repository"
fi

# Check package visibility and permissions
echo "🔍 Checking package visibility..."
PACKAGE_INFO=$(gh api "user/packages/container/${PACKAGE_NAME}" --jq '.visibility' 2>/dev/null || echo "null")

if [ "$PACKAGE_INFO" != "null" ]; then
    echo "📦 Package visibility: $PACKAGE_INFO"
    
    if [ "$PACKAGE_INFO" = "private" ]; then
        echo "🔒 Package is private - only you can access it"
    elif [ "$PACKAGE_INFO" = "public" ]; then
        echo "🌐 Package is public - anyone can access it"
    fi
else
    echo "⚠️  Could not determine package visibility"
fi

# Provide setup instructions
echo ""
echo "📋 Setup Instructions:"
echo "====================="
echo ""
echo "1. **Repository Settings**:"
echo "   - Go to: https://github.com/${REPO_OWNER}/${PACKAGE_NAME}/settings"
echo "   - Ensure 'Actions' is enabled"
echo "   - Check 'Workflow permissions' allows 'Read and write permissions'"
echo ""
echo "2. **Package Permissions**:"
echo "   - Go to: https://github.com/${REPO_OWNER}/${PACKAGE_NAME}/packages"
echo "   - Or: https://github.com/${REPO_OWNER}/${PACKAGE_NAME}/settings/packages"
echo "   - Ensure the repository has access to the package"
echo ""
echo "3. **GitHub Token Permissions**:"
echo "   - Go to: https://github.com/settings/tokens"
echo "   - Check that your token has 'write:packages' scope"
echo "   - Or use the built-in GITHUB_TOKEN (recommended)"
echo ""
echo "4. **Test the Setup**:"
echo "   - Push a change to trigger the workflow"
echo "   - Check the Actions tab for workflow status"
echo "   - Verify the package is created/updated"
echo ""

# Test workflow trigger
echo "🚀 Testing workflow trigger..."
echo "You can trigger the workflow by:"
echo "1. Making a change to the backstage/ directory"
echo "2. Pushing to main or develop branch"
echo "3. Or manually triggering from the Actions tab"
echo ""

# Show current workflow status
echo "📊 Current Workflow Status:"
echo "=========================="
if gh api "repos/${REPO_OWNER}/${PACKAGE_NAME}/actions/runs" --jq '.workflow_runs[0] | {status: .status, conclusion: .conclusion, created_at: .created_at, html_url: .html_url}' 2>/dev/null; then
    echo ""
    echo "View all runs: https://github.com/${REPO_OWNER}/${PACKAGE_NAME}/actions"
else
    echo "❌ Could not fetch workflow status"
fi

echo ""
echo "✅ Setup check complete!"
echo "If you're still having issues, check the GitHub Actions logs for detailed error messages."
