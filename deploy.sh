#!/bin/bash

# Function to parse output-dir from _quarto.yml
get_output_dir() {
    # Default output directory is _site
    local output_dir="_site"
    echo "Checking for custom output directory in _quarto.yml..."
    # Check if _quarto.yml exists and extract output-dir if specified
    if [[ -f "_quarto.yml" ]]; then
        # Extract the line containing output-dir and then extract the actual path
        output_dir=$(grep 'output-dir:' _quarto.yml | cut -d ":" -f2 | xargs)
    fi
    if [[ -z "$output_dir" ]]; then
        output_dir="_site" # Fallback to default if output-dir is empty
    fi
    echo "Using output directory: $output_dir"
    echo $output_dir
}

# Render the Quarto project
echo "Rendering the Quarto project..."
quarto render

# Get output directory from _quarto.yml
output_dir=$(get_output_dir)

# Stash all current changes in the working directory
echo "Stashing current changes..."
git stash push -m "Temporary stash before switching to gh-pages"

# Checkout gh-pages branch
echo "Switching to gh-pages branch..."
git checkout gh-pages

# Temporarily remove 'docs/' from .gitignore
echo "Updating .gitignore to track docs/ folder..."
sed -i '/docs\//d' .gitignore
git add .gitignore
git commit -m "Update .gitignore to track docs/"

# Pull the latest changes from gh-pages
echo "Pulling the latest changes from the remote gh-pages branch..."
git pull origin gh-pages --rebase

# Remove old contents (optional, be careful with this in the first run)
echo "Removing old content from gh-pages branch..."
git rm -rf .

# Copy new build from output directory to the root of the gh-pages branch
echo "Copying new content from $output_dir to gh-pages branch..."
cp -r ${output_dir}/* .

# Add the docs/ directory
echo "Adding docs/ folder..."
git add docs/

# Add changes to git
echo "Adding new files to gh-pages branch..."
git add .

# Commit changes
echo "Committing new site content..."
git commit -m "Update site content"

# Push to the gh-pages branch
echo "Pushing updates to GitHub..."
git push origin gh-pages

# Return to the main branch
echo "Switching back to the main branch..."
git checkout main

# Restore original .gitignore with docs/ ignored
echo "Restoring .gitignore in main branch..."
git checkout HEAD .gitignore

# Apply stashed changes (optional)
echo "Applying stashed changes..."
git stash pop

echo "Deployment to gh-pages completed successfully."
