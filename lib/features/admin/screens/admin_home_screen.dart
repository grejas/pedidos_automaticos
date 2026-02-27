import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/supabase_constants.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  Map<String, dynamic>? _admin;
  Map<String, int> _stats = {
    'operadores_activos': 0,
    'pedidos_hoy': 0,
    'total_clientes': 0,
  };
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

      final adminData = await supabase
          .from('operators')
          .select('id, full_name, email, role')
          .eq('user_id', userId)
          .single();

      final operatorsResult = await supabase
          .from('operators')
          .select('id')
          .eq('is_active', true);

      final clientsResult = await supabase
          .from('clients')
          .select('id');

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();
      final ordersResult = await supabase
          .from('orders')
          .select('id')
          .gte('created_at', startOfDay);

      setState(() {
        _admin = adminData;
        _stats = {
          'operadores_activos': (operatorsResult as List).length,
          'total_clientes': (clientsResult as List).length,
          'pedidos_hoy': (ordersResult as List).length,
        };
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
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRouter.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final name = _admin?['full_name'] ?? 'Administrador';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Panel Administrador'),
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
              _buildWelcomeCard(name),
              const SizedBox(height: 24),
              const Text('Resumen general',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              const SizedBox(height: 12),
              _buildStatsRow(),
              const SizedBox(height: 24),
              const Text('Modulos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              const SizedBox(height: 12),
              _buildModulesGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(String name) {
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
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hola, $name',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 2),
                Text('Administrador',
                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.75))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(20)),
            child: const Text('En linea',
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final stats = [
      {'label': 'Operadores', 'value': '${_stats['operadores_activos']}', 'icon': Icons.people_rounded, 'color': AppTheme.secondary},
      {'label': 'Pedidos hoy', 'value': '${_stats['pedidos_hoy']}', 'icon': Icons.shopping_bag_rounded, 'color': AppTheme.warning},
      {'label': 'Clientes', 'value': '${_stats['total_clientes']}', 'icon': Icons.person_rounded, 'color': AppTheme.accent},
    ];

    return Row(
      children: stats.asMap().entries.map((entry) {
        final i = entry.key;
        final s = entry.value;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < stats.length - 1 ? 10 : 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
                Icon(s['icon'] as IconData, color: s['color'] as Color, size: 26),
                const SizedBox(height: 8),
                Text(s['value'] as String,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                const SizedBox(height: 2),
                Text(s['label'] as String,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMid), textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildModulesGrid() {
    final modules = [
      {'label': 'Operadores', 'icon': Icons.manage_accounts_rounded, 'color': AppTheme.primary, 'route': AppRouter.operatorsManagement, 'available': true},
      {'label': 'Pedidos', 'icon': Icons.shopping_bag_rounded, 'color': AppTheme.secondary, 'route': AppRouter.adminOrders, 'available': true},
      {'label': 'Clientes', 'icon': Icons.people_rounded, 'color': AppTheme.accent, 'route': AppRouter.adminOrders, 'available': true},
      {'label': 'Cotizaciones', 'icon': Icons.calculate_rounded, 'color': AppTheme.warning, 'route': AppRouter.adminOrders, 'available': true},
      {'label': 'Reportes', 'icon': Icons.bar_chart_rounded, 'color': const Color(0xFF8E44AD), 'route': AppRouter.adminOrders, 'available': true},
      {'label': 'Configuracion', 'icon': Icons.settings_rounded, 'color': AppTheme.textMid, 'route': AppRouter.adminOrders, 'available': true},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.95,
      ),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final module = modules[index];
        final available = module['available'] as bool;
        return GestureDetector(
          onTap: available ? () => Navigator.pushNamed(context, module['route'] as String) : null,
          child: Opacity(
            opacity: available ? 1.0 : 0.45,
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
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: (module['color'] as Color).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(module['icon'] as IconData, color: module['color'] as Color, size: 26),
                  ),
                  const SizedBox(height: 8),
                  Text(module['label'] as String,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                      textAlign: TextAlign.center),
                  if (!available)
                    const Text('Proximo', style: TextStyle(fontSize: 9, color: AppTheme.textLight)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

