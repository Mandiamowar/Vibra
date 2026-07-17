import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/factura.dart';

class MisFacturasScreen extends StatefulWidget {
  const MisFacturasScreen({super.key});

  @override
  _MisFacturasScreenState createState() => _MisFacturasScreenState();
}

class _MisFacturasScreenState extends State<MisFacturasScreen> {
  List<Factura> _facturas = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _cargarFacturas();
  }

  Future<void> _cargarFacturas() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final usuarioId = await auth.obtenerToken();
      if (usuarioId == null) {
        setState(() {
          _error = 'Usuario no autenticado';
          _isLoading = false;
        });
        return;
      }

      final api = Provider.of<ApiService>(context, listen: false);
      final response = await api.misFacturas(int.parse(usuarioId));

      setState(() {
        _facturas = response.map((item) => Factura.fromJson(item)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar facturas: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _descargarFactura(int facturaId, String numeroFactura) async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final url = await api.descargarFactura(facturaId);

      // Abrir la URL en el navegador
      // O usar un paquete como `open_file` o `share` para guardar
      // Por ahora abrimos en el navegador
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text('Factura $numeroFactura'),
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.picture_as_pdf, size: 80, color: Colors.red),
                  SizedBox(height: 20),
                  Text('Descarga el PDF desde el navegador'),
                  SizedBox(height: 10),
                  Text('Próximamente: descarga directa en la app'),
                ],
              ),
            ),
          ),
        ),
      );

      // En el futuro, usar `dio` para descargar y guardar localmente
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al descargar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Facturas'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarFacturas,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                _error,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _cargarFacturas,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_facturas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No tienes facturas aún',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Cuando pagues en un negocio que use Vibra Pay,\nrecibirás la factura aquí.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarFacturas,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _facturas.length,
        itemBuilder: (context, index) {
          final factura = _facturas[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () => _descargarFactura(factura.id, factura.numeroFactura),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: factura.enviado ? Colors.green[100] : Colors.orange[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        factura.enviado ? Icons.check_circle : Icons.hourglass_empty,
                        color: factura.enviado ? Colors.green[700] : Colors.orange[700],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            factura.numeroFactura,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            factura.concepto,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '${factura.importe.toStringAsFixed(2)} €',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.deepPurple,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                factura.fecha,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}