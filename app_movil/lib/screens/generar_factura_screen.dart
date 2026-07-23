import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class GenerarFacturaScreen extends StatefulWidget {
  const GenerarFacturaScreen({super.key});

  @override
  _GenerarFacturaScreenState createState() => _GenerarFacturaScreenState();
}

class _GenerarFacturaScreenState extends State<GenerarFacturaScreen> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _importeController = TextEditingController();
  final TextEditingController _conceptoController = TextEditingController();
  String _estado = 'Busca al cliente y rellena los datos';
  bool _isLoading = false;
  List<dynamic> _clientes = [];
  bool _mostrarResultados = false;
  int? _clienteIdSeleccionado;
  int? _negocioIdSeleccionado;
  List<dynamic> _negocios = [];

  @override
  void initState() {
    super.initState();
    _cargarNegocios();
  }

  Future<void> _cargarNegocios() async {
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final usuarioId = await auth.obtenerToken();
      if (usuarioId == null) return;
      final api = Provider.of<ApiService>(context, listen: false);
      final negocio = await api.obtenerNegocio(int.parse(usuarioId));
      if (negocio['id'] != null) {
        setState(() {
          _negocios = [negocio];
          _negocioIdSeleccionado = negocio['id'];
        });
      } else {
        setState(() => _estado = '⚠️ No tienes un negocio registrado. Regístrate primero.');
      }
    } catch (e) {
      setState(() => _estado = '❌ Error al cargar negocio: $e');
    }
  }

  Future<void> _buscarCliente() async {
    final nombre = _nombreController.text.trim();
    if (nombre.length < 2) {
      setState(() {
        _clientes = [];
        _mostrarResultados = false;
        _clienteIdSeleccionado = null;
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

  Future<void> _generarFactura() async {
    if (_clienteIdSeleccionado == null) {
      setState(() => _estado = '⚠️ Selecciona un cliente de la lista');
      return;
    }
    if (_negocioIdSeleccionado == null) {
      setState(() => _estado = '⚠️ No hay negocio seleccionado');
      return;
    }
    final importe = double.tryParse(_importeController.text.trim());
    if (importe == null || importe <= 0) {
      setState(() => _estado = '⚠️ Importe inválido');
      return;
    }
    final concepto = _conceptoController.text.trim();
    if (concepto.isEmpty) {
      setState(() => _estado = '⚠️ Introduce un concepto');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final response = await api.generarFactura(
        negocioId: _negocioIdSeleccionado!,
        clienteId: _clienteIdSeleccionado!,
        importe: importe,
        concepto: concepto,
      );

      setState(() {
        _estado = '✅ Factura generada: ${response['numero_factura']}';
        _isLoading = false;
        _nombreController.clear();
        _importeController.clear();
        _conceptoController.clear();
        _clienteIdSeleccionado = null;
        _clientes = [];
        _mostrarResultados = false;
      });
    } catch (e) {
      setState(() {
        _estado = '❌ Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generar Factura'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_estado, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            if (_negocios.isEmpty)
              const Text('Registra un negocio antes de generar facturas.'),
            TextField(
              controller: _nombreController,
              onChanged: (_) => _buscarCliente(),
              decoration: const InputDecoration(
                labelText: 'Nombre del cliente',
                border: OutlineInputBorder(),
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
                          _clienteIdSeleccionado = user['id'];
                          _mostrarResultados = false;
                        });
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _importeController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Importe (€)',
                border: OutlineInputBorder(),
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
              onPressed: _isLoading ? null : _generarFactura,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Generar Factura'),
            ),
          ],
        ),
      ),
    );
  }
}