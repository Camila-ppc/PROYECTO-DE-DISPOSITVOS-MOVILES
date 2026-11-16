import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() => runApp(const PerdidosApp());

class PerdidosApp extends StatelessWidget {
  const PerdidosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UCB Perdidos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
