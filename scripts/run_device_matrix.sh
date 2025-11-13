#!/bin/bash

################################################################################
# Run Device Matrix Tests - Local Device Testing
#
# This script runs integration tests on local Android emulators and iOS simulators
# to validate device compatibility before submitting to Firebase Test Lab.
#
# Prerequisites:
# - Flutter SDK installed
# - Android SDK with emulator images
# - Xcode with simulators (macOS only)
#
# Usage:
#   ./scripts/run_device_matrix.sh [options]
#
# Options:
#   --platform [android|ios|all]    Platform to test (default: all)
#   --test [compatibility|performance|ui|all]  Test type (default: all)
#   --parallel                      Run tests in parallel
#   --create-emulators              Create emulators if missing
#   --verbose                       Enable verbose output
#
# Examples:
#   ./scripts/run_device_matrix.sh --platform android
#   ./scripts/run_device_matrix.sh --test performance --parallel
#   ./scripts/run_device_matrix.sh --create-emulators
################################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
PLATFORM="all"
TEST_TYPE="all"
PARALLEL=false
CREATE_EMULATORS=false
VERBOSE=false
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --platform)
      PLATFORM="$2"
      shift 2
      ;;
    --test)
      TEST_TYPE="$2"
      shift 2
      ;;
    --parallel)
      PARALLEL=true
      shift
      ;;
    --create-emulators)
      CREATE_EMULATORS=true
      shift
      ;;
    --verbose)
      VERBOSE=true
      shift
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      exit 1
      ;;
  esac
done

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

# Create Android emulator
create_android_emulator() {
  local name=$1
  local api_level=$2

  log "INFO" "Creating Android emulator: $name (API $api_level)"

  # Check if already exists
  if avdmanager list avd | grep -q "$name"; then
    log "INFO" "Emulator $name already exists"
    return 0
  fi

  # Download system image if needed
  yes | sdkmanager "system-images;android-${api_level};google_apis;x86_64"

  # Create AVD
  echo "no" | avdmanager create avd \
    --name "$name" \
    --package "system-images;android-${api_level};google_apis;x86_64" \
    --device "pixel"

  log "SUCCESS" "Emulator $name created"
}

# Create iOS simulator (if needed)
create_ios_simulator() {
  local name=$1
  local device=$2
  local runtime=$3

  log "INFO" "Checking iOS simulator: $name"

  # iOS simulators are managed by Xcode
  # Just verify it exists
  if xcrun simctl list devices | grep -q "$device"; then
    log "SUCCESS" "iOS simulator available: $device"
    return 0
  else
    log "WARNING" "iOS simulator not found: $device"
    return 1
  fi
}

# Setup emulators
setup_emulators() {
  if [[ "$CREATE_EMULATORS" != true ]]; then
    return 0
  fi

  log "INFO" "Setting up test emulators..."

  if [[ "$PLATFORM" == "android" ]] || [[ "$PLATFORM" == "all" ]]; then
    # Create Android emulators for key API levels
    create_android_emulator "test_api_21" 21  # Lollipop
    create_android_emulator "test_api_26" 26  # Oreo
    create_android_emulator "test_api_29" 29  # Q
    create_android_emulator "test_api_33" 33  # Tiramisu
  fi

  if [[ "$PLATFORM" == "ios" ]] || [[ "$PLATFORM" == "all" ]]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
      # Verify iOS simulators
      create_ios_simulator "iPhone 8" "iPhone 8" "iOS-12-0"
      create_ios_simulator "iPhone 11" "iPhone 11" "iOS-14-0"
      create_ios_simulator "iPhone 13" "iPhone 13" "iOS-16-0"
    fi
  fi
}

# List available devices
list_devices() {
  log "INFO" "Listing available devices..."

  if [[ "$PLATFORM" == "android" ]] || [[ "$PLATFORM" == "all" ]]; then
    log "INFO" "Android Emulators:"
    avdmanager list avd | grep "Name:" || log "WARNING" "No Android emulators found"
    echo ""
    log "INFO" "Connected Android Devices:"
    adb devices -l | grep -v "List of devices" || log "WARNING" "No Android devices connected"
    echo ""
  fi

  if [[ "$PLATFORM" == "ios" ]] || [[ "$PLATFORM" == "all" ]]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
      log "INFO" "iOS Simulators:"
      xcrun simctl list devices available | grep "iPhone" || log "WARNING" "No iOS simulators found"
      echo ""
    fi
  fi
}

# Run test on specific device
run_test_on_device() {
  local device_id=$1
  local test_file=$2
  local device_name=$3

  log "INFO" "Running tests on $device_name..."

  cd "$PROJECT_ROOT"

  # Run integration test
  if flutter drive \
    --driver=test_driver/integration_test.dart \
    --target="$test_file" \
    -d "$device_id" \
    --no-pub 2>&1 | tee "test_output_${device_name}.log"; then
    log "SUCCESS" "Tests passed on $device_name"
    return 0
  else
    log "ERROR" "Tests failed on $device_name"
    return 1
  fi
}

# Run tests on Android devices
run_android_tests() {
  log "INFO" "Running Android device tests..."

  # Get test file based on test type
  local test_file=""
  case $TEST_TYPE in
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

  # Get list of devices
  local devices=()
  while IFS= read -r line; do
    if [[ $line =~ ^([a-zA-Z0-9_-]+)[[:space:]]+ ]]; then
      devices+=("${BASH_REMATCH[1]}")
    fi
  done < <(adb devices | grep -v "List of devices")

  if [[ ${#devices[@]} -eq 0 ]]; then
    log "WARNING" "No Android devices available. Starting emulator..."

    # Start first available emulator
    local emulator_name=$(avdmanager list avd | grep "Name:" | head -1 | awk '{print $2}')
    if [[ -n "$emulator_name" ]]; then
      log "INFO" "Starting emulator: $emulator_name"
      emulator -avd "$emulator_name" -no-snapshot-load &
      EMULATOR_PID=$!

      # Wait for emulator to boot
      log "INFO" "Waiting for emulator to boot..."
      adb wait-for-device
      sleep 10

      # Get device ID
      devices=($(adb devices | grep -v "List of devices" | awk '{print $1}'))
    else
      log "ERROR" "No emulators available. Run with --create-emulators"
      return 1
    fi
  fi

  # Run tests on each device
  local failed=0
  for device in "${devices[@]}"; do
    if [[ -n "$device" ]]; then
      if ! run_test_on_device "$device" "$test_file" "android_${device}"; then
        ((failed++))
      fi
    fi
  done

  # Cleanup emulator if started
  if [[ -n "$EMULATOR_PID" ]]; then
    log "INFO" "Stopping emulator..."
    kill $EMULATOR_PID 2>/dev/null || true
  fi

  if [[ $failed -eq 0 ]]; then
    log "SUCCESS" "All Android tests passed"
    return 0
  else
    log "ERROR" "$failed Android test(s) failed"
    return 1
  fi
}

# Run tests on iOS devices
run_ios_tests() {
  if [[ "$OSTYPE" != "darwin"* ]]; then
    log "WARNING" "iOS testing requires macOS. Skipping..."
    return 0
  fi

  log "INFO" "Running iOS device tests..."

  # Get test file
  local test_file=""
  case $TEST_TYPE in
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

  # Get available simulators
  local simulators=()
  while IFS= read -r line; do
    if [[ $line =~ iPhone.*\(([A-F0-9-]+)\) ]]; then
      simulators+=("${BASH_REMATCH[1]}")
    fi
  done < <(xcrun simctl list devices available | grep "iPhone")

  if [[ ${#simulators[@]} -eq 0 ]]; then
    log "ERROR" "No iOS simulators available"
    return 1
  fi

  # Run tests on first simulator
  local simulator="${simulators[0]}"
  log "INFO" "Testing on simulator: $simulator"

  # Boot simulator
  xcrun simctl boot "$simulator" 2>/dev/null || true
  sleep 5

  # Run test
  if run_test_on_device "$simulator" "$test_file" "ios_simulator"; then
    log "SUCCESS" "iOS tests passed"
    return 0
  else
    log "ERROR" "iOS tests failed"
    return 1
  fi
}

# Main execution
main() {
  log "INFO" "=== Device Matrix Testing ==="
  log "INFO" "Platform: $PLATFORM"
  log "INFO" "Test Type: $TEST_TYPE"
  log "INFO" "Parallel: $PARALLEL"
  log "INFO" ""

  cd "$PROJECT_ROOT"

  # Setup emulators if requested
  setup_emulators

  # List available devices
  list_devices

  # Run tests
  local android_result=0
  local ios_result=0

  if [[ "$PLATFORM" == "android" ]] || [[ "$PLATFORM" == "all" ]]; then
    run_android_tests || android_result=$?
  fi

  if [[ "$PLATFORM" == "ios" ]] || [[ "$PLATFORM" == "all" ]]; then
    run_ios_tests || ios_result=$?
  fi

  # Report results
  log "INFO" ""
  log "INFO" "=== Test Results ==="
  if [[ $android_result -eq 0 ]]; then
    log "SUCCESS" "Android: PASSED"
  else
    log "ERROR" "Android: FAILED"
  fi

  if [[ $ios_result -eq 0 ]]; then
    log "SUCCESS" "iOS: PASSED"
  else
    log "ERROR" "iOS: FAILED"
  fi

  if [[ $android_result -eq 0 ]] && [[ $ios_result -eq 0 ]]; then
    log "SUCCESS" "=== All Tests Passed ==="
    exit 0
  else
    log "ERROR" "=== Some Tests Failed ==="
    exit 1
  fi
}

# Run main
main
