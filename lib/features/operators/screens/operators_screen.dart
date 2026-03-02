import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/validators.dart';

class OperatorsScreen extends StatefulWidget {
  const OperatorsScreen({super.key});

  @override
  State<OperatorsScreen> createState() => _OperatorsScreenState();
}

class _OperatorsScreenState extends State<OperatorsScreen> {
  List<Map<String, dynamic>> _operators = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOperators();
  }

  Future<void> _loadOperators() async {
    try {
      final data = await supabase
          .from('operators')
          .select('id, user_id, full_name, email, role, is_active, created_at')
          .order('created_at', ascending: false);
      setState(() {
        _operators = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar operadores: $e')),
        );
      }
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> operator) async {
    final newStatus = !(operator['is_active'] as bool);
    final userId = operator['user_id'] as String;

    try {
      await supabase
          .from('operators')
          .update({'is_active': newStatus})
          .eq('id', operator['id']);

      final adminClient = SupabaseClient(
        SupabaseConstants.url,
        SupabaseConstants.serviceRoleKey,
      );

      await adminClient.auth.admin.updateUserById(
        userId,
        attributes: AdminUserAttributes(
          banDuration: newStatus ? 'none' : '876600h',
        ),
      );

      await _loadOperators();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus
                ? '${operator['full_name']} activado'
                : '${operator['full_name']} desactivado'),
            backgroundColor: newStatus ? AppTheme.accent : AppTheme.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _openCreateOperator() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateOperatorScreen()),
    );
    if (result == true) _loadOperators();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Gestion de Operadores')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateOperator,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Nuevo', style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _operators.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _loadOperators,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _operators.length,
                    itemBuilder: (context, index) => _buildOperatorCard(_operators[index]),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: AppTheme.textLight),
          const SizedBox(height: 16),
          const Text('No hay operadores registrados',
              style: TextStyle(color: AppTheme.textMid, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Toca + para agregar uno',
              style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildOperatorCard(Map<String, dynamic> operator) {
    final isActive = operator['is_active'] as bool;
    final isAdmin = operator['role'] == 'admin';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: isAdmin ? AppTheme.primary.withOpacity(0.12) : AppTheme.secondary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                color: isAdmin ? AppTheme.primary : AppTheme.secondary, size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(operator['full_name'] ?? 'Sin nombre',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.textDark),
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isAdmin ? AppTheme.primary.withOpacity(0.1) : AppTheme.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(isAdmin ? 'Admin' : 'Cotizador',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                                color: isAdmin ? AppTheme.primary : AppTheme.secondary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(operator['email'] ?? '',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMid),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showToggleConfirm(operator),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.accent.withOpacity(0.1) : AppTheme.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7, height: 7,
                      decoration: BoxDecoration(
                        color: isActive ? AppTheme.accent : AppTheme.danger,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(isActive ? 'Activo' : 'Inactivo',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                            color: isActive ? AppTheme.accent : AppTheme.danger)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showToggleConfirm(Map<String, dynamic> operator) {
    final isActive = operator['is_active'] as bool;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isActive ? 'Desactivar operador' : 'Activar operador'),
        content: Text(isActive
            ? 'Desactivar a ${operator['full_name']} le impedira iniciar sesion. Continuar?'
            : 'Activar a ${operator['full_name']} le permitira iniciar sesion nuevamente. Continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); _toggleActive(operator); },
            style: ElevatedButton.styleFrom(backgroundColor: isActive ? AppTheme.danger : AppTheme.accent),
            child: Text(isActive ? 'Desactivar' : 'Activar'),
          ),
        ],
      ),
    );
  }
}

class CreateOperatorScreen extends StatefulWidget {
  const CreateOperatorScreen({super.key});

  @override
  State<CreateOperatorScreen> createState() => _CreateOperatorScreenState();
}

class _CreateOperatorScreenState extends State<CreateOperatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'operator';
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createOperator() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final adminClient = SupabaseClient(
        SupabaseConstants.url,
        SupabaseConstants.serviceRoleKey,
      );

      final response = await adminClient.auth.admin.createUser(
        AdminUserAttributes(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          emailConfirm: true,
        ),
      );

      if (response.user == null) throw Exception('No se pudo crear el usuario');

      await supabase.from('operators').insert({
        'user_id': response.user!.id,
        'full_name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone_number': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'role': _selectedRole,
        'is_active': true,
        'current_load': 0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Operador creado exitosamente'), backgroundColor: AppTheme.accent),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      String msg = e.toString();
      if (msg.contains('already registered') || msg.contains('email_exists')) {
        msg = 'Este correo ya tiene una cuenta registrada.';
      }
      setState(() { _errorMessage = msg; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Nuevo Operador')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Nombre completo'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Ej: Juan Perez',
                  prefixIcon: Icon(Icons.person_outline, color: AppTheme.textMid),
                ),
                validator: Validators.name,
              ),
              const SizedBox(height: 20),
              _label('Correo electronico'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'correo@empresa.com',
                  prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textMid),
                ),
                validator: Validators.email,
              ),
              const SizedBox(height: 20),
              _label('Telefono (opcional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: '70000000',
                  prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.textMid),
                ),
                validator: Validators.phone,
              ),
              const SizedBox(height: 20),
              _label('Contrasena'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Minimo 6 caracteres',
                  prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textMid),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppTheme.textMid),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: Validators.password,
              ),
              const SizedBox(height: 20),
              _label('Rol'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDDE1E7)),
                ),
                child: Column(
                  children: [
                    _roleTile('operator', 'Cotizador', Icons.person_rounded, 'Gestiona y cotiza pedidos'),
                    const Divider(height: 1),
                    _roleTile('admin', 'Administrador', Icons.admin_panel_settings_rounded, 'Acceso completo al sistema'),
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
                      Expanded(child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.danger, fontSize: 13))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              ElevatedButton(
                onPressed: _isLoading ? null : _createOperator,
                child: _isLoading
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('Crear Operador'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textDark));

  Widget _roleTile(String value, String title, IconData icon, String subtitle) {
    final selected = _selectedRole == value;
    return InkWell(
      onTap: () => setState(() => _selectedRole = value),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: selected ? AppTheme.primary : AppTheme.textMid, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w600,
                      color: selected ? AppTheme.primary : AppTheme.textDark)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textMid)),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
