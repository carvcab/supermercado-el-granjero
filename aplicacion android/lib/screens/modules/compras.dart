import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/firestore_service.dart';
import '../../theme.dart';

class CompScreen extends StatefulWidget {
  const CompScreen({super.key});
  @override
  State<CompScreen> createState() => _CompScreenState();
}

class _CompScreenState extends State<CompScreen> {
  final _searchC = TextEditingController();
  List<Map<dynamic, dynamic>> _compras = [];
  List<Map<dynamic, dynamic>> _proveedores = [];
  List<Map<dynamic, dynamic>> _productos = [];
  String _search = '';
  String _provFiltro = '';
  DateTime? _fDesde;
  DateTime? _fHasta;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _sub = Fb.stream('compras').listen((d) {
      d.sort((a, b) => (b['fecha'] ?? '').toString().compareTo((a['fecha'] ?? '').toString()));
      setState(() => _compras = d.cast<Map<dynamic, dynamic>>());
    });
    Future.wait([Fb.getList('proveedores'), Fb.getList('productos')]).then((res) {
      setState(() {
        _proveedores = (res[0] as List).cast<Map<dynamic, dynamic>>();
        _productos = (res[1] as List).cast<Map<dynamic, dynamic>>();
      });
    });
  }

  int _nextId() {
    if (_compras.isEmpty) return 1;
    return _compras
        .map((x) => x['id'] is int ? x['id'] as int : int.tryParse(x['id'].toString()) ?? 0)
        .reduce((a, b) => a > b ? a : b) + 1;
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString().substring(0, 10));
  }

  String _fmtDate(dynamic v) {
    final d = _parseDate(v);
    if (d == null) return '-';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  num _num(dynamic v) => v is num ? v : num.tryParse(v.toString()) ?? 0;

  String _provNombre(dynamic provId) {
    final pid = provId?.toString() ?? '';
    final p = _proveedores.where((x) => x['id']?.toString() == pid).firstOrNull;
    return p?['nombre']?.toString() ?? provId?.toString() ?? '-';
  }

  List<Map<dynamic, dynamic>> _filtrar() {
    return _compras.where((c) {
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        final fact = (c['numero_factura'] ?? c['factura'] ?? c['id'] ?? '').toString().toLowerCase();
        final provN = ((c['proveedor_nombre'] ?? c['prov_nombre'] ?? '')).toString().toLowerCase();
        if (!fact.contains(q) && !provN.contains(q)) return false;
      }
      if (_provFiltro.isNotEmpty) {
        if ((c['proveedor_id'] ?? c['prov_id'] ?? '').toString() != _provFiltro) return false;
      }
      if (_fDesde != null) {
        final df = _parseDate(c['fecha']);
        if (df != null && df.isBefore(_fDesde!)) return false;
      }
      if (_fHasta != null) {
        final df = _parseDate(c['fecha']);
        if (df != null && df.isAfter(_fHasta!.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)))) return false;
      }
      return true;
    }).toList();
  }

  void _actualizarStats(List<Map<dynamic, dynamic>> filtradas) {
    int pagadas = 0;
    num montoPendientes = 0;
    for (final c in filtradas) {
      if (c['pagado'] == true || c['estado'] == 'Pagada') {
        pagadas++;
      } else {
        montoPendientes += _num(c['total']);
      }
    }
    _stats = {
      'total': filtradas.length,
      'pagadas': pagadas,
      'pendientes': montoPendientes,
    };
  }

  Map<String, dynamic> _stats = {'total': 0, 'pagadas': 0, 'pendientes': 0};

  Future<void> _abrirForm([Map<dynamic, dynamic>? compra]) async {
    final result = await showDialog<Map<dynamic, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _CompraFormModal(
        compra: compra,
        proveedores: _proveedores,
        productos: _productos,
        onProveedorCreado: () => Fb.getList('proveedores').then((p) => setState(() => _proveedores = (p as List).cast<Map<dynamic, dynamic>>())),
      ),
    );
    if (result == null) return;
    final oldComp = compra;
    final bool oldPagado = oldComp != null && (oldComp['pagado'] == true || oldComp['estado'] == 'Pagada');
    final num oldTotal = oldComp != null ? _num(oldComp['total']) : 0;
    
    final bool newPagado = result['pagado'] == true || result['estado'] == 'Pagada';
    final num newTotal = _num(result['total']);

    if (compra != null) {
      final idx = _compras.indexWhere((x) => x['id'] == compra['id']);
      if (idx >= 0) _compras[idx] = result;
    } else {
      result['id'] = _nextId();
      _compras.add(result);
    }
    await Fb.setList('compras', _compras);

    // Update product stock and prices
    try {
      final productos = await Fb.getList('productos');
      
      // If editing, revert old stock first
      if (oldComp != null) {
        final oldItems = (oldComp['items'] as List?) ?? [];
        for (final oldItem in oldItems) {
          final pid = oldItem['producto_id']?.toString();
          final prodIdx = productos.indexWhere((p) => p['id']?.toString() == pid);
          if (prodIdx >= 0) {
            final oldQty = _num(oldItem['cantidad']);
            final currentStock = _num(productos[prodIdx]['stock_actual']);
            productos[prodIdx]['stock_actual'] = (currentStock - oldQty).toInt();
            if ((productos[prodIdx]['stock_actual'] as num) < 0) productos[prodIdx]['stock_actual'] = 0;
          }
        }
      }
      
      // Add new quantities and update prices
      final newItems = (result['items'] as List?) ?? [];
      for (final item in newItems) {
        final pid = item['producto_id']?.toString();
        final prodIdx = productos.indexWhere((p) => p['id']?.toString() == pid);
        if (prodIdx >= 0) {
          final qty = _num(item['cantidad']);
          final currentStock = _num(productos[prodIdx]['stock_actual']);
          productos[prodIdx]['stock_actual'] = (currentStock + qty).toInt();
          productos[prodIdx]['updated_at'] = DateTime.now().toIso8601String();
          
          final precioCosto = _num(item['precio_costo'] ?? item['precio_unitario']);
          if (precioCosto > 0) {
            productos[prodIdx]['precio_compra'] = precioCosto;
          }
          final precioVenta = _num(item['precio_venta']);
          if (precioVenta > 0) {
            productos[prodIdx]['precio_venta'] = precioVenta;
          }
          await Fb.mergeItem('productos', Map<dynamic, dynamic>.from(productos[prodIdx]));
        }
      }
      setState(() => _productos = productos.cast<Map<dynamic, dynamic>>());
    } catch (e) {
      debugPrint('Error updating product stock/prices: $e');
    }

    // Caja Negocio Update
    final int diffBalance;
    if (oldComp == null) {
      // New purchase
      diffBalance = newPagado ? newTotal.toInt() : 0;
    } else {
      // Edited purchase
      if (!oldPagado && newPagado) {
        diffBalance = newTotal.toInt();
      } else if (oldPagado && !newPagado) {
        diffBalance = -oldTotal.toInt();
      } else if (oldPagado && newPagado && newTotal != oldTotal) {
        diffBalance = (newTotal - oldTotal).toInt();
      } else {
        diffBalance = 0;
      }
    }

    if (diffBalance != 0) {
      try {
        final cajaN = await Fb.getDoc('config_caja_negocio');
        cajaN['balance'] = ((cajaN['balance'] ?? 0) as num).toInt() - diffBalance;
        cajaN['balance_al_cierre'] = ((cajaN['balance_al_cierre'] ?? 0) as num).toInt() - diffBalance;
        if (cajaN['balance'] < 0) cajaN['balance'] = 0;
        if (cajaN['balance_al_cierre'] < 0) cajaN['balance_al_cierre'] = 0;
        cajaN['updated_at'] = DateTime.now().toIso8601String();
        await Fb.setDoc('config_caja_negocio', cajaN);
      } catch (e) {
        debugPrint('Error updating config_caja_negocio for purchase: $e');
      }
    }
  }

  Future<void> _pagarCompra(Map<dynamic, dynamic> compra) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tema.radiusLg)),
        insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        title: Text('Marcar como Pagada', style: TextStyle(fontWeight: FontWeight.w700, color: Tema.textDark)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
          child: Text('Marcar esta compra como pagada?\n\nFactura #${compra['numero_factura'] ?? compra['id']}\nMonto: ${Fb.formatMoney(compra['total'] ?? 0)}\n\nSe descontara del saldo de la Caja Negocio.',
          style: TextStyle(color: Tema.textSoft),
        ))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Pagar')),
        ],
      ),
    );
    if (ok != true) return;

    compra['pagado'] = true;
    compra['estado'] = 'Pagada';
    compra['fecha_pago'] = DateTime.now().toIso8601String();

    final int total = _num(compra['total']).toInt();
    try {
      final cajaN = await Fb.getDoc('config_caja_negocio');
      cajaN['balance'] = ((cajaN['balance'] ?? 0) as num).toInt() - total;
      cajaN['balance_al_cierre'] = ((cajaN['balance_al_cierre'] ?? 0) as num).toInt() - total;
      if (cajaN['balance'] < 0) cajaN['balance'] = 0;
      if (cajaN['balance_al_cierre'] < 0) cajaN['balance_al_cierre'] = 0;
      cajaN['updated_at'] = DateTime.now().toIso8601String();
      await Fb.setDoc('config_caja_negocio', cajaN);
    } catch (e) {
      debugPrint('Error updating config_caja_negocio for paid purchase: $e');
    }

    final idx = _compras.indexWhere((x) => x['id'] == compra['id']);
    if (idx >= 0) _compras[idx] = compra;
    await Fb.setList('compras', _compras);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compra marcada como pagada'), backgroundColor: Tema.primary),
      );
    }
  }


  void _verDetalle(Map<dynamic, dynamic> compra) {
    showDialog(
      context: context,
      builder: (ctx) => _CompraDetalleModal(compra: compra, proveedores: _proveedores),
    );
  }

  Future<void> _eliminarCompra(Map<dynamic, dynamic> compra) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tema.radiusLg)),
        title: Text('Eliminar Compra', style: TextStyle(fontWeight: FontWeight.w700, color: Tema.textDark)),
        content: Text('Eliminar compra #${compra['numero_factura'] ?? compra['id']} de ${compra['proveedor_nombre'] ?? '-'}?\nEsta accion no se puede deshacer.',
          style: TextStyle(color: Tema.textSoft),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Eliminar', style: TextStyle(color: Tema.danger))),
        ],
      ),
    );
    if (ok != true) return;
    if (compra['pagado'] == true || compra['estado'] == 'Pagada') {
      try {
        final total = _num(compra['total']).toInt();
        final cajaN = await Fb.getDoc('config_caja_negocio');
        cajaN['balance'] = ((cajaN['balance'] ?? 0) as num).toInt() + total;
        cajaN['balance_al_cierre'] = ((cajaN['balance_al_cierre'] ?? 0) as num).toInt() + total;
        cajaN['updated_at'] = DateTime.now().toIso8601String();
        await Fb.setDoc('config_caja_negocio', cajaN);
      } catch (e) {
        debugPrint('Error restoring config_caja_negocio balance on delete: $e');
      }
    }
    _compras.removeWhere((x) => x['id'] == compra['id']);
    await Fb.setList('compras', _compras);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _searchC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtradas = _filtrar();
    _actualizarStats(filtradas);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirForm(),
        child: Icon(Icons.add),
      ),
      body: Column(children: [
          _buildStatsRow(),
          _buildFilters(),
          _buildSearch(),
          Expanded(child: _buildList(filtradas)),
        ]),
    );
  }

  Widget _buildStatsRow() {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        children: [
          Tema.kpiCard('Total Compras', '${_stats['total']}', Icons.shopping_bag, accent: const Color(0xFF073155)),
          SizedBox(width: 8),
          Tema.kpiCard('Pagadas', '${_stats['pagadas']}', Icons.check_circle, accent: const Color(0xFF1a7a2e)),
          SizedBox(width: 8),
          Tema.kpiCard('Pendientes', Fb.formatMoney(_stats['pendientes']), Icons.pending, accent: const Color(0xFFe65100)),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      padding: EdgeInsets.all(10),
      decoration: Tema.cardDeco,
      child: Wrap(spacing: 8, runSpacing: 6, children: [
        SizedBox(
          width: 140,
          child: _fechaPicker(
            label: 'Desde',
            value: _fDesde,
            onPicked: (d) => setState(() => _fDesde = d),
          ),
        ),
        SizedBox(
          width: 140,
          child: _fechaPicker(
            label: 'Hasta',
            value: _fHasta,
            onPicked: (d) => setState(() => _fHasta = d),
          ),
        ),
        SizedBox(
          width: 150,
          child: DropdownButtonFormField<String>(
            value: _provFiltro.isEmpty ? null : _provFiltro,
            isExpanded: true,
            isDense: true,
            decoration: InputDecoration(
              labelText: 'Proveedor',
              labelStyle: TextStyle(fontSize: 11),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(Tema.radiusSm), borderSide: BorderSide.none),
            ),
            items: [
              const DropdownMenuItem<String>(value: '', child: Text('Todos', style: TextStyle(fontSize: 13))),
              ..._proveedores.map((p) => DropdownMenuItem<String>(
                value: p['id']?.toString() ?? '',
                child: Text(p['nombre']?.toString() ?? '', style: TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
              )),
            ],
            onChanged: (v) => setState(() => _provFiltro = v ?? ''),
          ),
        ),
        if (_fDesde != null || _fHasta != null || _provFiltro.isNotEmpty)
          TextButton.icon(
            onPressed: () => setState(() { _fDesde = null; _fHasta = null; _provFiltro = ''; }),
            icon: Icon(Icons.clear, size: 16),
            label: Text('Limpiar', style: TextStyle(fontSize: 12)),
          ),
      ]),
    );
  }

  Widget _fechaPicker({required String label, required DateTime? value, required ValueChanged<DateTime?> onPicked}) {
    final ctl = TextEditingController(
      text: value != null ? '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}' : '',
    );
    return TextField(
      controller: ctl,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 11),
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        suffixIcon: value != null
            ? IconButton(
                icon: Icon(Icons.clear, size: 16),
                onPressed: () => onPicked(null),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              )
            : Icon(Icons.calendar_today, size: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(Tema.radiusSm), borderSide: BorderSide.none),
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          ctl.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
          onPicked(picked);
        }
      },
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(children: [
        Expanded(
          child: SearchInput(
            controller: _searchC,
            hintText: 'Buscar por factura o proveedor...',
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        if (_search.isNotEmpty)
          IconButton(
            icon: Icon(Icons.clear, size: 18),
            onPressed: () { _searchC.clear(); setState(() => _search = ''); },
          ),
      ]),
    );
  }

  Widget _buildList(List<Map<dynamic, dynamic>> filtradas) {
    if (filtradas.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: 80),
          Icon(Icons.shopping_bag_outlined, color: Tema.textMuted, size: 48),
          SizedBox(height: 12),
          Text('No hay compras registradas', textAlign: TextAlign.center, style: TextStyle(color: Tema.textMuted, fontSize: 15)),
        ],
      );
    }
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      itemCount: filtradas.length,
      itemBuilder: (_, i) => _buildCard(filtradas[i]),
    );
  }

  Widget _buildCard(Map<dynamic, dynamic> compra) {
    final pagado = compra['pagado'] == true || compra['estado'] == 'Pagada';
    final factura = (compra['numero_factura'] ?? compra['factura'] ?? '#${compra['id']}').toString();
    final provNombre = compra['proveedor_nombre']?.toString() ?? _provNombre(compra['proveedor_id'] ?? compra['prov_id']);
    final fecha = _fmtDate(compra['fecha']);
    final total = _num(compra['total']);
    final itemsCount = (compra['items'] as List?)?.length ?? 0;

    return Dismissible(
      key: Key('comp_${compra['id']}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        _eliminarCompra(compra);
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
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(Tema.radius),
          child: InkWell(
            onTap: () => _verDetalle(compra),
            borderRadius: BorderRadius.circular(Tema.radius),
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: pagado ? Tema.primary : const Color(0xFFe65100),
                      borderRadius: BorderRadius.circular(Tema.radiusSm),
                    ),
                    alignment: Alignment.center,
                    child: Icon(pagado ? Icons.check : Icons.pending, color: Colors.white, size: 20),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(
                          child: Text('Factura $factura', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, color: Tema.textDark, fontSize: 15)),
                        ),
                        _badge(pagado ? 'Pagada' : 'Pendiente', pagado ? Tema.primary : const Color(0xFFe65100)),
                      ]),
                      SizedBox(height: 3),
                      Text(provNombre, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: Tema.textSoft)),
                    ]),
                  ),
                ]),
                SizedBox(height: 10),
                Row(children: [
                  _infoChip(Icons.calendar_today, fecha),
                  SizedBox(width: 14),
                  _infoChip(Icons.inventory_2, '$itemsCount items'),
                  const Spacer(),
                  Text(Fb.formatMoney(total), style: TextStyle(fontWeight: FontWeight.w800, color: Tema.primary, fontSize: 17)),
                  if (!pagado) ...[
                    SizedBox(width: 8),
                    SizedBox(
                      height: 32,
                      child: ElevatedButton.icon(
                        onPressed: () => _pagarCompra(compra),
                        icon: Icon(Icons.payment, size: 14),
                        label: Text('Pagar', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1a7a2e),
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tema.radiusSm)),
                        ),
                      ),
                    ),
                  ],
                ]),
              ]),
            ),
          ),
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
      Icon(icon, size: 14, color: Tema.textMuted),
      SizedBox(width: 4),
      Text(text, style: TextStyle(fontSize: 12, color: Tema.textSoft)),
    ]);
  }
}

class _CompraFormModal extends StatefulWidget {
  final Map<dynamic, dynamic>? compra;
  final List<Map<dynamic, dynamic>> proveedores;
  final List<Map<dynamic, dynamic>> productos;
  final VoidCallback onProveedorCreado;

  const _CompraFormModal({
    this.compra,
    required this.proveedores,
    required this.productos,
    required this.onProveedorCreado,
  });

  @override
  State<_CompraFormModal> createState() => _CompraFormModalState();
}

class _CompraFormModalState extends State<_CompraFormModal> {
  final _provC = TextEditingController();
  final _facturaC = TextEditingController();
  final _fechaC = TextEditingController();
  final _descuentoC = TextEditingController();
  final _ivaC = TextEditingController();
  final _searchProdC = TextEditingController();

  DateTime _fecha = DateTime.now();
  List<Map<String, dynamic>> _items = [];
  List<Map<dynamic, dynamic>> _searchResults = [];
  bool _pagado = true;
  bool _isIvaManual = false;

  bool get _isEdit => widget.compra != null;

  num _num(dynamic v) => v is num ? v : num.tryParse(v.toString()) ?? 0;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final c = widget.compra!;
      _provC.text = c['proveedor_nombre']?.toString() ?? '';
      _facturaC.text = (c['numero_factura'] ?? c['factura'] ?? '').toString();
      _fecha = DateTime.tryParse((c['fecha'] ?? '').toString()) ?? DateTime.now();
      _fechaC.text = _fecha.toIso8601String().substring(0, 10);
      _descuentoC.text = (_num(c['descuento'])).toString();
      _ivaC.text = (_num(c['iva'])).toString();
      _isIvaManual = true;
      _pagado = c['pagado'] == true || c['estado'] == 'Pagada';
      final items = c['items'] as List? ?? [];
      _items = items.map((x) => Map<String, dynamic>.from(x as Map)).toList();
    } else {
      _fechaC.text = DateTime.now().toIso8601String().substring(0, 10);
      _ivaC.text = '0';
      _isIvaManual = false;
    }
  }

  void _recalcIva() {
    if (!_isIvaManual) {
      _ivaC.text = (_base * 0.19).round().toString();
    }
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _recalcIva();
  }

  @override
  void dispose() {
    _provC.dispose();
    _facturaC.dispose();
    _fechaC.dispose();
    _descuentoC.dispose();
    _ivaC.dispose();
    _searchProdC.dispose();
    super.dispose();
  }

  num get _subtotal => _items.fold<num>(0, (s, i) => s + _num(i['cantidad']) * _num(i['precio_unitario']));
  num get _descuento => num.tryParse(_descuentoC.text) ?? 0;
  num get _base => _subtotal - _descuento;
  num get _iva => num.tryParse(_ivaC.text) ?? 0;
  num get _total => _base + _iva;

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

  void _mostrarScannerCompra() {
    showDialog(
      context: context,
      builder: (ctx) => _ScannerInvDialog(
        onScan: (barcode) {
          if (!mounted) return;
          final matches = widget.productos.where((p) {
            final cod = (p['codigo'] ?? '').toString();
            final cb = (p['codigo_barras'] ?? '').toString();
            return cod == barcode || cb == barcode;
          }).toList();
          if (matches.isNotEmpty) {
            _agregarItem(matches.first);
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Producto no encontrado: $barcode')),
            );
          }
        },
      ),
    );
  }

  void _agregarItem(Map<dynamic, dynamic> prod, {double cantidad = 1, double? precio}) {
    final pid = prod['id']?.toString();
    final precioUnit = precio ?? _num(prod['precio_compra']).toDouble();
    final idx = _items.indexWhere((x) => x['producto_id']?.toString() == pid);
    if (idx >= 0) {
      final old = _num(_items[idx]['cantidad']).toDouble();
      _items[idx]['cantidad'] = old + cantidad;
      _items[idx]['precio_unitario'] = precioUnit;
      _items[idx]['subtotal'] = (old + cantidad) * precioUnit;
    } else {
      _items.add({
        'producto_id': prod['id'],
        'nombre': prod['nombre']?.toString() ?? '',
        'cantidad': cantidad,
        'precio_unitario': precioUnit,
        'subtotal': cantidad * precioUnit,
      });
    }
    setState(() {
      _searchResults = [];
      _searchProdC.clear();
    });
  }

  void _removeItem(int idx) {
    _items.removeAt(idx);
    setState(() {});
  }

  void _updateItemCantidad(int idx, double delta) {
    final cant = _num(_items[idx]['cantidad']).toDouble() + delta;
    if (cant <= 0) {
      _items.removeAt(idx);
    } else {
      _items[idx]['cantidad'] = cant;
      _items[idx]['subtotal'] = cant * _num(_items[idx]['precio_unitario']).toDouble();
    }
    setState(() {});
  }

  void _updateItemPrecio(int idx, double precio) {
    _items[idx]['precio_unitario'] = precio;
    _items[idx]['subtotal'] = _num(_items[idx]['cantidad']).toDouble() * precio;
    setState(() {});
  }

  Future<void> _pickFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _fecha = picked;
        _fechaC.text = picked.toIso8601String().substring(0, 10);
      });
    }
  }

  Future<void> _agregarProveedorRapido() async {
    final nombre = _provC.text.trim();
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
    final provNombre = _provC.text.trim();
    if (provNombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seleccione o escriba un proveedor')));
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agregue al menos un producto')));
      return;
    }

    dynamic proveedorId;
    final match = widget.proveedores.where((p) => (p['nombre'] ?? '').toString().toLowerCase() == provNombre.toLowerCase()).firstOrNull;
    if (match != null) {
      proveedorId = match['id'];
    }

    final data = <dynamic, dynamic>{
      'proveedor_nombre': provNombre,
      'proveedor_id': proveedorId,
      'numero_factura': _facturaC.text.trim(),
      'factura': _facturaC.text.trim(),
      'fecha': _fechaC.text,
      'items': _items.map((i) => {
        'producto_id': i['producto_id'],
        'nombre': i['nombre'],
        'cantidad': i['cantidad'],
        'precio_unitario': i['precio_unitario'],
        'precio_costo': i['precio_unitario'],
        'subtotal': i['subtotal'],
      }).toList(),
      'subtotal': _subtotal.toDouble(),
      'descuento': _descuento.toDouble(),
      'iva': _iva.toDouble(),
      'total': _total.toDouble(),
      'pagado': _pagado,
      'estado': _pagado ? 'Pagada' : 'Pendiente',
    };

    if (_fechaC.text.isEmpty) {
      data['fecha'] = DateTime.now().toIso8601String().substring(0, 10);
    }
    if (_pagado) {
      data['fecha_pago'] = DateTime.now().toIso8601String().substring(0, 10);
    }
    if (_isEdit) {
      data['id'] = widget.compra!['id'];
    }

    Navigator.pop(context, data);
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
                  Icon(Icons.shopping_bag, color: Colors.white.withValues(alpha: 0.8), size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(editing ? 'Editar Compra' : 'Nueva Compra',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
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
                    _buildProveedorField(),
                    SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                        flex: 2,
                        child: _buildFechaField(),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _facturaC,
                          decoration: const InputDecoration(labelText: 'N Factura', hintText: 'Numero de factura'),
                        ),
                      ),
                    ]),
                    SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_pagado ? 'Pagada' : 'Pendiente', style: TextStyle(fontWeight: FontWeight.w600, color: _pagado ? const Color(0xFF1a7a2e) : const Color(0xFFe65100))),
                      value: _pagado,
                      activeColor: const Color(0xFF1a7a2e),
                      onChanged: (v) => setState(() => _pagado = v),
                    ),
                    const Divider(height: 8),
                    _buildProductSearch(),
                    SizedBox(height: 10),
                    _buildItemsTable(),
                    SizedBox(height: 10),
                    _buildTotales(),
                  ]),
                ),
              ),
              Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), offset: const Offset(0, -2), blurRadius: 10)],
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

  Widget _buildProveedorField() {
    return Row(children: [
      Expanded(
        child: Autocomplete<String>(
          optionsBuilder: (v) {
            if (v.text.isEmpty) return widget.proveedores.map((p) => p['nombre']?.toString() ?? '');
            final q = v.text.toLowerCase();
            return widget.proveedores.where((p) => (p['nombre'] ?? '').toString().toLowerCase().contains(q)).map((p) => p['nombre']?.toString() ?? '');
          },
          onSelected: (v) => _provC.text = v,
          fieldViewBuilder: (ctx, ctl, node, _) => TextField(
            controller: _provC,
            focusNode: node,
            decoration: const InputDecoration(labelText: 'Proveedor', hintText: 'Buscar o escribir...'),
            onChanged: (_) => ctl.text = _provC.text,
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

  Widget _buildFechaField() {
    return TextField(
      controller: _fechaC,
      readOnly: true,
      decoration: InputDecoration(
        labelText: 'Fecha',
        suffixIcon: IconButton(
          icon: Icon(Icons.calendar_today, size: 18),
          onPressed: _pickFecha,
        ),
      ),
      onTap: _pickFecha,
    );
  }

  Widget _buildProductSearch() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Tema.radius),
        border: Border.all(color: const Color(0xFF1a7a2e), width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.search, size: 18, color: Tema.primary.withValues(alpha: 0.7)),
          SizedBox(width: 6),
          Text('Buscar Producto', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Tema.textDark)),
        ]),
        SizedBox(height: 8),
        Row(children: [
          IconButton(
            icon: Icon(Icons.qr_code_scanner, color: Tema.primary),
            onPressed: _mostrarScannerCompra,
            tooltip: 'Escanear codigo de barras',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          Expanded(
            child: TextField(
              controller: _searchProdC,
              decoration: const InputDecoration(
                hintText: 'Buscar por codigo o nombre...',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: _buscarProducto,
            ),
          ),
        ]),
        if (_searchResults.isNotEmpty) ...[
          SizedBox(height: 8),
          ..._searchResults.map((prod) {
            final stock = prod['stock_actual'] ?? prod['stock'] ?? 0;
            final precioAnt = _num(prod['precio_compra']).toDouble();
            double cant = 1;
            double precioCampo = precioAnt;

            return StatefulBuilder(
              builder: (ctx, setSt) => Container(
                margin: EdgeInsets.only(bottom: 6),
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Tema.bg,
                  borderRadius: BorderRadius.circular(Tema.radiusSm),
                  border: Border.all(color: Tema.cardBorder),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(prod['nombre']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Tema.textDark)),
                        Text('Cod: ${prod['codigo'] ?? '-'} | Stock: $stock', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Tema.textSoft)),
                      ]),
                    ),
                    Icon(Icons.chevron_right, size: 16, color: Tema.textMuted.withValues(alpha: 0.5)),
                  ]),
                  SizedBox(height: 8),
                  Text('Precio compra anterior: ${Fb.formatMoney(precioAnt)}', style: TextStyle(fontSize: 10, color: Tema.textMuted)),
                  SizedBox(height: 4),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Cantidad',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => setSt(() => cant = double.tryParse(v) ?? 1),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Precio Costo',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        keyboardType: TextInputType.number,
                        controller: TextEditingController(text: precioAnt > 0 ? '$precioAnt' : ''),
                        onChanged: (v) => setSt(() => precioCampo = double.tryParse(v) ?? 0),
                      ),
                    ),
                  ]),
                  SizedBox(height: 6),
                  Row(children: [
                    Text('Subtotal: ${Fb.formatMoney(cant * precioCampo)}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Tema.primary)),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () => _agregarItem(prod, cantidad: cant, precio: precioCampo),
                      icon: Icon(Icons.add, size: 14),
                      label: Text('Agregar', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        textStyle: TextStyle(fontSize: 12),
                      ),
                    ),
                  ]),
                ]),
              ),
            );
          }),
        ],
      ]),
    );
  }

  Widget _buildItemsTable() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Tema.radius),
        border: Border.all(color: const Color(0xFF073155), width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.list_alt, size: 18, color: Tema.textDark),
          SizedBox(width: 6),
          Text('Items de la Compra', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Tema.textDark)),
          const Spacer(),
          Text('${_items.length} items', style: TextStyle(fontSize: 12, color: Tema.textSoft)),
        ]),
        if (_items.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text('No hay items agregados', style: TextStyle(color: Tema.textMuted, fontSize: 13))),
          )
        else ...[
          SizedBox(height: 8),
          ...List.generate(_items.length, (idx) {
            final item = _items[idx];
            final nombre = item['nombre']?.toString() ?? '';
            final cantidad = _num(item['cantidad']).toDouble();
            final precio = _num(item['precio_unitario']).toDouble();
            final subtotal = cantidad * precio;

            return Dismissible(
              key: Key('item_${item['producto_id']}_$idx'),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => _removeItem(idx),
              background: Container(
                alignment: Alignment.centerRight,
                padding: EdgeInsets.only(right: 16),
                margin: EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(color: Tema.danger, borderRadius: BorderRadius.circular(Tema.radiusSm)),
                child: Icon(Icons.delete, color: Colors.white, size: 20),
              ),
              child: Container(
                margin: EdgeInsets.symmetric(vertical: 2),
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Tema.bg,
                  borderRadius: BorderRadius.circular(Tema.radiusSm),
                  border: Border.all(color: Tema.cardBorder),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                  Expanded(
                    child: Text(nombre, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Tema.textDark)),
                  ),
                    GestureDetector(
                      onTap: () => _removeItem(idx),
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Tema.danger.withValues(alpha: 0.1)),
                        child: Icon(Icons.close, size: 14, color: Tema.danger),
                      ),
                    ),
                  ]),
                  SizedBox(height: 6),
                  Row(children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Tema.cardBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Tema.cardBorder),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        InkWell(
                          onTap: () => _updateItemCantidad(idx, -1),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(padding: EdgeInsets.all(5), child: Icon(Icons.remove, size: 16, color: Tema.textDark)),
                        ),
                        SizedBox(
                          width: 36,
                          child: TextField(
                            textAlign: TextAlign.center,
                            controller: TextEditingController(text: '$cantidad'),
                            keyboardType: TextInputType.number,
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                            ),
                            onChanged: (v) {
                              final c = double.tryParse(v) ?? 0;
                              _items[idx]['cantidad'] = c;
                              _items[idx]['subtotal'] = c * _num(_items[idx]['precio_unitario']).toDouble();
                              setState(() {});
                            },
                          ),
                        ),
                        InkWell(
                          onTap: () => _updateItemCantidad(idx, 1),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(padding: EdgeInsets.all(5), child: Icon(Icons.add, size: 16, color: Tema.textDark)),
                        ),
                      ]),
                    ),
                    SizedBox(width: 10),
                    SizedBox(
                      width: 90,
                      child: TextField(
                        controller: TextEditingController(text: '$precio'),
                        keyboardType: TextInputType.number,
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                        decoration: const InputDecoration(
                          prefixText: '\$ ',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        ),
                        onChanged: (v) => _updateItemPrecio(idx, double.tryParse(v) ?? 0),
                      ),
                    ),
                    const Spacer(),
                    Text(Fb.formatMoney(subtotal), style: TextStyle(fontWeight: FontWeight.w800, color: Tema.primary, fontSize: 15)),
                  ]),
                ]),
              ),
            );
          }),
        ],
      ]),
    );
  }

  Widget _buildTotales() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Tema.radius),
        border: Border.all(color: Tema.cardBorder),
      ),
      child: Column(children: [
        Row(children: [
          Text('Subtotal: ${Fb.formatMoney(_subtotal)}', style: TextStyle(fontSize: 13, color: Tema.textSoft)),
          const Spacer(),
          Text('Descuento: ${Fb.formatMoney(_descuento)}', style: TextStyle(fontSize: 13, color: Tema.textSoft)),
        ]),
        SizedBox(height: 4),
        Row(children: [
          Text(_isIvaManual ? 'IVA: ${Fb.formatMoney(_iva)}' : 'IVA (19%): ${Fb.formatMoney(_iva)}', style: TextStyle(fontSize: 13, color: Tema.textSoft)),
          const Spacer(),
          Text('Total: ${Fb.formatMoney(_total)}', style: TextStyle(fontWeight: FontWeight.w800, color: Tema.primary, fontSize: 18)),
        ]),
        SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _descuentoC,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Descuento',
                prefixText: '\$ ',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _ivaC,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'IVA',
                prefixText: '\$ ',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onChanged: (val) {
                setState(() {
                  if (val.trim().isEmpty) {
                    _isIvaManual = false;
                  } else {
                    _isIvaManual = true;
                  }
                });
              },
            ),
          ),
        ]),
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
      title: Text('Nuevo Proveedor: ${widget.nombre}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, color: Tema.textDark)),
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
        ElevatedButton(onPressed: _guardar, child: const FittedBox(fit: BoxFit.scaleDown, child: Text('Guardar Proveedor'))),
      ],
    );
  }
}

class _CompraDetalleModal extends StatelessWidget {
  final Map<dynamic, dynamic> compra;
  final List<Map<dynamic, dynamic>> proveedores;

  const _CompraDetalleModal({required this.compra, required this.proveedores});

  num _num(dynamic v) => v is num ? v : num.tryParse(v.toString()) ?? 0;
  String _fmt(dynamic v) => Fb.formatMoney(_num(v));

  String _fmtDate(dynamic v) {
    final d = DateTime.tryParse(v.toString().substring(0, 10));
    if (d == null) return '-';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final pagado = compra['pagado'] == true || compra['estado'] == 'Pagada';
    final factura = (compra['numero_factura'] ?? compra['factura'] ?? '#${compra['id']}').toString();
    final provNombre = compra['proveedor_nombre']?.toString() ?? '-';
    final fecha = _fmtDate(compra['fecha']);
    final items = (compra['items'] as List?) ?? [];
    final subtotal = _num(compra['subtotal']);
    final iva = _num(compra['iva']);
    final descuento = _num(compra['descuento']);
    final total = _num(compra['total']);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tema.radiusLg)),
      insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxWidth: 500, maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(Tema.radiusLg),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: EdgeInsets.fromLTRB(20, 16, 8, 12),
            decoration: const BoxDecoration(
              color: Tema.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(Tema.radiusLg)),
            ),
            child: Row(children: [
              Icon(Icons.receipt_long, color: Colors.white.withValues(alpha: 0.8), size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text('Detalle de Compra', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: Colors.white, size: 22),
              ),
            ]),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Tema.bg,
                    borderRadius: BorderRadius.circular(Tema.radius),
                    border: Border.all(color: Tema.cardBorder),
                  ),
                  child: Row(children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: pagado ? Tema.primary : const Color(0xFFe65100),
                        borderRadius: BorderRadius.circular(Tema.radiusSm),
                      ),
                      alignment: Alignment.center,
                      child: Icon(pagado ? Icons.check : Icons.pending, color: Colors.white, size: 24),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Factura $factura', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Tema.textDark)),
                        SizedBox(height: 2),
                        Text('$provNombre | $fecha', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Tema.textSoft)),
                      ]),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (pagado ? Tema.primary : const Color(0xFFe65100)).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(pagado ? 'Pagada' : 'Pendiente',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: pagado ? Tema.primary : const Color(0xFFe65100)),
                      ),
                    ),
                  ]),
                ),
                SizedBox(height: 14),
                Row(children: [
                  _miniStat('Subtotal', _fmt(subtotal), Tema.textSoft),
                  _miniStat('IVA (19%)', _fmt(iva), Tema.textSoft),
                  if (descuento > 0) _miniStat('Desc.', _fmt(descuento), Tema.danger),
                  _miniStat('Total', _fmt(total), Tema.primary),
                ].expand((w) => [w, SizedBox(width: 8)]).toList()..removeLast()),
                SizedBox(height: 16),
                Text('Productos', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Tema.textDark)),
                SizedBox(height: 8),
                if (items.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Sin productos', style: TextStyle(color: Tema.textMuted)),
                  )
                else ...[
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Tema.radiusSm),
                      border: Border.all(color: Tema.cardBorder),
                    ),
                    child: Column(children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Tema.bg,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(Tema.radiusSm - 1)),
                        ),
                        child: Row(children: [
                          Expanded(flex: 4, child: Text('Producto', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Tema.textSoft))),
                          Expanded(flex: 1, child: Text('Cant.', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Tema.textSoft), textAlign: TextAlign.center)),
                          Expanded(flex: 2, child: Text('P. Unit.', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Tema.textSoft), textAlign: TextAlign.right)),
                          Expanded(flex: 2, child: Text('Subtotal', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Tema.textSoft), textAlign: TextAlign.right)),
                        ]),
                      ),
                      ...(items.map((item) {
                        final nom = item['nombre']?.toString() ?? '-';
                        final cant = _num(item['cantidad']);
                        final pu = _num(item['precio_unitario'] ?? item['precio_costo'] ?? item['precio_compra']);
                        final sub = cant * pu;
                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(border: Border(top: BorderSide(color: Tema.cardBorder.withValues(alpha: 0.5)))),
                          child: Row(children: [
                            Expanded(flex: 4, child: Text(nom, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Tema.textDark))),
                            Expanded(flex: 1, child: Text('$cant', style: TextStyle(fontSize: 12, color: Tema.textDark), textAlign: TextAlign.center)),
                            Expanded(flex: 2, child: Text(_fmt(pu), style: TextStyle(fontSize: 12, color: Tema.textSoft), textAlign: TextAlign.right)),
                            Expanded(flex: 2, child: Text(_fmt(sub), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Tema.primary), textAlign: TextAlign.right)),
                          ]),
                        );
                      })),
                    ]),
                  ),
                ],
              ]),
            ),
          ),
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), offset: const Offset(0, -2), blurRadius: 10)],
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(Tema.radiusLg)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cerrar'),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Tema.bg,
          borderRadius: BorderRadius.circular(Tema.radiusSm),
          border: Border.all(color: Tema.cardBorder),
        ),
        child: Column(children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Tema.textMuted)),
          SizedBox(height: 2),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
        ]),
      ),
    );
  }
}

class _ScannerInvDialog extends StatefulWidget {
  final void Function(String barcode) onScan;
  const _ScannerInvDialog({required this.onScan});
  @override
  State<_ScannerInvDialog> createState() => _ScannerInvDialogState();
}

class _ScannerInvDialogState extends State<_ScannerInvDialog> {
  final _controller = MobileScannerController();
  bool _scanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(16),
      child: Container(
        width: w * 0.9,
        height: h * 0.28,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(Tema.radiusLg),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            MobileScanner(
              controller: _controller,
              onDetect: (BarcodeCapture capture) {
                if (_scanned) return;
                final barcode = capture.barcodes.first.rawValue;
                if (barcode != null) {
                  setState(() {
                    _scanned = true;
                  });
                  try {
                    _controller.stop();
                  } catch (_) {}
                  widget.onScan(barcode);
                  Navigator.pop(context, barcode);
                }
              },
            ),
            Center(
              child: Container(
                width: w * 0.55,
                height: h * 0.22,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.greenAccent, width: 2.5),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white, size: 24),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              bottom: 6,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                  child: Text('Escanear codigo de barras', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
