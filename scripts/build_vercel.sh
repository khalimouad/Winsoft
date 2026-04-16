#!/bin/bash
set -e

if [ ! -d "flutter" ]; then
  echo "Cloning Flutter stable..."
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable flutter
fi

export PATH="$PATH:$PWD/flutter/bin"
flutter config --no-analytics
flutter pub get
flutter build web --release
