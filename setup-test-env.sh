#!/bin/bash

set -e

# Clone the test repository
if [ -d "test-workspace" ]; then
    echo "Test workspace already exists. Pulling latest changes..."
    cd test-workspace
    git pull
    cd ..
else
    echo "Cloning test workspace..."
    git clone --depth=1 https://github.com/janeczku/calibre-web.git test-workspace
fi

echo "Test environment is ready in the 'test-workspace' directory."
