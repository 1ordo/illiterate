#!/bin/bash
# =============================================================================
# ileterate - RSA Key Generation Script
# =============================================================================
# Generates RSA key pair for end-to-end encryption
# Usage: ./scripts/generate-keys.sh
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
KEYS_DIR="$PROJECT_ROOT/keys"

echo "=============================================="
echo "  ileterate - RSA Key Generation"
echo "=============================================="

# Create keys directory if it doesn't exist
mkdir -p "$KEYS_DIR"

# Check if keys already exist
if [ -f "$KEYS_DIR/private.pem" ] || [ -f "$KEYS_DIR/public.pem" ]; then
    echo ""
    echo "WARNING: Keys already exist in $KEYS_DIR"
    read -p "Do you want to overwrite them? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

echo ""
echo "Generating 2048-bit RSA key pair..."

# Generate private key
openssl genrsa -out "$KEYS_DIR/private.pem" 2048

# Extract public key
openssl rsa -in "$KEYS_DIR/private.pem" -pubout -out "$KEYS_DIR/public.pem"

# Set permissions (restrictive for private key)
chmod 600 "$KEYS_DIR/private.pem"
chmod 644 "$KEYS_DIR/public.pem"

echo ""
echo "=============================================="
echo "  Keys generated successfully!"
echo "=============================================="
echo ""
echo "  Private key: $KEYS_DIR/private.pem"
echo "  Public key:  $KEYS_DIR/public.pem"
echo ""
echo "IMPORTANT:"
echo "  - Keep the private key secure and never commit it to git"
echo "  - The public key can be shared with clients"
echo "  - Enable encryption by setting ENCRYPTION_ENABLED=true in .env"
echo ""
