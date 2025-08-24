class NetworkResponse<T> {
  final T data;
  final int statusCode;
  final Map<String, String> headers;
  final Duration responseTime;

  const NetworkResponse({
    required this.data,
    required this.statusCode,
    required this.headers,
    required this.responseTime,
  });
}
