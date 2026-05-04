#!/bin/bash
# Exit on error
set -e

echo "Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

echo "Preparing CodeFormer..."
cd ai-service

if [ ! -d "CodeFormer" ]; then
    echo "Cloning CodeFormer repository..."
    git clone https://github.com/sczhou/CodeFormer.git
fi

echo "Build complete."
