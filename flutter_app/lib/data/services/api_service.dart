import 'package:dio/dio.dart';
import '../../core/config/app_config.dart';
import '../../core/constants/api_constants.dart';
import '../models/check_request.dart';
import '../models/correction_result.dart';

/// API service for communicating with the grammar checking backend.
class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: Duration(milliseconds: AppConfig.requestTimeout),
        receiveTimeout: Duration(milliseconds: AppConfig.requestTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    if (AppConfig.debugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (msg) => print('[API] $msg'),
      ));
    }
  }

  /// Check grammar for the given text.
  Future<CorrectionResult> checkGrammar(CheckRequest request) async {
    try {
      final response = await _dio.post(
        ApiConstants.check,
        data: request.toJson(),
      );

      return CorrectionResult.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
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

  /// Handle Dio errors and convert to user-friendly messages.
  Exception _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          'Connection timeout. Please check your connection.',
          code: 'TIMEOUT',
        );

      case DioExceptionType.connectionError:
        return ApiException(
          'Cannot connect to server. Please check if the backend is running.',
          code: 'CONNECTION_ERROR',
        );

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['detail'] ?? 'Server error';

        if (statusCode == 400) {
          return ApiException(message, code: 'BAD_REQUEST');
        } else if (statusCode == 404) {
          return ApiException('Endpoint not found', code: 'NOT_FOUND');
        } else if (statusCode == 500) {
          return ApiException(
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
}
