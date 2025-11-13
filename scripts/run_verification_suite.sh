#!/bin/bash
set -e

echo "🧪 Juan Heart Mobile - Verification Suite"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}📋 Running unit tests...${NC}"
flutter test test/services/auth_service_test.dart || echo -e "${RED}Auth service tests failed${NC}"
flutter test test/services/assessment_sync_service_test.dart || echo -e "${RED}Assessment sync tests failed${NC}"

echo ""
echo -e "${YELLOW}🔄 Running integration tests...${NC}"
flutter test integration_test/ || echo -e "${RED}Integration tests failed${NC}"

echo ""
echo -e "${YELLOW}📊 Generating coverage report...${NC}"
./scripts/generate_coverage.sh || echo -e "${RED}Coverage generation failed${NC}"

echo ""
echo -e "${GREEN}✅ Verification suite complete!${NC}"
echo "Check coverage/html/index.html for detailed report"
