import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() => runApp(const PerdidosApp());

const Color _azul = Color(0xFF1B4F9C);

ThemeData _tema(Brightness brillo) {
  final esquema = ColorScheme.fromSeed(seedColor: _azul, brightness: brillo);
  return ThemeData(
    colorScheme: esquema,
    useMaterial3: true,
    appBarTheme: const AppBarTheme(centerTitle: false),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

class PerdidosApp extends StatelessWidget {
  const PerdidosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UCB Perdidos',
      debugShowCheckedModeBanner: false,
      theme: _tema(Brightness.light),
      darkTheme: _tema(Brightness.dark),
      themeMode: ThemeMode.system, // sigue el modo claro/oscuro del teléfono
      home: const HomeScreen(),
    );
  }
}
