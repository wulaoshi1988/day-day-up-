import 'package:dio/dio.dart';

import 'api_client.dart';

class DioApiClient implements ApiClient {
  DioApiClient({
    required String baseUrl,
    required String accessToken,
    Dio? dio,
  }) : _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl, headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        }));

  final Dio _dio;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(path, queryParameters: query);
    return response.data ?? <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(path, data: body);
    return response.data ?? <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(path, data: body);
    return response.data ?? <String, dynamic>{};
  }
}
