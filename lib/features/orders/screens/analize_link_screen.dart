import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/link_analyzer_service.dart';

class AnalyzeLinkScreen extends StatefulWidget {
  final String clientId; // Pasar desde el contexto de autenticación

  const AnalyzeLinkScreen({super.key, required this.clientId});

  @override
  State<AnalyzeLinkScreen> createState() => _AnalyzeLinkScreenState();
}

class _AnalyzeLinkScreenState extends State<AnalyzeLinkScreen> {
  final _urlController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _quantity = 1;
  bool _isLoading = false;
  AnalyzeLinkResult? _result;
  String? _errorMessage;

  @override
  void dispose() {
    _urlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ─── Lógica ────────────────────────────────────────────────────────────────

  Future<void> _analyzeLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _result = null;
      _errorMessage = null;
    });

    try {
      final result = await LinkAnalyzerService.analyzeLink(
        url: _urlController.text.trim(),
        clientId: widget.clientId,
        quantity: _quantity,
        clientNotes:
        _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _urlController.text = data!.text!;
    }
  }

  void _reset() {
    setState(() {
      _result = null;
      _errorMessage = null;
      _urlController.clear();
      _notesController.clear();
      _quantity = 1;
    });
  }

  // ─── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo pedido por link'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _result != null ? _buildResultView() : _buildInputForm(),
      ),
    );
  }

  // ── Formulario de entrada ──────────────────────────────────────────────────

  Widget _buildInputForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ícono y título
          const SizedBox(height: 8),
          Icon(Icons.link_rounded,
              size: 56, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            'Pegá el link del producto',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Analizamos el producto automáticamente con IA',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // Campo URL
          TextFormField(
            controller: _urlController,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: 'Link del producto',
              hintText: 'https://...',
              prefixIcon: const Icon(Icons.link),
              suffixIcon: IconButton(
                icon: const Icon(Icons.content_paste_rounded),
                tooltip: 'Pegar del portapapeles',
                onPressed: _pasteFromClipboard,
              ),
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ingresá un link';
              }
              if (!LinkAnalyzerService.isValidUrl(value.trim())) {
                return 'El link no es válido (debe empezar con http:// o https://)';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Cantidad
          Row(
            children: [
              const Text('Cantidad:', style: TextStyle(fontSize: 16)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _quantity > 1
                    ? () => setState(() => _quantity--)
                    : null,
              ),
              Text(
                '$_quantity',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => setState(() => _quantity++),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Notas opcionales
          TextFormField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notas adicionales (opcional)',
              hintText: 'Ej: quiero el color azul, talle M...',
              prefixIcon: Icon(Icons.notes_rounded),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          // Error
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_errorMessage!,
                        style: const TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Botón analizar
          FilledButton.icon(
            onPressed: _isLoading ? null : _analyzeLink,
            icon: _isLoading
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
                : const Icon(Icons.auto_awesome_rounded),
            label: Text(_isLoading ? 'Analizando con IA...' : 'Analizar producto'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 16),

          if (_isLoading)
            const Text(
              'Esto puede tardar hasta 20 segundos mientras analizamos el producto...',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
        ],
      ),
    );
  }

  // ── Vista de resultado ─────────────────────────────────────────────────────

  Widget _buildResultView() {
    final product = _result!.product;
    final confidence = product.confidence;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header éxito
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('¡Pedido creado!',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green)),
                    Text('Nº ${_result!.orderNumber}',
                        style: TextStyle(color: Colors.green[700])),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Confianza de la IA
        _buildConfidenceIndicator(confidence),
        const SizedBox(height: 16),

        // Datos del producto
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Producto detectado',
                    style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const Divider(height: 20),
                if (product.name != null)
                  _buildDataRow(Icons.inventory_2_outlined, 'Nombre', product.name!),
                if (product.brand != null)
                  _buildDataRow(Icons.branding_watermark_outlined, 'Marca', product.brand!),
                if (product.model != null)
                  _buildDataRow(Icons.tag_outlined, 'Modelo', product.model!),
                if (product.priceUsd != null)
                  _buildDataRow(
                    Icons.attach_money_rounded,
                    'Precio',
                    product.currencyOriginal != null && product.currencyOriginal != 'USD'
                        ? 'USD ${product.priceUsd!.toStringAsFixed(2)} (${product.currencyOriginal} ${product.priceOriginal?.toStringAsFixed(2) ?? '?'})'
                        : 'USD ${product.priceUsd!.toStringAsFixed(2)}',
                  ),
                _buildDataRow(Icons.storefront_outlined, 'Plataforma',
                    product.platform.toUpperCase()),
                if (product.asin != null)
                  _buildDataRow(Icons.qr_code_outlined, 'ASIN', product.asin!),
                if (product.description != null) ...[
                  const SizedBox(height: 8),
                  Text('Descripción',
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(product.description!),
                ],
              ],
            ),
          ),
        ),

        // Variantes
        if (product.variants.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Variantes disponibles',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: product.variants
                        .map((v) => Chip(
                      label: Text('${v['key']}: ${v['value']}'),
                    ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ],

        // Razonamiento de la IA (colapsable)
        const SizedBox(height: 12),
        ExpansionTile(
          title: const Text('Ver análisis de la IA',
              style: TextStyle(fontSize: 14)),
          leading: const Icon(Icons.psychology_outlined),
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                product.reasoning,
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Acciones
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.add_link_rounded),
                label: const Text('Nuevo pedido'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  // TODO: Navegar al detalle del pedido
                  // Navigator.pushNamed(context, '/order-detail',
                  //   arguments: _result!.orderId);
                },
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Ver pedido'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildConfidenceIndicator(double confidence) {
    Color color;
    String label;
    if (confidence >= 80) {
      color = Colors.green;
      label = 'Alta confianza';
    } else if (confidence >= 50) {
      color = Colors.orange;
      label = 'Confianza media — revisar datos';
    } else {
      color = Colors.red;
      label = 'Baja confianza — requiere revisión manual';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Confianza de la IA',
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            Text('${confidence.toStringAsFixed(0)}%',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: confidence / 100,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }

  Widget _buildDataRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(label,
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
