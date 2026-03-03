import 'dart:convert';
import 'package:http/http.dart' as http;

// ─── Modelos ──────────────────────────────────────────────────────────────────

class AnalyzedProduct {
  final String? id;
  final String? name;
  final String? brand;
  final String? model;
  final String? description;
  final double? priceUsd;
  final String? currencyOriginal;
  final double? priceOriginal;
  final String platform;
  final String? asin;
  final List<Map<String, dynamic>> variants;
  final Map<String, dynamic> specifications;
  final double confidence;
  final String reasoning;

  AnalyzedProduct({
    this.id,
    this.name,
    this.brand,
    this.model,
    this.description,
    this.priceUsd,
    this.currencyOriginal,
    this.priceOriginal,
    required this.platform,
    this.asin,
    required this.variants,
    required this.specifications,
    required this.confidence,
    required this.reasoning,
  });

  factory AnalyzedProduct.fromJson(Map<String, dynamic> json) {
    return AnalyzedProduct(
      id: json['id'],
      name: json['name'],
      brand: json['brand'],
      model: json['model'],
      description: json['description'],
      priceUsd: (json['price_usd'] as num?)?.toDouble(),
      currencyOriginal: json['currency_original'],
      priceOriginal: (json['price_original'] as num?)?.toDouble(),
      platform: json['platform'] ?? 'other',
      asin: json['asin'],
      variants: List<Map<String, dynamic>>.from(json['variants'] ?? []),
      specifications: Map<String, dynamic>.from(json['specifications'] ?? {}),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      reasoning: json['reasoning'] ?? '',
    );
  }
}

class AnalyzeLinkResult {
  final String orderId;
  final String orderNumber;
  final String status;
  final DateTime createdAt;
  final AnalyzedProduct product;

  AnalyzeLinkResult({
    required this.orderId,
    required this.orderNumber,
    required this.status,
    required this.createdAt,
    required this.product,
  });

  factory AnalyzeLinkResult.fromJson(Map<String, dynamic> json) {
    return AnalyzeLinkResult(
      orderId: json['order']['id'],
      orderNumber: json['order']['order_number'],
      status: json['order']['status'],
      createdAt: DateTime.parse(json['order']['created_at']),
      product: AnalyzedProduct.fromJson(json['product']),
    );
  }
}

// ─── Servicio ─────────────────────────────────────────────────────────────────

class LinkAnalyzerService {
  // ⚠️ Reemplazar con tu URL real de Supabase
  static const String _supabaseUrl = 'https://TU_PROYECTO.supabase.co';
  // ⚠️ Reemplazar con tu anon key de Supabase
  static const String _supabaseAnonKey = 'TU_ANON_KEY';

  static const String _functionPath = '/functions/v1/analyze-link';

  /// Analiza un link de producto y crea un pedido borrador.
  /// 
  /// [url]          Link del producto a analizar
  /// [clientId]     UUID del cliente autenticado
  /// [quantity]     Cantidad deseada (default: 1)
  /// [clientNotes]  Notas adicionales del cliente
  static Future<AnalyzeLinkResult> analyzeLink({
    required String url,
    required String clientId,
    int quantity = 1,
    String? clientNotes,
  }) async {
    final uri = Uri.parse('$_supabaseUrl$_functionPath');

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'apikey': _supabaseAnonKey,
            'Authorization': 'Bearer $_supabaseAnonKey',
          },
          body: jsonEncode({
            'url': url,
            'client_id': clientId,
            'quantity': quantity,
            if (clientNotes != null) 'client_notes': clientNotes,
          }),
        )
        .timeout(const Duration(seconds: 30));

    final responseBody = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(responseBody['error'] ?? 'Error al analizar el link');
    }

    return AnalyzeLinkResult.fromJson(responseBody);
  }

  /// Valida que una URL tenga formato correcto antes de enviarla
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (_) {
      return false;
    }
  }
}
