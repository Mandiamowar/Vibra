import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'transferir_screen.dart';
import 'generar_codigo_pago_screen.dart';
import 'confirmar_pago_screen.dart'; // ← IMPORTANTE: añadir este import
import 'mis_facturas_screen.dart';
import 'perfil_cliente_screen.dart';
import 'business_mode_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  double _precio = 0.0;
  double _saldo = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    final api = Provider.of<ApiService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);
    try {
      final precioResp = await api.obtenerPrecio();
      setState(() => _precio = precioResp['precio'] ?? 0.0);

      final token = await auth.obtenerToken();
      if (token != null) {
        final usuario = await api.obtenerUsuario(int.parse(token));
        setState(() => _saldo = usuario['saldo'] ?? 0.0);
      }
    } catch (e) {
      // ignorar
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vibra Pay'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const PerfilClienteScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.storefront),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const BusinessModeScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const MisFacturasScreen())),
            tooltip: 'Mis Facturas',
          ),
          // 🔥 NUEVO BOTÓN: Confirmar pago con código
          IconButton(
            icon: const Icon(Icons.payment),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ConfirmarPagoScreen()),
              );
              _cargarDatos(); // Recargar saldo al volver
            },
            tooltip: 'Confirmar pago con código',
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isLoading ? 'Cargando...' : 'Saldo: ${_saldo.toStringAsFixed(2)} VIBRA',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Precio: ${_precio.toStringAsFixed(6)} €',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => TransferirScreen()),
                            );
                          },
                          icon: const Icon(Icons.send, size: 30),
                          label: const Text('Pagar', style: TextStyle(fontSize: 18)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const GenerarCodigoPagoScreen()),
                            );
                            _cargarDatos();
                          },
                          icon: const Icon(Icons.qr_code, size: 30),
                          label: const Text('Recibir', style: TextStyle(fontSize: 18)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Paga a otro usuario o recibe un pago con código de 6 dígitos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          HistoryScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historial'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Ajustes'),
        ],
      ),
    );
  }
}