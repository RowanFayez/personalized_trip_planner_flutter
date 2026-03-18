import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_constants.dart';

class DioFactory {
  DioFactory._();

  static Dio create({String? baseUrl}) {
    final options = BaseOptions(
      baseUrl: (baseUrl ?? ApiConstants.baseUrl).trim(),
      connectTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      headers: <String, dynamic>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    final dio = Dio(options);

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestHeader: false,
          requestBody: true,
          responseHeader: false,
          responseBody: false,
          error: true,
          logPrint: (obj) => debugPrint(obj.toString()),
        ),
      );
    }

    return dio;
  }
}
