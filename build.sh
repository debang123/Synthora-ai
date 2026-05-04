#!/bin/bash

# Exit on error
set -e

echo "Checking for Flutter..."
if [ ! -d "flutter" ]; then
  echo "Cloning Flutter stable branch..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
else
  echo "Flutter already exists, skipping clone."
fi

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
