import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class EditarNegocioScreen extends StatefulWidget {
  final Map<String, dynamic> negocio;
  const EditarNegocioScreen({super.key, required this.negocio});

  @override
  _EditarNegocioScreenState createState() => _EditarNegocioScreenState();
}

class _EditarNegocioScreenState extends State<EditarNegocioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _nifController = TextEditingController();
  final _direccionController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _serieController = TextEditingController();
  final _ivaController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nombreController.text = widget.negocio['nombre_comercial'] ?? '';
    _nifController.text = widget.negocio['nif'] ?? '';
    _direccionController.text = widget.negocio['direccion'] ?? '';
    _emailController.text = widget.negocio['email_contacto'] ?? '';
    _telefonoController.text = widget.negocio['telefono'] ?? '';
    _serieController.text = widget.negocio['serie_factura'] ?? 'A';
    _ivaController.text = (widget.negocio['iva'] ?? 21.0).toString();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final iva = double.tryParse(_ivaController.text.trim()) ?? 21.0;
      await api.actualizarNegocio(widget.negocio['id'], {
        'nombre_comercial': _nombreController.text.trim(),
        'nif': _nifController.text.trim(),
        'direccion': _direccionController.text.trim(),
        'email_contacto': _emailController.text.trim(),
        'telefono': _telefonoController.text.trim(),
        'serie_factura': _serieController.text.trim(),
        'iva': iva,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Negocio actualizado')),
      );
      Navigator.pop(context, true);
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
        title: const Text('Editar negocio'),
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
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ivaController,
                decoration: const InputDecoration(
                  labelText: 'IVA (%)',
                  hintText: '21',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v!.isEmpty) return 'Requerido';
                  final value = double.tryParse(v);
                  if (value == null || value < 0) return 'Introduce un porcentaje válido';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _guardar,
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
                    : const Text('Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}