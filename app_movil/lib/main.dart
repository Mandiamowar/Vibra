import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final _storage = FlutterSecureStorage();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => ApiService()),
        Provider<AuthService>(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'Vibra Pay',
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          fontFamily: 'Roboto',
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: FutureBuilder(
          future: _storage.read(key: 'token'),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            final token = snapshot.data;
            if (token != null) {
              return const HomeScreen();
            } else {
              return const LoginScreen();
            }
          },
        ),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}