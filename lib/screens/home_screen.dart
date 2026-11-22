import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import '../models/alerta.dart';
import '../models/categorias.dart';
import '../models/item.dart';
import '../services/busqueda_service.dart';
import '../services/match_service.dart';
import '../services/storage_service.dart';
import '../widgets/foto.dart';
import 'alertas_screen.dart';
import 'detalle_screen.dart';
import 'publish_screen.dart';
import 'puntos_screen.dart';
import 'reconocer_texto_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Item> _items = [];
  final List<Alerta> _alertas = [];
  final TextEditingController _busquedaController = TextEditingController();
  String _consulta = '';
  String? _categoria; // null = todas
  bool _buscando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    final datos = await StorageService.cargar();
    if (!mounted) return;
    setState(() {
      _items
        ..clear()
        ..addAll(datos.items);
      _alertas
        ..clear()
        ..addAll(datos.alertas);
    });
  }

  Future<void> _guardar() => StorageService.guardar(_items, _alertas);

  Item? _buscarItem(String id) => _items.where((i) => i.id == id).firstOrNull;

  Future<void> _publicar() async {
    final nuevo = await Navigator.push<Item>(
      context,
      MaterialPageRoute(builder: (_) => const PublishScreen()),
    );
    if (nuevo == null || !mounted) return;
    setState(() => _items.insert(0, nuevo));
    await _guardar();
    await _buscarCoincidencias(nuevo);
  }

  /// La IA compara el objeto nuevo con los del tipo contrario.
  Future<void> _buscarCoincidencias(Item nuevo) async {
    setState(() => _buscando = true);
    List<Coincidencia> lista;
    try {
      lista = await MatchService.buscar(nuevo, _items);
    } catch (_) {
      lista = [];
    }
    if (!mounted) return;

    final mejor = lista.isEmpty ? null : _buscarItem(lista.first.itemId);
    setState(() {
      _buscando = false;
      nuevo.coincidencias = lista;
      // La coincidencia también se guarda del otro lado.
      for (final c in lista) {
        final otro = _buscarItem(c.itemId);
        if (otro == null) continue;
        otro.coincidencias = [
          ...otro.coincidencias.where((x) => x.itemId != nuevo.id),
          Coincidencia(itemId: nuevo.id, puntaje: c.puntaje, motivo: c.motivo),
        ];
      }
      if (mejor != null && lista.first.puntaje >= MatchService.umbralAlerta) {
        _alertas.insert(
          0,
          Alerta(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            mensaje: '"${nuevo.titulo}" podría ser "${mejor.titulo}"',
            itemId: nuevo.id,
            puntaje: lista.first.puntaje,
          ),
        );
      }
    });
    await _guardar();
    if (mejor != null) await _mostrarCoincidencia(mejor, lista.first);
  }

  Future<void> _mostrarCoincidencia(Item otro, Coincidencia c) async {
    if (!mounted) return;
    final ver = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.auto_awesome),
        title: const Text('¡Posible coincidencia!'),
        content: Text(
          '"${otro.titulo}" · ${c.puntaje}% de coincidencia'
          '${c.motivo.isEmpty ? '' : '\n${c.motivo}'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cerrar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ver'),
          ),
        ],
      ),
    );
    if (ver == true) await _abrirDetalle(otro);
  }

  Future<void> _abrirDetalle(Item it) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetalleScreen(item: it, todos: _items)),
    );
    if (!mounted) return;
    setState(() {}); // por si lo reclamaron
    await _guardar();
  }

  Future<void> _abrirAlertas() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AlertasScreen(alertas: _alertas, items: _items),
      ),
    );
    if (!mounted) return;
    setState(() {
      for (final a in _alertas) {
        a.leida = true;
      }
    });
    await _guardar();
  }

  Widget _tarjeta(Item it) {
    final esquema = Theme.of(context).colorScheme;
    final texto = Theme.of(context).textTheme;
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: esquema.outlineVariant),
      ),
      child: InkWell(
        onTap: () => _abrirDetalle(it),
        child: Row(
          children: [
            SizedBox(
              width: 104,
              height: 112,
              child: it.fotoPath != null
                  ? Foto(path: it.fotoPath!, width: 104, height: 112)
                  : ColoredBox(
                      color: esquema.primaryContainer,
                      child: Icon(
                        iconoCategoria(it.categoria),
                        size: 40,
                        color: esquema.onPrimaryContainer,
                      ),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            it.titulo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: texto.titleMedium,
                          ),
                        ),
                        if (it.reclamado)
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 20),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(iconoCategoria(it.categoria),
                            size: 14, color: esquema.primary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            it.lugar.isEmpty
                                ? it.categoria
                                : '${it.categoria} · ${it.lugar}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: texto.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      it.descripcion,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: texto.bodyMedium,
                    ),
                    if (it.coincidencias.isNotEmpty && !it.reclamado) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: esquema.tertiaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome,
                                size: 14, color: esquema.onTertiaryContainer),
                            const SizedBox(width: 4),
                            Text(
                              '${it.coincidencias.length} posible'
                              '${it.coincidencias.length == 1 ? '' : 's'} '
                              'coincidencia${it.coincidencias.length == 1 ? '' : 's'}',
                              style: texto.labelSmall?.copyWith(
                                  color: esquema.onTertiaryContainer),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vacio(bool encontrados) {
    final esquema = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: esquema.outline),
            const SizedBox(height: 12),
            Text(
              encontrados
                  ? 'Nada por aquí todavía 👀\nPublica lo que encuentres.'
                  : 'Nada por aquí todavía 👀\nPublica lo que perdiste.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _lista(bool encontrados) {
    final data = BusquedaService.buscar(
      _items.where((i) => i.encontrado == encontrados).toList(),
      _consulta,
      categoria: _categoria,
    );
    if (data.isEmpty) return _vacio(encontrados);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
      itemCount: data.length,
      itemBuilder: (_, i) => _tarjeta(data[i]),
    );
  }

  Widget _filtros() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('Todas'),
              selected: _categoria == null,
              onSelected: (_) => setState(() => _categoria = null),
            ),
          ),
          for (final c in categorias)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                avatar: Icon(iconoCategoria(c), size: 16),
                label: Text(c),
                selected: _categoria == c,
                onSelected: (_) =>
                    setState(() => _categoria = _categoria == c ? null : c),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sinLeer = _alertas.where((a) => !a.leida).length;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('UCB Perdidos'),
          actions: [
            if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
              IconButton(
                tooltip: 'Reconocer texto',
                icon: const Icon(Icons.text_fields),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReconocerTextoScreen()),
                ),
              ),
            IconButton(
              tooltip: 'Avisos',
              icon: Badge(
                isLabelVisible: sinLeer > 0,
                label: Text('$sinLeer'),
                child: const Icon(Icons.notifications_outlined),
              ),
              onPressed: _abrirAlertas,
            ),
            IconButton(
              tooltip: 'Puntos de entrega (QR)',
              icon: const Icon(Icons.qr_code_2),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PuntosScreen()),
              ),
            ),
          ],
          bottom: const TabBar(tabs: [
            Tab(text: 'Perdidos'),
            Tab(text: 'Encontrados'),
          ]),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: TextField(
                controller: _busquedaController,
                onChanged: (texto) => setState(() => _consulta = texto),
                decoration: InputDecoration(
                  hintText: 'Buscar por objeto, descripción o lugar',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _consulta.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpiar búsqueda',
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _busquedaController.clear();
                            setState(() => _consulta = '');
                          },
                        ),
                ),
              ),
            ),
            _filtros(),
            if (_buscando)
              const Padding(
                padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: LinearProgressIndicator(
                    semanticsLabel: 'Buscando coincidencias con IA'),
              ),
            Expanded(
              child: TabBarView(children: [_lista(false), _lista(true)]),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _publicar,
          icon: const Icon(Icons.add),
          label: const Text('Publicar'),
        ),
      ),
    );
  }
}
