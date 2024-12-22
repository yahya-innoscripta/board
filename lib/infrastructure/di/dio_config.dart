import 'package:dio/dio.dart';

class DioConfig {
  static Dio createRestDio(String apiToken) {
    final dio = Dio(BaseOptions(
      baseUrl: 'https://api.todoist.com/rest/v2',
      headers: {
        'Authorization': 'Bearer $apiToken',
      },
    ));

    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));

    return dio;
  }

  static Dio createSyncDio(String apiToken) {
    return Dio(BaseOptions(
      baseUrl: 'https://api.todoist.com/sync/v9',
      headers: {
        'Authorization': 'Bearer $apiToken',
      },
    ));
  }
}
