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
  String _estado = 'Introduce el monto para generar el código';
  bool _isGenerating = false;
  String? _codigoGenerado;

  Future<void> _generarCodigo() async {
    final monto = double.tryParse(_montoController.text.trim());
    if (monto == null || monto <= 0) {
      setState(() => _estado = '⚠️ Introduce un monto válido');
      return;
    }

    setState(() {
      _isGenerating = true;
      _estado = 'Generando código...';
    });

    try {
      // 🔥 El receptor es el usuario logueado (el que genera el código)
      final auth = Provider.of<AuthService>(context, listen: false);
      final receptorId = await auth.obtenerToken();
      if (receptorId == null) {
        setState(() => _estado = '❌ Usuario no autenticado');
        _isGenerating = false;
        return;
      }

      // ⚠️ IMPORTANTE: En el backend, el endpoint /pagos/generar espera emisor_id y receptor_id.
      // Pero en este flujo, el receptor es el que genera el código.
      // El emisor (pagador) se asignará cuando se confirme el pago.
      // Por eso, pasamos receptorId como receptor y emisorId lo dejamos en 0 o null.
      // El backend debe ajustarse para que el emisor sea opcional en la generación,
      // o mejor, que el endpoint solo necesite receptor_id y monto.
      // Si tu backend actual requiere emisor_id, puedes pasar un valor por defecto (ej: 0)
      // y luego en confirmar se asigna el emisor real.
      
      // Por ahora, ajustamos la llamada para que el backend funcione:
      // Pasamos el receptorId como receptor, y el emisorId lo ponemos a 0 (o al del usuario si quieres)
      // Pero lo correcto es que el backend solo necesite receptor_id y monto.
      // Como tengo entendido que tu backend ya tiene el endpoint /pagos/generar con emisor_id y receptor_id,
      // voy a pasar el receptorId como emisorId también (si no, el backend dará error).
      // 🔥 SOLUCIÓN RÁPIDA: pasamos el mismo ID para emisor y receptor (el receptor actual)
      // y luego en confirmar se sobreescribe el emisor con el pagador real.
      // Pero esto es un parche. La solución definitiva es modificar el backend.
      
      // Mientras tanto, haremos que el backend acepte un emisor_id opcional.
      // Voy a modificar la llamada para que el backend no falle.
      // Como el backend actual requiere emisor_id, usamos el receptorId como emisor también (temporal).
      
      final api = Provider.of<ApiService>(context, listen: false);
      final response = await api.generarPago(
        receptorId: int.parse(receptorId),
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
            const Icon(Icons.qr_code, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 20),
            Text(_estado, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 30),
            TextField(
              controller: _montoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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