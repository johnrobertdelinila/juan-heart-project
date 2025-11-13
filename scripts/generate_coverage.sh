#!/bin/bash

# Juan Heart Mobile - Test Coverage Generation Script
# Generates comprehensive test coverage reports with HTML output
# Usage: ./scripts/generate_coverage.sh [--html] [--open]

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
LCOV_FILE="${COVERAGE_DIR}/lcov.info"
FILTERED_LCOV_FILE="${COVERAGE_DIR}/lcov_filtered.info"
HTML_DIR="${COVERAGE_DIR}/html"
SUMMARY_FILE="${COVERAGE_DIR}/coverage_summary.txt"

# Flags
GENERATE_HTML=false
OPEN_REPORT=false

# Parse arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --html) GENERATE_HTML=true ;;
    --open) OPEN_REPORT=true; GENERATE_HTML=true ;;
    *) echo "Unknown parameter: $1"; exit 1 ;;
  esac
  shift
done

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Juan Heart Mobile - Coverage Report${NC}"
echo -e "${BLUE}======================================${NC}\n"

# Clean previous coverage data
echo -e "${YELLOW}Cleaning previous coverage data...${NC}"
rm -rf "${COVERAGE_DIR}"
mkdir -p "${COVERAGE_DIR}"

# Check if flutter is available
if ! command -v flutter &> /dev/null; then
  echo -e "${RED}Error: Flutter is not installed or not in PATH${NC}"
  exit 1
fi

# Create test .env file if it doesn't exist
if [ ! -f "${PROJECT_ROOT}/.env" ]; then
  echo -e "${YELLOW}Creating test .env file...${NC}"
  cat > "${PROJECT_ROOT}/.env" <<EOF
ACCOUNT_SID=TEST_ACCOUNT_SID
AUTH_TOKEN=TEST_AUTH_TOKEN
TWILIO_NUMBER=+15555555555
GENKIT_BACKEND_URL=https://us-central1-juan-heart-project.cloudfunctions.net/assessHeartRiskHttp
FEATURE_FLAGS_URL=
EDUCATIONAL_CONTENT_API_URL=http://localhost:8000/api/v1/mobile
GOOGLE_GEOCODING_API_KEY=TEST_API_KEY
EOF
fi

# Run tests with coverage
echo -e "${YELLOW}Running tests with coverage...${NC}"
flutter test --coverage --exclude-tags=integration 2>&1 | tee "${COVERAGE_DIR}/test_output.log"

if [ ! -f "${LCOV_FILE}" ]; then
  echo -e "${RED}Error: Coverage file not generated${NC}"
  echo -e "${RED}Check ${COVERAGE_DIR}/test_output.log for errors${NC}"
  exit 1
fi

# Filter out generated files and test files
echo -e "${YELLOW}Filtering coverage data...${NC}"
lcov --remove "${LCOV_FILE}" \
  '*.g.dart' \
  '*.freezed.dart' \
  '*.config.dart' \
  '*/test/*' \
  '*/generated_plugin_registrant.dart' \
  '**/main.dart' \
  -o "${FILTERED_LCOV_FILE}" 2>&1 | grep -v "Writing data" || true

# Generate summary
echo -e "${YELLOW}Generating coverage summary...${NC}"
lcov --list "${FILTERED_LCOV_FILE}" > "${SUMMARY_FILE}"

# Extract overall coverage percentage
OVERALL_COVERAGE=$(lcov --summary "${FILTERED_LCOV_FILE}" 2>&1 | grep "lines" | sed 's/.*: \([0-9.]*\)%.*/\1/')

# Display summary
echo -e "\n${GREEN}======================================${NC}"
echo -e "${GREEN}Coverage Summary${NC}"
echo -e "${GREEN}======================================${NC}"
echo -e "Overall Line Coverage: ${GREEN}${OVERALL_COVERAGE}%${NC}\n"

# Check coverage thresholds
THRESHOLD_CRITICAL=80
THRESHOLD_SERVICES=75
THRESHOLD_UI=60
THRESHOLD_OVERALL=70

echo -e "${BLUE}Coverage Thresholds:${NC}"
echo -e "  Critical paths: ${THRESHOLD_CRITICAL}%"
echo -e "  Services: ${THRESHOLD_SERVICES}%"
echo -e "  UI Widgets: ${THRESHOLD_UI}%"
echo -e "  Overall: ${THRESHOLD_OVERALL}%\n"

# Check if overall coverage meets threshold
if (( $(echo "${OVERALL_COVERAGE} < ${THRESHOLD_OVERALL}" | bc -l) )); then
  echo -e "${YELLOW}Warning: Overall coverage ${OVERALL_COVERAGE}% is below threshold ${THRESHOLD_OVERALL}%${NC}"
else
  echo -e "${GREEN}Overall coverage meets threshold${NC}"
fi

# Generate HTML report if requested
if [ "$GENERATE_HTML" = true ]; then
  echo -e "\n${YELLOW}Generating HTML coverage report...${NC}"

  # Check if genhtml is available
  if command -v genhtml &> /dev/null; then
    genhtml "${FILTERED_LCOV_FILE}" \
      --output-directory "${HTML_DIR}" \
      --title "Juan Heart Mobile - Coverage Report" \
      --show-details \
      --legend \
      --quiet

    echo -e "${GREEN}HTML report generated: ${HTML_DIR}/index.html${NC}"

    # Open report if requested
    if [ "$OPEN_REPORT" = true ]; then
      if [[ "$OSTYPE" == "darwin"* ]]; then
        open "${HTML_DIR}/index.html"
      elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        xdg-open "${HTML_DIR}/index.html"
      fi
    fi
  else
    echo -e "${YELLOW}genhtml not found. Using dart coverage tool for HTML report...${NC}"

    # Activate coverage tool if not already activated
    dart pub global activate coverage 2>&1 | grep -v "Resolving dependencies" || true

    # Generate HTML using dart coverage tool
    dart pub global run coverage:format_coverage \
      --lcov \
      --in="${COVERAGE_DIR}" \
      --out="${FILTERED_LCOV_FILE}" \
      --packages=.dart_tool/package_config.json \
      --report-on=lib \
      --check-ignore

    echo -e "${GREEN}Coverage report ready at: ${FILTERED_LCOV_FILE}${NC}"
    echo -e "${YELLOW}Note: Install lcov for HTML reports: brew install lcov (macOS) or apt-get install lcov (Linux)${NC}"
  fi
fi

# Display top 10 least covered files
echo -e "\n${BLUE}Top 10 Files Needing Coverage Improvement:${NC}"
echo -e "${BLUE}===========================================${NC}"
lcov --list "${FILTERED_LCOV_FILE}" 2>/dev/null | \
  grep "lib/" | \
  grep -v "100.0%" | \
  sort -t: -k2 -n | \
  head -10 || echo "No coverage data available"

# Critical paths coverage check
echo -e "\n${BLUE}Critical Paths Coverage:${NC}"
echo -e "${BLUE}=========================${NC}"

CRITICAL_PATHS=(
  "lib/services/auth_service.dart"
  "lib/services/assessment_sync_service.dart"
  "lib/services/appointment_service.dart"
  "lib/services/sync_queue_service.dart"
  "lib/models/questionnaire_model.dart"
)

for path in "${CRITICAL_PATHS[@]}"; do
  if grep -q "${path}" "${SUMMARY_FILE}"; then
    coverage_line=$(grep "${path}" "${SUMMARY_FILE}" || echo "Not found")
    echo -e "  ${path}: ${coverage_line}"
  else
    echo -e "  ${YELLOW}${path}: No coverage data${NC}"
  fi
done

# Save metadata
cat > "${COVERAGE_DIR}/metadata.json" <<EOF
{
  "generated_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "overall_coverage": ${OVERALL_COVERAGE},
  "threshold_critical": ${THRESHOLD_CRITICAL},
  "threshold_services": ${THRESHOLD_SERVICES},
  "threshold_ui": ${THRESHOLD_UI},
  "threshold_overall": ${THRESHOLD_OVERALL},
  "files_analyzed": $(grep -c "SF:" "${FILTERED_LCOV_FILE}" || echo 0),
  "lcov_file": "${FILTERED_LCOV_FILE}"
}
EOF

echo -e "\n${GREEN}======================================${NC}"
echo -e "${GREEN}Coverage report generated successfully${NC}"
echo -e "${GREEN}======================================${NC}"
echo -e "Coverage file: ${FILTERED_LCOV_FILE}"
echo -e "Summary file: ${SUMMARY_FILE}"
[ -d "${HTML_DIR}" ] && echo -e "HTML report: ${HTML_DIR}/index.html"
echo -e "\nRun with --html to generate HTML report"
echo -e "Run with --open to generate and open HTML report\n"

exit 0
