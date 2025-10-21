#!/bin/bash
# mySahara Web Deployment Script

echo "🚀 mySahara Flutter Web Deployment"
echo "==================================="
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Error: Flutter is not installed or not in PATH"
    exit 1
fi

echo "✅ Flutter found: $(flutter --version | head -1)"
echo ""

# Clean previous build
echo "🧹 Cleaning previous build..."
flutter clean
echo ""

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get
echo ""

# Build for web
echo "🔨 Building Flutter web (release mode)..."
flutter build web --release
echo ""

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo ""
    echo "📁 Build output: build/web/"
    echo ""
    
    # Check if Vercel CLI is installed
    if command -v vercel &> /dev/null; then
        echo "🌐 Vercel CLI found!"
        read -p "Do you want to deploy to Vercel now? (y/n) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "🚀 Deploying to Vercel..."
            vercel --cwd build/web --prod
        else
            echo "ℹ️  To deploy later, run: vercel --cwd build/web --prod"
        fi
    else
        echo "ℹ️  Vercel CLI not found. Install with: npm install -g vercel"
        echo "ℹ️  Then deploy with: vercel --cwd build/web --prod"
    fi
    
    echo ""
    echo "✅ Deployment ready!"
    echo "📖 See FLUTTER_WEB_DEPLOYMENT.md for detailed instructions"
else
    echo "❌ Build failed! Check errors above."
    exit 1
fi
