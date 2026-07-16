import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/firestore_service.dart';
import '../../theme.dart';

class ConsScreen extends StatefulWidget {
  const ConsScreen({super.key});
  @override
  State<ConsScreen> createState() => _ConsScreenState();
}

class _ConsScreenState extends State<ConsScreen> {
  final _searchC = TextEditingController();
  List<Map<dynamic, dynamic>> _consumos = [];
  List<Map<dynamic, dynamic>> _productos = [];
  String _search = '';
  StreamSubscription? _subCons;
  StreamSubscription? _subProd;

  @override
  void initState() {
    super.initState();
    _subCons = Fb.stream('autoconsumos').listen((d) {
      d.sort((a, b) => (b['fecha'] ?? '').toString().compareTo((a['fecha'] ?? '').toString()));
      setState(() => _consumos = d.cast<Map<dynamic, dynamic>>());
    });
    _subProd = Fb.stream('productos').listen((d) {
      setState(() => _productos = d.cast<Map<dynamic, dynamic>>());
    });
  }

  @override
  void dispose() {
    _subCons?.cancel();
    _subProd?.cancel();
    _searchC.dispose();
    super.dispose();
  }

  int _nextId() {
    if (_consumos.isEmpty) return 1;
    return _consumos
        .map((x) => x['id'] is int ? x['id'] as int : int.tryParse(x['id'].toString()) ?? 0)
        .reduce((a, b) => a > b ? a : b) + 1;
  }

  num _num(dynamic v) => v is num ? v : num.tryParse(v.toString()) ?? 0;

  num _getProductCost(Map<dynamic, dynamic> consumo) {
    final pid = (consumo['producto_id'] ?? '').toString();
    final prod = _productos.where((p) => p['id']?.toString() == pid).firstOrNull;
    return _num(prod?['precio_compra'] ?? 0);
  }

  void _verDetalle(Map<dynamic, dynamic> consumo) {
    final nombre = consumo['producto_nombre']?.toString() ?? '-';
    final cantidad = _num(consumo['cantidad']).toInt();
    final fecha = _fmtDate(consumo['fecha']);
    final motivo = consumo['motivo']?.toString() ?? '';
    final costoUnitario = _getProductCost(consumo);
    final costoTotal = costoUnitario * cantidad;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Tema.radiusLg))),
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(Tema.radiusLg)),
        ),
        padding: EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Tema.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: Tema.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(Tema.radiusSm),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.person_off, color: Tema.primary, size: 22),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(nombre, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Tema.textDark)),
                  Text('$cantidad und  •  $fecha', style: TextStyle(fontSize: 13, color: Tema.textSoft)),
                ]),
              ),
            ]),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Tema.bg,
                borderRadius: BorderRadius.circular(Tema.radiusSm),
                border: Border.all(color: Tema.cardBorder),
              ),
              child: Column(children: [
                _infoRow('Producto', nombre),
                _infoRow('Cantidad', '$cantidad unidades'),
                _infoRow('Fecha', fecha),
                _infoRow('Costo Unitario', Fb.formatMoney(costoUnitario)),
                _infoRow('Costo Total', Fb.formatMoney(costoTotal)),
                if (motivo.isNotEmpty) _infoRow('Motivo', motivo),
              ]),
            ),
            SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _abrirForm(consumo);
                  },
                  icon: Icon(Icons.edit, size: 18),
                  label: Text('Editar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Tema.primary,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tema.radiusSm)),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: ctx,
                      builder: (dCtx) => AlertDialog(
                        title: Text('Eliminar Consumo', style: TextStyle(fontWeight: FontWeight.w700)),
                        content: Text('Eliminar consumo de "$nombre"?\n\nSe restauraran $cantidad unidades al stock.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(dCtx, false), child: Text('Cancelar')),
                          TextButton(onPressed: () => Navigator.pop(dCtx, true), child: Text('Eliminar', style: TextStyle(color: Tema.danger))),
                        ],
                      ),
                    );
                    if (confirm == true && ctx.mounted) {
                      Navigator.pop(ctx);
                      _eliminar(consumo);
                    }
                  },
                  icon: Icon(Icons.delete_outline, size: 18),
                  label: Text('Eliminar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Tema.danger,
                    side: const BorderSide(color: Tema.danger),
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tema.radiusSm)),
                  ),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 120,
          child: Text('$label:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Tema.textSoft)),
        ),
        Expanded(
          child: Text(value, style: TextStyle(fontSize: 13, color: Tema.textDark)),
        ),
      ]),
    );
  }

  String _fmtDate(dynamic v) {
    final d = DateTime.tryParse((v ?? '').toString().substring(0, 10));
    if (d == null) return '-';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  List<Map<dynamic, dynamic>> _filtrar() {
    if (_search.isEmpty) return _consumos;
    final q = _search.toLowerCase();
    return _consumos.where((c) {
      final nom = (c['producto_nombre'] ?? '').toString().toLowerCase();
      final mot = (c['motivo'] ?? '').toString().toLowerCase();
      return nom.contains(q) || mot.contains(q);
    }).toList();
  }

  Future<void> _abrirForm([Map<dynamic, dynamic>? consumo]) async {
    final edit = consumo != null;
    final prodSearchC = TextEditingController(
      text: edit ? (consumo['producto_nombre'] ?? '').toString() : '',
    );
    final cantC = TextEditingController(
      text: edit ? _num(consumo['cantidad']).toString() : '1',
    );
    final fechaC = TextEditingController(
      text: edit ? (consumo['fecha'] ?? '').toString() : DateTime.now().toIso8601String().substring(0, 10),
    );
    final motivoC = TextEditingController(
      text: edit ? (consumo['motivo'] ?? '').toString() : '',
    );

    DateTime fecha = DateTime.tryParse(fechaC.text) ?? DateTime.now();
    Map<dynamic, dynamic>? selectedProduct;
    List<Map<dynamic, dynamic>> searchResults = [];

    if (edit) {
      final pid = (consumo['producto_id'] ?? '').toString();
      selectedProduct = _productos.where((p) => p['id']?.toString() == pid).firstOrNull;
    }

    void buscarProducto(String term) {
      if (term.isEmpty) {
        searchResults = [];
      } else {
        final q = term.toLowerCase();
        searchResults = _productos.where((p) {
          final nom = (p['nombre'] ?? '').toString().toLowerCase();
          final cod = (p['codigo'] ?? '').toString().toLowerCase();
          return nom.contains(q) || cod.contains(q);
        }).toList();
      }
    }

    void mostrarScannerConsumo(StateSetter setSt) {
      showDialog(
        context: context,
        builder: (ctx) => _ScannerInvDialog(
          onScan: (barcode) {
            final match = _productos.where((p) {
              final cod = (p['codigo'] ?? '').toString();
              final cb = (p['codigo_barras'] ?? '').toString();
              return cod == barcode || cb == barcode;
            }).firstOrNull;
            if (match != null) {
              setSt(() {
                selectedProduct = match;
                prodSearchC.text = (match['nombre'] ?? '').toString();
                searchResults = [];
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Producto no encontrado')),
              );
            }
          },
        ),
      );
    }

    await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Row(children: [
            Expanded(child: Text(edit ? 'Editar Consumo' : 'Nuevo Consumo Propio',
                style: TextStyle(color: Tema.textDark, fontWeight: FontWeight.w700))),
            IconButton(
              icon: Icon(Icons.close, size: 20, color: Tema.textMuted),
              onPressed: () => Navigator.pop(ctx, false),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ]),
          insetPadding: EdgeInsets.fromLTRB(12, 16, 12, MediaQuery.of(ctx).viewInsets.bottom + 16),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      IconButton(
                        icon: Icon(Icons.qr_code_scanner, color: Tema.primary),
                        onPressed: () => mostrarScannerConsumo(setSt),
                        tooltip: 'Escanear codigo de barras',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      ),
                      Expanded(
                        child: TextField(
                          controller: prodSearchC,
                          decoration: const InputDecoration(
                            labelText: 'Producto *',
                            hintText: 'Buscar producto...',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          onChanged: (v) {
                            setSt(() {
                              selectedProduct = null;
                              buscarProducto(v);
                            });
                          },
                        ),
                      ),
                    ]),
                    if (selectedProduct != null) ...[
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Tema.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Tema.primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(children: [
                          Icon(Icons.check_circle, size: 18, color: Tema.primary),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${selectedProduct!['nombre']} (${selectedProduct!['codigo'] ?? '-'})',
                              style: TextStyle(fontWeight: FontWeight.w600, color: Tema.primary),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setSt(() {
                              selectedProduct = null;
                              prodSearchC.clear();
                            }),
                            child: Icon(Icons.close, size: 18, color: Tema.textMuted),
                          ),
                        ]),
                      ),
                    ],
                    if (selectedProduct == null && searchResults.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Tema.cardBorder),
                        ),
                        child: ListView(
                          shrinkWrap: true,
                          children: searchResults.take(20).map((p) => ListTile(
                            dense: true,
                            title: Text(p['nombre'] ?? '', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            subtitle: Text('${p['codigo'] ?? '-'} | Stock: ${_num(p['stock_actual'])}', style: TextStyle(fontSize: 10)),
                            onTap: () => setSt(() {
                              selectedProduct = p;
                              prodSearchC.text = p['nombre'] ?? '';
                              searchResults = [];
                            }),
                          )).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _fld('Cantidad', cantC, num: true),
              Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: fechaC,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Fecha',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.calendar_today, size: 18),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: fecha,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setSt(() {
                            fecha = picked;
                            fechaC.text = picked.toIso8601String().substring(0, 10);
                          });
                        }
                      },
                    ),
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: fecha,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setSt(() {
                        fecha = picked;
                        fechaC.text = picked.toIso8601String().substring(0, 10);
                      });
                    }
                  },
                ),
              ),
              _fld('Motivo', motivoC),
            ]))),
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
                    onPressed: () async {
                      if (selectedProduct == null) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Seleccione un producto')),
                        );
                        return;
                      }
                      final cant = int.tryParse(cantC.text);
                      if (cant == null || cant <= 0) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Ingrese una cantidad valida')),
                        );
                        return;
                      }
                      final currentStock = _num(selectedProduct!['stock_actual']).toInt();

                      // If new: deduct stock
                      // If edit: reverse old stock, apply new deduction
                      int oldQty = 0;
                      String oldProductId = '';
                      if (edit) {
                        oldQty = _num(consumo!['cantidad']).toInt();
                        oldProductId = (consumo['producto_id'] ?? '').toString();
                        // Reverse old deduction
                        if (oldProductId.isNotEmpty) {
                          final oldProdIdx = _productos.indexWhere((p) => p['id']?.toString() == oldProductId);
                          if (oldProdIdx >= 0) {
                            _productos[oldProdIdx]['stock_actual'] = _num(_productos[oldProdIdx]['stock_actual']).toInt() + oldQty;
                            _productos[oldProdIdx]['updated_at'] = DateTime.now().toIso8601String();
                          }
                        }
                      }

                      // Check stock for new deduction
                      final newProductId = selectedProduct!['id']?.toString();
                      final prodIdx = _productos.indexWhere((p) => p['id']?.toString() == newProductId);
                      int newStock = currentStock;
                      if (prodIdx >= 0) {
                        // If same product, stock was already restored above
                        if (edit && oldProductId == newProductId) {
                          newStock = _num(_productos[prodIdx]['stock_actual']).toInt();
                        }
                        if (newStock < cant) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('Stock insuficiente. Disponible: $newStock')),
                          );
                          // Revert the old stock restore if we're aborting
                          if (edit && oldProductId.isNotEmpty) {
                            final oldIdx = _productos.indexWhere((p) => p['id']?.toString() == oldProductId);
                            if (oldIdx >= 0) {
                              _productos[oldIdx]['stock_actual'] = _num(_productos[oldIdx]['stock_actual']).toInt() - oldQty;
                            }
                          }
                          return;
                        }
                      }

                      // Apply new deduction
                      if (prodIdx >= 0) {
                        final st = _num(_productos[prodIdx]['stock_actual']).toInt();
                        _productos[prodIdx]['stock_actual'] = st - cant;
                        _productos[prodIdx]['updated_at'] = DateTime.now().toIso8601String();
                      }

                      final now = DateTime.now().toIso8601String();
                      final data = <dynamic, dynamic>{
                        'producto_id': selectedProduct!['id'],
                        'producto_nombre': selectedProduct!['nombre'] ?? '',
                        'cantidad': cant,
                        'fecha': fechaC.text,
                        'motivo': motivoC.text.trim(),
                        'updated_at': now,
                      };

                      if (edit) {
                        data['id'] = consumo!['id'];
                        data['created_at'] = consumo['created_at'] ?? now;
                      } else {
                        data['id'] = _nextId();
                        data['created_at'] = now;
                      }

                      final merged = await Fb.mergeItem('autoconsumos', data);
                      if (merged.isNotEmpty) {
                        _consumos = merged;
                      }

                      // Save product stock changes
                      if (prodIdx >= 0) {
                        await Fb.mergeItem('productos', Map<dynamic, dynamic>.from(_productos[prodIdx]));
                      }
                      // If editing and product changed, save old product stock
                      if (edit && oldProductId.isNotEmpty && oldProductId != newProductId) {
                        final oldIdx = _productos.indexWhere((p) => p['id']?.toString() == oldProductId);
                        if (oldIdx >= 0) {
                          await Fb.mergeItem('productos', Map<dynamic, dynamic>.from(_productos[oldIdx]));
                        }
                      }

                      if (mounted) setState(() {});
                      if (ctx.mounted) Navigator.pop(ctx, true);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Tema.primary,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Tema.radiusSm),
                      ),
                    ),
                    child: Text(edit ? 'Actualizar' : 'Guardar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _eliminar(Map<dynamic, dynamic> consumo) async {
    final cant = _num(consumo['cantidad']).toInt();
    final pid = (consumo['producto_id'] ?? '').toString();

    // Restore stock
    if (pid.isNotEmpty) {
      final idx = _productos.indexWhere((p) => p['id']?.toString() == pid);
      if (idx >= 0) {
        final st = _num(_productos[idx]['stock_actual']).toInt();
        _productos[idx]['stock_actual'] = st + cant;
        _productos[idx]['updated_at'] = DateTime.now().toIso8601String();
        await Fb.mergeItem('productos', Map<dynamic, dynamic>.from(_productos[idx]));
      }
    }

    final merged = await Fb.mergeItem('autoconsumos', {}, isDelete: true, deleteId: consumo['id']);
    if (merged.isNotEmpty) {
      _consumos = merged;
      if (mounted) setState(() {});
    }
  }

  Widget _fld(String l, TextEditingController c, {bool num = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: c,
        keyboardType: num ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: l,
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtradas = _filtrar();
    int totalCant = 0;
    for (final c in _consumos) {
      totalCant += _num(c['cantidad']).toInt();
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirForm(),
        child: Icon(Icons.add),
      ),
      body: Column(children: [
        _buildStatsRow(totalCant),
        _buildSearch(),
        Expanded(child: _buildList(filtradas)),
      ]),
    );
  }

  Widget _buildStatsRow(int totalCant) {
    num costoTotal = 0;
    for (final c in _consumos) {
      costoTotal += _getProductCost(c) * _num(c['cantidad']).toInt();
    }
    return SizedBox(
      height: 70,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        children: [
          Tema.kpiCard('Total Consumos', '${_consumos.length}', Icons.person_off, accent: Tema.primary),
          SizedBox(width: 8),
          Tema.kpiCard('Unidades Cons.', '$totalCant', Icons.inventory_2, accent: const Color(0xFFe65100)),
          SizedBox(width: 8),
          Tema.kpiCard('Costo Total', Fb.formatMoney(costoTotal), Icons.attach_money, accent: Tema.danger),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(children: [
        Expanded(
          child: SearchInput(
            controller: _searchC,
            hintText: 'Buscar por producto o motivo...',
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
          Icon(Icons.person_off, color: Tema.textMuted, size: 48),
          SizedBox(height: 12),
          Text('No hay consumos propios registrados', textAlign: TextAlign.center, style: TextStyle(color: Tema.textMuted, fontSize: 15)),
        ],
      );
    }
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      itemCount: filtradas.length,
      itemBuilder: (_, i) => _buildCard(filtradas[i]),
    );
  }

  Widget _buildCard(Map<dynamic, dynamic> consumo) {
    final nombre = consumo['producto_nombre']?.toString() ?? '-';
    final cantidad = _num(consumo['cantidad']).toInt();
    final fecha = _fmtDate(consumo['fecha']);
    final motivo = consumo['motivo']?.toString() ?? '';
    final costoUnitario = _getProductCost(consumo);
    final costoTotal = costoUnitario * cantidad;

    return Dismissible(
      key: Key('cons_${consumo['id']}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tema.radiusLg)),
            title: Text('Eliminar Consumo', style: TextStyle(fontWeight: FontWeight.w700, color: Tema.textDark)),
            content: Text('Eliminar consumo de "$nombre"?\n\nSe restauraran $cantidad unidades al stock.',
              style: TextStyle(color: Tema.textSoft),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Eliminar', style: TextStyle(color: Tema.danger))),
            ],
          ),
        );
        if (ok == true) {
          _eliminar(consumo);
        }
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
            onTap: () => _verDetalle(consumo),
            borderRadius: BorderRadius.circular(Tema.radius),
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: Tema.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(Tema.radiusSm),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.person_off, color: Tema.primary, size: 20),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(nombre, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, color: Tema.textDark, fontSize: 15)),
                      SizedBox(height: 3),
                      Row(children: [
                        _infoChip(Icons.calendar_today, fecha),
                        SizedBox(width: 14),
                        _infoChip(Icons.inventory_2, '$cantidad und'),
                      ]),
                    ]),
                  ),
                ]),
                if (costoUnitario > 0) ...[
                  SizedBox(height: 8),
                  Row(children: [
                    _infoChip(Icons.attach_money, 'Costo: ${Fb.formatMoney(costoTotal)}'),
                    SizedBox(width: 14),
                    _infoChip(Icons.sell, 'Unit: ${Fb.formatMoney(costoUnitario)}'),
                    const Spacer(),
                    Icon(Icons.chevron_right, size: 16, color: Tema.textMuted),
                  ]),
                ] else ...[
                  SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Icon(Icons.chevron_right, size: 16, color: Tema.textMuted),
                  ),
                ],
                if (motivo.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Tema.bg,
                      borderRadius: BorderRadius.circular(Tema.radiusSm),
                    ),
                    child: Row(children: [
                      Icon(Icons.chat_bubble_outline, size: 14, color: Tema.textMuted),
                      SizedBox(width: 6),
                      Expanded(child: Text(motivo, style: TextStyle(fontSize: 12, color: Tema.textSoft), maxLines: 2, overflow: TextOverflow.ellipsis)),
                    ]),
                  ),
                ],
              ]),
            ),
          ),
        ),
      ),
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