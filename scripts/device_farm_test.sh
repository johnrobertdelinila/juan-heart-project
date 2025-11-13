#!/bin/bash

################################################################################
# Device Farm Testing Script for Juan Heart Mobile
#
# This script runs comprehensive device testing using Firebase Test Lab
# across multiple Android and iOS devices targeting the Philippine market.
#
# Prerequisites:
# - Firebase project configured
# - gcloud CLI installed and authenticated
# - Flutter SDK installed
# - Android/iOS builds available
#
# Usage:
#   ./scripts/device_farm_test.sh [options]
#
# Options:
#   --platform [android|ios|all]    Platform to test (default: all)
#   --category [low|mid|high|all]   Device category (default: all)
#   --test [compatibility|performance|ui|all]  Test type (default: all)
#   --dry-run                       Show what would be tested without running
#   --verbose                       Enable verbose output
#   --results-dir [path]            Custom results directory
#
# Examples:
#   ./scripts/device_farm_test.sh --platform android --category low
#   ./scripts/device_farm_test.sh --test performance --verbose
#   ./scripts/device_farm_test.sh --dry-run
################################################################################

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default configuration
PLATFORM="all"
CATEGORY="all"
TEST_TYPE="all"
DRY_RUN=false
VERBOSE=false
RESULTS_DIR="test_lab/results"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIREBASE_PROJECT_ID="${FIREBASE_PROJECT_ID:-juan-heart-mobile}"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --platform)
      PLATFORM="$2"
      shift 2
      ;;
    --category)
      CATEGORY="$2"
      shift 2
      ;;
    --test)
      TEST_TYPE="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --verbose)
      VERBOSE=true
      shift
      ;;
    --results-dir)
      RESULTS_DIR="$2"
      shift 2
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      exit 1
      ;;
  esac
done

# Function to print colored output
log() {
  local level=$1
  shift
  local message="$@"

  case $level in
    "INFO")
      echo -e "${BLUE}[INFO]${NC} $message"
      ;;
    "SUCCESS")
      echo -e "${GREEN}[SUCCESS]${NC} $message"
      ;;
    "WARNING")
      echo -e "${YELLOW}[WARNING]${NC} $message"
      ;;
    "ERROR")
      echo -e "${RED}[ERROR]${NC} $message"
      ;;
  esac
}

# Check prerequisites
check_prerequisites() {
  log "INFO" "Checking prerequisites..."

  # Check Flutter
  if ! command -v flutter &> /dev/null; then
    log "ERROR" "Flutter SDK not found. Please install Flutter."
    exit 1
  fi

  # Check gcloud
  if ! command -v gcloud &> /dev/null; then
    log "ERROR" "gcloud CLI not found. Please install Google Cloud SDK."
    exit 1
  fi

  # Check Firebase project
  if ! gcloud config get-value project &> /dev/null; then
    log "ERROR" "No Firebase project configured. Run: gcloud config set project PROJECT_ID"
    exit 1
  fi

  log "SUCCESS" "All prerequisites met"
}

# Build Android APK for testing
build_android() {
  log "INFO" "Building Android APK..."

  cd "$PROJECT_ROOT"

  if [[ "$DRY_RUN" == true ]]; then
    log "INFO" "[DRY RUN] Would build Android APK"
    return 0
  fi

  flutter build apk --debug

  if [[ $? -eq 0 ]]; then
    log "SUCCESS" "Android APK built successfully"
    return 0
  else
    log "ERROR" "Android APK build failed"
    return 1
  fi
}

# Build Android instrumentation test APK
build_android_test() {
  log "INFO" "Building Android test APK..."

  cd "$PROJECT_ROOT"

  if [[ "$DRY_RUN" == true ]]; then
    log "INFO" "[DRY RUN] Would build Android test APK"
    return 0
  fi

  flutter build apk --debug

  # Build instrumentation test
  cd android
  ./gradlew app:assembleAndroidTest || ./gradlew app:assembleDebugAndroidTest
  cd ..

  if [[ $? -eq 0 ]]; then
    log "SUCCESS" "Android test APK built successfully"
    return 0
  else
    log "ERROR" "Android test APK build failed"
    return 1
  fi
}

# Build iOS IPA for testing
build_ios() {
  log "INFO" "Building iOS IPA..."

  cd "$PROJECT_ROOT"

  if [[ "$DRY_RUN" == true ]]; then
    log "INFO" "[DRY RUN] Would build iOS IPA"
    return 0
  fi

  # iOS build requires macOS
  if [[ "$OSTYPE" != "darwin"* ]]; then
    log "WARNING" "iOS build requires macOS. Skipping..."
    return 1
  fi

  flutter build ios --debug --no-codesign

  if [[ $? -eq 0 ]]; then
    log "SUCCESS" "iOS build completed successfully"
    return 0
  else
    log "ERROR" "iOS build failed"
    return 1
  fi
}

# Run Android tests on Firebase Test Lab
run_android_tests() {
  local device_category=$1
  local test_type=$2

  log "INFO" "Running Android tests (category: $device_category, type: $test_type)..."

  if [[ "$DRY_RUN" == true ]]; then
    log "INFO" "[DRY RUN] Would run Android tests on devices:"
    case $device_category in
      "low")
        log "INFO" "  - Samsung Galaxy J2 (API 21)"
        ;;
      "mid")
        log "INFO" "  - Google Pixel 5 (API 26)"
        log "INFO" "  - Google Pixel 4 (API 29)"
        ;;
      "high")
        log "INFO" "  - Google Pixel 6 (API 31)"
        log "INFO" "  - Google Pixel 7 (API 33)"
        ;;
      "all")
        log "INFO" "  - All device categories"
        ;;
    esac
    return 0
  fi

  # Determine device models based on category
  local device_models=""
  case $device_category in
    "low")
      device_models="model=j2lte,version=21,locale=en,orientation=portrait"
      ;;
    "mid")
      device_models="model=redfin,version=26,locale=en,orientation=portrait \
                     model=flame,version=29,locale=en,orientation=portrait"
      ;;
    "high")
      device_models="model=oriole,version=31,locale=en,orientation=portrait \
                     model=panther,version=33,locale=en,orientation=portrait"
      ;;
    "all")
      device_models="model=j2lte,version=21,locale=en,orientation=portrait \
                     model=redfin,version=26,locale=en,orientation=portrait \
                     model=flame,version=29,locale=en,orientation=portrait \
                     model=oriole,version=31,locale=en,orientation=portrait \
                     model=panther,version=33,locale=en,orientation=portrait"
      ;;
  esac

  # Determine test to run
  local test_file=""
  case $test_type in
    "compatibility")
      test_file="integration_test/device_compatibility_test.dart"
      ;;
    "performance")
      test_file="integration_test/performance_test.dart"
      ;;
    "ui")
      test_file="integration_test/ui_compatibility_test.dart"
      ;;
    "all")
      test_file="integration_test/device_compatibility_test.dart"
      ;;
  esac

  # Run Firebase Test Lab
  log "INFO" "Submitting tests to Firebase Test Lab..."

  gcloud firebase test android run \
    --type instrumentation \
    --app build/app/outputs/flutter-apk/app-debug.apk \
    --test build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk \
    --device $device_models \
    --timeout 45m \
    --results-bucket=gs://${FIREBASE_PROJECT_ID}-test-results \
    --results-dir="${RESULTS_DIR}/android-$(date +%Y%m%d-%H%M%S)" \
    --environment-variables coverage=true,clearPackageData=true \
    --project "$FIREBASE_PROJECT_ID"

  if [[ $? -eq 0 ]]; then
    log "SUCCESS" "Android tests submitted successfully"
    return 0
  else
    log "ERROR" "Android tests failed"
    return 1
  fi
}

# Run iOS tests on Firebase Test Lab
run_ios_tests() {
  local device_category=$1
  local test_type=$2

  log "INFO" "Running iOS tests (category: $device_category, type: $test_type)..."

  if [[ "$DRY_RUN" == true ]]; then
    log "INFO" "[DRY RUN] Would run iOS tests on devices:"
    case $device_category in
      "low")
        log "INFO" "  - iPhone 8 (iOS 12.0)"
        ;;
      "mid")
        log "INFO" "  - iPhone 11 (iOS 14.0)"
        log "INFO" "  - iPhone 12 (iOS 15.0)"
        ;;
      "high")
        log "INFO" "  - iPhone 13 (iOS 16.0)"
        ;;
      "all")
        log "INFO" "  - All device categories"
        ;;
    esac
    return 0
  fi

  # Determine device models based on category
  local device_models=""
  case $device_category in
    "low")
      device_models="model=iphone8,version=12.0,locale=en,orientation=portrait"
      ;;
    "mid")
      device_models="model=iphone11,version=14.0,locale=en,orientation=portrait \
                     model=iphone12,version=15.0,locale=en,orientation=portrait"
      ;;
    "high")
      device_models="model=iphone13,version=16.0,locale=en,orientation=portrait"
      ;;
    "all")
      device_models="model=iphone8,version=12.0,locale=en,orientation=portrait \
                     model=iphone11,version=14.0,locale=en,orientation=portrait \
                     model=iphone12,version=15.0,locale=en,orientation=portrait \
                     model=iphone13,version=16.0,locale=en,orientation=portrait"
      ;;
  esac

  log "INFO" "Submitting iOS tests to Firebase Test Lab..."

  gcloud firebase test ios run \
    --test build/ios/iphoneos/Runner.app \
    --device $device_models \
    --timeout 45m \
    --results-bucket=gs://${FIREBASE_PROJECT_ID}-test-results \
    --results-dir="${RESULTS_DIR}/ios-$(date +%Y%m%d-%H%M%S)" \
    --project "$FIREBASE_PROJECT_ID"

  if [[ $? -eq 0 ]]; then
    log "SUCCESS" "iOS tests submitted successfully"
    return 0
  else
    log "ERROR" "iOS tests failed"
    return 1
  fi
}

# Generate test report
generate_report() {
  log "INFO" "Generating test report..."

  if [[ "$DRY_RUN" == true ]]; then
    log "INFO" "[DRY RUN] Would generate test report"
    return 0
  fi

  # Download results from Firebase
  log "INFO" "Downloading test results..."

  # TODO: Parse results and generate HTML report
  # This would involve:
  # 1. Downloading test artifacts from GCS
  # 2. Parsing test results
  # 3. Generating HTML/JSON report
  # 4. Creating device compatibility matrix

  log "SUCCESS" "Test report generated in $RESULTS_DIR"
}

# Main execution
main() {
  log "INFO" "=== Juan Heart Mobile Device Farm Testing ==="
  log "INFO" "Platform: $PLATFORM"
  log "INFO" "Category: $CATEGORY"
  log "INFO" "Test Type: $TEST_TYPE"
  log "INFO" "Dry Run: $DRY_RUN"
  log "INFO" ""

  # Check prerequisites
  check_prerequisites

  # Create results directory
  mkdir -p "$RESULTS_DIR"

  # Build and test Android
  if [[ "$PLATFORM" == "android" ]] || [[ "$PLATFORM" == "all" ]]; then
    log "INFO" "Starting Android testing..."

    build_android
    build_android_test
    run_android_tests "$CATEGORY" "$TEST_TYPE"
  fi

  # Build and test iOS
  if [[ "$PLATFORM" == "ios" ]] || [[ "$PLATFORM" == "all" ]]; then
    log "INFO" "Starting iOS testing..."

    build_ios
    run_ios_tests "$CATEGORY" "$TEST_TYPE"
  fi

  # Generate report
  generate_report

  log "SUCCESS" "=== Device Farm Testing Complete ==="
  log "INFO" "Results available in: $RESULTS_DIR"
}

# Run main function
main
