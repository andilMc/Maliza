class WeatherException implements Exception {
  final String message;
  final int statusCode;

  WeatherException(this.message, this.statusCode);

  @override
  String toString() => 'WeatherException: $message (Code: $statusCode)';
}