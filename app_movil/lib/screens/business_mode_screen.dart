import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
 // ✅ Importar para NdefMessage y NdefRecord
import 'dart:convert';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/linea_concepto.dart';
import 'registrar_negocio_screen.dart';
import 'editar_negocio_screen.dart';

class BusinessModeScreen extends StatefulWidget {
  const BusinessModeScreen({super.key});

  @override
  _BusinessModeScreenState createState() => _BusinessModeScreenState();
}

class _BusinessModeScreenState extends State<BusinessModeScreen> {
  // Controladores
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _conceptoController = TextEditingController();
  final TextEditingController _importeController = TextEditingController();

  // Estado
  String _estado = 'Cargando datos del negocio...';
  bool _isLoading = true;
  bool _isProcessing = false;
  bool _mostrarResultados = false;

  // Datos del negocio
  Map<String, dynamic>? _negocio;
  bool _tieneNegocio = false;

  // Datos del cliente
  int? _clienteId;
  String? _clienteNombre;
  String? _clienteEmail;
  List<dynamic> _clientes = [];

  // Líneas de concepto
  List<LineaConcepto> _lineas = [];
  double _total = 0.0;

  // QR/NFC generado
  String? _qrData;
  bool _mostrarQR = false;

  @override
  void initState() {
    super.initState();
    _cargarNegocio();
  }

  Future<void> _cargarNegocio() async {
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final token = await auth.obtenerToken();
      if (token == null) {
        setState(() {
          _estado = '❌ Usuario no autenticado';
          _isLoading = false;
        });
        return;
      }
      final api = Provider.of<ApiService>(context, listen: false);
      final negocio = await api.obtenerNegocio(int.parse(token));
      if (negocio['id'] != null) {
        setState(() {
          _negocio = negocio;
          _tieneNegocio = true;
          _estado = '✅ Negocio: ${negocio['nombre_comercial']} (NIF: ${negocio['nif']})';
          _isLoading = false;
        });
      } else {
        setState(() {
          _tieneNegocio = false;
          _estado = '⚠️ No tienes un negocio registrado. Regístrate primero.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _estado = '❌ Error al cargar negocio: $e';
        _isLoading = false;
      });
    }
  }

  // 🔍 Buscar cliente por nombre
  Future<void> _buscarCliente() async {
    final nombre = _nombreController.text.trim();
    if (nombre.length < 2) {
      setState(() {
        _clientes = [];
        _mostrarResultados = false;
        _clienteId = null;
        _clienteNombre = null;
      });
      return;
    }
    final api = Provider.of<ApiService>(context, listen: false);
    try {
      final results = await api.buscarUsuarios(nombre);
      setState(() {
        _clientes = results;
        _mostrarResultados = results.isNotEmpty;
      });
    } catch (e) {
      setState(() {
        _clientes = [];
        _mostrarResultados = false;
      });
    }
  }

  // ➕ Añadir línea de concepto
  void _agregarLinea() {
    final cantidadController = TextEditingController(text: '1');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Añadir línea'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _conceptoController,
              decoration: const InputDecoration(labelText: 'Concepto'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _importeController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Precio unitario (€)'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: cantidadController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Cantidad'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _conceptoController.clear();
              _importeController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final concepto = _conceptoController.text.trim();
              final cantidad = int.tryParse(cantidadController.text.trim()) ?? 1;
              final precio = double.tryParse(_importeController.text.trim()) ?? 0.0;
              if (concepto.isNotEmpty && precio > 0) {
                setState(() {
                  _lineas.add(LineaConcepto(
                    cantidad: cantidad,
                    descripcion: concepto,
                    precioUnitario: precio,
                  ));
                  _calcularTotal();
                });
                _conceptoController.clear();
                _importeController.clear();
              }
              Navigator.pop(context);
            },
            child: const Text('Añadir'),
          ),
        ],
      ),
    );
  }

  // ❌ Eliminar línea
  void _eliminarLinea(int index) {
    setState(() {
      _lineas.removeAt(index);
      _calcularTotal();
    });
  }

  // 💰 Calcular total
  void _calcularTotal() {
    _total = _lineas.fold(0, (sum, linea) => sum + linea.subtotal);
  }

  // 📱 Generar QR/NFC
  void _generarCodigo() async {
    if (_clienteId == null) {
      setState(() => _estado = '⚠️ Identifica un cliente primero');
      return;
    }
    if (_lineas.isEmpty) {
      setState(() => _estado = '⚠️ Añade al menos una línea');
      return;
    }

    setState(() {
      _isProcessing = true;
      _estado = 'Generando código...';
    });

    try {
      // Construir JSON con los datos de la transacción
      final data = {
        'negocio_id': _negocio!['id'],
        'cliente_id': _clienteId,
        'total': _total,
        'lineas': _lineas.map((l) => l.toJson()).toList(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'firma': '', // Aquí iría un hash de seguridad
      };
      final jsonString = jsonEncode(data);
      setState(() {
        _qrData = jsonString;
        _mostrarQR = true;
        _estado = '✅ Código generado. El cliente debe escanearlo.';
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _estado = '❌ Error: $e';
        _isProcessing = false;
      });
    }
  }

 // 📡 Escribir en tag NFC
Future<void> _escribirNFC() async {
  if (_qrData == null) return;
  try {
    final availability = await FlutterNfcKit.nfcAvailability;
    if (availability != NFCAvailability.available) {
      setState(() => _estado = '❌ NFC no disponible');
      return;
    }

    // Crear mensaje NDEF (usando la API de flutter_nfc_kit)
    final ndefMessage = NdefMessage([
      NdefRecord.createText(_qrData!),
    ]);
    await FlutterNfcKit.writeNDEF(ndefMessage);
    setState(() => _estado = '✅ Tag NFC escrito correctamente');
    await FlutterNfcKit.finish();
  } catch (e) {
    setState(() => _estado = '❌ Error al escribir NFC: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_tieneNegocio) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Modo Negocio'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.storefront, size: 80, color: Colors.green),
                const SizedBox(height: 20),
                const Text('No tienes un negocio registrado.'),
                const SizedBox(height: 10),
                Text(
                  _estado,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegistrarNegocioScreen()),
                    ).then((_) => _cargarNegocio());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Registrar negocio'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modo Negocio (TPV)'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarNegocio,
            tooltip: 'Recargar datos',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Datos del negocio
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.business, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_negocio!['nombre_comercial']} (NIF: ${_negocio!['nif']})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.green),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditarNegocioScreen(negocio: _negocio!),
                          ),
                        );
                        if (result == true) _cargarNegocio();
                      },
                      tooltip: 'Editar negocio',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Estado
              Text(
                _estado,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),

              // Cliente
              const Text('Cliente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _nombreController,
                onChanged: (_) => _buscarCliente(),
                decoration: const InputDecoration(
                  labelText: 'Buscar por nombre',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_search),
                ),
              ),
              if (_mostrarResultados)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _clientes.length,
                    itemBuilder: (context, index) {
                      final user = _clientes[index];
                      return ListTile(
                        title: Text(user['nombre']),
                        subtitle: Text('ID: ${user['id']}'),
                        onTap: () {
                          setState(() {
                            _clienteId = user['id'];
                            _clienteNombre = user['nombre'];
                            _clienteEmail = user['email'] ?? '';
                            _mostrarResultados = false;
                            _nombreController.text = user['nombre'];
                            _estado = '✅ Cliente: $_clienteNombre';
                          });
                        },
                      );
                    },
                  ),
                ),
              if (_clienteNombre != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
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
              const SizedBox(height: 16),

              // Líneas de concepto
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Líneas de concepto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.green),
                    onPressed: _agregarLinea,
                    tooltip: 'Añadir línea',
                  ),
                ],
              ),
              if (_lineas.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Añade líneas para construir el ticket',
                      style: TextStyle(color: Colors.grey)),
                )
              else
                Column(
                  children: [
                    ..._lineas.asMap().entries.map((entry) {
                      final index = entry.key;
                      final linea = entry.value;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(linea.descripcion),
                          subtitle: Text(
                            '${linea.cantidad} x ${linea.precioUnitario.toStringAsFixed(2)} € = ${linea.subtotal.toStringAsFixed(2)} €',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _eliminarLinea(index),
                          ),
                        ),
                      );
                    }).toList(),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(
                            '${_total.toStringAsFixed(2)} €',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),

              // Botones de generación
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _generarCodigo,
                      icon: const Icon(Icons.qr_code),
                      label: const Text('Generar QR'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _qrData != null ? _escribirNFC : null,
                      icon: const Icon(Icons.nfc),
                      label: const Text('NFC'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              if (_mostrarQR && _qrData != null) ...[
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: QrImageView(
                      data: _qrData!,
                      version: QrVersions.auto,
                      size: 200,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}