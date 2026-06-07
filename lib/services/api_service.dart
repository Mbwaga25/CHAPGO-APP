import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  String? _token;
  String? customSaccoId;
  String? customStationId;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
    if (customSaccoId != null) 'x-sacco-id': customSaccoId!,
    if (customStationId != null) 'x-station-id': customStationId!,
  };

  Future<dynamic> request(String method, String path, {dynamic body}) async {
    final uri = Uri.parse('${ApiConfig.apiBase}$path');
    final headers = _headers;

    http.Response response;
    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers);
          break;
        default:
          throw ApiException('Unsupported method: $method');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }

    dynamic data;
    try {
      data = jsonDecode(response.body);
    } catch (_) {}

    if (response.statusCode == 401) {
      throw ApiException('Session expired. Please login again.', statusCode: 401);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data is Map ? (data['message'] ?? 'Request failed') : 'Request failed';
      throw ApiException(message.toString(), statusCode: response.statusCode);
    }

    return data;
  }

  Future<dynamic> get(String path) => request('GET', path);
  Future<dynamic> post(String path, {dynamic body}) => request('POST', path, body: body);
  Future<dynamic> put(String path, {dynamic body}) => request('PUT', path, body: body);

  Future<dynamic> multipartRequest(
    String method,
    String path, {
    Map<String, String>? fields,
    String? fileKey,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    final uri = Uri.parse('${ApiConfig.apiBase}$path');
    final request = http.MultipartRequest(method.toUpperCase(), uri);
    
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    
    if (fields != null) {
      request.fields.addAll(fields);
    }
    
    if (fileKey != null && fileBytes != null) {
      final multipartFile = http.MultipartFile.fromBytes(
        fileKey,
        fileBytes,
        filename: fileName ?? 'upload.jpg',
      );
      request.files.add(multipartFile);
    }
    
    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {}

      if (response.statusCode == 401) {
        throw ApiException('Session expired. Please login again.', statusCode: 401);
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = data is Map ? (data['message'] ?? 'Request failed') : 'Request failed';
        throw ApiException(message.toString(), statusCode: response.statusCode);
      }

      return data;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }
}
