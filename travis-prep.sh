#!/usr/bin/env bash

# ############################################################
# Setup

# Make sure we know where we are
PROJECT_ROOT=`pwd`

# Fail fast
set -e

# ############################################################
# Test database

echo "Initializing database:"
set -x
mysql -u root -e 'CREATE DATABASE IF NOT EXISTS mrt_tind_harvester_test CHARACTER SET utf8'
mysql -u root -e 'CREATE USER IF NOT EXISTS travis@localhost'
mysql -u root -e 'GRANT ALL ON mrt_tind_harvester_test.* TO travis@localhost'
{ set +x; } 2>/dev/null

# ############################################################
# Load database schema

bundle exec rake db:schema:load
