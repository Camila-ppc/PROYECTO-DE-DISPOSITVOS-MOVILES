import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Muestra una foto tanto en web (URL blob) como en móvil (archivo).
class Foto extends StatelessWidget {
  final String path;
  final double? width;
  final double? height;

  const Foto({super.key, required this.path, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return kIsWeb
        ? Image.network(path, width: width, height: height, fit: BoxFit.cover)
        : Image.file(File(path), width: width, height: height, fit: BoxFit.cover);
  }
}
