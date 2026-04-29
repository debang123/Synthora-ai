#!/bin/bash

echo "------------------------------------------------"
echo "   Synthora AI: Unified Backend Launcher"
echo "------------------------------------------------"

# Check for python3
if ! command -v python3 &> /dev/null
then
    echo "ERROR: python3 could not be found. Please install Python."
    exit
fi

echo "1. Checking dependencies..."
python3 -c "import fastapi, uvicorn, cv2, numpy" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "Installing missing dependencies..."
    pip install fastapi uvicorn opencv-python numpy python-multipart
fi

echo "2. Starting Unified Backend on http://127.0.0.1:5001"
echo "   (This server handles Auth, API, and AI processing)"
echo ""
echo "   To view the frontend, open this file in your browser:"
echo "   file://$(pwd)/demo/index.html"
echo ""
echo "------------------------------------------------"

python3 unified_backend.py
