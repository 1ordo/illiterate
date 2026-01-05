import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/oaep.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/pointycastle.dart' as pc;

/// End-to-end encryption service for secure API communication.
///
/// Uses RSA + AES hybrid encryption:
/// 1. Generate random AES key
/// 2. Encrypt payload with AES-GCM
/// 3. Encrypt AES key with server's RSA public key
class EncryptionService {
  RSAPublicKey? _serverPublicKey;
  bool _initialized = false;

  /// Check if encryption service is ready
  bool get isInitialized => _initialized;

  /// Initialize with server's public key (PEM format)
  void initialize(String publicKeyPem) {
    try {
      _serverPublicKey = _parsePublicKey(publicKeyPem);
      _initialized = true;
    } catch (e) {
      throw EncryptionException('Failed to parse public key: $e');
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

  /// Decrypt data received from server (if server supports encrypted responses)
  Map<String, dynamic> decrypt(EncryptedPayload payload, Uint8List privateKey) {
    throw UnimplementedError(
      'Client-side decryption not implemented. '
      'Server responses are typically not encrypted for mobile clients.',
    );
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

  /// RSA-OAEP encryption
  Uint8List _rsaEncrypt(Uint8List data, RSAPublicKey publicKey) {
    final encryptor = OAEPEncoding.withSHA256(RSAEngine())
      ..init(true, pc.PublicKeyParameter<RSAPublicKey>(publicKey));

    return _processInBlocks(encryptor, data);
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
