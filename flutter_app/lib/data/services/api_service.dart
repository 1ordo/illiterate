import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/encryption_service.dart';
import '../models/check_request.dart';
import '../models/correction_result.dart';

/// API service for communicating with the ileterate grammar checking backend.
///
/// Supports:
/// - API key authentication (X-API-Key header)
/// - End-to-end encryption (RSA + AES hybrid)
/// - Automatic retry and error handling
class ApiService {
  late final Dio _dio;
  final EncryptionService? _encryptionService;
  String? _serverPublicKey;
  bool _encryptionInitialized = false;

  ApiService({EncryptionService? encryptionService})
      : _encryptionService = encryptionService {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: Duration(milliseconds: AppConfig.requestTimeout),
        receiveTimeout: Duration(milliseconds: AppConfig.requestTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // Add API key header if configured
          if (AppConfig.apiKey != null) 'X-API-Key': AppConfig.apiKey,
        },
      ),
    );

    if (AppConfig.debugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (msg) => debugPrint('[API] $msg'),
      ));
    }
  }

  /// Initialize encryption by fetching server's public key
  /// This should be called before making encrypted requests
  Future<bool> initializeEncryption() async {
    if (!AppConfig.encryptionEnabled || _encryptionService == null) {
      debugPrint('[API] Encryption not enabled or service not provided');
      return false;
    }

    if (_encryptionInitialized) {
      return true;
    }

    try {
      debugPrint('[API] Fetching server public key...');
      final response = await _dio.get('/security/public-key');
      _serverPublicKey = response.data['public_key'];

      if (_serverPublicKey != null) {
        _encryptionService!.initialize(_serverPublicKey!);
        _encryptionInitialized = true;
        debugPrint('[API] Encryption initialized successfully');
        debugPrint('[API] Algorithm: ${response.data['algorithm']}');
        debugPrint('[API] Key Encryption: ${response.data['key_encryption']}');
        return true;
      }
    } catch (e) {
      debugPrint('[API] Failed to initialize encryption: $e');
    }
    return false;
  }

  /// Check if encryption is ready
  bool get isEncryptionReady =>
      _encryptionInitialized &&
      _encryptionService != null &&
      _encryptionService!.isInitialized;

  /// Check grammar for the given text.
  Future<CorrectionResult> checkGrammar(CheckRequest request) async {
    try {
      final data = request.toJson();

      // Initialize encryption if enabled but not yet initialized
      if (AppConfig.encryptionEnabled && !_encryptionInitialized) {
        await initializeEncryption();
      }

      // Encrypt if enabled and initialized
      if (_shouldEncrypt()) {
        return await _checkGrammarEncrypted(data);
      }

      final response = await _dio.post(
        ApiConstants.check,
        data: data,
      );

      return CorrectionResult.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Check grammar with encrypted request and response
  Future<CorrectionResult> _checkGrammarEncrypted(
      Map<String, dynamic> data) async {
    // Encrypt the request payload
    final encrypted = _encryptionService!.encrypt(data);

    debugPrint('[API] Sending encrypted request...');

    final response = await _dio.post(
      ApiConstants.check,
      data: encrypted.toJson(),
      options: Options(
        headers: {
          'Content-Type': 'application/x-encrypted',
          // Request encrypted response from server
          'Accept': 'application/x-encrypted, application/json',
        },
      ),
    );

    // Check if response is encrypted
    final contentType = response.headers.value('content-type') ?? '';
    if (contentType.contains('application/x-encrypted')) {
      debugPrint('[API] Received encrypted response, decrypting...');
      // Parse and decrypt the response
      final encryptedResponse = EncryptedPayload.fromJson(
        response.data as Map<String, dynamic>,
      );
      final decryptedData = _encryptionService!.decryptResponse(encryptedResponse);
      return CorrectionResult.fromJson(decryptedData);
    }

    // Response is not encrypted (server may not support response encryption)
    debugPrint('[API] Received plain response');
    return CorrectionResult.fromJson(response.data);
  }

  /// Check if encryption should be used
  bool _shouldEncrypt() {
    return AppConfig.encryptionEnabled &&
        _encryptionService != null &&
        _encryptionService!.isInitialized;
  }

  /// Get list of supported languages.
  Future<List<Map<String, dynamic>>> getLanguages() async {
    try {
      final response = await _dio.get(ApiConstants.languages);
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Check health of the backend services.
  Future<Map<String, dynamic>> checkHealth() async {
    try {
      final response = await _dio.get(ApiConstants.health);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update API key at runtime
  void setApiKey(String? apiKey) {
    if (apiKey != null && apiKey.isNotEmpty) {
      _dio.options.headers['X-API-Key'] = apiKey;
    } else {
      _dio.options.headers.remove('X-API-Key');
    }
  }

  /// Update base URL at runtime
  void setBaseUrl(String url) {
    _dio.options.baseUrl = url;
  }

  /// Handle Dio errors and convert to user-friendly messages.
  Exception _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          'Connection timeout. Please check your connection.',
          code: 'TIMEOUT',
        );

      case DioExceptionType.connectionError:
        return const ApiException(
          'Cannot connect to server. Please check if the backend is running.',
          code: 'CONNECTION_ERROR',
        );

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['detail'] ?? 'Server error';

        if (statusCode == 401) {
          return const ApiException(
            'Authentication required. Please check your API key.',
            code: 'UNAUTHORIZED',
          );
        } else if (statusCode == 403) {
          return const ApiException(
            'Invalid API key.',
            code: 'FORBIDDEN',
          );
        } else if (statusCode == 400) {
          return ApiException(message, code: 'BAD_REQUEST');
        } else if (statusCode == 404) {
          return const ApiException('Endpoint not found', code: 'NOT_FOUND');
        } else if (statusCode == 500) {
          return const ApiException(
            'Server error. Please try again later.',
            code: 'SERVER_ERROR',
          );
        }
        return ApiException(message, code: 'HTTP_$statusCode');

      default:
        return ApiException(
          e.message ?? 'An unexpected error occurred',
          code: 'UNKNOWN',
        );
    }
  }
}

/// Custom API exception with error code.
class ApiException implements Exception {
  final String message;
  final String code;

  const ApiException(this.message, {this.code = 'UNKNOWN'});

  @override
  String toString() => 'ApiException($code): $message';

  /// Check if this is an authentication error
  bool get isAuthError => code == 'UNAUTHORIZED' || code == 'FORBIDDEN';

  /// Check if this is a connection error
  bool get isConnectionError =>
      code == 'TIMEOUT' || code == 'CONNECTION_ERROR';
}
