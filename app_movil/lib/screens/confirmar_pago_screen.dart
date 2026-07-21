import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class ConfirmarPagoScreen extends StatefulWidget {
  const ConfirmarPagoScreen({super.key});

  @override
  _ConfirmarPagoScreenState createState() => _ConfirmarPagoScreenState();
}

class _ConfirmarPagoScreenState extends State<ConfirmarPagoScreen> {
  final TextEditingController _codigoController = TextEditingController();
  String _estado = 'Introduce el código de 6 dígitos';
  bool _isProcessing = false;

  Future<void> _confirmarPago() async {
    final codigo = _codigoController.text.trim();
    if (codigo.length != 6 || !RegExp(r'^[0-9]+$').hasMatch(codigo)) {
      setState(() => _estado = '⚠️ Introduce un código de 6 dígitos válido');
      return;
    }

    setState(() {
      _isProcessing = true;
      _estado = 'Confirmando pago...';
    });

    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final response = await api.confirmarPago(codigo);

      setState(() {
        _estado = '✅ Pago recibido: ${response['monto']} VIBRA de ${response['emisor']}';
        _isProcessing = false;
        _codigoController.clear();
      });

      // 🔥 Devolver los nuevos saldos a HomeScreen
      Navigator.pop(context, {
        'success': true,
        'nuevo_saldo': response['nuevo_saldo_receptor'], // el receptor es quien confirma
      });
    } catch (e) {
      setState(() {
        _estado = '❌ Error: $e';
        _isProcessing = false;
      });
      Navigator.pop(context, {'success': false});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar pago'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            Text(_estado, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 30),
            TextField(
              controller: _codigoController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Código de 6 dígitos',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.qr_code),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _confirmarPago,
              icon: Icon(_isProcessing ? Icons.hourglass_empty : Icons.check_circle),
              label: Text(_isProcessing ? 'Confirmando...' : 'Confirmar pago'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'El código debe ser de 6 dígitos y válido por 5 minutos.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}