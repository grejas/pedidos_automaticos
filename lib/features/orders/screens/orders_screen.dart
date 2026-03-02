import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../core/constants/supabase_constants.dart';
import 'quote_order_screen.dart';

final supabase = Supabase.instance.client;

class OrdersScreen extends StatefulWidget {
  final bool isAdmin;
  const OrdersScreen({super.key, this.isAdmin = false});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String _filterStatus = 'ALL';

  final List<Map<String, String>> _statusFilters = [
    {'value': 'ALL', 'label': 'Todos'},
    {'value': 'RECEIVED', 'label': 'Recibidos'},
    {'value': 'ANALYZING', 'label': 'En revision'},
    {'value': 'QUOTE_SENT', 'label': 'Cotizados'},
    {'value': 'CONFIRMED', 'label': 'Confirmados'},
    {'value': 'IN_TRANSIT', 'label': 'En transito'},
    {'value': 'DELIVERED', 'label': 'Entregados'},
    {'value': 'CANCELLED', 'label': 'Cancelados'},
  ];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      var query = supabase
          .from('orders')
          .select('id, order_number, status, source, original_input_type, original_input, quantity, client_notes, created_at, total_quote_usd, client_id, assigned_operator_id, product_source_platform');

      if (_filterStatus != 'ALL') {
        query = query.eq('status', _filterStatus);
      }

      final data = await query.order('created_at', ascending: false);

      setState(() {
        _orders = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar pedidos: $e')),
        );
      }
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
      case 'ESCALATED': return AppTheme.danger;
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
      case 'ESCALATED': return 'Escalado';
      default: return status;
    }
  }

  IconData _inputTypeIcon(String type) {
    switch (type) {
      case 'link': return Icons.link_rounded;
      case 'image': return Icons.image_rounded;
      case 'text': return Icons.text_fields_rounded;
      default: return Icons.help_outline_rounded;
    }
  }

  void _openOrderDetail(Map<String, dynamic> order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(
          order: order,
          isAdmin: widget.isAdmin,
          onUpdated: _loadOrders,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.isAdmin ? 'Todos los Pedidos' : 'Pedidos'),
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _orders.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
              onRefresh: _loadOrders,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _orders.length,
                itemBuilder: (context, index) =>
                    _buildOrderCard(_orders[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _statusFilters.map((filter) {
            final selected = _filterStatus == filter['value'];
            return GestureDetector(
              onTap: () {
                setState(() { _filterStatus = filter['value']!; _loading = true; });
                _loadOrders();
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primary : AppTheme.background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: selected ? AppTheme.primary : const Color(0xFFDDE1E7)),
                ),
                child: Text(filter['label']!,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : AppTheme.textMid)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 64, color: AppTheme.textLight),
          const SizedBox(height: 16),
          const Text('No hay pedidos', style: TextStyle(color: AppTheme.textMid, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Los pedidos apareceran aqui', style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] as String;
    final inputType = order['original_input_type'] as String? ?? 'text';

    return GestureDetector(
      onTap: () => _openOrderDetail(order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: _statusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_inputTypeIcon(inputType), color: _statusColor(status), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order['order_number'] ?? 'Sin numero',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark)),
                        const SizedBox(height: 2),
                        Text(_formatDate(order['created_at']),
                            style: const TextStyle(fontSize: 11, color: AppTheme.textLight)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_statusLabel(status),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _statusColor(status))),
                  ),
                ],
              ),
              if (order['original_input'] != null) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Text(
                  order['original_input'].toString().length > 60
                      ? '${order['original_input'].toString().substring(0, 60)}...'
                      : order['original_input'].toString(),
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMid),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.numbers_rounded, size: 14, color: AppTheme.textLight),
                  const SizedBox(width: 4),
                  Text('Cantidad: ${order['quantity'] ?? 1}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMid)),
                  const Spacer(),
                  if (order['total_quote_usd'] != null)
                    Text('\$${order['total_quote_usd']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark)),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded, color: AppTheme.textLight, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class OrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  final bool isAdmin;
  final VoidCallback onUpdated;

  const OrderDetailScreen({
    super.key,
    required this.order,
    required this.isAdmin,
    required this.onUpdated,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late String _currentStatus;
  bool _isUpdating = false;
  List<Map<String, dynamic>> _history = [];
  bool _loadingHistory = true;

  final List<Map<String, String>> _availableStatuses = [
    {'value': 'RECEIVED', 'label': 'Recibido'},
    {'value': 'ANALYZING', 'label': 'En revision'},
    {'value': 'SEARCHING_PRICES', 'label': 'Buscando precios'},
    {'value': 'QUOTE_GENERATED', 'label': 'Cotizacion lista'},
    {'value': 'QUOTE_SENT', 'label': 'Cotizacion enviada'},
    {'value': 'AWAITING_CONFIRMATION', 'label': 'Esperando confirmacion'},
    {'value': 'CONFIRMED', 'label': 'Confirmado'},
    {'value': 'PAYMENT_PENDING', 'label': 'Pago pendiente'},
    {'value': 'PAYMENT_RECEIVED', 'label': 'Pago recibido'},
    {'value': 'PURCHASING', 'label': 'Comprando'},
    {'value': 'IN_TRANSIT', 'label': 'En transito'},
    {'value': 'IN_CUSTOMS', 'label': 'En aduana'},
    {'value': 'READY_FOR_DELIVERY', 'label': 'Listo para entrega'},
    {'value': 'DELIVERED', 'label': 'Entregado'},
    {'value': 'CANCELLED', 'label': 'Cancelado'},
  ];

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order['status'] as String;
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final data = await supabase
          .from('order_history')
          .select('id, previous_status, new_status, created_at, operator_id, operators(full_name, email)')
          .eq('order_id', widget.order['id'])
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
      case 'QUOTE_SENT': return const Color(0xFF8E44AD);
      case 'CONFIRMED': return AppTheme.accent;
      case 'DELIVERED': return AppTheme.accent;
      case 'CANCELLED': return AppTheme.danger;
      default: return AppTheme.textMid;
    }
  }

  String _statusLabel(String status) {
    return _availableStatuses.firstWhere(
          (s) => s['value'] == status,
      orElse: () => {'label': status},
    )['label']!;
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdating = true);
    try {
      await supabase
          .from('orders')
          .update({'status': newStatus})
          .eq('id', widget.order['id']);

      // Registrar en historial
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        final operator = await supabase
            .from('operators')
            .select('id')
            .eq('user_id', userId)
            .maybeSingle();
        if (operator != null) {
          await supabase.from('order_history').insert({
            'order_id': widget.order['id'],
            'operator_id': operator['id'],
            'previous_status': _currentStatus,
            'new_status': newStatus,
          });
        }
      }

      setState(() {
        _currentStatus = newStatus;
        _isUpdating = false;
      });

      await _loadHistory();
      widget.onUpdated();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Estado actualizado'), backgroundColor: AppTheme.accent),
        );
      }
    } catch (e) {
      setState(() => _isUpdating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showStatusPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cambiar estado',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _availableStatuses.length,
                itemBuilder: (context, index) {
                  final s = _availableStatuses[index];
                  final isSelected = s['value'] == _currentStatus;
                  return ListTile(
                    leading: Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(color: _statusColor(s['value']!), shape: BoxShape.circle),
                    ),
                    title: Text(s['label']!,
                        style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppTheme.primary : AppTheme.textDark)),
                    trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary) : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      if (s['value'] != _currentStatus) _updateStatus(s['value']!);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(order['order_number'] ?? 'Pedido'),
        actions: [
          if (_isUpdating)
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
            _buildStatusCard(),
            const SizedBox(height: 16),
            _buildInfoCard(order),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showStatusPicker,
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('Cambiar Estado'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuoteOrderScreen(
                            order: widget.order,
                            onUpdated: () {
                              widget.onUpdated();
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.calculate_rounded, size: 18),
                    label: const Text('Cotizar'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondary),
                  ),
                ),
              ],
            ),
            if (order['client_notes'] != null) ...[
              const SizedBox(height: 16),
              _buildNotesCard(order['client_notes']),
            ],
            const SizedBox(height: 16),
            _buildHistoryCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _statusColor(_currentStatus).withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _statusColor(_currentStatus).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: _statusColor(_currentStatus).withOpacity(0.15),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(Icons.local_shipping_rounded, color: _statusColor(_currentStatus), size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Estado actual', style: TextStyle(fontSize: 12, color: AppTheme.textMid)),
              const SizedBox(height: 2),
              Text(_statusLabel(_currentStatus),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _statusColor(_currentStatus))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(Map<String, dynamic> order) {
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
          const Text('Detalles del pedido',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark)),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _infoRow('Numero', order['order_number'] ?? '-'),
          _infoRow('Tipo', order['original_input_type'] ?? '-'),
          _infoRow('Cantidad', '${order['quantity'] ?? 1}'),
          _infoRow('Plataforma', order['product_source_platform'] ?? '-'),
          _infoRow('Fuente', order['source'] ?? '-'),
          if (order['total_quote_usd'] != null)
            _infoRow('Cotizacion', '\$${order['total_quote_usd']}'),
          const SizedBox(height: 8),
          const Text('Descripcion / Link',
              style: TextStyle(fontSize: 12, color: AppTheme.textMid, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(order['original_input'] ?? '-',
              style: const TextStyle(fontSize: 13, color: AppTheme.textDark)),
        ],
      ),
    );
  }

  Widget _buildNotesCard(String notes) {
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
          const Text('Notas del cliente',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark)),
          const SizedBox(height: 8),
          Text(notes, style: const TextStyle(fontSize: 13, color: AppTheme.textMid)),
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
              Text('Historial de cambios',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          if (_loadingHistory)
            const Center(child: CircularProgressIndicator())
          else if (_history.isEmpty)
            const Text('Sin cambios registrados',
                style: TextStyle(fontSize: 13, color: AppTheme.textMid))
          else
            ...(_history.map((h) => _buildHistoryItem(h)).toList()),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> h) {
    final operatorData = h['operators'] as Map<String, dynamic>?;
    final operatorName = operatorData?['full_name'] ?? 'Sistema';
    final prevStatus = h['previous_status'] as String? ?? '-';
    final newStatus = h['new_status'] as String;
    final date = _formatDate(h['created_at']);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                  color: _statusColor(newStatus),
                  shape: BoxShape.circle,
                ),
              ),
              Container(width: 2, height: 30, color: const Color(0xFFDDE1E7)),
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
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor(newStatus))),
                  ],
                ),
                const SizedBox(height: 2),
                Text('Por: $operatorName',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textDark, fontWeight: FontWeight.w500)),
                Text(date, style: const TextStyle(fontSize: 10, color: AppTheme.textLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100,
              child: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMid))),
          Expanded(child: Text(value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDark))),
        ],
      ),
    );
  }
}

