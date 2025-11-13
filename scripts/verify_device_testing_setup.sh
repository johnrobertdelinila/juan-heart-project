#!/bin/bash

# Device Farm Testing Setup Verification Script
# Verifies all required files and configurations are in place

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "===== Device Farm Testing Setup Verification ====="
echo ""

# Check files
FILES=(
  "test_lab/test_config.yaml"
  "test_lab/device_matrix.json"
  "integration_test/device_compatibility_test.dart"
  "integration_test/performance_test.dart"
  "integration_test/ui_compatibility_test.dart"
  "scripts/device_farm_test.sh"
  "scripts/run_device_matrix.sh"
  "docs/testing/README.md"
  "docs/testing/device_farm_setup.md"
  "docs/testing/device_compatibility_matrix.md"
  "docs/testing/device_test_results.md"
  "docs/testing/performance_benchmarks.md"
)

MISSING=0
for file in "${FILES[@]}"; do
  if [[ -f "$file" ]]; then
    echo -e "${GREEN}✅${NC} $file"
  else
    echo -e "${RED}❌${NC} $file (MISSING)"
    ((MISSING++))
  fi
done

echo ""

# Check script permissions
echo "Checking script permissions..."
if [[ -x "scripts/device_farm_test.sh" ]]; then
  echo -e "${GREEN}✅${NC} device_farm_test.sh is executable"
else
  echo -e "${RED}❌${NC} device_farm_test.sh is not executable"
  ((MISSING++))
fi

if [[ -x "scripts/run_device_matrix.sh" ]]; then
  echo -e "${GREEN}✅${NC} run_device_matrix.sh is executable"
else
  echo -e "${RED}❌${NC} run_device_matrix.sh is not executable"
  ((MISSING++))
fi

echo ""

# Summary
if [[ $MISSING -eq 0 ]]; then
  echo -e "${GREEN}✅ All device farm testing files are in place!${NC}"
  echo ""
  echo "Next steps:"
  echo "1. Setup Firebase Test Lab (see docs/testing/device_farm_setup.md)"
  echo "2. Build APK/IPA for testing"
  echo "3. Run: ./scripts/device_farm_test.sh --dry-run"
  echo "4. Execute first test run"
  exit 0
else
  echo -e "${RED}❌ $MISSING file(s) missing or not executable${NC}"
  exit 1
fi
