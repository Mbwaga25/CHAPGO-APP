import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiConfig {
  static const String baseUrl = 'https://api.chapgo.co.tz/api/v1';
  static const String localUrl = 'http://localhost:5000/api/v1';

  static String _activeUrl = baseUrl;

  static String get apiBase => _activeUrl;

  /// Check if the local development server is reachable.
  /// If reachable, use the local development URL (or android emulator fallback).
  /// If unreachable (or not in debug mode), fallback to the production online URL.
  static Future<void> checkHostFallback() async {
    if (!kDebugMode) {
      _activeUrl = baseUrl;
      return;
    }

    final uri = Uri.parse(localUrl);
    final host = uri.host;
    final port = uri.port;

    if (kIsWeb) {
      try {
        // Web: Ping the local URL with a short timeout to see if it responds
        await http.get(Uri.parse(localUrl)).timeout(const Duration(milliseconds: 800));
        _activeUrl = localUrl;
      } catch (_) {
        _activeUrl = baseUrl;
      }
      return;
    }

    // Native platforms: Attempt a quick socket connection to the local URL
    try {
      final socket = await Socket.connect(host, port, timeout: const Duration(milliseconds: 800));
      socket.destroy();
      _activeUrl = localUrl;
      return;
    } catch (_) {}

    // Android Emulator specific fallback for localhost loopback
    if (host == 'localhost' || host == '127.0.0.1') {
      try {
        final socket = await Socket.connect('10.0.2.2', port, timeout: const Duration(milliseconds: 800));
        socket.destroy();
        _activeUrl = 'http://10.0.2.2:$port/api/v1';
        return;
      } catch (_) {}
    }

    _activeUrl = baseUrl;
  }
}

