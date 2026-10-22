import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Singleton Dio client with JWT token injection and base URL config.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  // ── Production (Render) ──
  static const String _prodBaseUrl =
      'https://melbet-report-kidu.onrender.com/api';

  // ── Local development (uncomment the one you need) ──
  // static const String _localWeb     = 'http://127.0.0.1:3000/api';
  // static const String _localAndroid = 'http://10.0.2.2:3000/api';
  // static const String _localDesktop = 'http://localhost:3000/api';

  /// Toggle this to `false` when developing locally.
  static const bool useProduction = true;

  static String get defaultBaseUrl {
    if (useProduction) return _prodBaseUrl;
    // Local dev fallback
    if (kIsWeb) return 'http://127.0.0.1:3000/api';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    }
    return 'http://localhost:3000/api';
  }

  static const String _tokenKey = 'jwt_token';

  late final Dio _dio;
  String? _token;

  Future<void> init({String? customBaseUrl}) async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);

    _dio = Dio(
      BaseOptions(
        baseUrl: customBaseUrl ?? defaultBaseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Attach JWT on every request if available
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          handler.next(options);
        },
        onError: (DioException err, handler) {
          handler.next(err);
        },
      ),
    );
  }

  Dio get dio => _dio;

  String? get token => _token;

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  bool get hasToken => _token != null && _token!.isNotEmpty;
}
