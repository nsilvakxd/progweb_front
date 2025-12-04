import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'vakinha_detail_screen.dart'; // Nova tela de detalhes

class VakinhasListScreen extends StatefulWidget {
  final ApiService apiService;

  const VakinhasListScreen({Key? key, required this.apiService}) : super(key: key);

  @override
  _VakinhasListScreenState createState() => _VakinhasListScreenState();
}

class _VakinhasListScreenState extends State<VakinhasListScreen> {
  late Future<List<Vakinha>> _vakinhasFuture;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadVakinhas();
    _isAdmin = Provider.of<AuthService>(context, listen: false)
            .currentUser
            ?.role
            .name ==
        'admin';
  }

  void _loadVakinhas() {
    setState(() {
      _vakinhasFuture = widget.apiService.getOpenVakinhas();
    });
  }

  void _navigateToDetail(Vakinha vakinha) async {
    // Navega para a tela de detalhes e espera um resultado
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VakinhaDetailScreen(
          vakinhaId: vakinha.id,
          apiService: widget.apiService,
        ),
      ),
    );

    // Se a tela de detalhes retornar 'true', atualiza a lista
    if (result == true) {
      _loadVakinhas();
    }
  }

  void _showCreateVakinhaDialog() {
    showDialog(
      context: context,
      builder: (context) => _VakinhaCreateDialog(
        apiService: widget.apiService,
        onVakinhaCreated: () {
          _loadVakinhas(); // Atualiza a lista após criar
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Vakinhas Abertas',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                if (_isAdmin)
                  ElevatedButton.icon(
                    icon: Icon(Icons.add),
                    label: Text('Nova Vakinha'),
                    onPressed: _showCreateVakinhaDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Vakinha>>(
              future: _vakinhasFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('Nenhuma vakinha aberta encontrada.'));
                }

                final vakinhas = snapshot.data!;
                return RefreshIndicator(
                  onRefresh: () async => _loadVakinhas(),
                  child: ListView.builder(
                    itemCount: vakinhas.length,
                    itemBuilder: (context, index) {
                      final vakinha = vakinhas[index];
                      return _buildVakinhaCard(vakinha);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVakinhaCard(Vakinha vakinha) {
    final dateFormat = DateFormat('dd/MM/yyyy \'às\' HH:mm');
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToDetail(vakinha),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vakinha.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[700]),
                  SizedBox(width: 4),
                  Text(
                    'Criada por: ${vakinha.createdBy.fullName ?? vakinha.createdBy.email}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                   Icon(Icons.calendar_today, size: 16, color: Colors.grey[700]),
                   SizedBox(width: 4),
                   Text(
                    'Aberta em: ${dateFormat.format(vakinha.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Arrecadado', style: Theme.of(context).textTheme.labelMedium),
                      Text(
                        currencyFormat.format(vakinha.totalCollected),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quem Busca', style: Theme.of(context).textTheme.labelMedium),
                      Text(
                        vakinha.fetcherName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Diálogo de Criação de Vakinha ---

class _VakinhaCreateDialog extends StatefulWidget {
  final ApiService apiService;
  final VoidCallback onVakinhaCreated;

  const _VakinhaCreateDialog({
    required this.apiService,
    required this.onVakinhaCreated,
  });

  @override
  _VakinhaCreateDialogState createState() => _VakinhaCreateDialogState();
}

class _VakinhaCreateDialogState extends State<_VakinhaCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Vakinha do Lanche');
  final _fetcherNameController = TextEditingController();
  final _fetcherPhoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final createData = VakinhaCreate(
      name: _nameController.text.isNotEmpty ? _nameController.text : null,
      fetcherName: _fetcherNameController.text,
      fetcherPhone: _fetcherPhoneController.text,
    );

    try {
      await widget.apiService.createVakinha(createData);
      Navigator.of(context).pop(); // Fecha o diálogo
      widget.onVakinhaCreated(); // Atualiza a lista
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Abrir Nova Vakinha'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nome da Vakinha',
                hintText: 'Vakinha do Lanche',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _fetcherNameController,
              decoration: InputDecoration(
                labelText: 'Quem vai buscar?',
                border: OutlineInputBorder(),
              ),
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Campo obrigatório'
                  : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _fetcherPhoneController,
              decoration: InputDecoration(
                labelText: 'Telefone de quem vai buscar',
                border: OutlineInputBorder(),
              ),
               validator: (value) => (value == null || value.isEmpty)
                  ? 'Campo obrigatório'
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text('Abrir Vakinha'),
        ),
      ],
    );
  }
}