import 'package:dio/dio.dart';

class ApiService {
  static final Dio _dio =
      Dio(BaseOptions(baseUrl: 'http://your-backend-url/api'));

  static Future<dynamic> post(
      String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(endpoint, data: data);
      return response.data;
    } catch (e) {
      print('Error: $e');
      throw e;
    }
  }

  static Future<dynamic> get(String endpoint) async {
    try {
      final response = await _dio.get(endpoint);
      return response.data;
    } catch (e) {
      print('Error: $e');
      throw e;
    }
  }
}
