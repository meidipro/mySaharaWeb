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

# 3. Get dependencies and build (we're already in the app directory)
echo "--- Getting Flutter dependencies --- "
flutter pub get

echo "--- Building Flutter web app --- "
flutter build web --release --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY --dart-define=WEB_VIEWER_URL=$WEB_VIEWER_URL

echo "--- Build Complete --- "
