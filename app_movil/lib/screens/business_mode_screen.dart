import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class BusinessModeScreen extends StatefulWidget {
  const BusinessModeScreen({super.key});

  @override
  _BusinessModeScreenState createState() => _BusinessModeScreenState();
}

class _BusinessModeScreenState extends State<BusinessModeScreen> {
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _importeController = TextEditingController();
  final TextEditingController _conceptoController = TextEditingController();
  String _estado = 'Introduce el código del cliente (6 dígitos)';
  bool _isProcessing = false;
  String? _clienteId;
  String? _clienteNombre;
  String? _clienteEmail;

  // Simulación de búsqueda de cliente por código (en producción, llamada a API)
  Future<void> _buscarClientePorCodigo(String codigo) async {
    if (codigo.length != 6 || !RegExp(r'^[0-9]+$').hasMatch(codigo)) {
      setState(() {
        _estado = '⚠️ Código inválido (debe ser de 6 dígitos)';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _estado = 'Buscando cliente...';
    });

    try {
      // 🔥 SIMULACIÓN: En producción, llamar a la API real
      await Future.delayed(const Duration(seconds: 1));
      
      // Simulación de cliente encontrado (si el código es 123456)
      if (codigo == '123456') {
        setState(() {
          _clienteId = '1';
          _clienteNombre = 'Pepe';
          _clienteEmail = 'pepe@empresa.com';
          _estado = '✅ Cliente identificado: $_clienteNombre';
          _isProcessing = false;
        });
      } else {
        setState(() {
          _estado = '❌ Código no válido o cliente no encontrado';
          _isProcessing = false;
          _clienteId = null;
          _clienteNombre = null;
          _clienteEmail = null;
        });
      }
    } catch (e) {
      setState(() {
        _estado = '❌ Error al buscar cliente: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _generarFactura() async {
    if (_clienteId == null) {
      setState(() => _estado = '⚠️ Primero identifica al cliente (código)');
      return;
    }
    final importe = double.tryParse(_importeController.text.trim());
    if (importe == null || importe <= 0) {
      setState(() => _estado = '⚠️ Introduce un importe válido');
      return;
    }
    final concepto = _conceptoController.text.trim();
    if (concepto.isEmpty) {
      setState(() => _estado = '⚠️ Introduce un concepto');
      return;
    }

    setState(() {
      _isProcessing = true;
      _estado = 'Generando factura...';
    });

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final negocioId = await auth.obtenerToken();
      if (negocioId == null) {
        setState(() => _estado = '❌ Negocio no autenticado');
        _isProcessing = false;
        return;
      }

      final api = Provider.of<ApiService>(context, listen: false);
      final response = await api.post('/facturas/generar', {
        'negocio_id': int.parse(negocioId),
        'cliente_id': int.parse(_clienteId!),
        'importe': importe,
        'concepto': concepto,
        'email_destino': _clienteEmail,
      });

      setState(() {
        _estado = '✅ Factura generada: ${response['numero_factura']}';
        _isProcessing = false;
        _importeController.clear();
        _conceptoController.clear();
        _codigoController.clear();
        _clienteId = null;
        _clienteNombre = null;
        _clienteEmail = null;
      });
    } catch (e) {
      setState(() {
        _estado = '❌ Error: $e';
        _isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _importeController.dispose();
    _conceptoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modo Negocio (TPV)'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.storefront, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            Text(
              _estado,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _codigoController,
              decoration: const InputDecoration(
                labelText: 'Código del cliente (6 dígitos)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.qr_code),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isProcessing ? null : () => _buscarClientePorCodigo(_codigoController.text),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text(_isProcessing ? 'Buscando...' : 'Identificar cliente'),
            ),
            if (_clienteNombre != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Colors.green),
                    const SizedBox(width: 8),
                    Text('Cliente: $_clienteNombre', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            TextField(
              controller: _importeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Importe (€)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _conceptoController,
              decoration: const InputDecoration(
                labelText: 'Concepto',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isProcessing ? null : _generarFactura,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text(_isProcessing ? 'Procesando...' : 'Generar Factura'),
            ),
          ],
        ),
      ),
    );
  }
}