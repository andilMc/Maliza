class SyncResult {
  final bool success;
  final String message;
  final int? operationsCount;

  const SyncResult._({
    required this.success,
    required this.message,
    this.operationsCount,
  });

  factory SyncResult.success({required String message, int? operationsCount}) =>
      SyncResult._(
        success: true,
        message: message,
        operationsCount: operationsCount,
      );

  factory SyncResult.error(String message) =>
      SyncResult._(success: false, message: message);

  @override
  String toString() =>
      'SyncResult(success: $success, message: $message, operations: $operationsCount)';
}
