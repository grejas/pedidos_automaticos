import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/supabase_constants.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  Map<String, dynamic>? _client;
  List<Map<String, dynamic>> _recentOrders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final clientData = await supabase
          .from('clients')
          .select('id, full_name, email, total_orders, total_spent_usd')
          .eq('app_user_id', userId)
          .maybeSingle();

      List<Map<String, dynamic>> orders = [];
      if (clientData != null) {
        final ordersData = await supabase
            .from('orders')
            .select('id, order_number, created_at, status, total_quote_usd')
            .eq('client_id', clientData['id'])
            .order('created_at', ascending: false)
            .limit(5);
        orders = List<Map<String, dynamic>>.from(ordersData);
      }

      setState(() {
        _client = clientData;
        _recentOrders = orders;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesion'),
        content: const Text('Estas seguro que quieres salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await supabase.auth.signOut();
      if (mounted) Navigator.pushReplacementNamed(context, AppRouter.login);
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
      case 'DELIVERED': return 'Entregado';
      case 'CANCELLED': return 'Cancelado';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final name = _client?['full_name'] ?? 'Cliente';
    final totalOrders = _client?['total_orders'] ?? 0;
    final totalSpent = _client?['total_spent_usd'] ?? 0.0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Mis Pedidos'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar sesion',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(name, totalOrders, totalSpent),
              const SizedBox(height: 24),
              _buildQuickActions(),
              const SizedBox(height: 24),
              const Text('Mis pedidos recientes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              const SizedBox(height: 12),
              _recentOrders.isEmpty ? _buildEmptyOrders() : _buildOrdersList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(String name, int totalOrders, dynamic totalSpent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hola, $name',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('Bienvenido a Father & Son',
                        style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.75))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statChip(Icons.shopping_bag_rounded, '$totalOrders pedidos'),
              const SizedBox(width: 12),
              _statChip(Icons.attach_money_rounded, '\$$totalSpent gastado'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'label': 'Nuevo pedido', 'icon': Icons.add_shopping_cart_rounded, 'color': AppTheme.secondary, 'route': AppRouter.newOrder},
      {'label': 'Mis pedidos', 'icon': Icons.list_alt_rounded, 'color': AppTheme.accent, 'route': ''},
      {'label': 'Tracking', 'icon': Icons.local_shipping_rounded, 'color': const Color(0xFF8E44AD), 'route': ''},
      {'label': 'Mi perfil', 'icon': Icons.person_rounded, 'color': AppTheme.warning, 'route': ''},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.85,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        final hasRoute = (action['route'] as String).isNotEmpty;
        return GestureDetector(
          onTap: () {
            if (hasRoute) {
              Navigator.pushNamed(context, action['route'] as String).then((result) {
                if (result == true) _loadData();
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${action['label']} - proximamente'),
                  backgroundColor: AppTheme.primary,
                ),
              );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: (action['color'] as Color).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(action['icon'] as IconData, color: action['color'] as Color, size: 22),
                ),
                const SizedBox(height: 6),
                Text(action['label'] as String,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                    textAlign: TextAlign.center, maxLines: 2),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyOrders() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Icon(Icons.shopping_bag_outlined, size: 56, color: AppTheme.textLight),
          const SizedBox(height: 12),
          const Text('No tienes pedidos aun',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
          const SizedBox(height: 4),
          const Text('Toca "Nuevo pedido" para empezar',
              style: TextStyle(fontSize: 13, color: AppTheme.textMid)),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    return Column(
      children: _recentOrders.map((order) {
        final status = order['status'] ?? 'RECEIVED';
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.shopping_bag_rounded, color: _statusColor(status), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order['order_number'] ?? 'Pedido',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textDark)),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(_statusLabel(status),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _statusColor(status))),
                    ),
                  ],
                ),
              ),
              if (order['total_quote_usd'] != null)
                Text('\$${order['total_quote_usd']}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
