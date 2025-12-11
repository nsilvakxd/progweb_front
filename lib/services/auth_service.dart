// lib/services/auth_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../config/config.dart';

class AuthService extends ChangeNotifier {
  static String get baseUrl => Config.apiUrl;
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'current_user';

  String? _token;
  User? _currentUser;
  late Dio _dio;
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  AuthService() {
    _dio = Dio();
    _configureDio();
  }

  // Getters públicos
  bool get isAuthenticated => _token != null;
  User? get currentUser => _currentUser;
  String? get token => _token;

  /// Header auxiliar para ser usado em outros Services (VakinhaService, etc)
  Map<String, String> get authHeaders {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_token',
    };
  }

  /// Configuração inicial do Dio (Timeouts e Interceptors)
  void _configureDio() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(seconds: 30);

    if (kIsWeb) {
      _dio.options.headers['Accept'] = 'application/json';
    }

    // Interceptor para logs (ajuda muito no debug)
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint('--> ${options.method} ${options.uri}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('<-- ${response.statusCode} ${response.requestOptions.uri}');
          handler.next(response);
        },
        onError: (error, handler) {
          debugPrint('Error: ${error.message}');
          debugPrint('Response: ${error.response?.data}');
          handler.next(error);
        },
      ),
    );
  }

  /// Inicializa o SharedPreferences e restaura a sessão
  Future<void> initializeAuth() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();
    await _loadSavedAuth();

    // Se existe um token salvo, tenta validar buscando os dados atuais do usuário
    if (isAuthenticated) {
      debugPrint('Token encontrado. Validando sessão...');
      await _fetchCurrentUser();
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// Realiza o Login
  Future<bool> login(String email, String password) async {
    try {
      // 1. Obter o Token (Form-UrlEncoded)
      final response = await _dio.post(
        '/auth/login',
        data: {
          'grant_type': 'password', // Padrão OAuth2
          'username': email,        // FastAPI exige 'username'
          'password': password,
        },
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        _token = data['access_token'];

        // 2. Com o token em mãos, buscar os detalhes do usuário (/users/me)
        bool userFetched = await _fetchCurrentUser();

        if (userFetched && _currentUser != null) {
          // 3. Se tudo deu certo, salva no disco
          await _saveAuth();
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Erro no login: $e');
      return false;
    }
  }

  /// Busca os dados do usuário logado usando o token atual
  Future<bool> _fetchCurrentUser() async {
    if (_token == null) return false;

    try {
      // Usa a instância principal do _dio, injetando o Header manualmente nesta requisição
      final response = await _dio.get(
        '/users/me',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_token',
          },
        ),
      );

      if (response.statusCode == 200) {
        _currentUser = User.fromJson(response.data);
        debugPrint('Usuário atualizado: ${_currentUser?.fullName}');
        return true;
      } else {
        await logout();
        return false;
      }
    } catch (e) {
      debugPrint('Erro ao buscar usuário (Token expirado?): $e');
      // Se der erro 401 (Unauthorized), força logout
      if (e is DioException && e.response?.statusCode == 401) {
        await logout();
      }
      return false;
    }
  }

  /// Logout completo
  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    await _clearSavedAuth();
    notifyListeners();
  }

  // --- MÉTODOS DE PERSISTÊNCIA (PRIVADOS) ---

  Future<void> _loadSavedAuth() async {
    try {
      if (_prefs == null) return;

      _token = _prefs!.getString(_tokenKey);
      final userJson = _prefs!.getString(_userKey);

      if (userJson != null) {
        _currentUser = User.fromJson(jsonDecode(userJson));
      }
    } catch (e) {
      debugPrint('Erro ao carregar cache: $e');
      await _clearSavedAuth();
    }
  }

  Future<void> _saveAuth() async {
    try {
      if (_prefs == null) return;

      if (_token != null) {
        await _prefs!.setString(_tokenKey, _token!);
      }
      if (_currentUser != null) {
        await _prefs!.setString(_userKey, jsonEncode(_currentUser!.toJson()));
      }
    } catch (e) {
      debugPrint('Erro ao salvar auth: $e');
    }
  }

  Future<void> _clearSavedAuth() async {
    if (_prefs != null) {
      await _prefs!.remove(_tokenKey);
      await _prefs!.remove(_userKey);
    }
  }
}