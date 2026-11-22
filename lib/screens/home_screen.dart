import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import '../models/item.dart';
import '../widgets/foto.dart';
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

  Future<void> _publicar() async {
    final nuevo = await Navigator.push<Item>(
      context,
      MaterialPageRoute(builder: (_) => const PublishScreen()),
    );
    if (nuevo != null) setState(() => _items.insert(0, nuevo));
  }

  Future<void> _abrirDetalle(Item it) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetalleScreen(item: it)),
    );
    setState(() {}); // por si lo reclamaron
  }

  Widget _lista(bool encontrados) {
    final data = _items.where((i) => i.encontrado == encontrados).toList();
    if (data.isEmpty) {
      return const Center(child: Text('Nada por aquí todavía 👀'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: data.length,
      itemBuilder: (_, i) {
        final it = data[i];
        return Card(
          child: ListTile(
            onTap: () => _abrirDetalle(it),
            leading: it.fotoPath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Foto(path: it.fotoPath!, width: 56, height: 56),
                  )
                : const Icon(Icons.inventory_2_outlined, size: 40),
            title: Text(it.titulo),
            subtitle: Text('${it.lugar}\n${it.descripcion}',
                maxLines: 2, overflow: TextOverflow.ellipsis),
            isThreeLine: true,
            trailing: it.reclamado
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
        body: TabBarView(children: [_lista(false), _lista(true)]),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _publicar,
          icon: const Icon(Icons.add),
          label: const Text('Publicar'),
        ),
      ),
    );
  }
}
