class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;

  const ApiException({required this.message, this.statusCode, this.errorCode});

  @override
  String toString() => 'ApiException: $message';
}
