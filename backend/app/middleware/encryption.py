"""
End-to-End Encryption Middleware.

Provides RSA + AES hybrid encryption for secure request/response handling.
- Client encrypts with server's public RSA key
- Server decrypts with private RSA key
- AES used for payload encryption (RSA encrypts the AES key)
"""

import base64
import json
import logging
import os
from typing import Optional, Tuple
from dataclasses import dataclass

from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import JSONResponse

logger = logging.getLogger(__name__)

# Cryptography imports (optional dependency)
try:
    from cryptography.hazmat.primitives import hashes, serialization
    from cryptography.hazmat.primitives.asymmetric import rsa, padding
    from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
    from cryptography.hazmat.backends import default_backend
    CRYPTO_AVAILABLE = True
except ImportError:
    CRYPTO_AVAILABLE = False
    logger.warning("cryptography package not installed. Encryption features disabled.")


@dataclass
class EncryptedPayload:
    """Structure for encrypted request/response payloads."""
    encrypted_key: str  # Base64 encoded RSA-encrypted AES key
    encrypted_data: str  # Base64 encoded AES-encrypted data
    iv: str  # Base64 encoded initialization vector
    version: str = "1.0"


class EncryptionService:
    """
    Handles RSA + AES hybrid encryption for E2E security.

    The encryption flow:
    1. Client generates random AES key
    2. Client encrypts payload with AES key
    3. Client encrypts AES key with server's RSA public key
    4. Server decrypts AES key with RSA private key
    5. Server decrypts payload with AES key
    """

    def __init__(self):
        self._private_key = None
        self._public_key = None
        self._initialized = False

    def initialize(
        self,
        private_key_path: Optional[str] = None,
        public_key_path: Optional[str] = None
    ) -> bool:
        """
        Initialize encryption service with RSA keys.

        Args:
            private_key_path: Path to PEM-encoded private key
            public_key_path: Path to PEM-encoded public key

        Returns:
            True if initialization successful
        """
        if not CRYPTO_AVAILABLE:
            logger.error("Cannot initialize encryption: cryptography package not installed")
            return False

        try:
            # Load private key if path provided
            if private_key_path and os.path.exists(private_key_path):
                with open(private_key_path, "rb") as f:
                    self._private_key = serialization.load_pem_private_key(
                        f.read(),
                        password=None,
                        backend=default_backend()
                    )
                logger.info(f"Loaded RSA private key from {private_key_path}")

            # Load public key if path provided
            if public_key_path and os.path.exists(public_key_path):
                with open(public_key_path, "rb") as f:
                    self._public_key = serialization.load_pem_public_key(
                        f.read(),
                        backend=default_backend()
                    )
                logger.info(f"Loaded RSA public key from {public_key_path}")

            # Derive public key from private if not provided
            if self._private_key and not self._public_key:
                self._public_key = self._private_key.public_key()

            self._initialized = self._private_key is not None
            return self._initialized

        except Exception as e:
            logger.error(f"Failed to initialize encryption: {e}")
            return False

    @property
    def is_available(self) -> bool:
        """Check if encryption service is available."""
        return CRYPTO_AVAILABLE and self._initialized

    def get_public_key_pem(self) -> Optional[str]:
        """Get the public key in PEM format for clients."""
        if not self._public_key:
            return None

        pem = self._public_key.public_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PublicFormat.SubjectPublicKeyInfo
        )
        return pem.decode('utf-8')

    def decrypt_payload(self, encrypted: EncryptedPayload) -> dict:
        """
        Decrypt an encrypted payload from the client.

        Args:
            encrypted: The encrypted payload containing encrypted key, data, and IV

        Returns:
            Decrypted JSON data as dictionary

        Raises:
            ValueError: If decryption fails
        """
        if not self._private_key:
            raise ValueError("Private key not loaded")

        try:
            # Decode base64 components
            encrypted_key = base64.b64decode(encrypted.encrypted_key)
            encrypted_data = base64.b64decode(encrypted.encrypted_data)
            iv = base64.b64decode(encrypted.iv)

            # Decrypt the AES key with RSA
            aes_key = self._private_key.decrypt(
                encrypted_key,
                padding.OAEP(
                    mgf=padding.MGF1(algorithm=hashes.SHA256()),
                    algorithm=hashes.SHA256(),
                    label=None
                )
            )

            # Decrypt the data with AES
            cipher = Cipher(
                algorithms.AES(aes_key),
                modes.GCM(iv),
                backend=default_backend()
            )
            decryptor = cipher.decryptor()

            # GCM tag is appended to ciphertext
            tag_length = 16
            ciphertext = encrypted_data[:-tag_length]
            tag = encrypted_data[-tag_length:]

            decryptor = cipher.decryptor()
            decryptor.authenticate_additional_data(b"")

            # For GCM, we need to handle the tag separately
            cipher = Cipher(
                algorithms.AES(aes_key),
                modes.GCM(iv, tag),
                backend=default_backend()
            )
            decryptor = cipher.decryptor()
            decrypted = decryptor.update(ciphertext) + decryptor.finalize()

            return json.loads(decrypted.decode('utf-8'))

        except Exception as e:
            logger.error(f"Decryption failed: {e}")
            raise ValueError(f"Failed to decrypt payload: {e}")

    def encrypt_payload(self, data: dict) -> EncryptedPayload:
        """
        Encrypt a response payload for the client.

        Args:
            data: Dictionary to encrypt

        Returns:
            EncryptedPayload with encrypted data

        Raises:
            ValueError: If encryption fails
        """
        if not self._public_key:
            raise ValueError("Public key not loaded")

        try:
            # Generate random AES key and IV
            aes_key = os.urandom(32)  # 256-bit key
            iv = os.urandom(12)  # 96-bit IV for GCM

            # Encrypt data with AES-GCM
            cipher = Cipher(
                algorithms.AES(aes_key),
                modes.GCM(iv),
                backend=default_backend()
            )
            encryptor = cipher.encryptor()

            plaintext = json.dumps(data).encode('utf-8')
            ciphertext = encryptor.update(plaintext) + encryptor.finalize()

            # Append GCM tag to ciphertext
            encrypted_data = ciphertext + encryptor.tag

            # Encrypt AES key with RSA
            encrypted_key = self._public_key.encrypt(
                aes_key,
                padding.OAEP(
                    mgf=padding.MGF1(algorithm=hashes.SHA256()),
                    algorithm=hashes.SHA256(),
                    label=None
                )
            )

            return EncryptedPayload(
                encrypted_key=base64.b64encode(encrypted_key).decode('utf-8'),
                encrypted_data=base64.b64encode(encrypted_data).decode('utf-8'),
                iv=base64.b64encode(iv).decode('utf-8'),
                version="1.0"
            )

        except Exception as e:
            logger.error(f"Encryption failed: {e}")
            raise ValueError(f"Failed to encrypt payload: {e}")

    @staticmethod
    def generate_key_pair(key_size: int = 2048) -> Tuple[bytes, bytes]:
        """
        Generate a new RSA key pair.

        Args:
            key_size: RSA key size in bits (default 2048)

        Returns:
            Tuple of (private_key_pem, public_key_pem)
        """
        if not CRYPTO_AVAILABLE:
            raise RuntimeError("cryptography package not installed")

        private_key = rsa.generate_private_key(
            public_exponent=65537,
            key_size=key_size,
            backend=default_backend()
        )

        private_pem = private_key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.PKCS8,
            encryption_algorithm=serialization.NoEncryption()
        )

        public_pem = private_key.public_key().public_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PublicFormat.SubjectPublicKeyInfo
        )

        return private_pem, public_pem


# Global encryption service instance
encryption_service = EncryptionService()


class EncryptionMiddleware(BaseHTTPMiddleware):
    """
    FastAPI middleware for handling encrypted requests/responses.

    When encryption is enabled:
    - POST requests with Content-Type: application/x-encrypted are decrypted
    - Responses are encrypted if Accept: application/x-encrypted is set
    """

    def __init__(self, app, encryption_svc: EncryptionService = None):
        super().__init__(app)
        self.encryption = encryption_svc or encryption_service

    async def dispatch(self, request: Request, call_next):
        """Process request, handling encryption if needed."""
        # Check if this is an encrypted request
        content_type = request.headers.get("content-type", "")
        is_encrypted_request = "application/x-encrypted" in content_type

        if is_encrypted_request and self.encryption.is_available:
            try:
                # Read and decrypt the request body
                body = await request.body()
                encrypted_data = json.loads(body)
                encrypted_payload = EncryptedPayload(**encrypted_data)

                # Decrypt and replace request body
                decrypted_data = self.encryption.decrypt_payload(encrypted_payload)

                # Create new request with decrypted body
                # Store decrypted data in request state
                request.state.decrypted_body = decrypted_data

            except Exception as e:
                logger.error(f"Failed to decrypt request: {e}")
                return JSONResponse(
                    status_code=400,
                    content={"detail": "Failed to decrypt request"}
                )

        # Process the request
        response = await call_next(request)

        # Check if client wants encrypted response
        accept = request.headers.get("accept", "")
        wants_encrypted = "application/x-encrypted" in accept

        if wants_encrypted and self.encryption.is_available:
            try:
                # Read response body
                body = b""
                async for chunk in response.body_iterator:
                    body += chunk

                # Encrypt response
                response_data = json.loads(body)
                encrypted = self.encryption.encrypt_payload(response_data)

                return JSONResponse(
                    content={
                        "encrypted_key": encrypted.encrypted_key,
                        "encrypted_data": encrypted.encrypted_data,
                        "iv": encrypted.iv,
                        "version": encrypted.version
                    },
                    headers={"Content-Type": "application/x-encrypted+json"}
                )

            except Exception as e:
                logger.error(f"Failed to encrypt response: {e}")
                # Return original response on encryption failure

        return response
