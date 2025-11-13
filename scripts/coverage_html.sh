#!/bin/bash

# Juan Heart Mobile - HTML Coverage Report Generator
# Generates a comprehensive HTML coverage report
# Usage: ./scripts/coverage_html.sh [--open]

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
HTML_DIR="${COVERAGE_DIR}/html"

# Flags
OPEN_REPORT=false

# Parse arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --open) OPEN_REPORT=true ;;
    *) echo "Unknown parameter: $1"; exit 1 ;;
  esac
  shift
done

# Check if coverage file exists
if [ ! -f "${FILTERED_LCOV_FILE}" ]; then
  echo -e "${RED}Error: Coverage file not found${NC}"
  echo -e "${RED}Run ./scripts/generate_coverage.sh first${NC}"
  exit 1
fi

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}HTML Coverage Report Generation${NC}"
echo -e "${BLUE}======================================${NC}\n"

# Clean previous HTML report
rm -rf "${HTML_DIR}"
mkdir -p "${HTML_DIR}"

# Check if genhtml is available
if command -v genhtml &> /dev/null; then
  echo -e "${YELLOW}Generating HTML report with genhtml...${NC}"

  genhtml "${FILTERED_LCOV_FILE}" \
    --output-directory "${HTML_DIR}" \
    --title "Juan Heart Mobile - Coverage Report" \
    --show-details \
    --legend \
    --branch-coverage \
    --function-coverage \
    --demangle-cpp \
    --quiet

  echo -e "${GREEN}HTML report generated successfully${NC}\n"

elif command -v dart &> /dev/null; then
  echo -e "${YELLOW}genhtml not found, using Dart coverage tools...${NC}"

  # Activate coverage tool if not already activated
  dart pub global activate coverage 2>&1 | grep -v "Resolving" || true

  # Generate pretty output using dart
  dart pub global run coverage:format_coverage \
    --lcov \
    --in="${COVERAGE_DIR}" \
    --out="${FILTERED_LCOV_FILE}" \
    --packages=.dart_tool/package_config.json \
    --report-on=lib \
    --check-ignore

  # Create simple HTML report
  echo -e "${YELLOW}Creating simple HTML report...${NC}"

  cat > "${HTML_DIR}/index.html" <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Juan Heart Mobile - Coverage Report</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
      line-height: 1.6;
      color: #333;
      background: #f5f5f5;
      padding: 20px;
    }
    .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
    h1 { color: #2196F3; margin-bottom: 10px; }
    .subtitle { color: #666; margin-bottom: 30px; }
    .summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin-bottom: 30px; }
    .summary-card { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 8px; }
    .summary-card h3 { font-size: 14px; opacity: 0.9; margin-bottom: 10px; }
    .summary-card .value { font-size: 36px; font-weight: bold; }
    .info { background: #e3f2fd; padding: 15px; border-radius: 8px; border-left: 4px solid #2196F3; margin-bottom: 20px; }
    .info h3 { color: #1976d2; margin-bottom: 10px; }
    .info p { color: #555; }
    a { color: #2196F3; text-decoration: none; }
    a:hover { text-decoration: underline; }
  </style>
</head>
<body>
  <div class="container">
    <h1>Juan Heart Mobile - Coverage Report</h1>
    <p class="subtitle">Test Coverage Analysis</p>

    <div class="summary">
      <div class="summary-card">
        <h3>Overall Coverage</h3>
        <div class="value" id="overall-coverage">--</div>
      </div>
    </div>

    <div class="info">
      <h3>View Detailed Coverage</h3>
      <p>To view detailed line-by-line coverage, install lcov:</p>
      <ul style="margin-top: 10px; margin-left: 20px;">
        <li><strong>macOS:</strong> <code>brew install lcov</code></li>
        <li><strong>Linux:</strong> <code>apt-get install lcov</code></li>
      </ul>
      <p style="margin-top: 10px;">Then run: <code>./scripts/coverage_html.sh --open</code></p>
    </div>

    <div class="info">
      <h3>Coverage Files</h3>
      <p>LCOV file: <a href="../lcov_filtered.info" download>lcov_filtered.info</a></p>
      <p>Summary: <a href="../coverage_summary.txt" download>coverage_summary.txt</a></p>
    </div>
  </div>

  <script>
    // Load coverage data from metadata if available
    fetch('../metadata.json')
      .then(res => res.json())
      .then(data => {
        document.getElementById('overall-coverage').textContent = data.overall_coverage.toFixed(1) + '%';
      })
      .catch(() => {
        document.getElementById('overall-coverage').textContent = 'N/A';
      });
  </script>
</body>
</html>
EOF

  echo -e "${GREEN}Simple HTML report created${NC}\n"
  echo -e "${YELLOW}Note: Install lcov for full coverage report${NC}"
  echo -e "${YELLOW}macOS: brew install lcov${NC}"
  echo -e "${YELLOW}Linux: apt-get install lcov${NC}\n"

else
  echo -e "${RED}Error: Neither genhtml nor dart found${NC}"
  exit 1
fi

# Display report location
echo -e "${BLUE}======================================${NC}"
echo -e "${GREEN}HTML Report Location${NC}"
echo -e "${BLUE}======================================${NC}"
echo -e "Open: ${HTML_DIR}/index.html\n"

# Open report if requested
if [ "$OPEN_REPORT" = true ]; then
  echo -e "${YELLOW}Opening coverage report...${NC}"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    open "${HTML_DIR}/index.html"
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    xdg-open "${HTML_DIR}/index.html"
  else
    echo -e "${YELLOW}Cannot auto-open on this platform${NC}"
    echo -e "${YELLOW}Please open: ${HTML_DIR}/index.html${NC}"
  fi
fi

exit 0
