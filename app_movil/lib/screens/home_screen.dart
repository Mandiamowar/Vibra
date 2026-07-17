import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'perfil_cliente_screen.dart';
import 'business_mode_screen.dart';
import 'mis_facturas_screen.dart';
import 'generar_codigo_pago_screen.dart';
import 'confirmar_pago_screen.dart';

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
      // Si falla, no actualizar
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
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Precio: ${_precio.toStringAsFixed(6)} €',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const GenerarCodigoPagoScreen()),
                          );
                        },
                        icon: const Icon(Icons.qr_code),
                        label: const Text('Generar código'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ConfirmarPagoScreen()),
                          );
                          _cargarDatos();
                        },
                        icon: const Icon(Icons.payment),
                        label: const Text('Confirmar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Genera un código para que otro usuario pague o confirma un código para recibir un pago.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
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