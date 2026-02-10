#!/bin/bash

# Script to manually package and publish Helm chart to gh-pages branch

set -e

CHART_NAME="nucleus"
REPO_URL="https://flawlessbyte.github.io/nucleus"
PACKAGES_DIR="./packages"
GH_PAGES_BRANCH="gh-pages"

echo "📦 Packaging Helm chart..."

# Clean up old packages
rm -rf ${PACKAGES_DIR}
mkdir -p ${PACKAGES_DIR}

# Lint the chart
echo "🔍 Linting chart..."
helm lint .

# Package the chart
echo "📦 Packaging chart..."
helm package . --destination ${PACKAGES_DIR}

# Generate index.yaml
echo "📝 Generating index.yaml..."
helm repo index ${PACKAGES_DIR} --url ${REPO_URL}

# Get the packaged chart filename
CHART_FILE=$(ls -1 ${PACKAGES_DIR}/*.tgz | head -1)
CHART_FILENAME=$(basename ${CHART_FILE})

echo "✅ Chart packaged: ${CHART_FILENAME}"

# Checkout gh-pages branch
echo "🌿 Checking out ${GH_PAGES_BRANCH} branch..."
if git show-ref --verify --quiet refs/heads/${GH_PAGES_BRANCH}; then
    git checkout ${GH_PAGES_BRANCH}
    git pull origin ${GH_PAGES_BRANCH} 2>/dev/null || true
else
    # Create orphan branch if it doesn't exist
    git checkout --orphan ${GH_PAGES_BRANCH}
    git rm -rf . 2>/dev/null || true
fi

# Copy chart and index
echo "📋 Copying chart and index..."
cp ${PACKAGES_DIR}/${CHART_FILENAME} .
cp ${PACKAGES_DIR}/index.yaml .

# Add and commit
echo "💾 Committing changes..."
git add ${CHART_FILENAME} index.yaml
git commit -m "Add ${CHART_FILENAME}" || echo "No changes to commit"

# Push to remote
echo "🚀 Pushing to origin/${GH_PAGES_BRANCH}..."
git push origin ${GH_PAGES_BRANCH}

# Switch back to main
echo "🔄 Switching back to main branch..."
git checkout main

echo ""
echo "✅ Done! Chart published to ${GH_PAGES_BRANCH} branch"
echo "📦 Chart: ${CHART_FILENAME}"
echo "🔗 Repository URL: ${REPO_URL}"
echo ""
echo "Users can now add the repository with:"
echo "  helm repo add nucleus ${REPO_URL}"
echo "  helm repo update"

