import 'package:flutter/material.dart';

/// Categorías de objetos. La IA elige una de estas al describir la foto.
const List<String> categorias = [
  'Electrónicos',
  'Documentos',
  'Ropa',
  'Mochilas y bolsos',
  'Llaves',
  'Útiles',
  'Otros',
];

/// Devuelve una categoría de la lista (o 'Otros' si no coincide ninguna).
String categoriaValida(String? c) {
  final t = (c ?? '').trim().toLowerCase();
  for (final x in categorias) {
    if (x.toLowerCase() == t) return x;
  }
  return 'Otros';
}

IconData iconoCategoria(String c) {
  switch (c) {
    case 'Electrónicos':
      return Icons.devices_other_outlined;
    case 'Documentos':
      return Icons.badge_outlined;
    case 'Ropa':
      return Icons.checkroom_outlined;
    case 'Mochilas y bolsos':
      return Icons.backpack_outlined;
    case 'Llaves':
      return Icons.vpn_key_outlined;
    case 'Útiles':
      return Icons.edit_outlined;
    default:
      return Icons.inventory_2_outlined;
  }
}
