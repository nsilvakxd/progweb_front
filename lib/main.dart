import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'config/config.dart';
import 'widgets/environment_banner.dart';

void main() {
  // Imprime a URL da API sendo usada no console
  debugPrint('🚀 App iniciado');
  debugPrint('🌐 API URL: ${Config.apiUrl}');
  debugPrint('📦 Versão: ${Config.appVersion}');
  debugPrint('🔧 Modo: ${Config.apiUrl.contains('localhost') ? 'DESENVOLVIMENTO' : 'PRODUÇÃO'}');
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthService())],
      child: EnvironmentBanner(
        child: MaterialApp(
          title: 'Admin App',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          home: AuthWrapper(),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.initializeAuth();

    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Carregando...'),
            ],
          ),
        ),
      );
    }

    return Consumer<AuthService>(
      builder: (context, authService, child) {
        if (authService.isAuthenticated) {
          return DashboardScreen();
        } else {
          return LoginScreen();
        }
      },
    );
  }
}
