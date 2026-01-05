#!/bin/bash
# =============================================================================
# ileterate - API Key Generation Script
# =============================================================================
# Generates a secure random API key
# Usage: ./scripts/generate-api-key.sh
# =============================================================================

set -e

echo "=============================================="
echo "  ileterate - API Key Generation"
echo "=============================================="
echo ""

# Generate a 32-byte (256-bit) random key in hex format
API_KEY=$(openssl rand -hex 32)

echo "Generated API Key:"
echo ""
echo "  $API_KEY"
echo ""
echo "=============================================="
echo ""
echo "To use this key:"
echo ""
echo "1. Add to your .env file:"
echo "   API_KEY=$API_KEY"
echo ""
echo "2. Include in client requests:"
echo "   curl -H 'X-API-Key: $API_KEY' http://localhost:8000/check"
echo ""
echo "3. For Flutter app, set in environment config"
echo ""
