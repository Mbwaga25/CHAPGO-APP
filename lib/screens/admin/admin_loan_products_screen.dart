import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';

class AdminLoanProductsScreen extends StatefulWidget {
  const AdminLoanProductsScreen({super.key});

  @override
  State<AdminLoanProductsScreen> createState() => _AdminLoanProductsScreenState();
}

class _AdminLoanProductsScreenState extends State<AdminLoanProductsScreen> {
  final _api = ApiService();
  List<dynamic> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) _api.setToken(user.token);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProducts());
  }

  Future<void> _loadProducts() async {
    setState(() => _loading = true);
    try {
      final r = await _api.get('/loans/admin/products');
      if (r is List) {
        setState(() {
          _products = r;
        });
      }
    } catch (e) {
      debugPrint('products load error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load products: $e'), backgroundColor: AppTheme.red, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showFormDialog({Map<String, dynamic>? product}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ProductFormDialog(
        product: product,
        api: _api,
        onSuccess: () {
          Navigator.pop(ctx);
          _loadProducts();
        },
      ),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete the "${product['name']} (${product['code']})" product? Existing loans referencing this product may lose their reference display.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _api.delete('/loans/admin/products/${product['id']}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Product deleted successfully'), backgroundColor: AppTheme.green, behavior: SnackBarBehavior.floating),
          );
        }
        _loadProducts();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: $e'), backgroundColor: AppTheme.red, behavior: SnackBarBehavior.floating),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Loan Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.category_outlined, size: 64, color: AppTheme.grayLight),
                      const SizedBox(height: 16),
                      Text('No loan products found', style: AppTheme.headingMedium),
                      const SizedBox(height: 8),
                      Text('Tap the + button to add a new loan product', style: TextStyle(color: AppTheme.gray)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _products.length,
                  itemBuilder: (context, idx) {
                    final p = _products[idx];
                    final code = p['code'].toString();
                    final name = p['name'].toString();
                    final nameSw = p['name_sw'].toString();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: AppTheme.border, width: 1),
                      ),
                      elevation: 1.5,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: AppTheme.surface,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.gold.withValues(alpha: 0.15),
                            child: Icon(Icons.shopping_bag_outlined, color: AppTheme.gold),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Code: $code  ·  Swahili: $nameSw',
                              style: TextStyle(color: AppTheme.gray, fontSize: 12),
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit_outlined, color: AppTheme.gold, size: 20),
                                onPressed: () => _showFormDialog(product: p),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline, color: AppTheme.red, size: 20),
                                onPressed: () => _confirmDelete(p),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(),
        backgroundColor: AppTheme.gold,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _ProductFormDialog extends StatefulWidget {
  final Map<String, dynamic>? product;
  final ApiService api;
  final VoidCallback onSuccess;

  const _ProductFormDialog({
    this.product,
    required this.api,
    required this.onSuccess,
  });

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _nameSwCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _codeCtrl.text = widget.product!['code'] ?? '';
      _nameCtrl.text = widget.product!['name'] ?? '';
      _nameSwCtrl.text = widget.product!['name_sw'] ?? '';
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _nameSwCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final payload = {
      'code': _codeCtrl.text.trim().toLowerCase(),
      'name': _nameCtrl.text.trim(),
      'name_sw': _nameSwCtrl.text.trim(),
    };

    try {
      if (widget.product == null) {
        await widget.api.post('/loans/admin/products', body: payload);
      } else {
        await widget.api.put('/loans/admin/products/${widget.product!['id']}', body: payload);
      }
      widget.onSuccess();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e'), backgroundColor: AppTheme.red, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.product == null ? 'Create Product' : 'Edit Product';

    return AlertDialog(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _codeCtrl,
                enabled: widget.product == null, // Code cannot be changed once created
                decoration: const InputDecoration(labelText: 'Product Code (e.g. fuel)'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (v.trim().contains(' ')) return 'No spaces allowed';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'English Name (e.g. Fuel)'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameSwCtrl,
                decoration: const InputDecoration(labelText: 'Swahili Name (e.g. Mafuta)'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save'),
        ),
      ],
    );
  }
}
