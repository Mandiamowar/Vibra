import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/cliente.dart';

class PerfilClienteScreen extends StatefulWidget {
  const PerfilClienteScreen({super.key});

  @override
  _PerfilClienteScreenState createState() => _PerfilClienteScreenState();
}

class _PerfilClienteScreenState extends State<PerfilClienteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _nifController = TextEditingController();
  final _emailController = TextEditingController();
  final _direccionController = TextEditingController();
  final _razonSocialController = TextEditingController();
  final _telefonoController = TextEditingController();

  Cliente? _cliente;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final id = await auth.obtenerToken();
    if (id == null) return;

    // Aquí iría una llamada a la API para obtener los datos del cliente
    // Por ahora usamos datos de ejemplo
    setState(() {
      _cliente = Cliente(
        id: int.parse(id),
        nombre: 'Pepe',
        nif: '12345678A',
        email: 'pepe@empresa.com',
        direccion: 'Calle Mayor 1, Madrid',
        razonSocial: 'Pepe S.L.',
        telefono: '600000000',
      );
      _nombreController.text = _cliente!.nombre;
      _nifController.text = _cliente!.nif ?? '';
      _emailController.text = _cliente!.email ?? '';
      _direccionController.text = _cliente!.direccion ?? '';
      _razonSocialController.text = _cliente!.razonSocial ?? '';
      _telefonoController.text = _cliente!.telefono ?? '';
      _isLoading = false;
    });
  }

  Future<void> _guardarCliente() async {
    if (!_formKey.currentState!.validate()) return;
    // Guardar en backend (pendiente de implementar)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Datos guardados correctamente')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // QR del cliente
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: 'cliente:${_cliente?.id ?? 0}',
                    version: QrVersions.auto,
                    size: 180,
                    gapless: false,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Escanea este QR para facturar',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Datos fiscales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre completo'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nifController,
                decoration: const InputDecoration(labelText: 'NIF / CIF'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email para facturas'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _razonSocialController,
                decoration: const InputDecoration(labelText: 'Razón social (opcional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _direccionController,
                decoration: const InputDecoration(labelText: 'Dirección'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _guardarCliente,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Guardar datos'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}