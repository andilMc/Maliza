import 'package:maliza/core/error/api_exception.dart';

class ApiResult<T> {
  final T? data;
  final bool isSuccess;
  final String? errorMessage;
  final String? errorCode;

  const ApiResult.success(this.data)
      : isSuccess = true,
        errorMessage = null,
        errorCode = null;

  const ApiResult.error({
    required String message,
    String? code,
  })  : data = null,
        isSuccess = false,
        errorMessage = message,
        errorCode = code;

  T get dataOrThrow {
    if (isSuccess && data != null) {
      return data!;
    }
    throw ApiException(
      message: errorMessage ?? 'Erreur inconnue',
      errorCode: errorCode,
    );
  }
}