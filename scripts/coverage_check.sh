#!/bin/bash

# Juan Heart Mobile - Coverage Threshold Check Script
# Validates coverage against defined thresholds and fails if not met
# Usage: ./scripts/coverage_check.sh

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COVERAGE_DIR="${PROJECT_ROOT}/coverage"
FILTERED_LCOV_FILE="${COVERAGE_DIR}/lcov_filtered.info"

# Coverage thresholds
THRESHOLD_CRITICAL=80
THRESHOLD_SERVICES=75
THRESHOLD_UI=60
THRESHOLD_OVERALL=70

# Check if coverage file exists
if [ ! -f "${FILTERED_LCOV_FILE}" ]; then
  echo -e "${RED}Error: Coverage file not found${NC}"
  echo -e "${RED}Run ./scripts/generate_coverage.sh first${NC}"
  exit 1
fi

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Juan Heart Mobile - Coverage Check${NC}"
echo -e "${BLUE}======================================${NC}\n"

# Extract overall coverage percentage
OVERALL_COVERAGE=$(lcov --summary "${FILTERED_LCOV_FILE}" 2>&1 | grep "lines" | sed 's/.*: \([0-9.]*\)%.*/\1/')

echo -e "Overall Line Coverage: ${GREEN}${OVERALL_COVERAGE}%${NC}\n"

# Track failures
FAILED_CHECKS=0

# Check overall coverage
echo -e "${BLUE}Checking Overall Coverage Threshold (${THRESHOLD_OVERALL}%)${NC}"
if (( $(echo "${OVERALL_COVERAGE} < ${THRESHOLD_OVERALL}" | bc -l) )); then
  echo -e "${RED}FAIL: Overall coverage ${OVERALL_COVERAGE}% is below threshold ${THRESHOLD_OVERALL}%${NC}\n"
  FAILED_CHECKS=$((FAILED_CHECKS + 1))
else
  echo -e "${GREEN}PASS: Overall coverage meets threshold${NC}\n"
fi

# Check critical paths
echo -e "${BLUE}Checking Critical Paths Coverage (${THRESHOLD_CRITICAL}%)${NC}"

CRITICAL_PATHS=(
  "lib/services/auth_service.dart"
  "lib/services/assessment_sync_service.dart"
  "lib/services/appointment_service.dart"
  "lib/services/sync_queue_service.dart"
)

for path in "${CRITICAL_PATHS[@]}"; do
  # Check if file exists in coverage
  if grep -q "SF:${PROJECT_ROOT}/${path}" "${FILTERED_LCOV_FILE}"; then
    # Extract line coverage for this file
    FILE_COVERAGE=$(lcov --list "${FILTERED_LCOV_FILE}" 2>/dev/null | \
      grep "${path}" | \
      awk '{print $(NF-1)}' | \
      sed 's/%//')

    if [ -n "${FILE_COVERAGE}" ]; then
      if (( $(echo "${FILE_COVERAGE} < ${THRESHOLD_CRITICAL}" | bc -l) )); then
        echo -e "${RED}FAIL: ${path} (${FILE_COVERAGE}%) below ${THRESHOLD_CRITICAL}%${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
      else
        echo -e "${GREEN}PASS: ${path} (${FILE_COVERAGE}%)${NC}"
      fi
    else
      echo -e "${YELLOW}WARN: ${path} - Unable to parse coverage${NC}"
    fi
  else
    echo -e "${RED}FAIL: ${path} - No coverage data${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
  fi
done

echo ""

# Check services coverage
echo -e "${BLUE}Checking Services Coverage (${THRESHOLD_SERVICES}%)${NC}"

SERVICES_COVERAGE=$(lcov --list "${FILTERED_LCOV_FILE}" 2>/dev/null | \
  grep "lib/services/" | \
  awk '{sum+=$(NF-1); count++} END {if (count>0) print sum/count; else print 0}' | \
  sed 's/%//')

if [ -n "${SERVICES_COVERAGE}" ] && [ "${SERVICES_COVERAGE}" != "0" ]; then
  if (( $(echo "${SERVICES_COVERAGE} < ${THRESHOLD_SERVICES}" | bc -l) )); then
    echo -e "${RED}FAIL: Services average coverage ${SERVICES_COVERAGE}% is below ${THRESHOLD_SERVICES}%${NC}\n"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
  else
    echo -e "${GREEN}PASS: Services average coverage ${SERVICES_COVERAGE}%${NC}\n"
  fi
else
  echo -e "${YELLOW}WARN: Unable to calculate services coverage${NC}\n"
fi

# Check UI widgets coverage
echo -e "${BLUE}Checking UI Widgets Coverage (${THRESHOLD_UI}%)${NC}"

UI_COVERAGE=$(lcov --list "${FILTERED_LCOV_FILE}" 2>/dev/null | \
  grep "lib/presentation/" | \
  awk '{sum+=$(NF-1); count++} END {if (count>0) print sum/count; else print 0}' | \
  sed 's/%//')

if [ -n "${UI_COVERAGE}" ] && [ "${UI_COVERAGE}" != "0" ]; then
  if (( $(echo "${UI_COVERAGE} < ${THRESHOLD_UI}" | bc -l) )); then
    echo -e "${RED}FAIL: UI widgets average coverage ${UI_COVERAGE}% is below ${THRESHOLD_UI}%${NC}\n"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
  else
    echo -e "${GREEN}PASS: UI widgets average coverage ${UI_COVERAGE}%${NC}\n"
  fi
else
  echo -e "${YELLOW}WARN: Unable to calculate UI widgets coverage${NC}\n"
fi

# Summary
echo -e "${BLUE}======================================${NC}"
if [ ${FAILED_CHECKS} -eq 0 ]; then
  echo -e "${GREEN}Coverage Check: PASSED${NC}"
  echo -e "${GREEN}All thresholds met${NC}"
  echo -e "${BLUE}======================================${NC}\n"
  exit 0
else
  echo -e "${RED}Coverage Check: FAILED${NC}"
  echo -e "${RED}${FAILED_CHECKS} threshold(s) not met${NC}"
  echo -e "${BLUE}======================================${NC}\n"

  echo -e "${YELLOW}Recommendations:${NC}"
  echo -e "1. Add unit tests for critical paths"
  echo -e "2. Focus on services with <75% coverage"
  echo -e "3. Add widget tests for UI components"
  echo -e "4. Review untested edge cases\n"

  exit 1
fi
