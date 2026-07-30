import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ticket_service.dart';
import '../services/auth_service.dart';
import '../models/ticket.dart';
import 'subir_ticket_screen.dart';

class MisTicketsScreen extends StatefulWidget {
  const MisTicketsScreen({super.key});

  @override
  _MisTicketsScreenState createState() => _MisTicketsScreenState();
}

class _MisTicketsScreenState extends State<MisTicketsScreen> {
  List<Ticket> _tickets = [];
  bool _isLoading = true;
  String _error = '';
  int? _mesFiltro;
  int? _yearFiltro;

  @override
  void initState() {
    super.initState();
    _cargarTickets();
  }

  Future<void> _cargarTickets() async {
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

      final service = TicketService();
      final tickets = await service.obtenerTickets(
        usuarioId: int.parse(usuarioId),
        mes: _mesFiltro,
        year: _yearFiltro,
      );
      setState(() {
        _tickets = tickets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar tickets: $e';
        _isLoading = false;
      });
    }
  }

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
                _cargarTickets();
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
                  _cargarTickets();
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

  // 🔥 Función para mostrar la foto ampliada
  void _mostrarFoto(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 100),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis tickets'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubirTicketScreen()),
              ).then((_) => _cargarTickets());
            },
            tooltip: 'Subir ticket',
          ),
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
                _cargarTickets();
              },
              tooltip: 'Limpiar filtro',
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
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _cargarTickets,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_tickets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text('No hay tickets guardados'),
              const SizedBox(height: 8),
              Text(
                _mesFiltro != null || _yearFiltro != null
                    ? 'No hay tickets para el filtro seleccionado'
                    : 'Sube tu primer ticket usando el botón +',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (_mesFiltro != null || _yearFiltro != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filtro: ${_mesFiltro != null ? _nombreMes(_mesFiltro!) : ''} ${_yearFiltro ?? ''}'.trim(),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${_tickets.length} tickets',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _tickets.length,
            itemBuilder: (context, index) {
              final ticket = _tickets[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: ticket.fotoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            ticket.fotoUrl!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image, color: Colors.grey),
                              );
                            },
                          ),
                        )
                      : Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey[300],
                          child: const Icon(Icons.receipt, color: Colors.grey),
                        ),
                  title: Text(ticket.proveedor),
                  subtitle: Text(
                    '${ticket.importe.toStringAsFixed(2)} €  •  ${ticket.fecha.day}/${ticket.fecha.month}/${ticket.fecha.year}',
                  ),
                  // 🔥 AÑADIR onTap PARA VER FOTO
                  onTap: () {
                    if (ticket.fotoUrl != null) {
                      _mostrarFoto(ticket.fotoUrl!);
                    }
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Eliminar ticket'),
                          content: const Text('¿Seguro que quieres eliminar este ticket?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Eliminar'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        try {
                          final service = TicketService();
                          await service.eliminarTicket(ticket.id!);
                          _cargarTickets();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error al eliminar: $e')),
                          );
                        }
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}