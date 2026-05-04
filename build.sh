#!/bin/bash

# Exit on error
set -e

echo "Cloning Flutter stable branch..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1

# Add Flutter to the path
export PATH="$PATH:`pwd`/flutter/bin"

echo "Checking Flutter version..."
flutter --version

echo "Enabling Flutter Web..."
flutter config --enable-web

echo "Getting packages..."
flutter pub get

echo "Building Flutter Web App..."
flutter build web --release

echo "Build complete."
