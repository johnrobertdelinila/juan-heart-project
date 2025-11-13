#!/bin/bash
# Extract SSL Certificate Pins for Juan Heart Mobile
#
# This script extracts SHA-256 public key pins from SSL certificates
# for use in certificate pinning implementation.
#
# Usage:
#   ./extract_certificate_pins.sh <hostname> [port]
#
# Examples:
#   ./extract_certificate_pins.sh api.juanheart.ph
#   ./extract_certificate_pins.sh api.juanheart.ph 443
#   ./extract_certificate_pins.sh maps.googleapis.com

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if hostname provided
if [ -z "$1" ]; then
  echo -e "${RED}Error: Hostname required${NC}"
  echo ""
  echo "Usage: $0 <hostname> [port]"
  echo ""
  echo "Examples:"
  echo "  $0 api.juanheart.ph"
  echo "  $0 api.juanheart.ph 443"
  echo "  $0 maps.googleapis.com"
  exit 1
fi

HOSTNAME="$1"
PORT="${2:-443}"  # Default to 443 if not specified

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}SSL Certificate Pin Extractor${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}Target:${NC} $HOSTNAME:$PORT"
echo ""

# Check if OpenSSL is installed
if ! command -v openssl &> /dev/null; then
  echo -e "${RED}Error: OpenSSL not found${NC}"
  echo ""
  echo "Install OpenSSL:"
  echo "  macOS:   brew install openssl"
  echo "  Ubuntu:  sudo apt-get install openssl"
  echo "  CentOS:  sudo yum install openssl"
  exit 1
fi

echo -e "${YELLOW}Step 1:${NC} Connecting to $HOSTNAME:$PORT..."

# Test connection
if ! timeout 5 bash -c "echo > /dev/tcp/$HOSTNAME/$PORT" 2>/dev/null; then
  echo -e "${RED}Error: Cannot connect to $HOSTNAME:$PORT${NC}"
  echo ""
  echo "Possible reasons:"
  echo "  - Server is down"
  echo "  - Incorrect hostname or port"
  echo "  - Firewall blocking connection"
  echo "  - Server does not use SSL/TLS"
  exit 1
fi

echo -e "${GREEN}✓ Connection successful${NC}"
echo ""

echo -e "${YELLOW}Step 2:${NC} Extracting certificate..."

# Extract certificate information
CERT_INFO=$(echo | openssl s_client -servername "$HOSTNAME" -connect "$HOSTNAME:$PORT" 2>/dev/null)

if [ -z "$CERT_INFO" ]; then
  echo -e "${RED}Error: Could not retrieve certificate${NC}"
  exit 1
fi

echo -e "${GREEN}✓ Certificate retrieved${NC}"
echo ""

echo -e "${YELLOW}Step 3:${NC} Computing public key pin (SHA-256)..."

# Extract public key pin (SHA-256)
PIN=$(echo | openssl s_client -servername "$HOSTNAME" -connect "$HOSTNAME:$PORT" 2>/dev/null \
  | openssl x509 -pubkey -noout \
  | openssl pkey -pubin -outform der \
  | openssl dgst -sha256 -binary \
  | openssl enc -base64)

if [ -z "$PIN" ]; then
  echo -e "${RED}Error: Could not compute certificate pin${NC}"
  exit 1
fi

echo -e "${GREEN}✓ Pin computed successfully${NC}"
echo ""

# Extract certificate details for verification
SUBJECT=$(echo "$CERT_INFO" | openssl x509 -noout -subject 2>/dev/null | sed 's/subject=//')
ISSUER=$(echo "$CERT_INFO" | openssl x509 -noout -issuer 2>/dev/null | sed 's/issuer=//')
VALID_FROM=$(echo "$CERT_INFO" | openssl x509 -noout -startdate 2>/dev/null | sed 's/notBefore=//')
VALID_UNTIL=$(echo "$CERT_INFO" | openssl x509 -noout -enddate 2>/dev/null | sed 's/notAfter=//')

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Certificate Details${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}Hostname:${NC}     $HOSTNAME"
echo -e "${YELLOW}Port:${NC}         $PORT"
echo -e "${YELLOW}Subject:${NC}      $SUBJECT"
echo -e "${YELLOW}Issuer:${NC}       $ISSUER"
echo -e "${YELLOW}Valid From:${NC}   $VALID_FROM"
echo -e "${YELLOW}Valid Until:${NC}  $VALID_UNTIL"
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Certificate Pin (SHA-256)${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}$PIN${NC}"
echo ""

# Generate Dart code snippet
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Dart Code Snippet${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "// Add to lib/config/pinned_certificates.dart"
echo ""
echo "class YourServicePins {"
echo "  const YourServicePins();"
echo ""
echo "  String get hostname => '$HOSTNAME';"
echo ""
echo "  String get primaryPin => '$PIN';"
echo ""
echo "  List<String> get backupPins => ["
echo "    // Add backup pins here"
echo "  ];"
echo ""
echo "  List<String> get allPins => [primaryPin, ...backupPins];"
echo ""
echo "  String get primaryExpiryDate => '$(date -j -f "%b %d %H:%M:%S %Y %Z" "$VALID_UNTIL" "+%Y-%m-%d" 2>/dev/null || echo "YYYY-MM-DD")';"
echo ""
echo "  int get rotationWarningDays => 90;"
echo "}"
echo ""

# Calculate days until expiry
if command -v gdate &> /dev/null; then
  # Use GNU date if available (more reliable for date parsing)
  EXPIRY_EPOCH=$(gdate -d "$(echo "$VALID_UNTIL" | sed 's/ GMT//')" +%s 2>/dev/null || echo "0")
else
  # Fallback to BSD date (macOS)
  EXPIRY_EPOCH=$(date -j -f "%b %d %H:%M:%S %Y %Z" "$VALID_UNTIL" +%s 2>/dev/null || echo "0")
fi

if [ "$EXPIRY_EPOCH" != "0" ]; then
  NOW_EPOCH=$(date +%s)
  DAYS_UNTIL_EXPIRY=$(( ($EXPIRY_EPOCH - $NOW_EPOCH) / 86400 ))

  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}Certificate Status${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo ""

  if [ $DAYS_UNTIL_EXPIRY -lt 0 ]; then
    echo -e "${RED}⚠️  Certificate EXPIRED $((-$DAYS_UNTIL_EXPIRY)) days ago${NC}"
  elif [ $DAYS_UNTIL_EXPIRY -lt 30 ]; then
    echo -e "${RED}⚠️  Certificate expires in $DAYS_UNTIL_EXPIRY days (URGENT)${NC}"
  elif [ $DAYS_UNTIL_EXPIRY -lt 90 ]; then
    echo -e "${YELLOW}⚠️  Certificate expires in $DAYS_UNTIL_EXPIRY days (action needed)${NC}"
  else
    echo -e "${GREEN}✓ Certificate valid for $DAYS_UNTIL_EXPIRY days${NC}"
  fi
  echo ""
fi

# Save to file
OUTPUT_FILE="certificate_pins_$(echo "$HOSTNAME" | tr '.' '_').txt"
cat > "$OUTPUT_FILE" << EOF
Certificate Pin Extraction Results
===================================

Date: $(date)
Hostname: $HOSTNAME
Port: $PORT

Certificate Details:
--------------------
Subject: $SUBJECT
Issuer: $ISSUER
Valid From: $VALID_FROM
Valid Until: $VALID_UNTIL

Certificate Pin (SHA-256):
--------------------------
$PIN

Dart Code:
----------
String get primaryPin => '$PIN';

EOF

echo -e "${GREEN}✓ Results saved to: $OUTPUT_FILE${NC}"
echo ""

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Next Steps${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "1. Copy the pin to lib/config/pinned_certificates.dart"
echo "2. Add at least one backup pin (from backup certificate)"
echo "3. Set the expiry date correctly"
echo "4. Test the implementation"
echo "5. Deploy with certificate pinning enabled"
echo ""
echo -e "${YELLOW}Important:${NC}"
echo "  - Always maintain backup pins for rotation"
echo "  - Monitor certificate expiry dates"
echo "  - Test thoroughly before production deployment"
echo ""
