import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/supabase_constants.dart';

final supabase = Supabase.instance.client;

class OperatorHomeScreen extends StatefulWidget {
  const OperatorHomeScreen({super.key});

  @override
  State<OperatorHomeScreen> createState() => _OperatorHomeScreenState();
}

class _OperatorHomeScreenState extends State<OperatorHomeScreen> {
  Map<String, dynamic>? _operator;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOperator();
  }

  Future<void> _loadOperator() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;
      final data = await supabase
          .from('operators')
          .select('id, full_name, email, role')
          .eq('user_id', userId)
          .single();
      setState(() { _operator = data; _loading = false; });
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
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

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final name = _operator?['full_name'] ?? 'Operador';
    final role = _operator?['role'] ?? 'operator';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Panel Operativo'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout_rounded), tooltip: 'Cerrar sesion'),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(name, role),
            const SizedBox(height: 24),
            const Text('Resumen del dia',
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
    );
  }

  Widget _buildWelcomeCard(String name, String role) {
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
                const SizedBox(height: 2),
                Text(role == 'admin' ? 'Administrador' : 'Cotizador',
                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.75))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(20)),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 8, color: Colors.white),
                SizedBox(width: 4),
                Text('En linea', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _statCard(Icons.inbox_rounded, '—', 'Nuevos', AppTheme.secondary),
        const SizedBox(width: 12),
        _statCard(Icons.warning_amber_rounded, '—', 'Escalados', AppTheme.warning),
        const SizedBox(width: 12),
        _statCard(Icons.check_circle_rounded, '—', 'Entregados', AppTheme.accent),
      ],
    );
  }

  Widget _statCard(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMid)),
          ],
        ),
      ),
    );
  }

  Widget _buildModulesGrid() {
    final modules = [
      {'label': 'Pedidos', 'icon': Icons.shopping_bag_rounded, 'color': AppTheme.secondary, 'route': AppRouter.orders},
      {'label': 'Escalados', 'icon': Icons.warning_amber_rounded, 'color': AppTheme.warning, 'route': ''},
      {'label': 'Clientes', 'icon': Icons.people_rounded, 'color': AppTheme.accent, 'route': ''},
      {'label': 'Cotizar', 'icon': Icons.calculate_rounded, 'color': AppTheme.primary, 'route': ''},
      {'label': 'Tracking', 'icon': Icons.local_shipping_rounded, 'color': const Color(0xFF8E44AD), 'route': ''},
      {'label': 'Configuracion', 'icon': Icons.settings_rounded, 'color': AppTheme.textMid, 'route': ''},
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
        final route = module['route'] as String;
        final available = route.isNotEmpty;

        return GestureDetector(
          onTap: () {
            if (available) {
              Navigator.pushNamed(context, route);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${module['label']} - proximamente'),
                  backgroundColor: AppTheme.primary,
                ),
              );
            }
          },
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
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(module['icon'] as IconData, color: module['color'] as Color, size: 26),
                  ),
                  const SizedBox(height: 8),
                  Text(module['label'] as String,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                      textAlign: TextAlign.center),
                  if (!available) ...[
                    const SizedBox(height: 2),
                    const Text('Proximo', style: TextStyle(fontSize: 9, color: AppTheme.textLight)),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

