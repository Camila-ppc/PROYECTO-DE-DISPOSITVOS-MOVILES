const Map<String, String> _acentos = {
  'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a',
  'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
  'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
  'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o',
  'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
  'ñ': 'n',
};

const Set<String> _vacias = {
  'para', 'con', 'sin', 'que', 'una', 'uno', 'unos', 'unas', 'del', 'los',
  'las', 'por', 'esta', 'este', 'ese', 'esa', 'muy', 'sus', 'mas', 'pero',
  'como', 'tiene', 'color', 'objeto',
};

/// Minúsculas, sin tildes ni signos, con espacios simples.
String normalizar(String texto) {
  final b = StringBuffer();
  for (final r in texto.toLowerCase().runes) {
    final c = String.fromCharCode(r);
    b.write(_acentos[c] ?? c);
  }
  return b.toString().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
}

/// Palabras significativas (3+ letras, sin palabras vacías).
Set<String> palabras(String texto) => normalizar(texto)
    .split(' ')
    .where((p) => p.length >= 3 && !_vacias.contains(p))
    .toSet();
