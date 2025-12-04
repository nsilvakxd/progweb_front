// lib/config/config_web_helper.dart
import 'package:web/web.dart' as web;

// Função que contém a lógica exclusiva para a web.
// Agora considera como ambiente de desenvolvimento SOMENTE quando
// a aplicação estiver rodando em `localhost` ou `127.0.0.1`.
bool isDevelopmentOnWeb() {
  final currentUrl = web.window.location.href;
  return currentUrl.contains('localhost') || currentUrl.contains('127.0.0.1');
}