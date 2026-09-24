import 'package:dio/dio.dart';

String friendlyErrorMessage(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Request timed out. Please try again.';
      case DioExceptionType.connectionError:
        return 'Cannot reach the server. Check your internet connection.';
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        return 'Received invalid response ($code).';
      default:
        return 'A network error occurred. Please try again.';
    }
  }
  return 'An unexpected error occurred.';
}
