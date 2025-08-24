
import 'package:maliza/core/models/network_error_type.dart';

class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  final String? responseBody;
  final NetworkErrorType type;

  const NetworkException({
    required this.message,
    required this.type,
    this.statusCode,
    this.responseBody,
  });

  @override
  String toString() => 'NetworkException: $message (${type.name})';
}