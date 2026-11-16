import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/item.dart';
import '../models/puntos.dart';
import '../services/ia_service.dart';
import '../widgets/foto.dart';
import 'scan_screen.dart';

class PublishScreen extends StatefulWidget {
  const PublishScreen({super.key});

  @override
  State<PublishScreen> createState() => _PublishScreenState();
}

class _PublishScreenState extends State<PublishScreen> {
  final _titulo = TextEditingController();
  final _desc = TextEditingController();
  final _lugar = TextEditingController();
  final _pregunta = TextEditingController();
  final _respuesta = TextEditingController();
  bool _encontrado = false;
  XFile? _foto;
  bool _cargandoIa = false;

  Future<void> _tomarFoto(ImageSource fuente) async {
    final f = await ImagePicker().pickImage(source: fuente, imageQuality: 70);
    if (f != null) setState(() => _foto = f);
  }

  Future<void> _autocompletar() async {
    if (_foto == null) return;
    setState(() => _cargandoIa = true);
    final r = await IaService.describirFoto(File(_foto!.path));
    setState(() {
      _titulo.text = r['titulo'] ?? '';
      _desc.text = r['descripcion'] ?? '';
      _cargandoIa = false;
    });
  }

  Future<void> _escanearPunto() async {
    final codigo = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
    if (codigo == null || !mounted) return;
    if (codigo.startsWith(qrPrefijoPunto)) {
      setState(() => _lugar.text = codigo.substring(qrPrefijoPunto.length));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ese QR no es de un punto de entrega')));
    }
  }

  void _guardar() {
    if (_titulo.text.trim().isEmpty) return;
    Navigator.pop(
      context,
      Item(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        titulo: _titulo.text.trim(),
        descripcion: _desc.text.trim(),
        lugar: _lugar.text.trim(),
        encontrado: _encontrado,
        fotoPath: _foto?.path,
        pregunta: _encontrado ? _pregunta.text.trim() : null,
        respuesta: _encontrado ? _respuesta.text.trim() : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva publicación')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Lo perdí')),
              ButtonSegment(value: true, label: Text('Lo encontré')),
            ],
            selected: {_encontrado},
            onSelectionChanged: (s) => setState(() => _encontrado = s.first),
          ),
          const SizedBox(height: 16),
          if (_foto != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Foto(path: _foto!.path, height: 200),
            ),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _tomarFoto(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Cámara'),
              ),
              TextButton.icon(
                onPressed: () => _tomarFoto(ImageSource.gallery),
                icon: const Icon(Icons.photo),
                label: const Text('Galería'),
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: (_foto == null || _cargandoIa) ? null : _autocompletar,
                icon: _cargandoIa
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_awesome),
                label: const Text('IA'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titulo,
            decoration: const InputDecoration(
                labelText: 'Qué es', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _desc,
            maxLines: 3,
            decoration: const InputDecoration(
                labelText: 'Descripción', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _lugar,
            decoration: InputDecoration(
              labelText: 'Dónde (bloque, aula...)',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: 'Escanear QR del punto',
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: _escanearPunto,
              ),
            ),
          ),
          if (_encontrado) ...[
            const SizedBox(height: 16),
            const Text('Verificación del dueño (opcional)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _pregunta,
              decoration: const InputDecoration(
                  labelText: 'Pregunta que solo el dueño sabría',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _respuesta,
              decoration: const InputDecoration(
                  labelText: 'Respuesta correcta',
                  border: OutlineInputBorder()),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(onPressed: _guardar, child: const Text('Publicar')),
        ],
      ),
    );
  }
}
