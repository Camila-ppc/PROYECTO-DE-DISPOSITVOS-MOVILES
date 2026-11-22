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
    Widget error(BuildContext c, Object e, StackTrace? s) => SizedBox(
          width: width,
          height: height,
          child: const Center(child: Icon(Icons.image_not_supported_outlined)),
        );
    return kIsWeb
        ? Image.network(path,
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: error)
        : Image.file(File(path),
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: error);
  }
}
