#!/bin/bash

################################################################################
# Juan Heart Mobile - Environment Setup Script
# Version: 1.0
# Last Updated: January 10, 2025
# Status: NOT VERIFIED AND TESTED
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_ROOT/.env"
ENV_EXAMPLE="$PROJECT_ROOT/.env.example"

################################################################################
# Functions
################################################################################

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}  Juan Heart Mobile - Environment Setup${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

check_env_example() {
    if [ ! -f "$ENV_EXAMPLE" ]; then
        print_error ".env.example not found at: $ENV_EXAMPLE"
        exit 1
    fi
    print_success ".env.example found"
}

check_existing_env() {
    if [ -f "$ENV_FILE" ]; then
        print_warning ".env file already exists"
        read -p "Do you want to overwrite it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Keeping existing .env file"
            return 1
        fi
    fi
    return 0
}

create_env_file() {
    print_info "Creating .env file from template..."
    cp "$ENV_EXAMPLE" "$ENV_FILE"
    print_success ".env file created at: $ENV_FILE"
}

check_git_status() {
    print_info "Checking git status for .env file..."

    if git ls-files --error-unmatch .env &>/dev/null; then
        print_error ".env is tracked by git! This is a security risk!"
        print_warning "Removing .env from git tracking..."
        git rm --cached .env
        print_success ".env removed from git tracking"
    else
        print_success ".env is not tracked by git (good!)"
    fi
}

verify_gitignore() {
    print_info "Verifying .gitignore contains .env..."

    GITIGNORE_FILE="$PROJECT_ROOT/.gitignore"

    if [ ! -f "$GITIGNORE_FILE" ]; then
        print_error ".gitignore not found!"
        return 1
    fi

    if grep -q "^\.env$" "$GITIGNORE_FILE" || grep -q "^\.env$" "$GITIGNORE_FILE"; then
        print_success ".env is in .gitignore"
    else
        print_warning ".env not found in .gitignore, adding it..."
        echo -e "\n# Environment variables (security critical)\n.env" >> "$GITIGNORE_FILE"
        print_success "Added .env to .gitignore"
    fi
}

check_credentials() {
    print_info "Checking for placeholder credentials..."

    local has_placeholders=false

    # Check for Twilio placeholder
    if grep -q "ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" "$ENV_FILE"; then
        print_warning "Twilio ACCOUNT_SID is still a placeholder"
        has_placeholders=true
    fi

    # Check for Google API placeholder
    if grep -q "GOOGLE_GEOCODING_API_KEY=AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" "$ENV_FILE"; then
        print_warning "Google Geocoding API Key is still a placeholder"
        has_placeholders=true
    fi

    if [ "$has_placeholders" = true ]; then
        echo ""
        print_warning "You need to replace placeholder credentials with real values"
        print_info "See docs/CREDENTIAL_MANAGEMENT.md for instructions"
    else
        print_success "No placeholder credentials detected"
    fi
}

print_next_steps() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Next Steps${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo "1. Edit .env file with your actual credentials:"
    echo -e "   ${YELLOW}nano $ENV_FILE${NC}"
    echo ""
    echo "2. Obtain required credentials:"
    echo "   - Twilio: https://console.twilio.com/"
    echo "   - Google Geocoding API: https://console.cloud.google.com/"
    echo ""
    echo "3. Read the security documentation:"
    echo -e "   ${YELLOW}cat docs/CREDENTIAL_MANAGEMENT.md${NC}"
    echo ""
    echo "4. Verify setup:"
    echo -e "   ${YELLOW}flutter pub get${NC}"
    echo -e "   ${YELLOW}flutter run${NC}"
    echo ""
    print_warning "NEVER commit .env to version control!"
    echo ""
}

################################################################################
# Main Script
################################################################################

main() {
    print_header

    # Step 1: Check for .env.example
    check_env_example

    # Step 2: Check if .env already exists
    if check_existing_env; then
        # Step 3: Create .env file
        create_env_file
    fi

    # Step 4: Verify git status
    if git rev-parse --git-dir > /dev/null 2>&1; then
        check_git_status
        verify_gitignore
    else
        print_warning "Not a git repository, skipping git checks"
    fi

    # Step 5: Check for placeholder credentials
    if [ -f "$ENV_FILE" ]; then
        check_credentials
    fi

    # Step 6: Print next steps
    print_next_steps

    print_success "Environment setup complete!"
}

# Run main function
main
