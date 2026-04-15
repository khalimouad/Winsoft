#!/bin/bash
set -e

# Install Flutter if not already present
if [ ! -d "flutter" ]; then
  echo "Cloning Flutter stable..."
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable flutter
fi

export PATH="$PATH:$PWD/flutter/bin"

# Disable analytics and accept license silently
flutter config --no-analytics
echo "y" | flutter doctor --android-licenses 2>/dev/null || true

# Enable web support
flutter config --enable-web

# Fetch dependencies
flutter pub get

# Build for web (release, tree-shaken)
flutter build web --release --web-renderer canvaskit
