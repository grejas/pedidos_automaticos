import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/validators.dart';

class QuoteOrderScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  final VoidCallback onUpdated;

  const QuoteOrderScreen({
    super.key,
    required this.order,
    required this.onUpdated,
  });

  @override
  State<QuoteOrderScreen> createState() => _QuoteOrderScreenState();
}

class _QuoteOrderScreenState extends State<QuoteOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productPriceController = TextEditingController();
  final _shippingController = TextEditingController(text: '0');
  final _customsController = TextEditingController(text: '0');
  final _serviceFeeController = TextEditingController(text: '0');
  final _discountController = TextEditingController(text: '0');
  final _notesController = TextEditingController();
  final _rejectionController = TextEditingController();
  DateTime? _estimatedDelivery;
  bool _isLoading = false;
  double _total = 0;

  @override
  void initState() {
    super.initState();
    // Cargar valores existentes si ya fue cotizado antes
    final o = widget.order;
    if (o['product_price_usd'] != null) _productPriceController.text = o['product_price_usd'].toString();
    if (o['shipping_cost_usd'] != null) _shippingController.text = o['shipping_cost_usd'].toString();
    if (o['customs_cost_usd'] != null) _customsController.text = o['customs_cost_usd'].toString();
    if (o['service_fee_usd'] != null) _serviceFeeController.text = o['service_fee_usd'].toString();
    if (o['discount_usd'] != null) _discountController.text = o['discount_usd'].toString();
    if (o['estimated_delivery_date'] != null) {
      _estimatedDelivery = DateTime.tryParse(o['estimated_delivery_date']);
    }
    _calculateTotal();

    _productPriceController.addListener(_calculateTotal);
    _shippingController.addListener(_calculateTotal);
    _customsController.addListener(_calculateTotal);
    _serviceFeeController.addListener(_calculateTotal);
    _discountController.addListener(_calculateTotal);
  }

  @override
  void dispose() {
    _productPriceController.dispose();
    _shippingController.dispose();
    _customsController.dispose();
    _serviceFeeController.dispose();
    _discountController.dispose();
    _notesController.dispose();
    _rejectionController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    final product = double.tryParse(_productPriceController.text) ?? 0;
    final shipping = double.tryParse(_shippingController.text) ?? 0;
    final customs = double.tryParse(_customsController.text) ?? 0;
    final service = double.tryParse(_serviceFeeController.text) ?? 0;
    final discount = double.tryParse(_discountController.text) ?? 0;
    setState(() {
      _total = product + shipping + customs + service - discount;
      if (_total < 0) _total = 0;
    });
  }

  Future<void> _sendQuote() async {
    if (!_formKey.currentState!.validate()) return;
    if (_estimatedDelivery == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona la fecha estimada de entrega'), backgroundColor: AppTheme.warning),
      );
      return;
    }
    if (_total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El total debe ser mayor a 0'), backgroundColor: AppTheme.warning),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userId = supabase.auth.currentUser?.id;
      final operator = await supabase
          .from('operators')
          .select('id')
          .eq('user_id', userId!)
          .single();

      await supabase.from('orders').update({
        'product_price_usd': double.tryParse(_productPriceController.text) ?? 0,
        'shipping_cost_usd': double.tryParse(_shippingController.text) ?? 0,
        'customs_cost_usd': double.tryParse(_customsController.text) ?? 0,
        'service_fee_usd': double.tryParse(_serviceFeeController.text) ?? 0,
        'discount_usd': double.tryParse(_discountController.text) ?? 0,
        'total_quote_usd': _total,
        'estimated_delivery_date': _estimatedDelivery!.toIso8601String().split('T')[0],
        'status': 'QUOTE_SENT',
        'quote_sent_at': DateTime.now().toIso8601String(),
        'assigned_operator_id': operator['id'],
        'quote_generated_by': 'human',
      }).eq('id', widget.order['id']);

      await supabase.from('order_history').insert({
        'order_id': widget.order['id'],
        'operator_id': operator['id'],
        'previous_status': widget.order['status'],
        'new_status': 'QUOTE_SENT',
        'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cotizacion enviada al cliente'), backgroundColor: AppTheme.accent),
        );
        widget.onUpdated();
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showRejectDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rechazar pedido',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 8),
            const Text('Indica la razon del rechazo (requerido)',
                style: TextStyle(fontSize: 13, color: AppTheme.textMid)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _rejectionController,
              maxLines: 3,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Ej: Producto no disponible, precio fuera de rango...',
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_rejectionController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('La razon es requerida'), backgroundColor: AppTheme.danger),
                        );
                        return;
                      }
                      Navigator.pop(ctx);
                      _rejectOrder();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
                    child: const Text('Rechazar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _rejectOrder() async {
    setState(() => _isLoading = true);
    try {
      final userId = supabase.auth.currentUser?.id;
      final operator = await supabase
          .from('operators')
          .select('id')
          .eq('user_id', userId!)
          .single();

      await supabase.from('orders').update({
        'status': 'REJECTED_AUTO',
        'rejection_reason': _rejectionController.text.trim(),
      }).eq('id', widget.order['id']);

      await supabase.from('order_history').insert({
        'order_id': widget.order['id'],
        'operator_id': operator['id'],
        'previous_status': widget.order['status'],
        'new_status': 'REJECTED_AUTO',
        'notes': _rejectionController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pedido rechazado'), backgroundColor: AppTheme.danger),
        );
        widget.onUpdated();
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 14)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _estimatedDelivery = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Cotizar - ${widget.order['order_number'] ?? ''}'),
        actions: [
          TextButton.icon(
            onPressed: _showRejectDialog,
            icon: const Icon(Icons.cancel_rounded, color: Colors.white, size: 18),
            label: const Text('Rechazar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info del pedido
              _buildOrderSummary(),
              const SizedBox(height: 24),

              // Precios
              _sectionTitle('Desglose de precios (USD)'),
              const SizedBox(height: 12),
              _buildPriceField('Precio del producto', _productPriceController, Icons.shopping_bag_rounded, required: true),
              const SizedBox(height: 12),
              _buildPriceField('Envio internacional', _shippingController, Icons.local_shipping_rounded),
              const SizedBox(height: 12),
              _buildPriceField('Aduana / Impuestos', _customsController, Icons.account_balance_rounded),
              const SizedBox(height: 12),
              _buildPriceField('Comision del servicio', _serviceFeeController, Icons.percent_rounded),
              const SizedBox(height: 12),
              _buildPriceField('Descuento', _discountController, Icons.local_offer_rounded, isDiscount: true),
              const SizedBox(height: 16),

              // Total
              _buildTotalCard(),
              const SizedBox(height: 24),

              // Fecha estimada
              _sectionTitle('Fecha estimada de entrega'),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _estimatedDelivery != null ? AppTheme.primary : const Color(0xFFDDE1E7),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          color: _estimatedDelivery != null ? AppTheme.primary : AppTheme.textMid),
                      const SizedBox(width: 12),
                      Text(
                        _estimatedDelivery != null
                            ? '${_estimatedDelivery!.day}/${_estimatedDelivery!.month}/${_estimatedDelivery!.year}'
                            : 'Seleccionar fecha',
                        style: TextStyle(
                          color: _estimatedDelivery != null ? AppTheme.textDark : AppTheme.textMid,
                          fontSize: 15,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right_rounded, color: AppTheme.textLight),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Notas opcionales
              _sectionTitle('Notas para el cliente (opcional)'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Ej: Incluye garantia de 1 año, tiempo de envio aproximado 15 dias...',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 48),
                    child: Icon(Icons.note_outlined, color: AppTheme.textMid),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Boton enviar
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _sendQuote,
                icon: _isLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(_isLoading ? 'Enviando...' : 'Enviar Cotizacion al Cliente'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    final order = widget.order;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(order['order_number'] ?? '-',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order['original_input'] ?? '-',
            style: const TextStyle(fontSize: 13, color: AppTheme.textDark),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (order['client_notes'] != null) ...[
            const SizedBox(height: 6),
            Text('Nota: ${order['client_notes']}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMid, fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 6),
          Text('Cantidad: ${order['quantity'] ?? 1}',
              style: const TextStyle(fontSize: 12, color: AppTheme.textMid)),
        ],
      ),
    );
  }

  Widget _buildPriceField(String label, TextEditingController controller, IconData icon,
      {bool required = false, bool isDiscount = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: isDiscount ? AppTheme.accent : AppTheme.textMid),
        prefixText: '\$ ',
        suffixText: 'USD',
      ),
      validator: required
          ? (v) {
        if (v == null || v.isEmpty) return 'Ingresa el precio del producto';
        if (double.tryParse(v) == null) return 'Ingresa un numero valido';
        if (double.parse(v) <= 0) return 'El precio debe ser mayor a 0';
        return null;
      }
          : (v) {
        if (v != null && v.isNotEmpty && double.tryParse(v) == null) return 'Numero invalido';
        return null;
      },
    );
  }

  Widget _buildTotalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.attach_money_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          const Text('Total cotizacion',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(
            '\$ ${_total.toStringAsFixed(2)} USD',
            style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(title,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.textDark));
}
