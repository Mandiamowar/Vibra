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

  Future<void> _buscarReceptor() async {
    final nombre = _nombreController.text.trim();
    if (nombre.length < 2) {
      setState(() {
        _resultados = [];
        _mostrarResultados = false;
      });
      return;
    }
    final api = Provider.of<ApiService>(context, listen: false);
    try {
      final results = await api.buscarUsuarios(nombre);
      setState(() {
        _resultados = results;
        _mostrarResultados = results.isNotEmpty;
      });
    } catch (e) {
      setState(() {
        _resultados = [];
        _mostrarResultados = false;
      });
    }
  }

  Future<void> _transferir(int receptorId, String receptorNombre) async {
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

      final api = Provider.of<ApiService>(context, listen: false);
      final response = await api.transferir(
        int.parse(emisorId),
        receptorId,
        monto,
      );

      setState(() {
        _estado = '✅ Transferencia realizada: $monto VIBRA a $receptorNombre';
        _isProcessing = false;
        _nombreController.clear();
        _montoController.clear();
        _resultados = [];
        _mostrarResultados = false;
      });
    } catch (e) {
      setState(() {
        _estado = '❌ Error: $e';
        _isProcessing = false;
      });
    }
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
                      subtitle: Text('ID: ${user['id']}'), // ✅ sin email
                      onTap: () {
                        _nombreController.text = user['nombre'];
                        setState(() {
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
              onPressed: _isProcessing ? null : () async {
                final nombre = _nombreController.text.trim();
                if (nombre.isEmpty) {
                  setState(() => _estado = '⚠️ Introduce un nombre válido');
                  return;
                }
                final selected = _resultados.firstWhere(
                  (u) => u['nombre'] == nombre,
                  orElse: () => null,
                );
                if (selected == null) {
                  setState(() => _estado = '⚠️ Usuario no encontrado. Selecciona de la lista.');
                  return;
                }
                await _transferir(selected['id'], selected['nombre']);
              },
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