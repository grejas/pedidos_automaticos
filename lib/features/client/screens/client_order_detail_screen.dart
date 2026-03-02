import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/supabase_constants.dart';

class ClientOrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  final VoidCallback onUpdated;

  const ClientOrderDetailScreen({
    super.key,
    required this.order,
    required this.onUpdated,
  });

  @override
  State<ClientOrderDetailScreen> createState() => _ClientOrderDetailScreenState();
}

class _ClientOrderDetailScreenState extends State<ClientOrderDetailScreen> {
  late Map<String, dynamic> _order;
  bool _isLoading = false;
  bool _loadingHistory = true;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final data = await supabase
          .from('order_history')
          .select('id, previous_status, new_status, notes, created_at, operators(full_name)')
          .eq('order_id', _order['id'])
          .order('created_at', ascending: false);

      setState(() {
        _history = List<Map<String, dynamic>>.from(data);
        _loadingHistory = false;
      });
    } catch (e) {
      setState(() => _loadingHistory = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'RECEIVED': return AppTheme.secondary;
      case 'ANALYZING': return AppTheme.warning;
      case 'SEARCHING_PRICES': return AppTheme.warning;
      case 'QUOTE_GENERATED': return const Color(0xFF8E44AD);
      case 'QUOTE_SENT': return const Color(0xFF8E44AD);
      case 'AWAITING_CONFIRMATION': return AppTheme.warning;
      case 'CONFIRMED': return AppTheme.accent;
      case 'PAYMENT_PENDING': return AppTheme.warning;
      case 'PAYMENT_RECEIVED': return AppTheme.accent;
      case 'IN_TRANSIT': return AppTheme.secondary;
      case 'DELIVERED': return AppTheme.accent;
      case 'CANCELLED': return AppTheme.danger;
      case 'REJECTED_AUTO': return AppTheme.danger;
      default: return AppTheme.textMid;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'RECEIVED': return 'Recibido';
      case 'ANALYZING': return 'En revision';
      case 'SEARCHING_PRICES': return 'Buscando precios';
      case 'QUOTE_GENERATED': return 'Cotizacion lista';
      case 'QUOTE_SENT': return 'Cotizacion enviada';
      case 'AWAITING_CONFIRMATION': return 'Esperando confirmacion';
      case 'CONFIRMED': return 'Confirmado';
      case 'PAYMENT_PENDING': return 'Pago pendiente';
      case 'PAYMENT_RECEIVED': return 'Pago recibido';
      case 'PURCHASING': return 'Comprando';
      case 'IN_TRANSIT': return 'En transito';
      case 'IN_CUSTOMS': return 'En aduana';
      case 'READY_FOR_DELIVERY': return 'Listo para entrega';
      case 'DELIVERED': return 'Entregado';
      case 'CANCELLED': return 'Cancelado';
      case 'REJECTED_AUTO': return 'Rechazado';
      default: return status;
    }
  }

  Future<void> _acceptQuote() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aceptar cotizacion'),
        content: Text(
          'Confirmas que aceptas la cotizacion por \$${_order['total_quote_usd']} USD?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
            child: const Text('Si, aceptar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    setState(() => _isLoading = true);

    try {
      await supabase.from('orders').update({
        'status': 'CONFIRMED',
        'client_response': 'accepted',
      }).eq('id', _order['id']);

      await supabase.from('order_history').insert({
        'order_id': _order['id'],
        'previous_status': 'QUOTE_SENT',
        'new_status': 'CONFIRMED',
        'notes': 'Cliente acepto la cotizacion',
      });

      setState(() {
        _order = {..._order, 'status': 'CONFIRMED'};
        _isLoading = false;
      });

      await _loadHistory();
      widget.onUpdated();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cotizacion aceptada'), backgroundColor: AppTheme.accent),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showCancelDialog() {
    final notesController = TextEditingController();
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
            const Text('Cancelar pedido',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 8),
            const Text('Puedes indicar el motivo (opcional)',
                style: TextStyle(fontSize: 13, color: AppTheme.textMid)),
            const SizedBox(height: 16),
            TextFormField(
              controller: notesController,
              maxLines: 3,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Ej: El precio es muy alto, ya no lo necesito...',
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Volver'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _cancelOrder(notesController.text.trim());
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
                    child: const Text('Cancelar pedido'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelOrder(String notes) async {
    setState(() => _isLoading = true);
    try {
      await supabase.from('orders').update({
        'status': 'CANCELLED',
        'client_response': 'cancelled',
        'client_notes': notes.isEmpty ? _order['client_notes'] : notes,
      }).eq('id', _order['id']);

      await supabase.from('order_history').insert({
        'order_id': _order['id'],
        'previous_status': _order['status'],
        'new_status': 'CANCELLED',
        'notes': notes.isEmpty ? 'Cliente cancelo el pedido' : notes,
      });

      setState(() {
        _order = {..._order, 'status': 'CANCELLED'};
        _isLoading = false;
      });

      await _loadHistory();
      widget.onUpdated();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pedido cancelado'), backgroundColor: AppTheme.danger),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _order['status'] as String;
    final isQuoteSent = status == 'QUOTE_SENT';
    final canCancel = !['CANCELLED', 'REJECTED_AUTO', 'DELIVERED'].contains(status);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(_order['order_number'] ?? 'Pedido'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estado
            _buildStatusCard(status),
            const SizedBox(height: 16),

            // Cotizacion si aplica
            if (isQuoteSent || status == 'CONFIRMED') ...[
              _buildQuoteCard(),
              const SizedBox(height: 16),
            ],

            // Rechazo si aplica
            if (status == 'REJECTED_AUTO') ...[
              _buildRejectionCard(),
              const SizedBox(height: 16),
            ],

            // Info del pedido
            _buildOrderInfo(),
            const SizedBox(height: 16),

            // Botones de accion
            if (isQuoteSent) ...[
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _acceptQuote,
                icon: const Icon(Icons.check_circle_rounded, size: 20),
                label: const Text('Aceptar Cotizacion'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
              ),
              const SizedBox(height: 12),
            ],

            if (canCancel)
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _showCancelDialog,
                icon: const Icon(Icons.cancel_outlined, size: 20, color: AppTheme.danger),
                label: const Text('Cancelar Pedido', style: TextStyle(color: AppTheme.danger)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.danger),
                ),
              ),

            const SizedBox(height: 24),

            // Historial
            _buildHistoryCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String status) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _statusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _statusColor(status).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: _statusColor(status).withOpacity(0.15),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(Icons.local_shipping_rounded, color: _statusColor(status), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Estado actual',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMid)),
                const SizedBox(height: 2),
                Text(_statusLabel(status),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                        color: _statusColor(status))),
              ],
            ),
          ),
          if (_order['estimated_delivery_date'] != null) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Entrega est.', style: TextStyle(fontSize: 10, color: AppTheme.textMid)),
                Text(
                  _formatDate(_order['estimated_delivery_date']),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuoteCard() {
    final productPrice = (_order['product_price_usd'] ?? 0).toDouble();
    final shipping = (_order['shipping_cost_usd'] ?? 0).toDouble();
    final customs = (_order['customs_cost_usd'] ?? 0).toDouble();
    final service = (_order['service_fee_usd'] ?? 0).toDouble();
    final discount = (_order['discount_usd'] ?? 0).toDouble();
    final total = (_order['total_quote_usd'] ?? 0).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        border: Border.all(color: const Color(0xFF8E44AD).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calculate_rounded, color: Color(0xFF8E44AD), size: 20),
              SizedBox(width: 8),
              Text('Detalle de cotizacion',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          if (productPrice > 0) _priceRow('Precio del producto', productPrice),
          if (shipping > 0) _priceRow('Envio internacional', shipping),
          if (customs > 0) _priceRow('Aduana / Impuestos', customs),
          if (service > 0) _priceRow('Comision del servicio', service),
          if (discount > 0) _priceRow('Descuento', -discount, isDiscount: true),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark)),
              Text('\$ ${total.toStringAsFixed(2)} USD',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, double amount, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textMid)),
          Text(
            isDiscount ? '- \$ ${amount.abs().toStringAsFixed(2)}' : '\$ ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDiscount ? AppTheme.accent : AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.danger.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.danger.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.cancel_rounded, color: AppTheme.danger, size: 20),
              SizedBox(width: 8),
              Text('Pedido rechazado',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.danger)),
            ],
          ),
          if (_order['rejection_reason'] != null) ...[
            const SizedBox(height: 8),
            Text(_order['rejection_reason'],
                style: const TextStyle(fontSize: 13, color: AppTheme.textMid)),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tu pedido',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark)),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _infoRow('Numero', _order['order_number'] ?? '-'),
          _infoRow('Tipo', _order['original_input_type'] ?? '-'),
          _infoRow('Cantidad', '${_order['quantity'] ?? 1}'),
          _infoRow('Fecha', _formatDate(_order['created_at'])),
          const SizedBox(height: 8),
          const Text('Descripcion / Link',
              style: TextStyle(fontSize: 12, color: AppTheme.textMid, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(_order['original_input'] ?? '-',
              style: const TextStyle(fontSize: 13, color: AppTheme.textDark)),
          if (_order['client_notes'] != null) ...[
            const SizedBox(height: 8),
            const Text('Tus notas',
                style: TextStyle(fontSize: 12, color: AppTheme.textMid, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(_order['client_notes'],
                style: const TextStyle(fontSize: 13, color: AppTheme.textMid, fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history_rounded, color: AppTheme.primary, size: 20),
              SizedBox(width: 8),
              Text('Seguimiento del pedido',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          if (_loadingHistory)
            const Center(child: CircularProgressIndicator())
          else if (_history.isEmpty)
            const Text('Sin movimientos aun', style: TextStyle(fontSize: 13, color: AppTheme.textMid))
          else
            ...(_history.map((h) => _buildHistoryItem(h)).toList()),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> h) {
    final newStatus = h['new_status'] as String;
    final prevStatus = h['previous_status'] as String? ?? '-';
    final notes = h['notes'] as String?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(color: _statusColor(newStatus), shape: BoxShape.circle),
              ),
              Container(width: 2, height: 34, color: const Color(0xFFDDE1E7)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(_statusLabel(prevStatus),
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMid)),
                    const Icon(Icons.arrow_forward_rounded, size: 12, color: AppTheme.textMid),
                    Text(_statusLabel(newStatus),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                            color: _statusColor(newStatus))),
                  ],
                ),
                if (notes != null && notes.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(notes, style: const TextStyle(fontSize: 11, color: AppTheme.textMid,
                      fontStyle: FontStyle.italic)),
                ],
                const SizedBox(height: 2),
                Text(_formatDate(h['created_at']),
                    style: const TextStyle(fontSize: 10, color: AppTheme.textLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80,
              child: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMid))),
          Expanded(child: Text(value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDark))),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    return '${date.day}/${date.month}/${date.year}';
  }
}
