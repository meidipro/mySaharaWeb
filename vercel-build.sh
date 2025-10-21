#!/bin/sh
# This script tells Vercel how to build the Flutter web app.
# It will exit immediately if any command fails.
set -e

# 1. Install the Flutter SDK
echo "--- Cloning Flutter SDK --- "
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# 2. Verify Flutter installation
flutter --version

# 3. Navigate into the app directory, get dependencies, and build
echo "--- Entering app directory --- "
cd my_sahara_app

echo "--- Getting Flutter dependencies --- "
flutter pub get

echo "--- Building Flutter web app --- "
flutter build web --release

echo "--- Build Complete --- "
