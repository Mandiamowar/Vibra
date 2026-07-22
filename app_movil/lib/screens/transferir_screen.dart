import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class TransferirScreen extends StatefulWidget {
  const TransferirScreen({super.key});

  @override
  _TransferirScreenState createState() => _TransferirScreenState();
}

class _TransferirScreenState extends State<TransferirScreen> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _montoController = TextEditingController();
  String _estado = 'Introduce el nombre del receptor y el monto';
  bool _isProcessing = false;
  List<dynamic> _resultados = [];
  bool _mostrarResultados = false;
  int? _receptorIdSeleccionado; // 🔥 Guardar el ID seleccionado

  Future<void> _buscarReceptor() async {
    final nombre = _nombreController.text.trim();
    if (nombre.length < 2) {
      setState(() {
        _resultados = [];
        _mostrarResultados = false;
        _receptorIdSeleccionado = null;
      });
      return;
    }
    final api = Provider.of<ApiService>(context, listen: false);
    try {
      final results = await api.buscarUsuarios(nombre);
      setState(() {
        _resultados = results;
        _mostrarResultados = results.isNotEmpty;
        if (_resultados.isEmpty) _receptorIdSeleccionado = null;
      });
    } catch (e) {
      setState(() {
        _resultados = [];
        _mostrarResultados = false;
        _receptorIdSeleccionado = null;
      });
    }
  }

  Future<void> _transferir() async {
    // 🔥 Validar que se haya seleccionado un receptor de la lista
    if (_receptorIdSeleccionado == null) {
      setState(() => _estado = '⚠️ Selecciona un receptor de la lista');
      return;
    }

    final montoTexto = _montoController.text.trim();
    final monto = double.tryParse(montoTexto);
    if (monto == null || monto <= 0) {
      setState(() => _estado = '⚠️ Introduce un monto válido');
      return;
    }

    setState(() {
      _isProcessing = true;
      _estado = 'Procesando transferencia...';
    });

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final emisorId = await auth.obtenerToken();
      if (emisorId == null) {
        setState(() => _estado = '❌ Usuario no autenticado');
        _isProcessing = false;
        return;
      }

      // 🔥 Verificar que no sea pago a uno mismo
      if (int.parse(emisorId) == _receptorIdSeleccionado) {
        setState(() => _estado = '⚠️ No puedes pagarte a ti mismo');
        _isProcessing = false;
        return;
      }

      final api = Provider.of<ApiService>(context, listen: false);
      final response = await api.transferir(
        int.parse(emisorId),
        _receptorIdSeleccionado!,
        monto,
      );

      // 🔥 Verificar que la respuesta sea exitosa (puedes ajustar según tu backend)
      if (response['estado'] == 'confirmada' || response['transaccion_id'] != null) {
        setState(() {
          _estado = '✅ Transferencia realizada: $monto VIBRA';
          _isProcessing = false;
        });
        // 🔥 Cerrar pantalla indicando éxito para que HomeScreen recargue
        Navigator.pop(context, true);
      } else {
        setState(() {
          _estado = '⚠️ La transferencia no se completó: ${response['estado'] ?? 'error desconocido'}';
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _estado = '❌ Error: $e';
        _isProcessing = false;
      });
      Navigator.pop(context, false); // 🔥 Cerrar con error
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagar a usuario'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.send, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 20),
            Text(_estado, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 30),
            TextField(
              controller: _nombreController,
              onChanged: (_) => _buscarReceptor(),
              decoration: const InputDecoration(
                labelText: 'Nombre del receptor',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
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
                  itemCount: _resultados.length,
                  itemBuilder: (context, index) {
                    final user = _resultados[index];
                    return ListTile(
                      title: Text(user['nombre']),
                      subtitle: Text('ID: ${user['id']}'),
                      tileColor: _receptorIdSeleccionado == user['id'] 
                          ? Colors.grey.shade200 
                          : null,
                      onTap: () {
                        _nombreController.text = user['nombre'];
                        setState(() {
                          _receptorIdSeleccionado = user['id'];
                          _mostrarResultados = false;
                        });
                      },
                    );
                  },
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
              onPressed: _isProcessing ? null : _transferir,
              icon: Icon(_isProcessing ? Icons.hourglass_empty : Icons.send),
              label: Text(_isProcessing ? 'Procesando...' : 'Transferir'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}