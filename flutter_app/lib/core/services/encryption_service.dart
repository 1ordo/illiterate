import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/oaep.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/pointycastle.dart' as pc;

/// End-to-end encryption service for secure API communication.
///
/// Uses RSA + AES hybrid encryption:
/// 1. Generate random AES key
/// 2. Encrypt payload with AES-GCM
/// 3. Encrypt AES key with server's RSA public key
///
/// The encryption format is compatible with Python's cryptography library:
/// - RSA: OAEP padding with SHA-256
/// - AES: 256-bit key, GCM mode with 96-bit IV
/// - GCM tag: Appended to ciphertext (16 bytes)
class EncryptionService {
  RSAPublicKey? _serverPublicKey;
  RSAPrivateKey? _clientPrivateKey;
  bool _initialized = false;

  /// Check if encryption service is ready
  bool get isInitialized => _initialized;

  /// Initialize with server's public key (PEM format)
  /// Optionally provide client private key for decrypting responses
  void initialize(String publicKeyPem, {String? clientPrivateKeyPem}) {
    try {
      _serverPublicKey = _parsePublicKey(publicKeyPem);
      if (clientPrivateKeyPem != null) {
        _clientPrivateKey = _parsePrivateKey(clientPrivateKeyPem);
      }
      _initialized = true;
    } catch (e) {
      throw EncryptionException('Failed to parse keys: $e');
    }
  }

  /// Encrypt data for sending to server
  EncryptedPayload encrypt(Map<String, dynamic> data) {
    if (!_initialized || _serverPublicKey == null) {
      throw EncryptionException('Encryption service not initialized');
    }

    try {
      // Generate random AES key (256-bit)
      final aesKey = _generateRandomBytes(32);
      final iv = _generateRandomBytes(12); // 96-bit IV for GCM

      // Encrypt data with AES-GCM
      // The encrypt package appends the GCM tag to the ciphertext automatically
      final encrypter = Encrypter(AES(Key(aesKey), mode: AESMode.gcm));
      final plaintext = jsonEncode(data);
      final encrypted = encrypter.encrypt(plaintext, iv: IV(iv));

      // Encrypt AES key with RSA-OAEP
      final encryptedKey = _rsaEncrypt(aesKey, _serverPublicKey!);

      return EncryptedPayload(
        encryptedKey: base64Encode(encryptedKey),
        encryptedData: encrypted.base64,
        iv: base64Encode(iv),
        version: '1.0',
      );
    } catch (e) {
      throw EncryptionException('Encryption failed: $e');
    }
  }

  /// Decrypt data received from server
  /// This is used when server sends encrypted responses
  Map<String, dynamic> decryptResponse(EncryptedPayload payload) {
    if (!_initialized) {
      throw EncryptionException('Encryption service not initialized');
    }

    try {
      // Decode base64 components
      final encryptedData = base64Decode(payload.encryptedData);
      final iv = base64Decode(payload.iv);

      // For response decryption, we need to decrypt with the same AES key
      // The server encrypts responses using ITS private key to encrypt the AES key
      // and WE need the server's public key to decrypt (but that's backwards)
      //
      // Actually, for proper bidirectional encryption, the server should:
      // 1. Generate a new AES key for the response
      // 2. Encrypt it with the CLIENT's public key (which we'd need to send)
      //
      // For now, we support a simpler model where responses use a shared secret
      // derived from the original request, OR the response is simply not encrypted
      // and we decrypt using the AES key that was used for the request.

      // If we have a client private key, use RSA decryption
      if (_clientPrivateKey != null && payload.encryptedKey.isNotEmpty) {
        final encryptedKey = base64Decode(payload.encryptedKey);
        final aesKey = _rsaDecrypt(encryptedKey, _clientPrivateKey!);

        // Decrypt with AES-GCM
        final encrypter = Encrypter(AES(Key(aesKey), mode: AESMode.gcm));
        final decrypted = encrypter.decrypt(
          Encrypted(encryptedData),
          iv: IV(iv),
        );

        return jsonDecode(decrypted) as Map<String, dynamic>;
      }

      throw EncryptionException(
        'Cannot decrypt response: client private key not configured',
      );
    } catch (e) {
      if (e is EncryptionException) rethrow;
      throw EncryptionException('Decryption failed: $e');
    }
  }

  /// Decrypt using a known AES key (for session-based decryption)
  Map<String, dynamic> decryptWithKey(
    EncryptedPayload payload,
    Uint8List aesKey,
  ) {
    try {
      final encryptedData = base64Decode(payload.encryptedData);
      final iv = base64Decode(payload.iv);

      final encrypter = Encrypter(AES(Key(aesKey), mode: AESMode.gcm));
      final decrypted = encrypter.decrypt(
        Encrypted(encryptedData),
        iv: IV(iv),
      );

      return jsonDecode(decrypted) as Map<String, dynamic>;
    } catch (e) {
      throw EncryptionException('Decryption with key failed: $e');
    }
  }

  /// Parse PEM-encoded RSA public key
  RSAPublicKey _parsePublicKey(String pem) {
    final lines = pem
        .replaceAll('-----BEGIN PUBLIC KEY-----', '')
        .replaceAll('-----END PUBLIC KEY-----', '')
        .replaceAll('\n', '')
        .replaceAll('\r', '');

    final keyBytes = base64Decode(lines);
    final asn1Parser = pc.ASN1Parser(keyBytes);
    final topLevelSeq = asn1Parser.nextObject() as pc.ASN1Sequence;

    // Parse SubjectPublicKeyInfo structure
    final bitString = topLevelSeq.elements![1] as pc.ASN1BitString;
    final publicKeyAsn = pc.ASN1Parser(bitString.valueBytes!);
    final publicKeySeq = publicKeyAsn.nextObject() as pc.ASN1Sequence;

    final modulus = (publicKeySeq.elements![0] as pc.ASN1Integer).integer!;
    final exponent = (publicKeySeq.elements![1] as pc.ASN1Integer).integer!;

    return RSAPublicKey(modulus, exponent);
  }

  /// Parse PEM-encoded RSA private key (PKCS#8 format)
  RSAPrivateKey _parsePrivateKey(String pem) {
    final lines = pem
        .replaceAll('-----BEGIN PRIVATE KEY-----', '')
        .replaceAll('-----END PRIVATE KEY-----', '')
        .replaceAll('-----BEGIN RSA PRIVATE KEY-----', '')
        .replaceAll('-----END RSA PRIVATE KEY-----', '')
        .replaceAll('\n', '')
        .replaceAll('\r', '');

    final keyBytes = base64Decode(lines);
    final asn1Parser = pc.ASN1Parser(keyBytes);
    final topLevelSeq = asn1Parser.nextObject() as pc.ASN1Sequence;

    // PKCS#8 format: PrivateKeyInfo structure
    // For PKCS#8, we need to extract the private key from the structure
    pc.ASN1Sequence privateKeySeq;

    if (topLevelSeq.elements!.length == 3) {
      // PKCS#8 format
      final privateKeyOctet = topLevelSeq.elements![2] as pc.ASN1OctetString;
      final privateKeyParser = pc.ASN1Parser(privateKeyOctet.valueBytes!);
      privateKeySeq = privateKeyParser.nextObject() as pc.ASN1Sequence;
    } else {
      // PKCS#1 format (raw RSA key)
      privateKeySeq = topLevelSeq;
    }

    // RSAPrivateKey structure
    final modulus = (privateKeySeq.elements![1] as pc.ASN1Integer).integer!;
    final privateExponent =
        (privateKeySeq.elements![3] as pc.ASN1Integer).integer!;
    final p = (privateKeySeq.elements![4] as pc.ASN1Integer).integer!;
    final q = (privateKeySeq.elements![5] as pc.ASN1Integer).integer!;

    // Note: publicExponent is calculated automatically from p, q, and privateExponent
    return RSAPrivateKey(modulus, privateExponent, p, q);
  }

  /// RSA-OAEP encryption
  Uint8List _rsaEncrypt(Uint8List data, RSAPublicKey publicKey) {
    final encryptor = OAEPEncoding.withSHA256(RSAEngine())
      ..init(true, pc.PublicKeyParameter<RSAPublicKey>(publicKey));

    return _processInBlocks(encryptor, data);
  }

  /// RSA-OAEP decryption
  Uint8List _rsaDecrypt(Uint8List data, RSAPrivateKey privateKey) {
    final decryptor = OAEPEncoding.withSHA256(RSAEngine())
      ..init(false, pc.PrivateKeyParameter<RSAPrivateKey>(privateKey));

    return _processInBlocks(decryptor, data);
  }

  /// Process data in blocks for RSA
  Uint8List _processInBlocks(pc.AsymmetricBlockCipher engine, Uint8List data) {
    final inputBlockSize = engine.inputBlockSize;
    final outputBlockSize = engine.outputBlockSize;

    final numBlocks = (data.length / inputBlockSize).ceil();
    final output = Uint8List(numBlocks * outputBlockSize);

    var inputOffset = 0;
    var outputOffset = 0;

    while (inputOffset < data.length) {
      final chunkSize = min(inputBlockSize, data.length - inputOffset);
      final chunk = data.sublist(inputOffset, inputOffset + chunkSize);
      final processed = engine.process(chunk);
      output.setRange(outputOffset, outputOffset + processed.length, processed);
      inputOffset += chunkSize;
      outputOffset += processed.length;
    }

    return output.sublist(0, outputOffset);
  }

  /// Generate cryptographically secure random bytes
  Uint8List _generateRandomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }
}

/// Encrypted payload structure
class EncryptedPayload {
  final String encryptedKey;
  final String encryptedData;
  final String iv;
  final String version;

  const EncryptedPayload({
    required this.encryptedKey,
    required this.encryptedData,
    required this.iv,
    required this.version,
  });

  /// Parse encrypted payload from JSON (for decrypting server responses)
  factory EncryptedPayload.fromJson(Map<String, dynamic> json) {
    return EncryptedPayload(
      encryptedKey: json['encrypted_key'] as String? ?? '',
      encryptedData: json['encrypted_data'] as String,
      iv: json['iv'] as String,
      version: json['version'] as String? ?? '1.0',
    );
  }

  Map<String, dynamic> toJson() => {
        'encrypted_key': encryptedKey,
        'encrypted_data': encryptedData,
        'iv': iv,
        'version': version,
      };
}

/// Encryption exception
class EncryptionException implements Exception {
  final String message;
  const EncryptionException(this.message);

  @override
  String toString() => 'EncryptionException: $message';
}
