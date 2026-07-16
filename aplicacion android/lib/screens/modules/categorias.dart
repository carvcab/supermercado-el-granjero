import 'dart:async';

import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../theme.dart';

class CatScreen extends StatefulWidget {
  const CatScreen({super.key});
  @override
  State<CatScreen> createState() => _CatScreenState();
}

class _CatScreenState extends State<CatScreen> {
  final _q = TextEditingController();
  List<Map<dynamic, dynamic>> _d = [];
  List<Map<dynamic, dynamic>> _productos = [];
  String _f = '';
  StreamSubscription? _subC;
  StreamSubscription? _subP;

  static const _icons = [
    {'name': 'category', 'icon': Icons.category},
    {'name': 'shopping_cart', 'icon': Icons.shopping_cart},
    {'name': 'local_grocery_store', 'icon': Icons.local_grocery_store},
    {'name': 'restaurant', 'icon': Icons.restaurant},
    {'name': 'local_drink', 'icon': Icons.local_drink},
    {'name': 'bakery_dining', 'icon': Icons.bakery_dining},
    {'name': 'egg', 'icon': Icons.egg},
    {'name': 'lunch_dining', 'icon': Icons.lunch_dining},
    {'name': 'local_pizza', 'icon': Icons.local_pizza},
    {'name': 'icecream', 'icon': Icons.icecream},
    {'name': 'coffee', 'icon': Icons.coffee},
    {'name': 'wine_bar', 'icon': Icons.wine_bar},
    {'name': 'cleaning_services', 'icon': Icons.cleaning_services},
    {'name': 'checkroom', 'icon': Icons.checkroom},
    {'name': 'toys', 'icon': Icons.toys},
    {'name': 'pets', 'icon': Icons.pets},
    {'name': 'medication', 'icon': Icons.medication},
    {'name': 'electrical_services', 'icon': Icons.electrical_services},
    {'name': 'home', 'icon': Icons.home},
    {'name': 'more_horiz', 'icon': Icons.more_horiz},
  ];

  static const _colorPresets = [
    '#059669', '#1b4d3e', '#2563eb', '#7c3aed', '#db2777',
    '#dc2626', '#ea580c', '#ca8a04', '#16a34a', '#0891b2',
    '#4f46e5', '#9333ea', '#0f766e', '#b45309', '#475569',
  ];

  @override
  void initState() {
    super.initState();
    _subC = Fb.stream('categorias').listen((d) => setState(() => _d = List<Map<dynamic, dynamic>>.from(d)));
    _subP = Fb.stream('productos').listen((d) => setState(() => _productos = List<Map<dynamic, dynamic>>.from(d)));
  }

  int _countProductos(dynamic catId) {
    if (catId == null) return 0;
    final idStr = catId.toString();
    return _productos.where((p) {
      final cid = p['categoria_id'] ?? p['categoriaId'];
      return cid != null && cid.toString() == idStr;
    }).length;
  }

  List<Map> _filtrar() {
    if (_f.isEmpty) return _d;
    final q = _f.toLowerCase();
    return _d.where((c) {
      final n = (c['nombre'] ?? '').toString().toLowerCase();
      final d = (c['descripcion'] ?? '').toString().toLowerCase();
      return n.contains(q) || d.contains(q);
    }).toList()
      ..sort((a, b) => ((a['orden'] ?? 0) as num).compareTo((b['orden'] ?? 0) as num));
  }

  IconData _getIcon(String? iconName) {
    for (final i in _icons) {
      if (i['name'] == iconName) return i['icon'] as IconData;
    }
    return Icons.category;
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Tema.primary;
    }
  }

  Future<void> _abrirForm([Map? c]) async {
    final nombreCtl = TextEditingController(text: c?['nombre'] ?? '');
    final colorCtl = TextEditingController(text: c?['color'] ?? '#059669');
    final ordenCtl = TextEditingController(text: (c?['orden'] ?? 0).toString());
    final descCtl = TextEditingController(text: c?['descripcion'] ?? '');
    String icono = c?['icono'] ?? 'category';
    String colorHex = c?['color'] ?? '#059669';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text(
            c != null ? 'Editar Categoria' : 'Nueva Categoria',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _fld('Nombre', nombreCtl),
              SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Color', style: TextStyle(fontSize: 12, color: Tema.textSoft, fontWeight: FontWeight.w600)),
              ),
              SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _colorPresets.map((hex) {
                  final sel = hex == colorHex;
                  return GestureDetector(
                    onTap: () => setSt(() {
                      colorHex = hex;
                      colorCtl.text = hex;
                    }),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _parseColor(hex),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: sel ? Tema.textDark : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: sel
                            ? [BoxShadow(color: _parseColor(hex).withValues(alpha: 0.4), blurRadius: 6)]
                            : null,
                      ),
                      child: sel ? Icon(Icons.check, color: Colors.white, size: 18) : null,
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 6),
              TextField(
                controller: colorCtl,
                decoration: const InputDecoration(
                  labelText: 'Color HEX (ej: #059669)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => colorHex = v,
              ),
              SizedBox(height: 10),
              _fld('Orden', ordenCtl, number: true),
              SizedBox(height: 10),
              TextField(
                controller: descCtl,
                decoration: const InputDecoration(
                  labelText: 'Descripcion',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Icono', style: TextStyle(fontSize: 12, color: Tema.textSoft, fontWeight: FontWeight.w600)),
              ),
              SizedBox(height: 6),
              SizedBox(
                height: 180,
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                  ),
                  itemCount: _icons.length,
                  itemBuilder: (_, i) {
                    final ic = _icons[i];
                    final sel = ic['name'] == icono;
                    return GestureDetector(
                      onTap: () => setSt(() => icono = ic['name'] as String),
                      child: Container(
                        decoration: BoxDecoration(
                          color: sel ? Tema.primary.withValues(alpha: 0.12) : Colors.transparent,
                          borderRadius: BorderRadius.circular(Tema.radiusSm),
                          border: Border.all(
                            color: sel ? Tema.primary : Tema.cardBorder,
                          ),
                        ),
                        child: Icon(
                          ic['icon'] as IconData,
                          color: sel ? Tema.primary : Tema.textSoft,
                          size: 24,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ]),
          ),
          actionsPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Tema.textMuted),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Tema.radiusSm),
                      ),
                    ),
                    child: Text('Cancelar', style: TextStyle(color: Tema.textDark, fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Tema.primary,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Tema.radiusSm),
                      ),
                    ),
                    child: Text('Guardar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (ok != true || nombreCtl.text.trim().isEmpty) return;

    if (c != null) {
      c['nombre'] = nombreCtl.text.trim();
      c['color'] = colorCtl.text;
      c['orden'] = int.tryParse(ordenCtl.text) ?? 0;
      c['descripcion'] = descCtl.text.trim();
      c['icono'] = icono;
    } else {
      final id = _d.isEmpty
          ? 1
          : _d.map((x) => (x['id'] as num?)?.toInt() ?? 0).reduce((a, b) => a > b ? a : b) + 1;
      _d.add({
        'id': id,
        'nombre': nombreCtl.text.trim(),
        'color': colorCtl.text,
        'orden': int.tryParse(ordenCtl.text) ?? 0,
        'descripcion': descCtl.text.trim(),
        'icono': icono,
      });
    }
    await Fb.setList('categorias', _d);
  }

  Future<void> _eliminar(Map c) async {
    _d.removeWhere((x) => (x['id'] ?? '').toString() == (c['id'] ?? '').toString());
    await Fb.setList('categorias', _d);
  }

  Future<bool?> _confirmDelete(Map c) async {
    final count = _countProductos(c['id']);
    final nombre = (c['nombre'] ?? 'esta categoria').toString();
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar categoria'),
        content: Text(
          count > 0
              ? '$count producto(s) usan "$nombre".\n¿Eliminar de todas formas?'
              : '¿Eliminar "$nombre"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Eliminar', style: TextStyle(color: Tema.danger)),
          ),
        ],
      ),
    );
  }

  Widget _fld(String l, TextEditingController ctl, {bool number = false}) {
    return TextField(
      controller: ctl,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: l,
        border: const OutlineInputBorder(),
      ),
    );
  }

  @override
  void dispose() {
    _subC?.cancel();
    _subP?.cancel();
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fl = _filtrar();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirForm(),
        backgroundColor: Tema.primary,
        child: Icon(Icons.add),
      ),
      body: Column(children: [
        Padding(
          padding: EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: SearchInput(
            controller: _q,
            hintText: 'Buscar categoria...',
            onChanged: (v) => setState(() => _f = v),
          ),
        ),
        Expanded(
          child: fl.isEmpty
                ? ListView(children: [
                    Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No se encontraron categorias',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Tema.textMuted),
                      ),
                    )
                  ])
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    itemCount: fl.length,
                    itemBuilder: (_, i) => _buildCard(fl[i]),
                  )
          ),
      ]),
    );
  }

  Widget _buildCard(Map c) {
    final nombre = (c['nombre'] ?? 'C').toString();
    final descripcion = (c['descripcion'] ?? '').toString();
    final orden = (c['orden'] ?? 0) as num;
    final icono = _getIcon(c['icono'] as String?);
    final color = _parseColor(c['color'] ?? '#059669');
    final productosCount = _countProductos(c['id']);

    return Dismissible(
      key: Key('cat_${c['id']}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(c),
      onDismissed: (_) => _eliminar(c),
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        margin: EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Tema.danger,
          borderRadius: BorderRadius.circular(Tema.radius),
        ),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: () => _abrirForm(c),
        child: Container(
          margin: EdgeInsets.only(bottom: 8),
          decoration: Tema.cardDeco,
          padding: EdgeInsets.all(14),
          child: Row(children: [
            CircleAvatar(
              backgroundColor: color,
              radius: 22,
              child: Icon(icono, color: Colors.white, size: 22),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Tema.textDark,
                    ),
                  ),
                  if (descripcion.isNotEmpty) ...[
                    SizedBox(height: 2),
                    Text(
                      descripcion,
                      style: TextStyle(fontSize: 12, color: Tema.textSoft),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _badge('Orden $orden', color),
                SizedBox(height: 4),
                Text(
                  '$productosCount prod.',
                  style: TextStyle(fontSize: 11, color: Tema.textMuted),
                ),
              ],
            ),
            SizedBox(width: 4),
            Icon(Icons.chevron_right, color: Tema.textMuted),
          ]),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}


