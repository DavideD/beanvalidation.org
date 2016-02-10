#!/bin/bash
# Make sure the staging branch is in sync with its remote
git reset --hard origin/staging
git clean -fdx

# Remove all generated files and directories
rake clean

# Make sure there was no update to the used dependencies (if not, this is just a quick version check for Bundler)
rake setup

# Build the site using the staging profile and sync
rake --trace gen[staging]

rsync --delete -avh _site/ 54.174.65.136:/var/www/staging-beanvalidation.org
