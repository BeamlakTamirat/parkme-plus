class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final String? error;
  final int? statusCode;
  final DateTime timestamp;

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.error,
    this.statusCode,
    required this.timestamp,
  });

  factory ApiResponse.success({
    required T data,
    String message = 'Success',
    int statusCode = 200,
  }) {
    return ApiResponse(
      success: true,
      message: message,
      data: data,
      statusCode: statusCode,
      timestamp: DateTime.now(),
    );
  }

  factory ApiResponse.error({
    required String error,
    String message = 'Error',
    int statusCode = 400,
  }) {
    return ApiResponse(
      success: false,
      message: message,
      error: error,
      statusCode: statusCode,
      timestamp: DateTime.now(),
    );
  }

  bool get isSuccess => success && error == null;
  bool get isError => !success || error != null;
}
