import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class GenerarCodigoPagoScreen extends StatefulWidget {
  const GenerarCodigoPagoScreen({super.key});

  @override
  _GenerarCodigoPagoScreenState createState() => _GenerarCodigoPagoScreenState();
}

class _GenerarCodigoPagoScreenState extends State<GenerarCodigoPagoScreen> {
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _receptorIdController = TextEditingController();
  String _estado = 'Introduce el monto y el ID del receptor';
  bool _isGenerating = false;
  String? _codigoGenerado;

  Future<void> _generarCodigo() async {
    final monto = double.tryParse(_montoController.text.trim());
    if (monto == null || monto <= 0) {
      setState(() => _estado = '⚠️ Introduce un monto válido');
      return;
    }
    final receptorId = int.tryParse(_receptorIdController.text.trim());
    if (receptorId == null || receptorId <= 0) {
      setState(() => _estado = '⚠️ Introduce un ID de receptor válido');
      return;
    }

    setState(() {
      _isGenerating = true;
      _estado = 'Generando código...';
    });

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final emisorId = await auth.obtenerToken();
      if (emisorId == null) {
        setState(() => _estado = '❌ Usuario no autenticado');
        _isGenerating = false;
        return;
      }

      final api = Provider.of<ApiService>(context, listen: false);
      final response = await api.generarPago(
        emisorId: int.parse(emisorId),
        receptorId: receptorId,
        monto: monto,
      );

      setState(() {
        _codigoGenerado = response['codigo'];
        _estado = '✅ Código generado: ${response['codigo']}';
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _estado = '❌ Error: $e';
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generar código de pago'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 20),
            Text(_estado, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 30),
            TextField(
              controller: _receptorIdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'ID del receptor',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _montoController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Monto (VIBRA)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generarCodigo,
              icon: Icon(_isGenerating ? Icons.hourglass_empty : Icons.qr_code),
              label: Text(_isGenerating ? 'Generando...' : 'Generar código'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
            if (_codigoGenerado != null) ...[
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text('Código de pago:', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(_codigoGenerado!, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 4)),
                    const SizedBox(height: 8),
                    const Text('Válido por 5 minutos', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}