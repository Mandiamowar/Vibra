import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart'; // Para XFile
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
  bool _isSelecting = false;
  Set<int> _selectedIds = {};

  int? _mesFiltro;
  int? _yearFiltro;

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

  Future<void> _abrirFactura(int facturaId, String numeroFactura) async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      String url = await api.descargarFactura(facturaId);
      url = url.split('?').first;
      final uri = Uri.parse(url);
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        // OK
      } else {
        _mostrarDialogoError(url);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al abrir la factura: $e')),
      );
    }
  }

  void _mostrarDialogoError(String url) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('No se puede abrir el PDF'),
        content: Text('Intenta copiar esta URL en tu navegador:\n\n$url'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('URL copiada al portapapeles')),
              );
              Navigator.pop(context);
            },
            child: const Text('Copiar URL'),
          ),
        ],
      ),
    );
  }

  // 🔥 Descargar en ZIP (corregido)
  Future<void> _descargarSeleccionadas() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos una factura')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        title: Text('Descargando...'),
        content: SizedBox(
          height: 50,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );

    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final archive = Archive();

      for (var id in _selectedIds) {
        final factura = _facturas.firstWhere((f) => f.id == id);
        final url = await api.descargarFactura(factura.id);
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final fileName = 'factura_${factura.numeroFactura.replaceAll('/', '-')}.pdf';
          final fileContent = response.bodyBytes;
          // 🔥 CORREGIDO: pasar nombre, contenido (List<int>) y tamaño (int)
          archive.addFile(ArchiveFile(fileName, fileContent.length, fileContent));
        }
      }

      final zipBytes = ZipEncoder().encode(archive);
      if (zipBytes == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al comprimir las facturas')),
        );
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final zipFile = File('${tempDir.path}/facturas_seleccionadas.zip');
      await zipFile.writeAsBytes(zipBytes);

      Navigator.pop(context);

      // Compartir el ZIP
      await Share.shareXFiles(
        [XFile(zipFile.path)],
        text: 'Facturas seleccionadas de Vibra Pay',
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al descargar: $e')),
      );
    }
  }

  // 🔥 Reenviar por email (simulado)
  Future<void> _enviarSeleccionadas() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos una factura')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        title: Text('Enviando...'),
        content: SizedBox(
          height: 50,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );

    try {
      // Simulación: solo contamos
      int enviadas = _selectedIds.length;
      await Future.delayed(const Duration(seconds: 2));
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ $enviadas facturas reenviadas (simulado)')),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar: $e')),
      );
    }
  }

  // 🔥 Filtro por mes (igual que tickets)
  Future<void> _mostrarDialogoFiltro() async {
    int? mesSeleccionado = _mesFiltro;
    int? yearSeleccionado = _yearFiltro;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filtrar por mes'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Mes'),
                value: mesSeleccionado,
                items: List.generate(12, (index) => index + 1).map((mes) {
                  return DropdownMenuItem(
                    value: mes,
                    child: Text(_nombreMes(mes)),
                  );
                }).toList(),
                onChanged: (value) => mesSeleccionado = value,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Año'),
                value: yearSeleccionado,
                items: List.generate(5, (index) => DateTime.now().year - index).map((year) {
                  return DropdownMenuItem(
                    value: year,
                    child: Text(year.toString()),
                  );
                }).toList(),
                onChanged: (value) => yearSeleccionado = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _mesFiltro = mesSeleccionado;
                  _yearFiltro = yearSeleccionado;
                });
                Navigator.pop(context);
                _cargarFacturas();
              },
              child: const Text('Aplicar'),
            ),
            if (_mesFiltro != null || _yearFiltro != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    _mesFiltro = null;
                    _yearFiltro = null;
                  });
                  Navigator.pop(context);
                  _cargarFacturas();
                },
                child: const Text('Limpiar filtro'),
              ),
          ],
        );
      },
    );
  }

  String _nombreMes(int mes) {
    const meses = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    return meses[mes - 1];
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
            icon: const Icon(Icons.filter_list),
            onPressed: _mostrarDialogoFiltro,
            tooltip: 'Filtrar por mes',
          ),
          if (_mesFiltro != null || _yearFiltro != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _mesFiltro = null;
                  _yearFiltro = null;
                });
                _cargarFacturas();
              },
              tooltip: 'Limpiar filtro',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarFacturas,
          ),
          IconButton(
            icon: Icon(_isSelecting ? Icons.close : Icons.select_all),
            onPressed: () {
              setState(() {
                _isSelecting = !_isSelecting;
                if (!_isSelecting) _selectedIds.clear();
              });
            },
            tooltip: _isSelecting ? 'Cancelar selección' : 'Seleccionar',
          ),
          if (_isSelecting)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _descargarSeleccionadas,
              tooltip: 'Descargar seleccionadas (ZIP)',
            ),
          if (_isSelecting)
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _enviarSeleccionadas,
              tooltip: 'Reenviar por email',
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
              onTap: _isSelecting
                  ? () {
                      setState(() {
                        if (_selectedIds.contains(factura.id)) {
                          _selectedIds.remove(factura.id);
                        } else {
                          _selectedIds.add(factura.id);
                        }
                      });
                    }
                  : () => _abrirFactura(factura.id, factura.numeroFactura),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (_isSelecting)
                      Checkbox(
                        value: _selectedIds.contains(factura.id),
                        onChanged: (_) {
                          setState(() {
                            if (_selectedIds.contains(factura.id)) {
                              _selectedIds.remove(factura.id);
                            } else {
                              _selectedIds.add(factura.id);
                            }
                          });
                        },
                      ),
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