import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class ReconocerTextoScreen extends StatefulWidget {
  const ReconocerTextoScreen({super.key});

  @override
  State<ReconocerTextoScreen> createState() => _ReconocerTextoScreenState();
}

class _ReconocerTextoScreenState extends State<ReconocerTextoScreen> {
  // Este canal conecta la pantalla con ML Kit en MainActivity.kt.
  static const _canalOcr = MethodChannel('ucb_perdidos/ocr');
  final _selector = ImagePicker();
  XFile? _foto;
  bool _ocupado = false;
  String _texto = '';
  String _mensaje = '';

  void _mostrarAviso(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _seleccionarFoto(ImageSource origen) async {
    if (_ocupado) return;
    setState(() => _ocupado = true);
    try {
      final foto = await _selector.pickImage(
        source: origen,
        maxWidth: 2560,
        maxHeight: 2560,
      );
      // Si el usuario cancela, puede seguir trabajando con la foto anterior.
      if (!mounted || foto == null) return;
      setState(() {
        _foto = foto;
        _texto = '';
        _mensaje = '';
      });
    } on PlatformException catch (error) {
      final mensaje = error.code == 'camera_access_denied'
          ? 'Permite el acceso a la cámara o elige una foto de la galería.'
          : 'No se pudo abrir la foto. Intenta de nuevo.';
      _mostrarAviso(mensaje);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _reconocerTexto() async {
    final foto = _foto;
    if (foto == null || _ocupado) return;
    setState(() {
      _ocupado = true;
      _texto = '';
      _mensaje = '';
    });
    try {
      // Android recibe la ruta local y devuelve las líneas que encontró.
      final resultado = await _canalOcr.invokeMethod<String>(
        'reconocerTexto',
        foto.path,
      );
      if (!mounted) return;
      setState(() {
        _texto = resultado?.trim() ?? '';
        if (_texto.isEmpty) {
          _mensaje = 'No se detectó texto. Prueba con una foto más nítida.';
        }
      });
    } on PlatformException {
      if (mounted) {
        setState(
          () => _mensaje = 'No se pudo leer la imagen. Intenta con otra foto.',
        );
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _copiarTexto() async {
    try {
      await Clipboard.setData(ClipboardData(text: _texto));
      _mostrarAviso('Texto copiado.');
    } on PlatformException {
      _mostrarAviso('No se pudo copiar el texto.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final foto = _foto;
    return Scaffold(
      appBar: AppBar(title: const Text('Reconocer texto')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Tomar fotografía'),
            onPressed:
                _ocupado ? null : () => _seleccionarFoto(ImageSource.camera),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Seleccionar de la galería'),
            onPressed:
                _ocupado ? null : () => _seleccionarFoto(ImageSource.gallery),
          ),
          if (foto != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Image.file(
                File(foto.path),
                height: 220,
                fit: BoxFit.contain,
                cacheWidth: 800,
                semanticLabel: 'Vista previa de la fotografía',
                errorBuilder: (_, __, ___) =>
                    const Text('Vista previa no disponible.'),
              ),
            ),
          FilledButton.icon(
            icon: const Icon(Icons.text_fields),
            label: const Text('Reconocer texto'),
            onPressed: foto == null || _ocupado ? null : _reconocerTexto,
          ),
          if (_ocupado)
            const LinearProgressIndicator(semanticsLabel: 'Procesando'),
          const SizedBox(height: 16),
          if (_mensaje.isNotEmpty) Text(_mensaje),
          if (_texto.isNotEmpty) ...[
            Text(
              'Texto reconocido',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SelectableText(_texto),
            TextButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('Copiar texto'),
              onPressed: _ocupado ? null : _copiarTexto,
            ),
          ],
        ],
      ),
    );
  }
}
