import 'dart:io';  // <--- IMPORTAR
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/ticket_service.dart';
import '../services/auth_service.dart';

class SubirTicketScreen extends StatefulWidget {
  const SubirTicketScreen({super.key});

  @override
  _SubirTicketScreenState createState() => _SubirTicketScreenState();
}

class _SubirTicketScreenState extends State<SubirTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _importeController = TextEditingController();
  final _proveedorController = TextEditingController();
  final _categoriaController = TextEditingController();
  
  DateTime _fechaSeleccionada = DateTime.now();
  XFile? _imagenSeleccionada;
  bool _isLoading = false;
  String _mensaje = '';

  final ImagePicker _picker = ImagePicker();

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (fecha != null) {
      setState(() => _fechaSeleccionada = fecha);
    }
  }

  Future<void> _tomarFoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 70,
    );
    setState(() => _imagenSeleccionada = image);
  }

  Future<void> _subirTicket() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imagenSeleccionada == null) {
      setState(() => _mensaje = '⚠️ Haz una foto del ticket');
      return;
    }

    setState(() {
      _isLoading = true;
      _mensaje = '';
    });

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final usuarioId = await auth.obtenerToken();
      if (usuarioId == null) {
        setState(() => _mensaje = '❌ Usuario no autenticado');
        return;
      }

      final ticketService = TicketService();
      await ticketService.subirTicket(
        usuarioId: int.parse(usuarioId),
        fecha: _fechaSeleccionada,
        importe: double.parse(_importeController.text.trim()),
        proveedor: _proveedorController.text.trim(),
        categoria: _categoriaController.text.trim().isEmpty ? null : _categoriaController.text.trim(),
        imagen: _imagenSeleccionada,
      );

      setState(() {
        _mensaje = '✅ Ticket guardado correctamente';
        _isLoading = false;
        _imagenSeleccionada = null;
        _importeController.clear();
        _proveedorController.clear();
        _categoriaController.clear();
      });
    } catch (e) {
      setState(() => _mensaje = '❌ Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subir ticket'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (_imagenSeleccionada != null) ...[
                  Image.file(
                    File(_imagenSeleccionada!.path), // Ahora File está importado
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(height: 10),
                ],
                ElevatedButton.icon(
                  onPressed: _tomarFoto,
                  icon: const Icon(Icons.camera_alt),
                  label: Text(_imagenSeleccionada == null ? 'Hacer foto' : 'Cambiar foto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 45),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _proveedorController,
                  decoration: const InputDecoration(
                    labelText: 'Proveedor *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _importeController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Importe (€) *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v!.isEmpty) return 'Requerido';
                    if (double.tryParse(v) == null) return 'Importe inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _categoriaController,
                  decoration: const InputDecoration(
                    labelText: 'Categoría (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _seleccionarFecha,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha',
                      border: OutlineInputBorder(),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_fechaSeleccionada.day}/${_fechaSeleccionada.month}/${_fechaSeleccionada.year}',
                        ),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _subirTicket,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.green,
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
                      : const Text('Guardar ticket'),
                ),
                const SizedBox(height: 10),
                if (_mensaje.isNotEmpty)
                  Text(
                    _mensaje,
                    style: TextStyle(
                      color: _mensaje.contains('✅') ? Colors.green : Colors.red,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}