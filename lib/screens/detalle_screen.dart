import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/item.dart';
import '../models/puntos.dart';
import '../widgets/foto.dart';

class DetalleScreen extends StatefulWidget {
  final Item item;
  const DetalleScreen({super.key, required this.item});

  @override
  State<DetalleScreen> createState() => _DetalleScreenState();
}

class _DetalleScreenState extends State<DetalleScreen> {
  Item get it => widget.item;

  Future<void> _reclamar() async {
    final ctrl = TextEditingController();
    final tienePregunta = it.pregunta != null && it.pregunta!.isNotEmpty;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Verificar que es tuyo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tienePregunta
                ? it.pregunta!
                : 'Este objeto no tiene pregunta de verificación.'),
            if (tienePregunta) ...[
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                decoration: const InputDecoration(
                    labelText: 'Tu respuesta', border: OutlineInputBorder()),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final correcta = !tienePregunta ||
                  ctrl.text.trim().toLowerCase() ==
                      (it.respuesta ?? '').trim().toLowerCase();
              Navigator.pop(context, correcta);
            },
            child: const Text('Verificar'),
          ),
        ],
      ),
    );

    if (ok == null) return;
    if (!mounted) return;
    if (ok) {
      setState(() => it.reclamado = true);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Verificado, objeto reclamado')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Respuesta incorrecta')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = it.fecha;
    return Scaffold(
      appBar: AppBar(title: Text(it.titulo)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (it.fotoPath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Foto(path: it.fotoPath!, height: 220),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              Chip(label: Text(it.encontrado ? 'Encontrado' : 'Perdido')),
              if (it.reclamado) const Chip(label: Text('Reclamado ✅')),
            ],
          ),
          const SizedBox(height: 8),
          Text(it.descripcion),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.place_outlined),
            title: Text(it.lugar.isEmpty ? 'Sin lugar' : it.lugar),
            subtitle: Text('${f.day}/${f.month}/${f.year}'),
          ),
          const SizedBox(height: 12),
          if (it.encontrado && !it.reclamado)
            FilledButton.icon(
              onPressed: _reclamar,
              icon: const Icon(Icons.verified_user),
              label: const Text('Es mío, reclamar'),
            ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                const Text('QR del objeto'),
                const SizedBox(height: 8),
                QrImageView(
                  data: '$qrPrefijoObjeto${it.id}',
                  size: 160,
                  backgroundColor: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
