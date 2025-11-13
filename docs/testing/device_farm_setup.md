# Device Farm Testing Setup Guide

## Overview

This guide explains how to set up and execute comprehensive device testing for Juan Heart Mobile using Firebase Test Lab and local device matrices. Device farm testing ensures broad compatibility across Android and iOS devices targeting the Philippine market.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Firebase Test Lab Setup](#firebase-test-lab-setup)
3. [Local Device Testing](#local-device-testing)
4. [Test Execution](#test-execution)
5. [Results Analysis](#results-analysis)
6. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Tools

1. **Flutter SDK** (3.0+)
   ```bash
   flutter --version
   ```

2. **Google Cloud SDK** (gcloud CLI)
   ```bash
   # Install on macOS
   brew install google-cloud-sdk

   # Install on Linux
   curl https://sdk.cloud.google.com | bash

   # Verify installation
   gcloud --version
   ```

3. **Firebase CLI**
   ```bash
   npm install -g firebase-tools
   firebase --version
   ```

4. **Android SDK** (for Android testing)
   - Android Studio or Android command-line tools
   - Emulator images for API 21, 23, 26, 29, 31, 33
   - Build tools and platform tools

5. **Xcode** (for iOS testing, macOS only)
   - Xcode 13.0+
   - iOS simulators for iOS 12.0, 13.0, 14.0, 15.0, 16.0

### Firebase Project Setup

1. **Create Firebase Project**
   ```bash
   # Login to Firebase
   firebase login

   # Initialize project
   firebase init
   ```

2. **Enable Test Lab**
   - Go to Firebase Console: https://console.firebase.google.com
   - Select your project
   - Navigate to Test Lab
   - Enable Test Lab API

3. **Configure Billing**
   - Test Lab requires a paid plan (Blaze)
   - Set up billing account
   - Configure spending limits if needed

4. **Authenticate gcloud**
   ```bash
   # Authenticate
   gcloud auth login

   # Set project
   gcloud config set project juan-heart-mobile

   # Verify
   gcloud config list
   ```

## Firebase Test Lab Setup

### 1. Configure Test Matrices

Edit `test_lab/test_config.yaml` to customize:
- Target devices
- Test types
- Timeout settings
- Environment variables

### 2. Build Application

**Android:**
```bash
# Build debug APK
flutter build apk --debug

# Build instrumentation test APK
cd android
./gradlew app:assembleDebugAndroidTest
cd ..
```

**iOS:**
```bash
# Build iOS app (macOS only)
flutter build ios --debug --no-codesign
```

### 3. Upload and Run Tests

**Using Script (Recommended):**
```bash
# Run all tests on all devices
./scripts/device_farm_test.sh

# Test specific platform
./scripts/device_farm_test.sh --platform android

# Test specific device category
./scripts/device_farm_test.sh --category low-end

# Test specific test type
./scripts/device_farm_test.sh --test performance

# Dry run (show what would be tested)
./scripts/device_farm_test.sh --dry-run
```

**Manual gcloud Commands:**

Android:
```bash
gcloud firebase test android run \
  --type instrumentation \
  --app build/app/outputs/flutter-apk/app-debug.apk \
  --test build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk \
  --device model=j2lte,version=21,locale=en,orientation=portrait \
  --device model=redfin,version=26,locale=en,orientation=portrait \
  --device model=panther,version=33,locale=en,orientation=portrait \
  --timeout 45m \
  --results-bucket=gs://juan-heart-mobile-test-results \
  --results-dir=android-$(date +%Y%m%d-%H%M%S)
```

iOS:
```bash
gcloud firebase test ios run \
  --test build/ios/iphoneos/Runner.app \
  --device model=iphone8,version=12.0,locale=en,orientation=portrait \
  --device model=iphone11,version=14.0,locale=en,orientation=portrait \
  --device model=iphone13,version=16.0,locale=en,orientation=portrait \
  --timeout 45m \
  --results-bucket=gs://juan-heart-mobile-test-results \
  --results-dir=ios-$(date +%Y%m%d-%H%M%S)
```

## Local Device Testing

### 1. Setup Android Emulators

**Create Emulators:**
```bash
# Create low-end emulator (API 21)
avdmanager create avd \
  --name test_api_21 \
  --package "system-images;android-21;google_apis;x86_64" \
  --device "pixel"

# Create mid-range emulator (API 29)
avdmanager create avd \
  --name test_api_29 \
  --package "system-images;android-29;google_apis;x86_64" \
  --device "pixel"

# Create high-end emulator (API 33)
avdmanager create avd \
  --name test_api_33 \
  --package "system-images;android-33;google_apis;x86_64" \
  --device "pixel"
```

**Or use the script:**
```bash
./scripts/run_device_matrix.sh --create-emulators
```

### 2. Setup iOS Simulators

iOS simulators are managed by Xcode. Install via Xcode settings:

1. Open Xcode
2. Go to Settings > Platforms
3. Download iOS versions: 12.0, 13.0, 14.0, 15.0, 16.0

### 3. Run Local Tests

**Using Script:**
```bash
# Run tests on all local devices
./scripts/run_device_matrix.sh

# Run tests on Android only
./scripts/run_device_matrix.sh --platform android

# Run performance tests
./scripts/run_device_matrix.sh --test performance

# Run tests in parallel (faster)
./scripts/run_device_matrix.sh --parallel
```

**Manual Execution:**
```bash
# List available devices
flutter devices

# Run on specific device
flutter test integration_test/device_compatibility_test.dart \
  -d <device-id>

# Run with driver
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/device_compatibility_test.dart \
  -d <device-id>
```

## Test Execution

### Test Types

1. **Device Compatibility Test** (`device_compatibility_test.dart`)
   - App installation and launch
   - User authentication flows
   - Heart risk assessment
   - Offline/online sync
   - Emergency features
   - UI rendering
   - Touch targets
   - Localization

2. **Performance Test** (`performance_test.dart`)
   - App launch time
   - Screen transition time
   - Assessment completion time
   - Memory usage
   - List scrolling performance
   - Form input performance
   - PDF generation performance

3. **UI Compatibility Test** (`ui_compatibility_test.dart`)
   - Screen dimensions and DPI
   - Render overflow detection
   - Touch target sizes
   - Text readability
   - Safe area handling (notch/Dynamic Island)
   - Portrait/landscape orientation
   - Color contrast
   - Image loading

### Test Execution Workflow

1. **Pre-Flight Checks**
   ```bash
   # Verify Flutter setup
   flutter doctor -v

   # Run analyzer
   flutter analyze

   # Run unit tests
   flutter test
   ```

2. **Build Applications**
   ```bash
   # Android
   flutter build apk --debug
   cd android && ./gradlew assembleDebugAndroidTest && cd ..

   # iOS (macOS)
   flutter build ios --debug --no-codesign
   ```

3. **Execute Tests**
   ```bash
   # Local testing (fast feedback)
   ./scripts/run_device_matrix.sh --platform android

   # Firebase Test Lab (comprehensive)
   ./scripts/device_farm_test.sh --platform all
   ```

4. **Monitor Execution**
   - Firebase Console: https://console.firebase.google.com/project/juan-heart-mobile/testlab
   - View real-time test progress
   - Monitor device status
   - Check logs

5. **Download Results**
   ```bash
   # List test results
   gsutil ls gs://juan-heart-mobile-test-results/

   # Download specific test
   gsutil -m cp -r \
     gs://juan-heart-mobile-test-results/android-20250110-120000/ \
     ./test_lab/results/
   ```

## Results Analysis

### Understanding Test Results

Firebase Test Lab provides:
- **Pass/Fail Status** per device
- **Screenshots** at key points
- **Video Recordings** of test execution
- **Logcat/Console Logs** for debugging
- **Performance Metrics** (CPU, memory, network)
- **Coverage Reports** (if enabled)

### Performance Benchmarks

**Low-End Devices (2GB RAM, API 21-23):**
- App launch: <4s ✅
- Memory usage: <200MB ✅
- Battery drain: <10%/hour ✅
- Assessment completion: <30s ✅

**Mid-Range Devices (4GB RAM, API 24-30):**
- App launch: <3s ✅
- Memory usage: <150MB ✅
- Battery drain: <8%/hour ✅
- Assessment completion: <20s ✅

**High-End Devices (8GB+ RAM, API 31+):**
- App launch: <2s ✅
- Memory usage: <120MB ✅
- Battery drain: <6%/hour ✅
- Assessment completion: <15s ✅

### Device Compatibility Matrix

See `docs/testing/device_compatibility_matrix.md` for detailed pass/fail status per device.

### Common Issues and Fixes

| Issue | Device | Solution |
|-------|--------|----------|
| Render overflow | Small screens | Use `LayoutBuilder`, `MediaQuery` |
| Touch targets too small | All | Minimum 48x48dp (44x44 acceptable) |
| Text too small | Low DPI | Minimum 12sp font size |
| Notch overlap | iPhone X+ | Use `SafeArea` widget |
| Battery drain | MIUI devices | Request battery optimization exemption |
| Notification issues | ColorOS/FunTouch | Document notification setup |
| Background sync killed | Xiaomi | Test WorkManager persistence |

## Troubleshooting

### Common Setup Issues

**1. gcloud authentication fails**
```bash
# Clear credentials and re-authenticate
gcloud auth revoke
gcloud auth login
```

**2. Firebase Test Lab quota exceeded**
- Check Firebase Console > Test Lab > Usage
- Upgrade plan or wait for quota reset
- Use local testing for rapid iteration

**3. Android build fails**
```bash
# Clean and rebuild
flutter clean
cd android && ./gradlew clean && cd ..
flutter pub get
flutter build apk --debug
```

**4. iOS build fails (macOS)**
```bash
# Clean Xcode build
rm -rf ~/Library/Developer/Xcode/DerivedData/*
cd ios && pod deintegrate && pod install && cd ..
flutter clean
flutter build ios --debug --no-codesign
```

**5. Emulator won't start**
```bash
# Kill all emulator processes
pkill -9 qemu-system-x86_64

# Cold boot emulator
emulator -avd test_api_29 -no-snapshot-load
```

### Test Execution Issues

**1. Test times out**
- Increase timeout in `test_config.yaml`
- Check network connectivity in test
- Reduce test scope

**2. Flaky tests**
- Add `await tester.pumpAndSettle()` after actions
- Increase delays for slow devices
- Use `find.byKey()` instead of `find.byType()`

**3. No devices available**
- Check `flutter devices`
- Start emulator manually
- Verify USB debugging enabled

**4. Test results not uploaded**
- Check GCS bucket permissions
- Verify Firebase project ID
- Check network connectivity

### Getting Help

- **Firebase Test Lab Docs**: https://firebase.google.com/docs/test-lab
- **Flutter Testing Docs**: https://flutter.dev/docs/testing
- **Juan Heart Dev Team**: juanheart.dev@example.com
- **Issue Tracker**: https://github.com/juan-heart/mobile/issues

## Cost Optimization

### Firebase Test Lab Pricing

- **Physical devices**: $5/hour
- **Virtual devices**: $1/hour
- **Free tier**: 10 virtual tests/day, 5 physical tests/day

### Optimization Strategies

1. **Use Local Testing First**
   - Catch obvious issues locally
   - Only run Test Lab for final validation

2. **Limit Device Matrix**
   - Test critical devices first
   - Add more devices as needed

3. **Batch Tests**
   - Run multiple test types in one session
   - Group related tests together

4. **Use Virtual Devices**
   - Cheaper than physical devices
   - Sufficient for most testing

5. **Set Timeouts**
   - Avoid runaway tests
   - Typical tests: 10-15 minutes
   - Maximum: 45 minutes

6. **Schedule Tests**
   - Run during off-peak hours
   - Automate with CI/CD (GitHub Actions, etc.)

## CI/CD Integration

Example GitHub Actions workflow:

```yaml
name: Device Farm Tests

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.10.0'
      - uses: google-github-actions/setup-gcloud@v1
        with:
          service_account_key: ${{ secrets.GCP_SA_KEY }}
          project_id: juan-heart-mobile

      - name: Build APK
        run: |
          flutter build apk --debug
          cd android && ./gradlew assembleDebugAndroidTest && cd ..

      - name: Run Firebase Test Lab
        run: |
          gcloud firebase test android run \
            --type instrumentation \
            --app build/app/outputs/flutter-apk/app-debug.apk \
            --test build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk \
            --device model=panther,version=33
```

## Next Steps

1. ✅ Setup Firebase Test Lab (this guide)
2. [ ] Run initial device compatibility tests
3. [ ] Analyze results and fix issues
4. [ ] Create device compatibility matrix
5. [ ] Integrate with CI/CD pipeline
6. [ ] Schedule regular testing runs

---

**Status**: Ready for use (NOT VERIFIED AND TESTED)
**Last Updated**: 2025-01-10
**Maintainer**: JH-QA-Guardian
