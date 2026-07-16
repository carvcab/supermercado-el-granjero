import 'dart:async';

import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../theme.dart';

class CprScreen extends StatefulWidget {
  const CprScreen({super.key});
  @override
  State<CprScreen> createState() => _CprScreenState();
}

class _CprScreenState extends State<CprScreen> {
  final _searchController = TextEditingController();
  List<Map<dynamic, dynamic>> _templates = [];
  List<Map<dynamic, dynamic>> _proveedores = [];
  List<Map<dynamic, dynamic>> _productos = [];
  List<Map<dynamic, dynamic>> _compras = [];
  String _search = '';
  StreamSubscription? _sub;

  static const _diasSemana = ['Lunes', 'Martes', 'Miercoles', 'Jueves', 'Viernes', 'Sabado', 'Domingo'];

  @override
  void initState() {
    super.initState();
    _sub = Fb.stream('compras_programadas').listen((d) => setState(() => _templates = d.cast<Map<dynamic, dynamic>>()));
    Future.wait([Fb.getList('proveedores'), Fb.getList('productos'), Fb.getList('compras')]).then((results) {
      setState(() {
        _proveedores = (results[0] as List).cast<Map<dynamic, dynamic>>();
        _productos = (results[1] as List).cast<Map<dynamic, dynamic>>();
        _compras = (results[2] as List).cast<Map<dynamic, dynamic>>();
      });
    });
  }

  int _nextId() {
    if (_templates.isEmpty) return 1;
    return _templates
        .map((x) => x['id'] is int ? x['id'] as int : int.tryParse(x['id'].toString()) ?? 0)
        .reduce((a, b) => a > b ? a : b) + 1;
  }

  int _nextCompraId() {
    if (_compras.isEmpty) return 1;
    return _compras
        .map((x) => x['id'] is int ? x['id'] as int : int.tryParse(x['id'].toString()) ?? 0)
        .reduce((a, b) => a > b ? a : b) + 1;
  }

  DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    return DateTime.tryParse(val.toString().substring(0, 10));
  }

  String _fmtDate(dynamic val) {
    final d = _parseDate(val);
    if (d == null) return '-';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  num _num(dynamic v) => v is num ? v : num.tryParse(v.toString()) ?? 0;

  Color _frecuenciaColor(String f) {
    switch (f) {
      case 'Diario':
        return const Color(0xFFe65100);
      case 'Semanal':
        return Tema.darkBlue;
      case 'Quincenal':
        return Colors.purple;
      case 'Mensual':
        return Tema.primary;
      default:
        return Tema.textSoft;
    }
  }

  String _calcularProximaFecha(String frecuencia, String dia) {
    final hoy = DateTime.now();
    switch (frecuencia) {
      case 'Diario':
        return hoy.add(const Duration(days: 1)).toIso8601String().substring(0, 10);
      case 'Semanal':
        final idxDia = _diasSemana.indexOf(dia);
        if (idxDia < 0) return hoy.add(const Duration(days: 7)).toIso8601String().substring(0, 10);
        final weekday = idxDia + 1;
        int daysUntil = weekday - hoy.weekday;
        if (daysUntil <= 0) daysUntil += 7;
        return hoy.add(Duration(days: daysUntil)).toIso8601String().substring(0, 10);
      case 'Quincenal':
        final diaN = int.tryParse(dia) ?? 1;
        DateTime next;
        if (diaN <= 15) {
          next = DateTime(hoy.year, hoy.month, diaN);
          if (next.isBefore(hoy) || next.isAtSameMomentAs(hoy)) {
            next = DateTime(hoy.year, hoy.month + 1, diaN);
          }
        } else {
          final lastDay = DateTime(hoy.year, hoy.month + 1, 0).day;
          next = DateTime(hoy.year, hoy.month, diaN > lastDay ? lastDay : diaN);
          if (next.isBefore(hoy) || next.isAtSameMomentAs(hoy)) {
            final nextMonth = DateTime(hoy.year, hoy.month + 1, 1);
            final nextLastDay = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
            next = DateTime(nextMonth.year, nextMonth.month, diaN > nextLastDay ? nextLastDay : diaN);
          }
        }
        return next.toIso8601String().substring(0, 10);
      case 'Mensual':
        final diaN = int.tryParse(dia) ?? 1;
        final lastDay = DateTime(hoy.year, hoy.month + 1, 0).day;
        DateTime next = DateTime(hoy.year, hoy.month, diaN > lastDay ? lastDay : diaN);
        if (next.isBefore(hoy) || next.isAtSameMomentAs(hoy)) {
          final nextMonth = DateTime(hoy.year, hoy.month + 1, 1);
          final nextLastDay = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
          next = DateTime(nextMonth.year, nextMonth.month, diaN > nextLastDay ? nextLastDay : diaN);
        }
        return next.toIso8601String().substring(0, 10);
      default:
        return hoy.add(const Duration(days: 7)).toIso8601String().substring(0, 10);
    }
  }

  List<Map<dynamic, dynamic>> _filtrar() {
    if (_search.isEmpty) return _templates;
    final q = _search.toLowerCase();
    return _templates.where((t) {
      final nombre = (t['nombre'] ?? '').toString().toLowerCase();
      final prov = (t['proveedor_nombre'] ?? '').toString().toLowerCase();
      return nombre.contains(q) || prov.contains(q);
    }).toList();
  }

  Future<void> _abrirForm([Map<dynamic, dynamic>? template]) async {
    final result = await showDialog<Map<dynamic, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _CprFormModal(
        template: template,
        proveedores: _proveedores,
        productos: _productos,
        onProveedorCreado: () => Fb.getList('proveedores').then((p) => setState(() => _proveedores = (p as List).cast<Map<dynamic, dynamic>>())),
      ),
    );
    if (result == null) return;
    if (template != null) {
      final idx = _templates.indexWhere((x) => x['id'] == template['id']);
      if (idx >= 0) _templates[idx] = result;
    } else {
      result['id'] = _nextId();
      _templates.add(result);
    }
    await Fb.setList('compras_programadas', _templates);
  }

  Future<void> _abastecer(Map<dynamic, dynamic> template) async {
    final fechaCtl = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
    double totalEstimado = 0;
    final productos = List<Map<String, dynamic>>.from(
      (template['productos'] as List?)?.map((x) => Map<String, dynamic>.from(x as Map)) ?? [],
    );
    for (final p in productos) {
      final prod = _productos.where((px) => (px['id'] ?? '').toString() == (p['producto_id'] ?? '').toString()).firstOrNull;
      final precio = prod != null ? _num(prod['precio_compra']).toDouble() : 0.0;
      final cant = _num(p['cantidad']).toDouble();
      p['precio_unitario'] = precio;
      p['subtotal'] = cant * precio;
      totalEstimado += cant * precio;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tema.radiusLg)),
          insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          title: Text('Abastecer: ${template['nombre'] ?? ''}', style: TextStyle(fontWeight: FontWeight.w700, color: Tema.textDark)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Proveedor: ${template['proveedor_nombre'] ?? ''}', style: TextStyle(color: Tema.textSoft)),
              SizedBox(height: 8),
              TextField(
                controller: fechaCtl,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Fecha', border: OutlineInputBorder()),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: _parseDate(fechaCtl.text) ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    fechaCtl.text = picked.toIso8601String().substring(0, 10);
                    setSt(() {});
                  }
                },
              ),
              SizedBox(height: 12),
              Text('Productos:', style: TextStyle(fontWeight: FontWeight.w600, color: Tema.textDark)),
              SizedBox(height: 4),
              ...productos.map((p) => Padding(
                padding: EdgeInsets.symmetric(vertical: 3),
                child: Row(children: [
                  Expanded(child: Text(p['nombre']?.toString() ?? '', style: TextStyle(fontSize: 13))),
                  Text('x${p['cantidad'] ?? 1}', style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(width: 12),
                  Text(Fb.formatMoney(p['subtotal'] ?? 0), style: TextStyle(fontWeight: FontWeight.w600, color: Tema.primary)),
                ]),
              )),
              const Divider(height: 16),
              Row(children: [
                Text('Total estimado: ', style: TextStyle(fontWeight: FontWeight.w600)),
                Text(Fb.formatMoney(totalEstimado), style: TextStyle(fontWeight: FontWeight.w800, color: Tema.primary, fontSize: 16)),
              ]),
            ]))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Confirmar Abastecimiento')),
          ],
        ),
      ),
    );

    if (ok != true) return;

    final compraId = _nextCompraId();
    final items = productos.map((p) => {
      'producto_id': p['producto_id'],
      'nombre': p['nombre'],
      'cantidad': p['cantidad'],
      'precio_unitario': p['precio_unitario'],
      'subtotal': p['subtotal'],
    }).toList();

    final iva = (totalEstimado * 0.19).round().toDouble();

    final compra = <dynamic, dynamic>{
      'id': compraId,
      'proveedor_id': template['proveedor'],
      'proveedor_nombre': template['proveedor_nombre'],
      'fecha': fechaCtl.text,
      'items': items,
      'subtotal': totalEstimado,
      'descuento': 0,
      'iva': iva,
      'total': totalEstimado + iva,
      'pagado': false,
      'estado': 'Pendiente',
      'tipo': 'programada',
      'compra_programada_id': template['id'],
    };
    _compras.add(compra);
    await Fb.setList('compras', _compras);

    final historial = List<Map<dynamic, dynamic>>.from(template['historial'] ?? []);
    historial.insert(0, {
      'fecha': fechaCtl.text,
      'total': (totalEstimado + iva).toInt(),
      'items_count': items.length,
    });
    template['historial'] = historial;
    template['proxima_fecha'] = _calcularProximaFecha(
      template['frecuencia']?.toString() ?? '',
      template['dia']?.toString() ?? '',
    );

    final idx = _templates.indexWhere((x) => x['id'] == template['id']);
    if (idx >= 0) _templates[idx] = template;
    await Fb.setList('compras_programadas', _templates);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Abastecimiento registrado. Compra #$compraId creada.'), backgroundColor: Tema.primary),
      );
    }
  }

  Future<void> _eliminarTemplate(Map<dynamic, dynamic> template) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tema.radiusLg)),
        title: Text('Eliminar Plantilla', style: TextStyle(fontWeight: FontWeight.w700, color: Tema.textDark)),
        content: Text('Eliminar plantilla "${template['nombre'] ?? ''}"?\nEsta accion no se puede deshacer.', style: TextStyle(color: Tema.textSoft)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Eliminar', style: TextStyle(color: Tema.danger))),
        ],
      ),
    );
    if (ok != true) return;
    _templates.removeWhere((x) => x['id'] == template['id']);
    await Fb.setList('compras_programadas', _templates);
  }

  void _verHistorial(Map<dynamic, dynamic> template) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Tema.radiusLg))),
      builder: (ctx) => _HistorialSheet(template: template),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtradas = _filtrar();
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirForm(),
        backgroundColor: Tema.primary,
        child: Icon(Icons.add),
      ),
      body: Column(children: [
          _buildSearch(),
          Expanded(child: _buildList(filtradas)),
        ]),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: SearchInput(
        controller: _searchController,
        hintText: 'Buscar plantilla...',
        onChanged: (v) => setState(() => _search = v),
      ),
    );
  }

  Widget _buildList(List<Map<dynamic, dynamic>> filtradas) {
    if (filtradas.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: 80),
          Icon(Icons.calendar_month_outlined, color: Tema.textMuted, size: 48),
          SizedBox(height: 12),
          Text('No hay compras programadas', textAlign: TextAlign.center, style: TextStyle(color: Tema.textMuted, fontSize: 15)),
        ],
      );
    }
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: filtradas.length,
      itemBuilder: (_, i) => _buildCard(filtradas[i]),
    );
  }

  Widget _buildCard(Map<dynamic, dynamic> template) {
    final nombre = (template['nombre'] ?? 'Sin nombre').toString();
    final proveedorNombre = (template['proveedor_nombre'] ?? '').toString();
    final frecuencia = (template['frecuencia'] ?? '').toString();
    final activo = template['activo'] != false;
    final productos = (template['productos'] as List?) ?? [];
    final proxFecha = _fmtDate(template['proxima_fecha']);
    final freqColor = _frecuenciaColor(frecuencia);
    final historial = (template['historial'] as List?) ?? [];

    return Dismissible(
      key: Key('cpr_${template['id']}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        _eliminarTemplate(template);
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        margin: EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(color: Tema.danger, borderRadius: BorderRadius.circular(Tema.radius)),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        decoration: Tema.cardDeco,
        child: Padding(
          padding: EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(
                backgroundColor: Tema.primary,
                radius: 20,
                child: Text(nombre[0].toUpperCase(), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(nombre, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Tema.textDark)),
                  SizedBox(height: 2),
                  Text(proveedorNombre, style: TextStyle(fontSize: 12, color: Tema.textSoft)),
                ]),
              ),
              _badge(frecuencia, freqColor),
            ]),
            SizedBox(height: 10),
            Row(children: [
              _infoChip(Icons.calendar_today, 'Prox: $proxFecha'),
              SizedBox(width: 12),
              _infoChip(Icons.inventory_2, '${productos.length} productos'),
              const Spacer(),
              _badge(activo ? 'Activo' : 'Inactivo', activo ? Tema.primary : Tema.textMuted),
            ]),
            SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _verHistorial(template),
                  icon: Icon(Icons.history, size: 16),
                  label: Text('Historial (${historial.length})', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    side: BorderSide(color: Tema.cardBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tema.radiusSm)),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _abastecer(template),
                  icon: Icon(Icons.shopping_cart, size: 16),
                  label: Text('Abastecer', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Tema.primary,
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tema.radiusSm)),
                  ),
                ),
              ),
              SizedBox(width: 8),
              IconButton(
                onPressed: () => _abrirForm(template),
                icon: Icon(Icons.edit, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: Tema.textSoft,
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: Tema.textMuted),
      SizedBox(width: 4),
      Text(text, style: TextStyle(fontSize: 11, color: Tema.textSoft)),
    ]);
  }
}

class _CprFormModal extends StatefulWidget {
  final Map<dynamic, dynamic>? template;
  final List<Map<dynamic, dynamic>> proveedores;
  final List<Map<dynamic, dynamic>> productos;
  final VoidCallback onProveedorCreado;

  const _CprFormModal({
    this.template,
    required this.proveedores,
    required this.productos,
    required this.onProveedorCreado,
  });

  @override
  State<_CprFormModal> createState() => _CprFormModalState();
}

class _CprFormModalState extends State<_CprFormModal> {
  final _nombreController = TextEditingController();
  final _provController = TextEditingController();
  final _fechaController = TextEditingController();
  final _searchProdController = TextEditingController();

  String _frecuencia = 'Semanal';
  String _dia = '';
  List<Map<String, dynamic>> _items = [];
  bool _activo = true;
  List<Map<dynamic, dynamic>> _searchResults = [];
  DateTime _proximaFecha = DateTime.now();

  static const _frecuencias = ['Diario', 'Semanal', 'Quincenal', 'Mensual'];
  static const _diasSemana = ['Lunes', 'Martes', 'Miercoles', 'Jueves', 'Viernes', 'Sabado', 'Domingo'];

  bool get _isEdit => widget.template != null;

  num _num(dynamic v) => v is num ? v : num.tryParse(v.toString()) ?? 0;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final t = widget.template!;
      _nombreController.text = (t['nombre'] ?? '').toString();
      _provController.text = (t['proveedor_nombre'] ?? '').toString();
      _frecuencia = (t['frecuencia'] ?? 'Semanal').toString();
      _dia = (t['dia'] ?? '').toString();
      _activo = t['activo'] != false;
      _proximaFecha = _parseDateVal(t['proxima_fecha']) ?? DateTime.now();
      _fechaController.text = _proximaFecha.toIso8601String().substring(0, 10);
      final items = t['productos'] as List? ?? [];
      _items = items.map((x) => Map<String, dynamic>.from(x as Map)).toList();
    } else {
      _fechaController.text = DateTime.now().toIso8601String().substring(0, 10);
    }
    _ensureDia();
    _recalcularProximaFecha();
  }

  DateTime? _parseDateVal(dynamic val) {
    if (val == null) return null;
    return DateTime.tryParse(val.toString().substring(0, 10));
  }

  void _ensureDia() {
    if (_dia.isEmpty && _frecuencia != 'Diario') {
      switch (_frecuencia) {
        case 'Semanal':
          _dia = _diasSemana[DateTime.now().weekday - 1];
          break;
        case 'Quincenal':
          _dia = '1';
          break;
        case 'Mensual':
          _dia = DateTime.now().day.toString();
          break;
      }
    }
  }

  void _recalcularProximaFecha() {
    final hoy = DateTime.now();
    switch (_frecuencia) {
      case 'Diario':
        _proximaFecha = hoy.add(const Duration(days: 1));
        break;
      case 'Semanal':
        final idxDia = _diasSemana.indexOf(_dia);
        if (idxDia < 0) {
          _proximaFecha = hoy.add(const Duration(days: 7));
        } else {
          final weekday = idxDia + 1;
          int daysUntil = weekday - hoy.weekday;
          if (daysUntil <= 0) daysUntil += 7;
          _proximaFecha = hoy.add(Duration(days: daysUntil));
        }
        break;
      case 'Quincenal':
        final diaN = int.tryParse(_dia) ?? 1;
        DateTime next;
        if (diaN <= 15) {
          next = DateTime(hoy.year, hoy.month, diaN);
          if (next.isBefore(hoy) || next.isAtSameMomentAs(hoy)) {
            next = DateTime(hoy.year, hoy.month + 1, diaN);
          }
        } else {
          final lastDay = DateTime(hoy.year, hoy.month + 1, 0).day;
          next = DateTime(hoy.year, hoy.month, diaN > lastDay ? lastDay : diaN);
          if (next.isBefore(hoy) || next.isAtSameMomentAs(hoy)) {
            final nextMonth = DateTime(hoy.year, hoy.month + 1, 1);
            final nextLastDay = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
            next = DateTime(nextMonth.year, nextMonth.month, diaN > nextLastDay ? nextLastDay : diaN);
          }
        }
        _proximaFecha = next;
        break;
      case 'Mensual':
        final diaN = int.tryParse(_dia) ?? 1;
        final lastDay = DateTime(hoy.year, hoy.month + 1, 0).day;
        DateTime next = DateTime(hoy.year, hoy.month, diaN > lastDay ? lastDay : diaN);
        if (next.isBefore(hoy) || next.isAtSameMomentAs(hoy)) {
          final nextMonth = DateTime(hoy.year, hoy.month + 1, 1);
          final nextLastDay = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
          next = DateTime(nextMonth.year, nextMonth.month, diaN > nextLastDay ? nextLastDay : diaN);
        }
        _proximaFecha = next;
        break;
      default:
        _proximaFecha = hoy.add(const Duration(days: 7));
    }
    _fechaController.text = _proximaFecha.toIso8601String().substring(0, 10);
  }

  void _buscarProducto(String term) {
    if (term.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final q = term.toLowerCase();
    final found = widget.productos.where((p) {
      final nom = (p['nombre'] ?? '').toString().toLowerCase();
      final cod = (p['codigo'] ?? '').toString().toLowerCase();
      return nom.contains(q) || cod.contains(q);
    }).toList();
    setState(() => _searchResults = found);
  }

  void _agregarProducto(Map<dynamic, dynamic> prod) {
    final pid = prod['id']?.toString();
    final idx = _items.indexWhere((x) => x['producto_id']?.toString() == pid);
    if (idx >= 0) {
      _items[idx]['cantidad'] = _num(_items[idx]['cantidad']) + 1;
    } else {
      _items.add({
        'producto_id': prod['id'],
        'nombre': prod['nombre']?.toString() ?? '',
        'cantidad': 1,
      });
    }
    setState(() {
      _searchResults = [];
      _searchProdController.clear();
    });
  }

  void _quitarProducto(int idx) {
    _items.removeAt(idx);
    setState(() {});
  }

  void _cambiarCantidad(int idx, int delta) {
    final cant = _num(_items[idx]['cantidad']).toInt() + delta;
    if (cant <= 0) {
      _items.removeAt(idx);
    } else {
      _items[idx]['cantidad'] = cant;
    }
    setState(() {});
  }

  Future<void> _pickFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _proximaFecha,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _proximaFecha = picked;
        _fechaController.text = picked.toIso8601String().substring(0, 10);
      });
    }
  }

  Future<void> _agregarProveedorRapido() async {
    final nombre = _provController.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escriba el nombre del proveedor')));
      return;
    }
    final nuevo = await showDialog<Map<dynamic, dynamic>>(
      context: context,
      builder: (ctx) => _QuickProvDialog(nombre: nombre),
    );
    if (nuevo == null) return;
    widget.proveedores.add(nuevo);
    widget.onProveedorCreado();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Proveedor creado'), backgroundColor: Tema.primary));
  }

  void _guardar() {
    final nombre = _nombreController.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingrese un nombre para la plantilla')));
      return;
    }
    final provNombre = _provController.text.trim();
    if (provNombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seleccione un proveedor')));
      return;
    }

    dynamic proveedorId;
    final match = widget.proveedores.where((p) => (p['nombre'] ?? '').toString().toLowerCase() == provNombre.toLowerCase()).firstOrNull;
    if (match != null) {
      proveedorId = match['id'];
    }

    final data = <dynamic, dynamic>{
      'nombre': nombre,
      'proveedor': proveedorId,
      'proveedor_nombre': provNombre,
      'frecuencia': _frecuencia,
      'dia': _frecuencia == 'Diario' ? '' : _dia,
      'proxima_fecha': _fechaController.text,
      'productos': _items.map((i) => {
        'producto_id': i['producto_id'],
        'nombre': i['nombre'],
        'cantidad': i['cantidad'],
      }).toList(),
      'activo': _activo,
      'historial': _isEdit ? (widget.template!['historial'] ?? []) : [],
    };

    if (_isEdit) {
      data['id'] = widget.template!['id'];
    }

    Navigator.pop(context, data);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _provController.dispose();
    _fechaController.dispose();
    _searchProdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = _isEdit;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tema.radiusLg)),
      insetPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 600, maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: EdgeInsets.fromLTRB(20, 16, 8, 12),
                decoration: const BoxDecoration(
                  color: Tema.primary,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(Tema.radiusLg)),
                ),
                child: Row(children: [
                  Icon(Icons.calendar_month, color: Colors.white.withValues(alpha: 0.8), size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(editing ? 'Editar Plantilla' : 'Nueva Plantilla',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.white, size: 22),
                  ),
                ]),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _buildNombreField(),
                    SizedBox(height: 10),
                    _buildProveedorField(),
                    SizedBox(height: 10),
                    _buildFrecuenciaDropdown(),
                    if (_frecuencia != 'Diario') ...[
                      SizedBox(height: 10),
                      _buildDiaSelector(),
                    ],
                    SizedBox(height: 10),
                    _buildFechaField(),
                    SizedBox(height: 10),
                    _buildEstadoToggle(),
                    const Divider(height: 8),
                    _buildProductSearch(),
                    SizedBox(height: 10),
                    _buildItemsList(),
                  ]),
                ),
              ),
              Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      offset: const Offset(0, -2),
                      blurRadius: 10,
                    ),
                  ],
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(Tema.radiusLg)),
                ),
                child: Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancelar'),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _guardar,
                      icon: Icon(Icons.save, size: 18),
                      label: Text(editing ? 'Actualizar' : 'Guardar'),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildNombreField() {
    return TextField(
      controller: _nombreController,
      decoration: const InputDecoration(labelText: 'Nombre de la Plantilla', hintText: 'Ej: Pedido semanal frutas'),
    );
  }

  Widget _buildProveedorField() {
    return Row(children: [
      Expanded(
        child: Autocomplete<String>(
          optionsBuilder: (v) {
            if (v.text.isEmpty) return widget.proveedores.map((p) => p['nombre']?.toString() ?? '');
            final q = v.text.toLowerCase();
            return widget.proveedores.where((p) => (p['nombre'] ?? '').toString().toLowerCase().contains(q)).map((p) => p['nombre']?.toString() ?? '');
          },
          onSelected: (v) => _provController.text = v,
          fieldViewBuilder: (ctx, ctl, node, _) => TextField(
            controller: _provController,
            focusNode: node,
            decoration: const InputDecoration(labelText: 'Proveedor', hintText: 'Buscar o escribir...'),
            onChanged: (_) => ctl.text = _provController.text,
          ),
        ),
      ),
      SizedBox(width: 6),
      SizedBox(
        height: 52,
        width: 44,
        child: ElevatedButton(
          onPressed: _agregarProveedorRapido,
          style: ElevatedButton.styleFrom(padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tema.radiusSm))),
          child: Icon(Icons.add, size: 20),
        ),
      ),
    ]);
  }

  Widget _buildFrecuenciaDropdown() {
    return DropdownButtonFormField<String>(
      value: _frecuencia,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Frecuencia'),
      items: _frecuencias.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
      onChanged: (v) {
        if (v == null) return;
        setState(() {
          _frecuencia = v;
          _ensureDia();
          _recalcularProximaFecha();
        });
      },
    );
  }

  Widget _buildDiaSelector() {
    switch (_frecuencia) {
      case 'Semanal':
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Dia de la semana', style: TextStyle(fontSize: 12, color: Tema.textSoft, fontWeight: FontWeight.w600)),
          SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _diasSemana.map((d) {
              final sel = _dia == d;
              return FilterChip(
                label: Text(d.substring(0, 3)),
                selected: sel,
                onSelected: (v) {
                  if (v) {
                    setState(() {
                      _dia = d;
                      _recalcularProximaFecha();
                    });
                  }
                },
                selectedColor: Tema.primary.withValues(alpha: 0.15),
                checkmarkColor: Tema.primary,
                side: BorderSide(color: sel ? Tema.primary : Tema.cardBorder),
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ]);

      case 'Quincenal':
        return DropdownButtonFormField<String>(
          value: _dia,
          decoration: const InputDecoration(labelText: 'Quincena'),
          items: const [
            DropdownMenuItem(value: '1', child: Text('Primera quincena (1-15)')),
            DropdownMenuItem(value: '16', child: Text('Segunda quincena (16-31)')),
          ],
          onChanged: (v) {
            if (v != null) {
              setState(() {
                _dia = v;
                _recalcularProximaFecha();
              });
            }
          },
        );

      case 'Mensual':
        return DropdownButtonFormField<String>(
          value: _dia,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Dia del mes'),
          items: List.generate(31, (i) => (i + 1).toString()).map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
          onChanged: (v) {
            if (v != null) {
              setState(() {
                _dia = v;
                _recalcularProximaFecha();
              });
            }
          },
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFechaField() {
    return TextField(
      controller: _fechaController,
      readOnly: true,
      decoration: InputDecoration(
        labelText: 'Proxima Fecha',
        suffixIcon: IconButton(
          icon: Icon(Icons.calendar_today, size: 18),
          onPressed: _pickFecha,
        ),
      ),
      onTap: _pickFecha,
    );
  }

  Widget _buildEstadoToggle() {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(_activo ? 'Activo' : 'Inactivo', style: TextStyle(fontWeight: FontWeight.w600, color: _activo ? Tema.primary : Tema.textMuted)),
      value: _activo,
      activeColor: Tema.primary,
      onChanged: (v) => setState(() => _activo = v),
    );
  }

  Widget _buildProductSearch() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Tema.radius),
        border: Border.all(color: Tema.primary, width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.search, size: 18, color: Tema.primary.withValues(alpha: 0.7)),
          SizedBox(width: 6),
          Text('Buscar Producto', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Tema.textDark)),
        ]),
        SizedBox(height: 8),
        TextField(
          controller: _searchProdController,
          decoration: const InputDecoration(
            hintText: 'Buscar por codigo o nombre...',
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          onChanged: _buscarProducto,
        ),
        if (_searchResults.isNotEmpty) ...[
          SizedBox(height: 8),
          ..._searchResults.map((prod) => Container(
            margin: EdgeInsets.only(bottom: 6),
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Tema.bg,
              borderRadius: BorderRadius.circular(Tema.radiusSm),
              border: Border.all(color: Tema.cardBorder),
            ),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(prod['nombre']?.toString() ?? '', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Tema.textDark)),
                  Text('Cod: ${prod['codigo'] ?? '-'} | Stock: ${prod['stock_actual'] ?? prod['stock'] ?? 0}', style: TextStyle(fontSize: 11, color: Tema.textSoft)),
                ]),
              ),
              ElevatedButton.icon(
                onPressed: () => _agregarProducto(prod),
                icon: Icon(Icons.add, size: 14),
                label: Text('Agregar', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  textStyle: TextStyle(fontSize: 12),
                ),
              ),
            ]),
          )),
        ],
      ]),
    );
  }

  Widget _buildItemsList() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Tema.radius),
        border: Border.all(color: Tema.darkBlue, width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.list_alt, size: 18, color: Tema.textDark),
          SizedBox(width: 6),
          Text('Productos de la Plantilla', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Tema.textDark)),
          const Spacer(),
          Text('${_items.length} items', style: TextStyle(fontSize: 12, color: Tema.textSoft)),
        ]),
        if (_items.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text('No hay productos agregados', style: TextStyle(color: Tema.textMuted, fontSize: 13))),
          )
        else ...[
          SizedBox(height: 8),
          ...List.generate(_items.length, (idx) {
            final item = _items[idx];
            final nombre = item['nombre']?.toString() ?? '';
            final cantidad = _num(item['cantidad']).toInt();

            return Container(
              margin: EdgeInsets.symmetric(vertical: 2),
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Tema.bg,
                borderRadius: BorderRadius.circular(Tema.radiusSm),
                border: Border.all(color: Tema.cardBorder),
              ),
              child: Row(children: [
                Expanded(
                  child: Text(nombre, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Tema.textDark)),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Tema.cardBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Tema.cardBorder),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    InkWell(
                      onTap: () => _cambiarCantidad(idx, -1),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(padding: EdgeInsets.all(5), child: Icon(Icons.remove, size: 16, color: Tema.textDark)),
                    ),
                    SizedBox(
                      width: 36,
                      child: Text(
                        '$cantidad',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                    InkWell(
                      onTap: () => _cambiarCantidad(idx, 1),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(padding: EdgeInsets.all(5), child: Icon(Icons.add, size: 16, color: Tema.textDark)),
                    ),
                  ]),
                ),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _quitarProducto(idx),
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Tema.danger.withValues(alpha: 0.1)),
                    child: Icon(Icons.close, size: 14, color: Tema.danger),
                  ),
                ),
              ]),
            );
          }),
        ],
      ]),
    );
  }
}

class _QuickProvDialog extends StatefulWidget {
  final String nombre;
  const _QuickProvDialog({required this.nombre});
  @override
  State<_QuickProvDialog> createState() => _QuickProvDialogState();
}

class _QuickProvDialogState extends State<_QuickProvDialog> {
  final _contactoC = TextEditingController();
  final _telefonoC = TextEditingController();
  final _emailC = TextEditingController();
  final _direccionC = TextEditingController();

  @override
  void dispose() {
    _contactoC.dispose();
    _telefonoC.dispose();
    _emailC.dispose();
    _direccionC.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final proveedores = await Fb.getList('proveedores');
    final id = proveedores.isEmpty
        ? 1
        : proveedores.map((x) => x['id'] is int ? x['id'] as int : int.tryParse(x['id'].toString()) ?? 0).reduce((a, b) => a > b ? a : b) + 1;

    final nuevo = <dynamic, dynamic>{
      'id': id,
      'nombre': widget.nombre,
      'contacto': _contactoC.text.trim(),
      'telefono': _telefonoC.text.trim(),
      'email': _emailC.text.trim(),
      'direccion': _direccionC.text.trim(),
      'tipo': 'General',
      'activo': true,
      'fecha_registro': DateTime.now().toIso8601String(),
      'dias_visita': <String>[],
      'observaciones': '',
      'nit': '',
    };
    proveedores.add(nuevo);
    await Fb.setList('proveedores', proveedores);
    if (!mounted) return;
    Navigator.pop(context, nuevo);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tema.radiusLg)),
      insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Text('Nuevo Proveedor: ${widget.nombre}', style: TextStyle(fontWeight: FontWeight.w700, color: Tema.textDark)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: _contactoC, decoration: const InputDecoration(labelText: 'Contacto', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10))),
        SizedBox(height: 6),
        TextField(controller: _telefonoC, decoration: const InputDecoration(labelText: 'Telefono', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10))),
        SizedBox(height: 6),
        TextField(controller: _emailC, decoration: const InputDecoration(labelText: 'Email', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10))),
        SizedBox(height: 6),
        TextField(controller: _direccionC, decoration: const InputDecoration(labelText: 'Direccion', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10))),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar')),
        ElevatedButton(onPressed: _guardar, child: Text('Guardar Proveedor')),
      ],
    );
  }
}

class _HistorialSheet extends StatelessWidget {
  final Map<dynamic, dynamic> template;

  const _HistorialSheet({required this.template});

  String _fmtDate(dynamic val) {
    final d = DateTime.tryParse(val.toString().substring(0, 10));
    if (d == null) return '-';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final historial = List<Map<dynamic, dynamic>>.from(template['historial'] ?? []);
    final nombre = (template['nombre'] ?? 'Sin nombre').toString();

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (ctx, scrollCtl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(Tema.radiusLg)),
        ),
        child: ListView(
          controller: scrollCtl,
          padding: EdgeInsets.all(16),
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Tema.cardBorder, borderRadius: BorderRadius.circular(2)))),
            SizedBox(height: 16),
            Text('Historial: $nombre', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Tema.textDark)),
            SizedBox(height: 4),
            Text('${historial.length} abastecimientos registrados', style: TextStyle(color: Tema.textSoft, fontSize: 13)),
            SizedBox(height: 16),
            if (historial.isEmpty)
              Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('Sin historial de abastecimientos', style: TextStyle(color: Tema.textMuted))),
              )
            else
              ...historial.map((h) => Container(
                margin: EdgeInsets.only(bottom: 6),
                decoration: Tema.cardDeco,
                padding: EdgeInsets.all(12),
                child: Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Tema.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(Tema.radiusSm),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.shopping_cart, color: Tema.primary, size: 20),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_fmtDate(h['fecha']), style: TextStyle(fontWeight: FontWeight.w600, color: Tema.textDark)),
                      Text('${h['items_count'] ?? 0} items', style: TextStyle(fontSize: 12, color: Tema.textSoft)),
                    ]),
                  ),
                  Text(Fb.formatMoney(h['total'] ?? 0), style: TextStyle(fontWeight: FontWeight.w700, color: Tema.primary, fontSize: 15)),
                ]),
              )),
          ],
        ),
      ),
    );
  }
}

