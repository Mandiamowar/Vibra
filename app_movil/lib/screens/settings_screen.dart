import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Ajustes de Vibra Pay'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              await auth.eliminarToken();
              Navigator.pushReplacementNamed(context, '/');
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}