import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/validators.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      await supabase.auth.resetPasswordForEmail(_emailController.text.trim());
      setState(() { _emailSent = true; _isLoading = false; });
    } on AuthException catch (e) {
      setState(() { _errorMessage = _translateError(e.message); _isLoading = false; });
    } catch (e) {
      setState(() { _errorMessage = 'Error al enviar el correo. Verifica tu internet.'; _isLoading = false; });
    }
  }

  String _translateError(String message) {
    if (message.contains('rate limit')) return 'Demasiados intentos. Espera unos minutos.';
    if (message.contains('invalid email')) return 'El correo no es valido.';
    return 'Error al enviar el correo. Intenta de nuevo.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Recuperar contrasena'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _emailSent ? _buildSuccessView() : _buildFormView(),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Center(
          child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.lock_reset_rounded, size: 42, color: AppTheme.primary),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Olvidaste tu contrasena?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        const SizedBox(height: 8),
        const Text(
          'Ingresa tu correo electronico y te enviaremos un enlace para restablecer tu contrasena.',
          style: TextStyle(fontSize: 14, color: AppTheme.textMid, height: 1.5),
        ),
        const SizedBox(height: 32),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Correo electronico',
                  hintText: 'tu@correo.com',
                  prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textMid),
                ),
                validator: Validators.email,
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
                onPressed: _isLoading ? null : _sendResetEmail,
                child: _isLoading
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('Enviar enlace'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Volver al inicio de sesion',
                    style: TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 48),
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            color: AppTheme.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(28),
          ),
          child: const Icon(Icons.mark_email_read_rounded, size: 52, color: AppTheme.accent),
        ),
        const SizedBox(height: 28),
        const Text('Correo enviado',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        const SizedBox(height: 12),
        Text(
          'Enviamos un enlace de recuperacion a\n${_emailController.text.trim()}',
          style: const TextStyle(fontSize: 14, color: AppTheme.textMid, height: 1.6),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text('Revisa tu bandeja de entrada y sigue las instrucciones.',
            style: TextStyle(fontSize: 13, color: AppTheme.textLight, height: 1.5),
            textAlign: TextAlign.center),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Volver al inicio de sesion'),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _isLoading ? null : _sendResetEmail,
          child: const Text('Reenviar correo', style: TextStyle(color: AppTheme.secondary)),
        ),
      ],
    );
  }
}
