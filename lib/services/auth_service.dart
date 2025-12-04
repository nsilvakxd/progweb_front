// lib/services/auth_service.dart

import 'dart:convert'; // <-- IMPORTAÇÃO NOVA
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

  /// Inicializa o SharedPreferences e carrega dados salvos
  Future<void> initializeAuth() async {
    if (_isInitialized) return; // Evita reinicializar

    _prefs = await SharedPreferences.getInstance();
    await _loadSavedAuth();

    // --- MUDANÇA ---
    // Se encontramos um token salvo, precisamos buscar os dados do usuário
    // para validar o token e popular o _currentUser
    if (isAuthenticated) {
      print('Token encontrado no cache, validando e buscando dados do usuário...');
      await _fetchCurrentUser();
    }
    // --- FIM DA MUDANÇA ---

    _isInitialized = true;
  }

  void _configureDio() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(seconds: 30);

    // Configurações específicas para web
    if (kIsWeb) {
      _dio.options.headers.addAll({
        'Accept': 'application/json',
        // O content-type é definido na própria chamada de login
      });
    }

    // Interceptor para logs e debugging
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print('Enviando requisição para: ${options.uri}');
          print('Headers: ${options.headers}');
          print('Data: ${options.data}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          print('Resposta recebida: ${response.statusCode}');
          handler.next(response);
        },
        onError: (error, handler) {
          print('Erro na requisição: ${error.message}');
          print('Tipo do erro: ${error.type}');
          if (error.response != null) {
            print('Status Code: ${error.response!.statusCode}');
            print('Response data: ${error.response!.data}');
          }
          handler.next(error);
        },
      ),
    );
  }

  bool get isAuthenticated => _token != null;
  User? get currentUser => _currentUser;
  String? get token => _token;

  /// Carrega dados de autenticação salvos no localStorage
  Future<void> _loadSavedAuth() async {
    try {
      if (_prefs == null) return;

      _token = _prefs!.getString(_tokenKey);

      // Carrega dados do usuário se existirem
      final userJsonString = _prefs!.getString(_userKey);
      if (userJsonString != null) {
        // --- MUDANÇA ---
        // Agora vamos realmente desserializar o usuário salvo
        _currentUser = User.fromJson(jsonDecode(userJsonString));
        print('Usuário carregado do cache: ${_currentUser?.fullName}');
        // --- FIM DA MUDANÇA ---
      }

      if (_token != null) {
        print('Token carregado do cache.');
        // notifyListeners(); // Não notifica aqui, deixa o initializeAuth controlar
      }
    } catch (e) {
      print('Erro ao carregar autenticação salva (cache corrompido?): $e');
      // Se houver erro, limpa os dados corrompidos
      await _clearSavedAuth();
    }
  }

  /// Salva dados de autenticação no localStorage
  Future<void> _saveAuth() async {
    try {
      if (_prefs == null) return;

      if (_token != null) {
        await _prefs!.setString(_tokenKey, _token!);
        print('Token salvo no cache');
      }

      if (_currentUser != null) {
        // --- MUDANÇA ---
        // Agora vamos realmente serializar o usuário para salvar
        await _prefs!.setString(_userKey, jsonEncode(_currentUser!.toJson()));
        // --- FIM DA MUDANÇA ---
        print('Dados do usuário salvos no cache');
      }
    } catch (e) {
      print('Erro ao salvar autenticação: $e');
    }
  }

  /// Remove dados de autenticação do localStorage
  Future<void> _clearSavedAuth() async {
    try {
      if (_prefs != null) {
        await _prefs!.remove(_tokenKey);
        await _prefs!.remove(_userKey);
        print('Cache de autenticação limpo');
      }
    } catch (e) {
      print('Erro ao limpar cache: $e');
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      // Primeira tentativa: POST com form-urlencoded
      final response = await _dio.post(
        '/auth/login',
        data: {
          'grant_type': 'password',
          'username': email,
          'password': password,
        },
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          headers: {'Accept': 'application/json'},
          // Força a não usar preflight request
          method: 'POST',
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        _token = data['access_token'];

        // Não salva o token ainda, espera buscar o usuário
        
        // --- MUDANÇA ---
        // Buscar dados do usuário atual
        await _fetchCurrentUser();
        // --- FIM DA MUDANÇA ---

        // Se _fetchCurrentUser foi bem sucedido, _currentUser não será nulo
        if (_currentUser != null) {
          await _saveAuth(); // Agora salva o token E o usuário
          notifyListeners();
          return true;
        }
        
        // Se _fetchCurrentUser falhou, _currentUser será nulo e o login falha
        return false;
      }
      return false;
    } catch (e) {
      print('Erro no login: $e');
      if (e is DioException) {
        print('Dio Error: ${e.message}');
        print('Response: ${e.response?.data}');
      }
      // O login alternativo não é mais necessário com o CORS corrigido
      return false;
    }
  }

  // O _tryAlternativeLogin não é mais necessário
  // Future<bool> _tryAlternativeLogin(String email, String password) async { ... }

  // --- FUNÇÃO ATUALIZADA ---
  Future<void> _fetchCurrentUser() async {
    if (_token == null) {
      print("Fetch de usuário falhou: token é nulo.");
      return;
    }

    try {
      // Cria uma instância de Dio APENAS para esta chamada,
      // já com o token de autorização.
      final authDio = Dio();
      authDio.options.baseUrl = baseUrl;
      authDio.options.headers['Authorization'] = 'Bearer $_token';
      authDio.options.headers['Accept'] = 'application/json';

      print('Buscando dados do usuário em /users/me');
      final response = await authDio.get('/users/me');

      if (response.statusCode == 200) {
        // Deserializa o usuário e o armazena
        final user = User.fromJson(response.data);
        setCurrentUser(user); // Isso vai notificar os listeners
        print('Usuário atual definido: ${user.fullName} (${user.role.name})');
      } else {
        // Se falhar (ex: 401), limpa os dados
        print('Falha ao buscar usuário, limpando sessão.');
        await logout(); // Faz o logout completo
      }
    } catch (e) {
      print('Erro ao buscar usuário atual (token pode ter expirado): $e');
      // Se der erro (ex: 401 Unauthorized), faz o logout
      await logout();
    }
  }

  // _tryFetchUserFromAPI foi substituída por _fetchCurrentUser
  // Future<void> _tryFetchUserFromAPI() async { ... }

  // Método para definir o usuário atual externamente
  void setCurrentUser(User? user) {
    _currentUser = user;
    // Não notifica aqui, deixa o login/logout controlar
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;

    // Remove dados do localStorage
    await _clearSavedAuth();

    notifyListeners();
  }

  Map<String, String> get authHeaders {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_token',
    };
  }
}