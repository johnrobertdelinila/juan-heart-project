#!/bin/bash

# Juan Heart iOS Clean Rebuild Script
# This script performs a complete clean build for iOS

echo "🧹 Starting clean rebuild process..."
echo ""

# Step 1: Flutter clean
echo "📦 Step 1/5: Cleaning Flutter build cache..."
flutter clean
echo "✅ Flutter clean complete"
echo ""

# Step 2: Remove .dart_tool
echo "🗑️  Step 2/5: Removing .dart_tool..."
rm -rf .dart_tool
echo "✅ .dart_tool removed"
echo ""

# Step 3: Get dependencies
echo "📥 Step 3/5: Getting Flutter dependencies..."
flutter pub get
echo "✅ Dependencies installed"
echo ""

# Step 4: Clean iOS pods
echo "🍎 Step 4/5: Cleaning and reinstalling iOS pods..."
cd ios
rm -rf Pods Podfile.lock .symlinks
pod install
cd ..
echo "✅ Pods reinstalled"
echo ""

# Step 5: Build for device
echo "🚀 Step 5/5: Building app for iPhone..."
flutter build ios --release
echo ""

echo "✅ Build complete!"
echo ""
echo "📱 Now you can run: flutter run --release"
echo "   Or open Xcode and run from there"
echo ""
