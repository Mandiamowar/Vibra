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
  int? _anioFiltro;

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
        year: _anioFiltro,
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
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Aquí se puede añadir un diálogo para filtrar por mes/año
            },
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
                'Sube tu primer ticket usando el botón +',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tickets.length,
      itemBuilder: (context, index) {
        final ticket = _tickets[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: ticket.fotoUrl != null
                ? Image.network(
                    ticket.fotoUrl!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  )
                : const Icon(Icons.receipt, size: 40),
            title: Text(ticket.proveedor),
            subtitle: Text(
              '${ticket.importe.toStringAsFixed(2)} €  •  ${ticket.fecha.day}/${ticket.fecha.month}/${ticket.fecha.year}',
            ),
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
    );
  }
}