#!/bin/bash

# Juan Heart Mobile - Coverage Badge Generation Script
# Generates a coverage badge for README.md using shields.io
# Usage: ./scripts/coverage_badge.sh

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
BADGE_FILE="${COVERAGE_DIR}/coverage_badge.svg"
BADGE_JSON="${COVERAGE_DIR}/coverage_badge.json"

# Check if coverage file exists
if [ ! -f "${FILTERED_LCOV_FILE}" ]; then
  echo -e "${RED}Error: Coverage file not found${NC}"
  echo -e "${RED}Run ./scripts/generate_coverage.sh first${NC}"
  exit 1
fi

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Coverage Badge Generation${NC}"
echo -e "${BLUE}======================================${NC}\n"

# Extract overall coverage percentage
OVERALL_COVERAGE=$(lcov --summary "${FILTERED_LCOV_FILE}" 2>&1 | grep "lines" | sed 's/.*: \([0-9.]*\)%.*/\1/')

echo -e "Overall Line Coverage: ${GREEN}${OVERALL_COVERAGE}%${NC}\n"

# Determine badge color based on coverage
if (( $(echo "${OVERALL_COVERAGE} >= 80" | bc -l) )); then
  COLOR="brightgreen"
  STATUS="excellent"
elif (( $(echo "${OVERALL_COVERAGE} >= 70" | bc -l) )); then
  COLOR="green"
  STATUS="good"
elif (( $(echo "${OVERALL_COVERAGE} >= 60" | bc -l) )); then
  COLOR="yellowgreen"
  STATUS="fair"
elif (( $(echo "${OVERALL_COVERAGE} >= 50" | bc -l) )); then
  COLOR="yellow"
  STATUS="needs improvement"
else
  COLOR="red"
  STATUS="poor"
fi

# Generate badge URL
BADGE_URL="https://img.shields.io/badge/coverage-${OVERALL_COVERAGE}%25-${COLOR}?style=flat-square&logo=flutter"

# Generate badge markdown
BADGE_MARKDOWN="![Coverage](${BADGE_URL})"

# Save badge data
cat > "${BADGE_JSON}" <<EOF
{
  "schemaVersion": 1,
  "label": "coverage",
  "message": "${OVERALL_COVERAGE}%",
  "color": "${COLOR}",
  "status": "${STATUS}",
  "url": "${BADGE_URL}",
  "markdown": "${BADGE_MARKDOWN}"
}
EOF

# Download badge SVG if curl is available
if command -v curl &> /dev/null; then
  echo -e "${YELLOW}Downloading badge SVG...${NC}"
  curl -s "${BADGE_URL}" -o "${BADGE_FILE}"
  echo -e "${GREEN}Badge SVG saved to: ${BADGE_FILE}${NC}\n"
fi

# Display badge markdown
echo -e "${BLUE}======================================${NC}"
echo -e "${GREEN}Badge Generated Successfully${NC}"
echo -e "${BLUE}======================================${NC}\n"

echo -e "${BLUE}Badge URL:${NC}"
echo -e "${BADGE_URL}\n"

echo -e "${BLUE}Markdown for README.md:${NC}"
echo -e "${BADGE_MARKDOWN}\n"

echo -e "${BLUE}Badge Status:${NC} ${STATUS}"
echo -e "${BLUE}Badge Color:${NC} ${COLOR}\n"

# Provide integration instructions
echo -e "${YELLOW}Integration Instructions:${NC}"
echo -e "1. Add the following line to your README.md:"
echo -e "   ${BADGE_MARKDOWN}"
echo -e ""
echo -e "2. Or use the dynamic Codecov badge:"
echo -e "   [![codecov](https://codecov.io/gh/YOUR_ORG/juan-heart-mobile/branch/main/graph/badge.svg)](https://codecov.io/gh/YOUR_ORG/juan-heart-mobile)"
echo -e ""
echo -e "3. Or use the local SVG file:"
echo -e "   ![Coverage](./coverage/coverage_badge.svg)\n"

# Update README.md if it exists and doesn't have a badge
README_FILE="${PROJECT_ROOT}/README.md"
if [ -f "${README_FILE}" ]; then
  if ! grep -q "coverage" "${README_FILE}"; then
    echo -e "${YELLOW}Note: README.md exists but has no coverage badge${NC}"
    echo -e "${YELLOW}Would you like to add it manually?${NC}\n"
  else
    echo -e "${GREEN}Coverage badge already exists in README.md${NC}\n"
  fi
fi

exit 0
