import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/supabase_constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() { _errorMessage = null; });
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final response = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      if (response.user == null) {
        setState(() {
          _errorMessage = 'No se pudo iniciar sesion. Verifica tus datos.';
          _isLoading = false;
        });
        return;
      }

      final operator = await supabase
          .from('operators')
          .select('id, full_name, role, is_active')
          .eq('user_id', response.user!.id)
          .maybeSingle();

      if (!mounted) return;

      if (operator != null) {
        if (operator['is_active'] == false) {
          await supabase.auth.signOut();
          setState(() {
            _errorMessage = 'Tu cuenta esta desactivada. Contacta al administrador.';
            _isLoading = false;
          });
          return;
        }
        final role = operator['role'] as String;
        if (role == 'admin') {
          Navigator.pushReplacementNamed(context, AppRouter.adminHome);
        } else {
          Navigator.pushReplacementNamed(context, AppRouter.operatorHome);
        }
        return;
      }

      final client = await supabase
          .from('clients')
          .select('id, is_blocked')
          .eq('app_user_id', response.user!.id)
          .maybeSingle();

      if (!mounted) return;

      if (client != null) {
        if (client['is_blocked'] == true) {
          await supabase.auth.signOut();
          setState(() {
            _errorMessage = 'Tu cuenta ha sido bloqueada. Contacta al soporte.';
            _isLoading = false;
          });
          return;
        }
        Navigator.pushReplacementNamed(context, AppRouter.clientHome);
        return;
      }

      await supabase.auth.signOut();
      setState(() {
        _errorMessage = 'No se encontro un perfil asociado a este correo.';
        _isLoading = false;
      });

    } on AuthException catch (e) {
      setState(() {
        _errorMessage = _translateAuthError(e.message);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexion. Verifica tu internet e intenta de nuevo.';
        _isLoading = false;
      });
    }
  }

  String _translateAuthError(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'Email o contrasena incorrectos.';
    } else if (message.contains('Email not confirmed')) {
      return 'Debes confirmar tu email antes de iniciar sesion.';
    } else if (message.contains('Too many requests')) {
      return 'Demasiados intentos. Espera unos minutos.';
    }
    return 'Error al iniciar sesion. Intenta de nuevo.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.all(24),
                child: _buildForm(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: const BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.local_shipping_rounded, size: 44, color: Colors.white),
          ),
          const SizedBox(height: 16),
          const Text('Father & Son',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text('Panel Operativo',
              style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7))),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text('Iniciar Sesion',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 4),
          const Text('Ingresa tus credenciales para continuar',
              style: TextStyle(fontSize: 14, color: AppTheme.textMid)),
          const SizedBox(height: 28),

          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Correo electronico',
              hintText: 'tu@correo.com',
              prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textMid),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Ingresa tu correo';
              if (!v.contains('@')) return 'Correo invalido';
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _login(),
            decoration: InputDecoration(
              labelText: 'Contrasena',
              prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textMid),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppTheme.textMid,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Ingresa tu contrasena';
              if (v.length < 6) return 'Minimo 6 caracteres';
              return null;
            },
          ),
          const SizedBox(height: 8),

          // Olvidaste tu contrasena
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRouter.forgotPassword),
              child: const Text(
                'Olvidaste tu contrasena?',
                style: TextStyle(
                  color: AppTheme.secondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
            onPressed: _isLoading ? null : _login,
            child: _isLoading
                ? const SizedBox(height: 22, width: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Text('Ingresar'),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No tienes cuenta? ',
                  style: TextStyle(color: AppTheme.textMid, fontSize: 14)),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRouter.register),
                child: const Text('Registrate',
                    style: TextStyle(
                      color: AppTheme.secondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Text('Father & Son v1.0',
                style: TextStyle(fontSize: 11, color: AppTheme.textLight)),
          ),
        ],
      ),
    );
  }
}
