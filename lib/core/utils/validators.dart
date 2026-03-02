class Validators {
  // Email
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ingresa tu correo';
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) return 'Ingresa un correo valido';
    return null;
  }

  // Telefono Bolivia (6xxxxxxx o 7xxxxxxx, 8 digitos)
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // opcional
    final clean = value.trim().replaceAll(' ', '').replaceAll('-', '').replaceAll('+591', '');
    final phoneRegex = RegExp(r'^[67]\d{7}$');
    if (!phoneRegex.hasMatch(clean)) return 'Ingresa un numero valido (Ej: 70000000)';
    return null;
  }

  // Telefono requerido
  static String? phoneRequired(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ingresa tu telefono';
    return phone(value);
  }

  // Contrasena
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa una contrasena';
    if (value.length < 6) return 'Minimo 6 caracteres';
    return null;
  }

  // Confirmar contrasena
  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Confirma tu contrasena';
    if (value != original) return 'Las contrasenas no coinciden';
    return null;
  }

  // Nombre
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ingresa el nombre';
    if (value.trim().length < 3) return 'El nombre es muy corto';
    return null;
  }

  // Campo requerido generico
  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return 'Ingresa $fieldName';
    return null;
  }
}
