import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/supabase_constants.dart';

class NewOrderScreen extends StatefulWidget {
  const NewOrderScreen({super.key});

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _linkController = TextEditingController();
  final _textController = TextEditingController();
  final _notesController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  String _inputType = 'link';
  String _platform = 'other';
  bool _isLoading = false;
  String? _errorMessage;

  final List<Map<String, dynamic>> _platforms = [
    {'value': 'amazon', 'label': 'Amazon', 'icon': '??'},
    {'value': 'aliexpress', 'label': 'AliExpress', 'icon': '??'},
    {'value': 'alibaba', 'label': 'Alibaba', 'icon': '??'},
    {'value': 'temu', 'label': 'Temu', 'icon': '???'},
    {'value': 'walmart', 'label': 'Walmart', 'icon': '??'},
    {'value': 'mercadolibre', 'label': 'MercadoLibre', 'icon': '??'},
    {'value': 'other', 'label': 'Otro', 'icon': '??'},
  ];

  @override
  void dispose() {
    _linkController.dispose();
    _textController.dispose();
    _notesController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  String _generateOrderNumber() {
    final now = DateTime.now();
    final random = (now.millisecondsSinceEpoch % 9000 + 1000).toString();
    return 'FS-${now.year}-$random';
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('No hay sesion activa');

      final client = await supabase
          .from('clients')
          .select('id')
          .eq('app_user_id', userId)
          .single();

      final orderNumber = _generateOrderNumber();
      final originalInput = _inputType == 'link'
          ? _linkController.text.trim()
          : _textController.text.trim();

      await supabase.from('orders').insert({
        'order_number': orderNumber,
        'client_id': client['id'],
        'status': 'RECEIVED',
        'source': 'app',
        'original_input_type': _inputType,
        'original_input': originalInput,
        'client_notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        'quantity': int.tryParse(_quantityController.text) ?? 1,
        'product_source_platform': _platform,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pedido $orderNumber creado exitosamente'),
            backgroundColor: AppTheme.accent,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al crear el pedido: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Nuevo Pedido')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Como quieres describir el producto?'),
              const SizedBox(height: 12),
              _buildInputTypeSelector(),
              const SizedBox(height: 24),

              if (_inputType == 'link') ...[
                _sectionTitle('Link del producto'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _linkController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    hintText: 'https://www.amazon.com/...',
                    prefixIcon: Icon(Icons.link_rounded, color: AppTheme.textMid),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Ingresa el link del producto';
                    if (!v.startsWith('http')) return 'El link debe comenzar con http';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _sectionTitle('Plataforma'),
                const SizedBox(height: 8),
                _buildPlatformSelector(),
              ] else if (_inputType == 'text') ...[
                _sectionTitle('Describe el producto'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _textController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Ej: iPhone 15 Pro Max 256GB color negro...',
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 60),
                      child: Icon(Icons.text_fields_rounded, color: AppTheme.textMid),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Describe el producto';
                    if (v.trim().length < 10) return 'La descripcion es muy corta';
                    return null;
                  },
                ),
              ] else ...[
                _buildImagePlaceholder(),
              ],

              const SizedBox(height: 24),
              _sectionTitle('Cantidad'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: '1',
                  prefixIcon: Icon(Icons.numbers_rounded, color: AppTheme.textMid),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingresa la cantidad';
                  if (int.tryParse(v) == null || int.parse(v) < 1) return 'Cantidad invalida';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              _sectionTitle('Notas adicionales (opcional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Color, talla, version, instrucciones especiales...',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.note_outlined, color: AppTheme.textMid),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.secondary.withOpacity(0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: AppTheme.secondary, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Un cotizador revisara tu pedido y te enviara una cotizacion pronto.',
                        style: TextStyle(fontSize: 12, color: AppTheme.secondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.danger, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_errorMessage!,
                          style: const TextStyle(color: AppTheme.danger, fontSize: 13))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              ElevatedButton(
                onPressed: _isLoading ? null : _submitOrder,
                child: _isLoading
                    ? const SizedBox(height: 22, width: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Enviar Pedido'),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textDark));
  }

  Widget _buildInputTypeSelector() {
    final types = [
      {'value': 'link', 'label': 'Link', 'icon': Icons.link_rounded},
      {'value': 'text', 'label': 'Texto', 'icon': Icons.text_fields_rounded},
      {'value': 'image', 'label': 'Imagen', 'icon': Icons.image_rounded},
    ];

    return Row(
      children: types.asMap().entries.map((entry) {
        final type = entry.value;
        final selected = _inputType == type['value'];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _inputType = type['value'] as String),
            child: Container(
              margin: EdgeInsets.only(right: entry.key < types.length - 1 ? 10 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: selected ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selected ? AppTheme.primary : const Color(0xFFDDE1E7)),
                boxShadow: selected ? [BoxShadow(color: AppTheme.primary.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))] : [],
              ),
              child: Column(
                children: [
                  Icon(type['icon'] as IconData, color: selected ? Colors.white : AppTheme.textMid, size: 24),
                  const SizedBox(height: 4),
                  Text(type['label'] as String,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : AppTheme.textMid)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlatformSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE1E7)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _platform,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          borderRadius: BorderRadius.circular(12),
          items: _platforms.map((p) {
            return DropdownMenuItem<String>(
              value: p['value'] as String,
              child: Text('${p['icon']} ${p['label']}'),
            );
          }).toList(),
          onChanged: (val) => setState(() => _platform = val!),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subida de imagenes proximamente'), backgroundColor: AppTheme.primary),
        );
      },
      child: Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_rounded, size: 48, color: AppTheme.primary.withOpacity(0.5)),
            const SizedBox(height: 8),
            const Text('Toca para subir una imagen', style: TextStyle(color: AppTheme.textMid, fontSize: 14)),
            const SizedBox(height: 4),
            const Text('JPG, PNG (max 5MB)', style: TextStyle(color: AppTheme.textLight, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
