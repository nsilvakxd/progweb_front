import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/user_avatar.dart';

class VakinhaDetailScreen extends StatefulWidget {
  final int vakinhaId;
  final ApiService apiService;

  const VakinhaDetailScreen({
    Key? key,
    required this.vakinhaId,
    required this.apiService,
  }) : super(key: key);

  @override
  _VakinhaDetailScreenState createState() => _VakinhaDetailScreenState();
}

class _VakinhaDetailScreenState extends State<VakinhaDetailScreen> {
  Future<Vakinha>? _vakinhaFuture;
  bool _isAdmin = false;
  final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final dateFormat = DateFormat('dd/MM/yyyy \'às\' HH:mm');

  @override
  void initState() {
    super.initState();
    _loadVakinhaDetails();
    _isAdmin = Provider.of<AuthService>(context, listen: false)
            .currentUser
            ?.role
            .name ==
        'admin';
  }

  void _loadVakinhaDetails() {
    setState(() {
      _vakinhaFuture = widget.apiService.getVakinhaDetails(widget.vakinhaId);
    });
  }

  void _showAddContributionDialog(Vakinha vakinha) {
     showDialog(
      context: context,
      builder: (context) => _ContributionCreateDialog(
        apiService: widget.apiService,
        vakinhaId: vakinha.id,
        onContributionAdded: () {
          _loadVakinhaDetails(); // Atualiza os detalhes
        },
      ),
    );
  }

  void _showCloseVakinhaDialog(Vakinha vakinha) {
    showDialog(
      context: context,
      builder: (context) => _VakinhaCloseDialog(
        apiService: widget.apiService,
        vakinha: vakinha,
        onVakinhaClosed: () {
          _loadVakinhaDetails(); // Atualiza os detalhes
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes da Vakinha'),
      ),
      body: FutureBuilder<Vakinha>(
        future: _vakinhaFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return Center(child: Text('Vakinha não encontrada.'));
          }

          final vakinha = snapshot.data!;
          final isOpen = vakinha.status == 'open';

          return RefreshIndicator(
            onRefresh: () async => _loadVakinhaDetails(),
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                _buildHeaderCard(vakinha),
                SizedBox(height: 20),
                _buildContributionsSection(vakinha),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FutureBuilder<Vakinha>(
        future: _vakinhaFuture,
        builder: (context, snapshot) {
           if (!snapshot.hasData) return SizedBox.shrink();
           final vakinha = snapshot.data!;
           final isOpen = vakinha.status == 'open';

           return Column(
             mainAxisSize: MainAxisSize.min,
             children: [
                if (isOpen)
                  FloatingActionButton.extended(
                    onPressed: () => _showAddContributionDialog(vakinha),
                    label: Text('Contribuir'),
                    icon: Icon(Icons.add_card),
                  ),
                if (isOpen && _isAdmin)
                  SizedBox(height: 16),
                if (isOpen && _isAdmin)
                   FloatingActionButton.extended(
                    onPressed: () => _showCloseVakinhaDialog(vakinha),
                    label: Text('Fechar Vakinha'),
                    icon: Icon(Icons.check_circle),
                    backgroundColor: Colors.red[700],
                  ),
             ],
           );
        },
      )
    );
  }

  Widget _buildHeaderCard(Vakinha vakinha) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              vakinha.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 12),
            _buildInfoRow(Icons.person, 'Quem busca', vakinha.fetcherName),
            _buildInfoRow(Icons.phone, 'Contato', vakinha.fetcherPhone),
            _buildInfoRow(Icons.admin_panel_settings, 'Criada por', vakinha.createdBy.fullName ?? vakinha.createdBy.email),
            _buildInfoRow(Icons.calendar_today, 'Aberta em', dateFormat.format(vakinha.createdAt)),
            SizedBox(height: 16),
            _buildTotalsGrid(vakinha),
            
            if (vakinha.status == 'closed')
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Divider(),
                     SizedBox(height: 12),
                     Text('Vakinha Fechada', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.red[700], fontWeight: FontWeight.bold)),
                     SizedBox(height: 8),
                    _buildInfoRow(Icons.calendar_today, 'Fechada em', dateFormat.format(vakinha.closedAt!)),
                    _buildInfoRow(Icons.shopping_cart, 'Total Gasto', currencyFormat.format(vakinha.amountSpent ?? 0)),
                    _buildInfoRow(Icons.receipt_long, 'Sobrou', currencyFormat.format(vakinha.amountLeftover ?? 0)),
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsGrid(Vakinha vakinha) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
           _buildTotalColumn(
            'Arrecadado', 
            currencyFormat.format(vakinha.totalCollected),
            Colors.green[800]!
          ),
          _buildTotalColumn(
            'Contribuições', 
            vakinha.contributions.length.toString(),
            Colors.blue[800]!
          ),
          _buildTotalColumn(
            'Status', 
            vakinha.status == 'open' ? 'Aberta' : 'Fechada',
            vakinha.status == 'open' ? Colors.orange[800]! : Colors.red[800]!
          ),
        ],
      ),
    );
  }

  Widget _buildTotalColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label.toUpperCase(), 
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey[700])
        ),
        SizedBox(height: 4),
        Text(
          value, 
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color, 
            fontWeight: FontWeight.bold
          )
        ),
      ],
    );
  }


  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          SizedBox(width: 8),
          Text('$label: ', style: Theme.of(context).textTheme.labelLarge),
          Expanded(
            child: Text(
              value, 
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContributionsSection(Vakinha vakinha) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contribuições (${vakinha.contributions.length})',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        SizedBox(height: 12),
        if (vakinha.contributions.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Ninguém contribuiu ainda.'),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: vakinha.contributions.length,
            itemBuilder: (context, index) {
              final contribution = vakinha.contributions[index];
              return _buildContributionTile(contribution);
            },
          ),
      ],
    );
  }

  Widget _buildContributionTile(Contribution contribution) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: UserAvatar(
          profileImageUrl: contribution.user.profileImageUrl,
          profileImageBase64: contribution.user.profileImageBase64,
          fallbackText: contribution.user.fullName ?? contribution.user.email,
        ),
        title: Text(contribution.user.fullName ?? contribution.user.email),
        subtitle: Text('Pagou em: ${dateFormat.format(contribution.createdAt)}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              currencyFormat.format(contribution.amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green[700],
              ),
            ),
             if (contribution.proofBase64 != null)
              Icon(Icons.receipt, size: 16, color: Colors.blue)
          ],
        ),
        onTap: () {
          if (contribution.proofBase64 != null) {
            _showProofDialog(contribution);
          } else {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('Usuário não anexou comprovante.'))
             );
          }
        },
      ),
    );
  }

  void _showProofDialog(Contribution contribution) {
    showDialog(
      context: context,
      builder: (context) {
         // Tenta decodificar o base64
        ImageProvider? imageProvider;
        try {
          String base64String = contribution.proofBase64!;
          if (base64String.contains(',')) {
            base64String = base64String.split(',')[1];
          }
          final bytes = base64Decode(base64String);
          imageProvider = MemoryImage(bytes);
        } catch (e) {
          imageProvider = null;
        }

        return AlertDialog(
          title: Text('Comprovante de ${contribution.user.fullName}'),
          content: imageProvider != null 
            ? Image(image: imageProvider, fit: BoxFit.contain)
            : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 40),
                SizedBox(height: 16),
                Text('Não foi possível exibir o comprovante (formato inválido ou corrompido).')
              ],
            ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Fechar'),
            )
          ],
        );
      }
    );
  }
}


// --- Diálogo de Adicionar Contribuição ---

class _ContributionCreateDialog extends StatefulWidget {
  final ApiService apiService;
  final int vakinhaId;
  final VoidCallback onContributionAdded;

  const _ContributionCreateDialog({
    required this.apiService,
    required this.vakinhaId,
    required this.onContributionAdded,
  });

  @override
  _ContributionCreateDialogState createState() =>
      _ContributionCreateDialogState();
}

class _ContributionCreateDialogState extends State<_ContributionCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String? _selectedImageBase64;
  String? _selectedImageName;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    // Lógica exata do seu users_screen.dart
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final bytes = file.bytes;

        if (bytes != null) {
          String mimeType = 'image/jpeg'; // default
          final extension = file.extension?.toLowerCase() ?? '';
          if (extension == 'png') mimeType = 'image/png';
          if (extension == 'gif') mimeType = 'image/gif';
          if (extension == 'webp') mimeType = 'image/webp';
          
          String base64String = base64Encode(bytes);
          String dataUrl = 'data:$mimeType;base64,$base64String';

          setState(() {
            _selectedImageBase64 = dataUrl;
            _selectedImageName = file.name;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao selecionar imagem: $e')),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;

    final createData = ContributionCreate(
      amount: amount,
      proofBase64: _selectedImageBase64,
    );

    try {
      await widget.apiService.addContribution(widget.vakinhaId, createData);
      Navigator.of(context).pop(); // Fecha o diálogo
      widget.onContributionAdded(); // Atualiza a lista
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
      title: Text('Adicionar Contribuição'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Valor (R\$)',
                prefixText: 'R\$ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Campo obrigatório';
                final amount = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
                if (amount <= 0) return 'O valor deve ser positivo';
                return null;
              },
            ),
            SizedBox(height: 16),
            Text('Anexar comprovante (opcional):', style: Theme.of(context).textTheme.labelLarge),
            SizedBox(height: 8),
            ElevatedButton.icon(
              icon: Icon(Icons.upload_file),
              label: Text('Selecionar Imagem'),
              onPressed: _pickImage,
            ),
            if (_selectedImageName != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _selectedImageName!,
                  style: TextStyle(fontSize: 12, color: Colors.green[700]),
                  overflow: TextOverflow.ellipsis,
                ),
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
              : Text('Adicionar'),
        ),
      ],
    );
  }
}

// --- Diálogo de Fechar Vakinha ---

class _VakinhaCloseDialog extends StatefulWidget {
  final ApiService apiService;
  final Vakinha vakinha;
  final VoidCallback onVakinhaClosed;

  const _VakinhaCloseDialog({
    required this.apiService,
    required this.vakinha,
    required this.onVakinhaClosed,
  });

  @override
  _VakinhaCloseDialogState createState() => _VakinhaCloseDialogState();
}

class _VakinhaCloseDialogState extends State<_VakinhaCloseDialog> {
   final _formKey = GlobalKey<FormState>();
  final _spentController = TextEditingController();
  final _leftoverController = TextEditingController();
  bool _isLoading = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final spent = double.tryParse(_spentController.text.replaceAll(',', '.')) ?? 0.0;
    final leftover = double.tryParse(_leftoverController.text.replaceAll(',', '.')) ?? 0.0;

    final closeData = VakinhaClose(
      amountSpent: spent,
      amountLeftover: leftover,
    );

    try {
      await widget.apiService.closeVakinha(widget.vakinha.id, closeData);
      Navigator.of(context).pop(); // Fecha o diálogo
      widget.onVakinhaClosed(); // Atualiza a lista
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
     final totalCollected = widget.vakinha.totalCollected;

    return AlertDialog(
      title: Text('Fechar Vakinha'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Arrecadado: R\$ ${totalCollected.toStringAsFixed(2)}'),
            SizedBox(height: 16),
            TextFormField(
              controller: _spentController,
              decoration: InputDecoration(
                labelText: 'Valor Total Gasto (R\$)',
                prefixText: 'R\$ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Campo obrigatório';
                final amount = double.tryParse(value.replaceAll(',', '.')) ?? -1.0;
                if (amount < 0) return 'O valor não pode ser negativo';
                return null;
              },
            ),
            SizedBox(height: 16),
             TextFormField(
              controller: _leftoverController,
              decoration: InputDecoration(
                labelText: 'Valor que Sobrou (R\$)',
                prefixText: 'R\$ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Campo obrigatório';
                final amount = double.tryParse(value.replaceAll(',', '.')) ?? -1.0;
                if (amount < 0) return 'O valor não pode ser negativo';
                return null;
              },
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
              : Text('Confirmar Fechamento'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
        ),
      ],
    );
  }
}