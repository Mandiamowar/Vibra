import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'registrar_negocio_screen.dart'; // Asegúrate de tener esta pantalla

class BusinessModeScreen extends StatefulWidget {
  const BusinessModeScreen({super.key});

  @override
  _BusinessModeScreenState createState() => _BusinessModeScreenState();
}

class _BusinessModeScreenState extends State<BusinessModeScreen> {
  // Controladores
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _importeController = TextEditingController();
  final TextEditingController _conceptoController = TextEditingController();
  
  // Estado
  String _estado = 'Cargando datos del negocio...';
  bool _isLoading = true;
  bool _isProcessing = false;
  
  // Datos del negocio
  Map<String, dynamic>? _negocio;
  bool _tieneNegocio = false;
  
  // Datos del cliente
  int? _clienteId;
  String? _clienteNombre;
  String? _clienteEmail;
  List<dynamic> _clientes = [];
  bool _mostrarResultados = false;

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

  // 🔍 Buscar cliente por nombre (igual que en TransferirScreen)
  Future<void> _buscarClientePorNombre() async {
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

  // 🔑 Buscar cliente por código de 6 dígitos (simulado, puedes conectar con API real)
  Future<void> _buscarClientePorCodigo(String codigo) async {
    if (codigo.length != 6 || !RegExp(r'^[0-9]+$').hasMatch(codigo)) {
      setState(() => _estado = '⚠️ Código inválido (debe ser de 6 dígitos)');
      return;
    }

    setState(() {
      _isProcessing = true;
      _estado = 'Buscando cliente por código...';
    });

    try {
      // 🔥 SIMULACIÓN: En producción, llama a un endpoint /clientes/buscar/{codigo}
      await Future.delayed(const Duration(seconds: 1));
      // Simulación: si el código es 123456, devuelve cliente ficticio
      if (codigo == '123456') {
        setState(() {
          _clienteId = 1;
          _clienteNombre = 'Pepe';
          _clienteEmail = 'pepe@empresa.com';
          _estado = '✅ Cliente identificado: $_clienteNombre (código)';
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

  // 📄 Generar factura
  Future<void> _generarFactura() async {
    if (_clienteId == null) {
      setState(() => _estado = '⚠️ Identifica un cliente primero');
      return;
    }
    if (_negocio == null || _negocio!['id'] == null) {
      setState(() => _estado = '⚠️ No hay negocio seleccionado');
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
      final api = Provider.of<ApiService>(context, listen: false);
      final response = await api.generarFactura(
        negocioId: _negocio!['id'],
        clienteId: _clienteId!,
        importe: importe,
        concepto: concepto,
        emailDestino: _clienteEmail,
      );

      setState(() {
        _estado = '✅ Factura generada: ${response['numero_factura']}';
        _isProcessing = false;
        _importeController.clear();
        _conceptoController.clear();
        _nombreController.clear();
        _codigoController.clear();
        _clienteId = null;
        _clienteNombre = null;
        _clienteEmail = null;
        _clientes = [];
        _mostrarResultados = false;
      });
    } catch (e) {
      setState(() {
        _estado = '❌ Error: $e';
        _isProcessing = false;
      });
    }
  }

  void _irARegistrarNegocio() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegistrarNegocioScreen()),
    ).then((_) => _cargarNegocio()); // Recargar al volver
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _codigoController.dispose();
    _importeController.dispose();
    _conceptoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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
                  onPressed: _irARegistrarNegocio,
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
        title: const Text('Modo Negocio'),
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
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _estado,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),

              // SECCIÓN: Identificar cliente
              const Text('Identificar cliente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              // Búsqueda por nombre
              TextField(
                controller: _nombreController,
                onChanged: (_) => _buscarClientePorNombre(),
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
                          _nombreController.text = user['nombre'];
                          setState(() {
                            _clienteId = user['id'];
                            _clienteNombre = user['nombre'];
                            _clienteEmail = user['email'] ?? '';
                            _mostrarResultados = false;
                            _estado = '✅ Cliente: $_clienteNombre';
                          });
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 10),
              // O por código
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codigoController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        labelText: 'Código de 6 dígitos',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.qr_code),
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isProcessing ? null : () => _buscarClientePorCodigo(_codigoController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Identificar'),
                  ),
                ],
              ),
              if (_clienteNombre != null) ...[
                const SizedBox(height: 10),
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
              const SizedBox(height: 20),

              // SECCIÓN: Generar factura
              const Text('Datos de la factura', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
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
                  prefixIcon: Icon(Icons.description),
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
      ),
    );
  }
}