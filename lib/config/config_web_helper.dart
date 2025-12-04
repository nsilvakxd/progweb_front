// lib/config/config_web_helper.dart
import 'package:web/web.dart' as web;

// Função que contém a lógica exclusiva para a web.
bool isDevelopmentOnWeb() {
  final currentUrl = web.window.location.href;
  // Verifica se está rodando em localhost OU se NÃO está na URL de produção
  return currentUrl.contains('localhost') || 
         currentUrl.contains('127.0.0.1') || 
         !currentUrl.contains('app-front-vakinha.onrender.com');
}