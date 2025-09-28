#!/usr/bin/env bash
# exit on error
set -o errexit

# Install dependencies
bundle install

# Install Node.js and Yarn if not present
if ! command -v node &> /dev/null; then
  curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
  apt-get install -y nodejs
fi

if ! command -v yarn &> /dev/null; then
  npm install -g yarn@1.22.19
fi

# Install JavaScript dependencies
yarn install --check-files

# Precompile assets
bundle exec rails assets:precompile

# Clean up
bundle exec rails assets:clean

# Run database migrations
bundle exec rails db:migrate

# Run database seeds (create admin user)
bundle exec rails db:seed