import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../widgets/user_avatar.dart';
import 'users_screen.dart';
import 'roles_screen.dart';
// --- NOVA IMPORTAÇÃO ---
import 'vakinha_list_screen.dart'; 

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  late List<Widget> _adminScreens;
  late List<Widget> _userScreens;
  late List<NavigationRailDestination> _adminDestinations;
  late List<NavigationRailDestination> _userDestinations;

  late ApiService _apiService;
  late AuthService _authService;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _authService = Provider.of<AuthService>(context, listen: false);
    _apiService = ApiService(_authService);
    
    // Verifica se é admin
    _isAdmin = _authService.currentUser?.role.name == 'admin';

    // Telas de Admin
    _adminScreens = [
      // --- MUDANÇA: Tela principal agora é Vakinhas ---
      VakinhasListScreen(apiService: _apiService), // index 0
      UsersScreen(apiService: _apiService),      // index 1
      RolesScreen(apiService: _apiService),      // index 2
    ];

    // Telas de User
    _userScreens = [
      VakinhasListScreen(apiService: _apiService), // index 0
    ];

    // Destinos de Admin
    _adminDestinations = [
      // --- MUDANÇA: Tela principal agora é Vakinhas ---
      NavigationRailDestination(
        icon: Icon(Icons.savings_outlined),
        selectedIcon: Icon(Icons.savings),
        label: Text('Vakinhas'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.people_outline),
        selectedIcon: Icon(Icons.people),
        label: Text('Usuários'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.security_outlined),
        selectedIcon: Icon(Icons.security),
        label: Text('Roles'),
      ),
    ];

    // Destinos de User
    _userDestinations = [
       NavigationRailDestination(
        icon: Icon(Icons.savings_outlined),
        selectedIcon: Icon(Icons.savings),
        label: Text('Vakinhas'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Escolhe as telas e destinos com base na role
    final destinations = _isAdmin ? _adminDestinations : _userDestinations;
    final screens = _isAdmin ? _adminScreens : _userScreens;

    // Garante que o índice não estoure se for um user
    if (!_isAdmin && _selectedIndex >= screens.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        // --- MUDANÇA: Título dinâmico ---
        title: Text(_isAdmin ? 'Painel Admin' : 'Vakinha do Lanche'),
        actions: [
          Consumer<AuthService>(
            builder: (context, authService, child) {
              final currentUser = authService.currentUser;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (currentUser != null) ...[
                    Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            currentUser.fullName ?? 'Usuário',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            currentUser.role.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      child: Container(
                        padding: EdgeInsets.all(4),
                        child: UserAvatar(
                          profileImageUrl: currentUser.profileImageUrl,
                          profileImageBase64: currentUser.profileImageBase64,
                          fallbackText: currentUser.fullName?.isNotEmpty == true
                              ? currentUser.fullName![0].toUpperCase()
                              : 'U',
                          size: 36,
                        ),
                      ),
                      onSelected: (value) async {
                        if (value == 'logout') {
                          await authService.logout();
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'profile',
                          enabled: false, // Desabilitado por enquanto
                          child: Row(
                            children: [
                              Icon(Icons.person, size: 18),
                              SizedBox(width: 8),
                              Text('Perfil'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout, size: 18),
                              SizedBox(width: 8),
                              Text('Sair'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ] else
                    IconButton(
                      icon: Icon(Icons.logout),
                      onPressed: () async => await authService.logout(),
                    ),
                ],
              );
            },
          ),
          SizedBox(width: 8), // Espaçamento da borda
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: destinations, // Usa a lista de destinos correta
          ),
          VerticalDivider(thickness: 1, width: 1),
          Expanded(child: screens[_selectedIndex]), // Usa a lista de telas correta
        ],
      ),
    );
  }
}