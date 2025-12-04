// lib/config/config.dart
import 'package:flutter/foundation.dart';

// Importa nosso seletor, que fornecerá a função correta para a plataforma.
import 'config_helper.dart';

class Config {
  // URLs da API
  static const String productionApiUrl = 'https://progweb_front.onrender.com';
  static const String developmentApiUrl = 'http://localhost:8000';

  // A lógica agora é mais limpa e segura para todas as plataformas.
  static String get apiUrl {
    // Caso 1: Ambiente de desenvolvimento (qualquer plataforma)
    // - Para web, isDevelopmentOnWeb() verifica a URL.
    // - Para mobile/desktop, kReleaseMode é falso.
    if ((kIsWeb && isDevelopmentOnWeb()) || (!kIsWeb && !kReleaseMode)) {
      return developmentApiUrl;
    }

    // Caso 2: Ambiente de produção (padrão)
    return productionApiUrl;
  }

  // O resto da sua classe permanece igual.
  static bool get isWeb => kIsWeb;
  static const String appVersion = '1.0.0';
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}