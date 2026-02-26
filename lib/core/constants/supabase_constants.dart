import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConstants {
  static const String supabaseUrl = '';
  static const String supabaseKey = '';
  static const String serviceRoleKey = '';
}

SupabaseClient get supabase => Supabase.instance.client;
