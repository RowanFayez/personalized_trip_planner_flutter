class ApiErrorModel {
	final int? statusCode;
	final String message;
	final dynamic data;

	const ApiErrorModel({
		required this.message,
		this.statusCode,
		this.data,
	});

	@override
	String toString() => 'ApiErrorModel(statusCode: $statusCode, message: $message)';
}

