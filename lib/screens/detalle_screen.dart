import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/categorias.dart';
import '../models/item.dart';
import '../models/puntos.dart';
import '../services/verificacion_service.dart';
import '../widgets/foto.dart';

class DetalleScreen extends StatefulWidget {
  final Item item;

  /// Todas las publicaciones, para mostrar las coincidencias.
  final List<Item> todos;

  const DetalleScreen({super.key, required this.item, this.todos = const []});

  @override
  State<DetalleScreen> createState() => _DetalleScreenState();
}

class _DetalleScreenState extends State<DetalleScreen> {
  bool _verificando = false;

  Item get it => widget.item;

  Future<void> _reclamar() async {
    final ctrl = TextEditingController();
    final tienePregunta = it.pregunta != null && it.pregunta!.isNotEmpty;

    final respuesta = await showDialog<String>(
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
                decoration: const InputDecoration(labelText: 'Tu respuesta'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: const Text('Verificar'),
          ),
        ],
      ),
    );
    ctrl.dispose();

    if (respuesta == null || !mounted) return;
    setState(() => _verificando = true);
    final ok = !tienePregunta ||
        await VerificacionService.respuestaCorrecta(
          pregunta: it.pregunta!,
          esperada: it.respuesta ?? '',
          dada: respuesta,
        );
    if (!mounted) return;
    setState(() {
      _verificando = false;
      if (ok) it.reclamado = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? '✅ Verificado, objeto reclamado'
            : '❌ Respuesta incorrecta')));
  }

  Widget _coincidencias() {
    final esquema = Theme.of(context).colorScheme;
    final filas = <Widget>[];
    for (final c in it.coincidencias) {
      final otro = widget.todos.where((x) => x.id == c.itemId).firstOrNull;
      if (otro == null) continue;
      filas.add(Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: esquema.outlineVariant),
        ),
        child: ListTile(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetalleScreen(item: otro, todos: widget.todos),
            ),
          ),
          leading: CircleAvatar(
            backgroundColor: esquema.tertiaryContainer,
            child: Text('${c.puntaje}%',
                style: TextStyle(
                    fontSize: 12, color: esquema.onTertiaryContainer)),
          ),
          title: Text(otro.titulo),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (c.motivo.isNotEmpty) Text(c.motivo),
              const SizedBox(height: 4),
              LinearProgressIndicator(value: c.puntaje / 100),
            ],
          ),
          trailing: const Icon(Icons.chevron_right),
        ),
      ));
    }
    if (filas.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.auto_awesome, size: 18, color: esquema.primary),
            const SizedBox(width: 6),
            Text('Posibles coincidencias',
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 8),
        ...filas,
      ],
    );
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
              borderRadius: BorderRadius.circular(16),
              child: Foto(path: it.fotoPath!, height: 220),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              Chip(label: Text(it.encontrado ? 'Encontrado' : 'Perdido')),
              Chip(
                avatar: Icon(iconoCategoria(it.categoria), size: 16),
                label: Text(it.categoria),
              ),
              if (it.reclamado) const Chip(label: Text('Reclamado ✅')),
            ],
          ),
          const SizedBox(height: 8),
          Text(it.descripcion),
          if (it.textoOcr.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Texto en la foto: ${it.textoOcr}',
                style: Theme.of(context).textTheme.bodySmall),
          ],
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
              onPressed: _verificando ? null : _reclamar,
              icon: _verificando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.verified_user),
              label: Text(_verificando ? 'Verificando…' : 'Es mío, reclamar'),
            ),
          _coincidencias(),
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
