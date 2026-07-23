import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

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

  bool _isLoading = true;
  bool _isSaving = false;
  int? _usuarioId;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final token = await auth.obtenerToken();
      if (token == null) {
        setState(() => _isLoading = false);
        return;
      }
      _usuarioId = int.parse(token);

      final api = Provider.of<ApiService>(context, listen: false);
      final usuario = await api.obtenerUsuario(_usuarioId!);

      _nombreController.text = usuario['nombre'] ?? '';
      _nifController.text = usuario['nif'] ?? '';
      _emailController.text = usuario['email_factura'] ?? '';
      _direccionController.text = usuario['direccion_factura'] ?? '';
      _razonSocialController.text = usuario['razon_social'] ?? '';
      _telefonoController.text = usuario['telefono'] ?? '';
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar perfil: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _guardarDatos() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final data = {
        'nombre': _nombreController.text.trim(),
        'nif': _nifController.text.trim(),
        'email_factura': _emailController.text.trim(),
        'direccion_factura': _direccionController.text.trim(),
        'razon_social': _razonSocialController.text.trim(),
        'telefono': _telefonoController.text.trim(),
      };
      // Eliminar campos vacíos
      final filteredData = Map.fromEntries(
        data.entries.where((entry) => entry.value.isNotEmpty)
      );
      await api.actualizarUsuario(_usuarioId!, filteredData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Perfil actualizado correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error al guardar: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _nifController.dispose();
    _emailController.dispose();
    _direccionController.dispose();
    _razonSocialController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _guardarDatos,
            tooltip: 'Guardar cambios',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text('Datos personales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                controller: _direccionController,
                decoration: const InputDecoration(labelText: 'Dirección'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _razonSocialController,
                decoration: const InputDecoration(labelText: 'Razón social (opcional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _guardarDatos,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}