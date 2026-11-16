import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/puntos.dart';

/// Muestra el QR de cada punto de entrega (para imprimir / mostrar).
class PuntosScreen extends StatelessWidget {
  const PuntosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Puntos de entrega (QR)')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: puntosEntrega.length,
        itemBuilder: (_, i) {
          final punto = puntosEntrega[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(punto,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  QrImageView(
                    data: '$qrPrefijoPunto$punto',
                    size: 180,
                    backgroundColor: Colors.white,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
