#!/bin/bash
set -e

echo "------------------------------------------------"
echo "   Synthora AI Service: AI Model Setup"
echo "------------------------------------------------"

# 1. Create venv if not exists
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi
source venv/bin/activate

# 2. Install pip requirements
echo "Installing dependencies (torch, basicsr, facexlib...)"
pip install --upgrade pip
pip install -r requirements.txt

# 3. Clone CodeFormer if missing
if [ ! -d "CodeFormer" ]; then
    echo "Cloning CodeFormer repository..."
    git clone https://github.com/sczhou/CodeFormer.git
fi

# 4. Download Weights
echo "Checking for model weights..."
WEIGHTS_DIR="CodeFormer/weights/codeformer.pth"
if [ ! -f "$WEIGHTS_DIR" ]; then
    echo "Model weights missing! You need to download codeformer.pth"
    echo "Please download it from: https://github.com/sczhou/CodeFormer/releases/download/v0.1.0/codeformer.pth"
    echo "And place it in: ai-service/CodeFormer/weights/codeformer.pth"
fi

echo "------------------------------------------------"
echo "Setup complete. If weights are missing, the server will run in MOCK mode."
echo "------------------------------------------------"
