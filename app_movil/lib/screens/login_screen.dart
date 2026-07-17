import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLoginMode = true; // true = login, false = registro

  void _submit() async {
    final nombre = _nombreController.text.trim();
    final password = _passwordController.text.trim();

    if (nombre.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final api = Provider.of<ApiService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);

    try {
      Map<String, dynamic> response;

      if (_isLoginMode) {
        // 🔐 INICIAR SESIÓN
        response = await api.login(nombre, password);
        if (response['id'] != null) {
          await auth.guardarToken(response['token']);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Credenciales incorrectas')),
          );
        }
      } else {
        // 📝 REGISTRAR NUEVO USUARIO
        response = await api.registrarUsuario(nombre, password);
        if (response['id'] != null) {
          // Una vez registrado, guardamos el token y redirigimos
          await auth.guardarToken(response['id'].toString());
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al registrar')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.payments, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 20),
            const Text('Vibra Pay', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Usuario',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
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
                  : Text(_isLoginMode ? 'Iniciar sesión' : 'Registrarse'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                setState(() {
                  _isLoginMode = !_isLoginMode;
                });
              },
              child: Text(
                _isLoginMode
                    ? '¿No tienes cuenta? Regístrate'
                    : '¿Ya tienes cuenta? Inicia sesión',
                style: const TextStyle(color: Colors.deepPurple),
              ),
            ),
          ],
        ),
      ),
    );
  }
}