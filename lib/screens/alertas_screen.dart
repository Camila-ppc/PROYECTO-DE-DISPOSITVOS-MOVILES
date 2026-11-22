import 'package:flutter/material.dart';
import '../models/alerta.dart';
import '../models/item.dart';
import 'detalle_screen.dart';

/// Avisos de posibles coincidencias encontradas por la IA.
class AlertasScreen extends StatelessWidget {
  final List<Alerta> alertas;
  final List<Item> items;

  const AlertasScreen({super.key, required this.alertas, required this.items});

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Avisos')),
      body: alertas.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Cuando la IA encuentre una posible coincidencia, te avisamos aquí.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: alertas.length,
              itemBuilder: (_, i) {
                final a = alertas[i];
                final item = items.where((x) => x.id == a.itemId).firstOrNull;
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: esquema.outlineVariant),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: esquema.tertiaryContainer,
                      child: Text('${a.puntaje}%'),
                    ),
                    title: Text(a.mensaje),
                    subtitle: Text(
                        '${a.fecha.day}/${a.fecha.month}/${a.fecha.year}'),
                    trailing: item == null
                        ? null
                        : const Icon(Icons.chevron_right),
                    onTap: item == null
                        ? null
                        : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DetalleScreen(item: item, todos: items),
                              ),
                            ),
                  ),
                );
              },
            ),
    );
  }
}
