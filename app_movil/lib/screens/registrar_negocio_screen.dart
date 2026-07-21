import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class RegistrarNegocioScreen extends StatefulWidget {
  const RegistrarNegocioScreen({super.key});

  @override
  _RegistrarNegocioScreenState createState() => _RegistrarNegocioScreenState();
}

class _RegistrarNegocioScreenState extends State<RegistrarNegocioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _nifController = TextEditingController();
  final _direccionController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _serieController = TextEditingController(text: 'A');
  bool _isLoading = false;

  Future<void> _registrarNegocio() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final usuarioId = await auth.obtenerToken();
      if (usuarioId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario no autenticado')),
        );
        return;
      }

      final api = Provider.of<ApiService>(context, listen: false);
      final response = await api.registrarNegocio(
        usuarioId: int.parse(usuarioId),
        nombreComercial: _nombreController.text.trim(),
        nif: _nifController.text.trim(),
        direccion: _direccionController.text.trim(),
        emailContacto: _emailController.text.trim(),
        telefono: _telefonoController.text.trim(),
        serieFactura: _serieController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Negocio registrado: ${response['nombre_comercial']}')),
      );
      Navigator.pop(context); // Volver a la pantalla anterior
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Negocio'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre comercial *'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nifController,
                decoration: const InputDecoration(labelText: 'NIF *'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _direccionController,
                decoration: const InputDecoration(labelText: 'Dirección'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email de contacto'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _serieController,
                decoration: const InputDecoration(labelText: 'Serie de facturación'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _registrarNegocio,
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
                    : const Text('Registrar negocio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}