import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/firestore_service.dart';
import '../../theme.dart';

class InvScreen extends StatefulWidget {
  const InvScreen({super.key});
  @override
  State<InvScreen> createState() => _InvScreenState();
}

class _InvScreenState extends State<InvScreen> {
  final _q = TextEditingController();
  List<Map<dynamic, dynamic>> _p = [];
  List<Map<dynamic, dynamic>> _cats = [];
  String _f = '';
  String _catFiltroId = '';
  String _marcaFiltro = '';
  String _stockFiltro = '';
  bool _isTableView = false;
  StreamSubscription? _sub;
  StreamSubscription? _subCats;

  static const _unidades = ['und', 'kg', 'g', 'lb', 'L', 'ml', 'm'];

  @override
  void initState() {
    super.initState();
    _subCats = Fb.stream('categorias').listen((d) => setState(() => _cats = List<Map<dynamic, dynamic>>.from(d)));
    _sub = Fb.stream('productos').listen((d) => setState(() => _p = List<Map<dynamic, dynamic>>.from(d)));
  }

  @override
  void dispose() {
    _sub?.cancel();
    _subCats?.cancel();
    super.dispose();
  }

  int _nextId() {
    if (_p.isEmpty) return 1;
    return _p
        .map((x) => x['id'] is int ? x['id'] as int : int.tryParse(x['id'].toString()) ?? 0)
        .reduce((a, b) => a > b ? a : b) + 1;
  }

  String _nextCodigo() {
    int max = 0;
    for (final x in _p) {
      final c = (x['codigo'] ?? '').toString();
      final n = int.tryParse(c.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      if (n > max) max = n;
    }
    return 'P${(max + 1).toString().padLeft(4, '0')}';
  }

  int _num(dynamic v) => v is int ? v : int.tryParse(v.toString()) ?? 0;
  double _numD(dynamic v) => v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0;

  List<String> _getMarcas() {
    final set = <String>{};
    for (final p in _p) {
      final m = (p['marca'] ?? '').toString().trim();
      if (m.isNotEmpty) set.add(m);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<Map<dynamic, dynamic>> _filtradas() {
    return _p.where((p) {
      if (_f.isNotEmpty) {
        final nom = (p['nombre'] ?? '').toString().toLowerCase();
        final cod = (p['codigo'] ?? '').toString().toLowerCase();
        final mar = (p['marca'] ?? '').toString().toLowerCase();
        if (!nom.contains(_f.toLowerCase()) && !cod.contains(_f.toLowerCase()) && !mar.contains(_f.toLowerCase())) return false;
      }
      if (_catFiltroId.isNotEmpty && (p['categoria_id'] ?? '').toString() != _catFiltroId) return false;
      if (_marcaFiltro.isNotEmpty && (p['marca'] ?? '').toString().toLowerCase() != _marcaFiltro.toLowerCase()) return false;
      final st = _num(p['stock_actual']);
      final mn = _num(p['stock_minimo']);
      if (_stockFiltro == 'agotado' && st > 0) return false;
      if (_stockFiltro == 'bajo' && (st > mn || st == 0)) return false;
      if (_stockFiltro == 'normal' && st <= mn) return false;
      return true;
    }).toList();
  }

  Widget _statsRow(List<Map<dynamic, dynamic>> data) {
    int totalProd = data.length;
    int totalUnids = 0;
    double valCosto = 0;
    double valVenta = 0;
    int agotados = 0;
    int agotandose = 0;
    for (final p in data) {
      final st = _num(p['stock_actual']);
      final mn = _num(p['stock_minimo']);
      final pc = _numD(p['precio_compra']);
      final pv = _numD(p['precio_venta']);
      totalUnids += st;
      valCosto += st * pc;
      valVenta += st * pv;
      if (st == 0) {
        agotados++;
      } else if (mn > 0 && st <= mn) {
        agotandose++;
      }
    }
    return Container(
      margin: EdgeInsets.fromLTRB(8, 0, 8, 4),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Tema.primary,
        borderRadius: BorderRadius.circular(Tema.radiusSm),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _statChip('Total Prods', totalProd.toString(), null),
          SizedBox(width: 4),
          _statChip('Unidades', totalUnids.toString(), null),
          SizedBox(width: 4),
          _statChip('Valor Costo', Fb.formatMoney(valCosto), null),
          SizedBox(width: 4),
          _statChip('Valor Venta', Fb.formatMoney(valVenta), null),
          SizedBox(width: 4),
          _statChip('Agotados', agotados.toString(), Tema.danger),
          SizedBox(width: 4),
          _statChip('Agotandose', agotandose.toString(), Colors.orange),
        ]),
      ),
    );
  }

  Widget _statChip(String label, String value, Color? color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
        child: Column(children: [
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color ?? Colors.white)),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.white70)),
      ]),
    );
  }

  void _mostrarScannerInventario() {
    showDialog(
      context: context,
      builder: (ctx) => _ScannerInvDialog(
        onScan: (barcode) {
          final matches = _p.where((p) {
            final cod = (p['codigo'] ?? '').toString();
            final cb = (p['codigo_barras'] ?? '').toString();
            return cod == barcode || cb == barcode;
          }).toList();
          if (matches.isNotEmpty) {
            _abrirForm(matches.first);
          } else {
            _abrirForm(null, barcode);
          }
        },
      ),
    );
  }



  Future<void> _abrirForm([Map<dynamic, dynamic>? prod, String? prefilledBarcode]) async {
    final edit = prod != null;
    // Ensure categories are loaded
    if (_cats.isEmpty) {
      final loaded = await Fb.getList('categorias');
      if (!mounted) return;
      if (loaded.isNotEmpty) setState(() => _cats = List<Map<dynamic, dynamic>>.from(loaded));
    }
    final cdC = TextEditingController(text: edit ? (prod['codigo'] ?? '') : _nextCodigo());
    final nmC = TextEditingController(text: edit ? (prod['nombre'] ?? '') : '');
    final catC = TextEditingController(text: edit ? (prod['categoria_nombre'] ?? '') : '');
    String catId = edit ? (prod['categoria_id'] ?? '').toString() : '';
    final marcaC = TextEditingController(text: edit ? (prod['marca'] ?? '') : '');
    final pcC = TextEditingController(text: edit ? (prod['precio_compra'] ?? '').toString() : '');
    final pvC = TextEditingController(text: edit ? (prod['precio_venta'] ?? '').toString() : '');

    final stC = TextEditingController(text: edit ? (prod['stock_actual'] ?? '').toString() : '');
    final smC = TextEditingController(text: edit ? (prod['stock_minimo'] ?? 5).toString() : '5');
    String uni = edit ? (prod['unidad_medida'] ?? 'und') : 'und';
    final cbC = TextEditingController(text: edit ? (prod['codigo_barras'] ?? '') : (prefilledBarcode ?? ''));
    bool esAlcohol = edit ? (prod['es_alcohol'] == true || prod['es_alcohol'] == 'true') : false;

    StreamSubscription? dialogSubCats;
    StreamSubscription? dialogSubProds;
    try {
      await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setSt) {
            dialogSubCats ??= Fb.stream('categorias').listen((d) {
              setSt(() {
                _cats = List<Map<dynamic, dynamic>>.from(d);
              });
            });
            dialogSubProds ??= Fb.stream('productos').listen((d) {
              setSt(() {
                _p = List<Map<dynamic, dynamic>>.from(d);
              });
            });
            return AlertDialog(
          title: Row(children: [
            Expanded(child: Text(edit ? 'Editar Producto' : 'Nuevo Producto',
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
              Row(children: [
                Expanded(child: _fld('Codigo', cdC, required: true)),
                SizedBox(width: 8),
                Expanded(child: _fld('Nombre', nmC, required: true)),
              ]),
              Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: catC,
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onChanged: (v) {
                        setSt(() {
                          catId = '';
                        });
                      },
                    ),
                    SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        catC.text.isEmpty ? 'Categorias sugeridas:' : 'Categorias encontradas:',
                        style: TextStyle(fontSize: 10, color: Tema.textSoft),
                      ),
                    ),
                    SizedBox(height: 2),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: (catC.text.isEmpty
                              ? _cats
                              : _cats.where((c) => (c['nombre'] ?? '').toString().toLowerCase().contains(catC.text.trim().toLowerCase())))
                          .take(5)
                          .map((c) => ActionChip(
                                label: Text(c['nombre'] ?? '', style: const TextStyle(fontSize: 11)),
                                backgroundColor: (catId == (c['id'] ?? '').toString())
                                    ? Tema.primary
                                    : Tema.primary.withValues(alpha: 0.08),
                                labelStyle: TextStyle(
                                  color: (catId == (c['id'] ?? '').toString()) ? Colors.white : Tema.primary,
                                  fontSize: 11,
                                ),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                onPressed: () {
                                  setSt(() {
                                    catC.text = c['nombre'] ?? '';
                                    catId = (c['id'] ?? '').toString();
                                  });
                                },
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: marcaC,
                      decoration: const InputDecoration(
                        labelText: 'Marca',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onChanged: (v) {
                        setSt(() {});
                      },
                    ),
                    SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        marcaC.text.isEmpty ? 'Marcas sugeridas:' : 'Marcas encontradas:',
                        style: TextStyle(fontSize: 10, color: Tema.textSoft),
                      ),
                    ),
                    SizedBox(height: 2),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: (marcaC.text.isEmpty
                              ? _p.map((p) => (p['marca'] ?? '').toString().trim()).where((b) => b.isNotEmpty).toSet().toList()
                              : _p.map((p) => (p['marca'] ?? '').toString().trim()).where((b) => b.isNotEmpty && b.toLowerCase().contains(marcaC.text.trim().toLowerCase())).toSet().toList())
                          .take(5)
                          .map((b) => ActionChip(
                                label: Text(b, style: const TextStyle(fontSize: 11)),
                                backgroundColor: (marcaC.text.trim().toLowerCase() == b.toLowerCase())
                                    ? Tema.primary
                                    : Tema.primary.withValues(alpha: 0.08),
                                labelStyle: TextStyle(
                                  color: (marcaC.text.trim().toLowerCase() == b.toLowerCase()) ? Colors.white : Tema.primary,
                                  fontSize: 11,
                                ),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                onPressed: () {
                                  setSt(() {
                                    marcaC.text = b;
                                  });
                                },
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
              Row(children: [
                Expanded(child: _fld('Precio Compra', pcC, num: true)),
                SizedBox(width: 8),
                Expanded(child: _fld('Precio Venta', pvC, num: true)),
              ]),
              Row(children: [
                Expanded(child: _fld('Stock Actual', stC, num: true)),
                SizedBox(width: 8),
                Expanded(child: _fld('Stock Minimo', smC, num: true)),
              ]),
              SizedBox(height: 4),
              DropdownButtonFormField<String>(
                value: uni,
                decoration: const InputDecoration(
                    labelText: 'Unidad Medida',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                items: _unidades
                    .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                    .toList(),
                onChanged: (v) {
                  uni = v ?? 'und';
                  setSt(() {});
                },
              ),
              SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _fld('Codigo Barras', cbC),
                  ),
                  SizedBox(width: 8),
                  SizedBox(
                    height: 40,
                    width: 44,
                    child: IconButton(
                      icon: const Icon(Icons.qr_code_scanner_rounded, color: Tema.primary),
                      onPressed: () {
                        showDialog<String>(
                          context: ctx,
                          builder: (c) => _ScannerInvDialog(
                            onScan: (barcode) {},
                          ),
                        ).then((barcode) {
                          if (barcode != null && barcode.isNotEmpty) {
                            setSt(() {
                              cbC.text = barcode;
                            });
                          }
                        });
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Tema.primary.withValues(alpha: 0.1),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Tema.radiusSm),
                          side: const BorderSide(color: Tema.primary, width: 1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              CheckboxListTile(
                value: esAlcohol,
                onChanged: (v) => setSt(() => esAlcohol = v ?? false),
                title: const Text('Es Alcohol', style: TextStyle(fontSize: 14)),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ]),
          )),
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
                      if (nmC.text.trim().isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('El nombre es obligatorio')),
                        );
                        return;
                      }
                      if (catC.text.trim().isNotEmpty && catId.isEmpty) {
                        final found = _cats.where(
                            (c) => (c['nombre'] ?? '').toString().toLowerCase() == catC.text.trim().toLowerCase());
                        if (found.isNotEmpty) {
                          catId = (found.first['id'] ?? '').toString();
                        } else {
                          final newId = _cats.isEmpty
                              ? 1
                              : _cats.map((x) => (x['id'] as num?)?.toInt() ?? 0).reduce((a, b) => a > b ? a : b) + 1;
                          final newCat = {
                            'id': newId,
                            'nombre': catC.text.trim(),
                            'color': '#059669',
                            'icono': 'category',
                            'orden': _cats.length + 1,
                          };
                          final updated = List<Map<dynamic, dynamic>>.from(_cats)..add(newCat);
                          _cats = updated;
                          catId = newId.toString();
                          Fb.setList('categorias', updated);
                        }
                      }
                      final now = DateTime.now().toIso8601String();
                      final data = <dynamic, dynamic>{
                        'codigo': cdC.text.trim(),
                        'nombre': nmC.text.trim(),
                        'categoria_id': catId.isNotEmpty ? catId : null,
                        'categoria_nombre': catC.text.trim(),
                        'marca': marcaC.text.trim(),
                        'precio_compra': int.tryParse(pcC.text) ?? 0,
                        'precio_venta': int.tryParse(pvC.text) ?? 0,
                        'stock_actual': int.tryParse(stC.text) ?? 0,
                        'stock_minimo': int.tryParse(smC.text) ?? 5,
                        'unidad_medida': uni,
                        'codigo_barras': cbC.text.trim(),
                        'es_alcohol': esAlcohol,
                        'activo': true,
                        'created_at': edit ? (prod['created_at'] ?? now) : now,
                        'updated_at': now,
                      };
                      // Check for duplicate codigo or nombre
                      final newCodigo = (data['codigo'] ?? '').toString().toLowerCase();
                      final newNombre = (data['nombre'] ?? '').toString().toLowerCase();
                      for (final existing in _p) {
                        if (edit && existing['id'] == prod['id']) continue;
                        final ec = (existing['codigo'] ?? '').toString().toLowerCase();
                        final en = (existing['nombre'] ?? '').toString().toLowerCase();
                        if (ec == newCodigo) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Ya existe un producto con ese código')),
                          );
                          return;
                        }
                        if (en == newNombre) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Ya existe un producto con ese nombre')),
                          );
                          return;
                        }
                      }
                      if (edit) {
                        data['id'] = prod['id'];
                      } else {
                        data['id'] = _nextId();
                      }
                      final merged = await Fb.mergeItem('productos', data);
                      if (merged.isNotEmpty) {
                        _p = merged;
                        if (mounted) setState(() {});
                      }
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
                    child: Text(edit ? 'Actualizar' : 'Guardar', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
    } finally {
      dialogSubCats?.cancel();
      dialogSubProds?.cancel();
    }
  }

  Future<void> _abrirAjuste(Map<dynamic, dynamic> p) async {
    final stActual = _num(p['stock_actual']).toInt();
    final cantC = TextEditingController(text: '$stActual');
    final motC = TextEditingController(text: 'Conteo de inventario');

    await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text('Ajustar Stock',
              style: TextStyle(color: Tema.textDark, fontWeight: FontWeight.w700)),
          insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(p['nombre'] ?? '',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Tema.textDark)),
            Text('Stock actual: $stActual',
                style: TextStyle(fontSize: 13, color: Tema.textSoft)),
            SizedBox(height: 14),
            _fld('Cantidad Real / Nuevo Stock', cantC, num: true),
            _fld('Motivo', motC),
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
                      final cant = int.tryParse(cantC.text) ?? stActual;
                      final idx = _p.indexWhere((x) => x['id'] == p['id']);
                      if (idx >= 0) {
                        _p[idx]['stock_actual'] = cant.clamp(0, 999999);
                        _p[idx]['updated_at'] = DateTime.now().toIso8601String();
                      }
                      final merged = await Fb.mergeItem('productos', Map<dynamic, dynamic>.from(_p[idx]));
                      if (merged.isNotEmpty) {
                        _p = merged;
                        if (mounted) setState(() {});
                      }
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
                    child: const Text('Guardar Ajuste', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _eliminar(Map<dynamic, dynamic> p) async {
    final merged = await Fb.mergeItem('productos', {}, isDelete: true, deleteId: p['id']);
    if (merged.isNotEmpty) {
      _p = merged;
      if (mounted) setState(() {});
    }
  }

  Widget _fld(String l, TextEditingController c, {bool num = false, bool required = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: c,
        keyboardType: num ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: required ? '$l *' : l,
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext c) {
    final fl = _filtradas();
    return Scaffold(
      floatingActionButton: _buildFabMenu(),
      body: Column(children: [
        Padding(
          padding: EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.qr_code_scanner, color: Tema.primary),
              onPressed: _mostrarScannerInventario,
              tooltip: 'Escanear codigo de barras',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
            Expanded(
              child: SearchInput(
                controller: _q,
                hintText: 'Buscar producto...',
                onChanged: (v) => setState(() => _f = v),
              ),
            ),
            SizedBox(width: 6),
            SizedBox(
              width: 130,
              child: DropdownButtonFormField<String>(
                value: _catFiltroId.isEmpty ? null : _catFiltroId,
                isExpanded: true,
                decoration: InputDecoration(
                  hintText: 'Categoria',
                  hintStyle: TextStyle(color: Tema.textMuted, fontSize: 12),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Tema.radiusSm), borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                ),
                items: [
                  const DropdownMenuItem<String>(
                      value: '', child: Text('Todas', style: TextStyle(fontSize: 12))),
                  ..._cats.map((c) => DropdownMenuItem<String>(
                        value: (c['id'] ?? '').toString(),
                        child: Text((c['nombre'] ?? '').toString(), style: const TextStyle(fontSize: 12)),
                      )),
                ],
                onChanged: (v) => setState(() => _catFiltroId = v ?? ''),
              ),
            ),
            SizedBox(width: 4),
            IconButton(
              icon: Icon(_isTableView ? Icons.grid_view : Icons.list, color: Tema.primary),
              onPressed: () => setState(() => _isTableView = !_isTableView),
              tooltip: _isTableView ? 'Vista tarjetas' : 'Vista tabla',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ]),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(children: [
            _chip('Todos', ''),
            SizedBox(width: 5),
            _chip('Normal', 'normal'),
            SizedBox(width: 5),
            _chip('Bajo', 'bajo'),
            SizedBox(width: 5),
            _chip('Agotado', 'agotado'),
          const Spacer(),
          SizedBox(
            width: 120,
            child: DropdownButtonFormField<String>(
              value: _marcaFiltro.isEmpty ? null : _marcaFiltro,
              isExpanded: true,
              decoration: InputDecoration(
                hintText: 'Marca',
                hintStyle: TextStyle(color: Tema.textMuted, fontSize: 12),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Tema.radiusSm), borderSide: BorderSide.none),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              ),
              items: [
                const DropdownMenuItem<String>(
                    value: '', child: Text('Todas', style: TextStyle(fontSize: 12))),
                ..._getMarcas().map((m) => DropdownMenuItem<String>(
                      value: m,
                      child: Text(m, style: const TextStyle(fontSize: 12)),
                    )),
              ],
              onChanged: (v) => setState(() => _marcaFiltro = v ?? ''),
            ),
          ),
          ]),
        ),
        _statsRow(fl),
        Expanded(
          child: fl.isEmpty
                ? ListView(children: [
                    SizedBox(height: 80),
                    Center(
                        child: Text('No se encontraron productos',
                            style: TextStyle(color: Tema.textMuted)))
                  ])
                : _isTableView
                    ? _buildTableView(fl)
                    : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    itemCount: fl.length,
                    itemBuilder: (_, i) {
                      final p = fl[i];
                      final st = _num(p['stock_actual']);
                      final mn = _num(p['stock_minimo']);
                      final pc = _numD(p['precio_compra']);
                      final pv = _numD(p['precio_venta']);
                      final avatarColor =
                          st <= 0 ? Tema.danger : (mn > 0 && st <= mn) ? Colors.orange : Tema.primary;
                      final ratio = mn > 0 ? (st / mn).clamp(0.0, 1.0) : (st > 0 ? 1.0 : 0.0);
                      final barColor = ratio <= 0
                          ? Tema.danger
                          : ratio <= 0.5
                              ? Colors.orange
                              : Tema.primary;

                      return Dismissible(
                        key: Key('inv_${p['id']}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(right: 20),
                          margin: EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: Tema.danger.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(Tema.radius),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (_) async {
                          return await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Eliminar Producto',
                                      style: TextStyle(color: Tema.danger)),
                                   content: Text('Eliminar "${p['nombre']}"?', maxLines: 2, overflow: TextOverflow.ellipsis),
                                  actions: [
                                    TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Cancelar')),
                                    TextButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Eliminar',
                                            style: TextStyle(color: Tema.danger))),
                                  ],
                                ),
                              ) ??
                              false;
                        },
                        onDismissed: (_) => _eliminar(p),
                        child: InkWell(
                          onTap: () => _abrirForm(p),
                          child: Container(
                            margin: EdgeInsets.only(bottom: 6),
                            padding: EdgeInsets.all(12),
                            decoration: Tema.cardDeco,
                            child: Row(children: [
                               CircleAvatar(
                                backgroundColor: avatarColor,
                                radius: 18,
                                child: Text(
                                  (p['nombre'] ?? 'P').toString()[0].toUpperCase(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${p['nombre']}',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600, color: Tema.textDark),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                      SizedBox(height: 2),
                                      Row(children: [
                                        Text(p['codigo'] ?? '-',
                                            style: TextStyle(
                                                fontSize: 11, color: Tema.textMuted)),
                                        if ((p['categoria_nombre'] ?? '').toString().isNotEmpty) ...[
                                          SizedBox(width: 6),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                                color: Tema.primary.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(4)),
                                            child: Text(p['categoria_nombre'] ?? '',
                                                style: const TextStyle(
                                                    fontSize: 10, color: Tema.primary)),
                                          ),
                                        ],
                                      ]),
                                       SizedBox(height: 4),
                                      Row(children: [
                                        Expanded(
                                          child: Text('Stock: $st / $mn',
                                              maxLines: 1, overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  fontSize: 11, color: Tema.textSoft)),
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          flex: 2,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(3),
                                            child: LinearProgressIndicator(
                                              value: ratio,
                                              backgroundColor: Colors.grey.shade200,
                                              valueColor: AlwaysStoppedAnimation(barColor),
                                              minHeight: 5,
                                            ),
                                          ),
                                        ),
                                      ]),
                                    ]),
                              ),
                               Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Flexible(child: Text(Fb.formatMoney(pv),
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800, color: Tema.textDark))),
                                SizedBox(height: 2),
                                Flexible(child: Text('Compra: ${Fb.formatMoney(pc)}',
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 10, color: Tema.textMuted))),
                              ]),
                            ]),
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ]),
    );
  }

  Widget _buildTableView(List<Map<dynamic, dynamic>> fl) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columnSpacing: 12,
          dataRowMinHeight: 36,
          dataRowMaxHeight: 52,
          headingRowHeight: 42,
          headingTextStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 10, color: Tema.textDark),
          dataTextStyle: TextStyle(fontSize: 10, color: Tema.textSoft),
          columns: const [
            DataColumn(label: Text('Codigo')),
            DataColumn(label: Text('Nombre')),
            DataColumn(label: Text('Cat')),
            DataColumn(label: Text('Stock'), numeric: true),
            DataColumn(label: Text('Min'), numeric: true),
            DataColumn(label: Text('P.Compra'), numeric: true),
            DataColumn(label: Text('P.Venta'), numeric: true),
            DataColumn(label: Text('Utilidad'), numeric: true),
            DataColumn(label: Text('Margen%'), numeric: true),
            DataColumn(label: Text('Valor Total'), numeric: true),
            DataColumn(label: Text('Estado')),
            DataColumn(label: Text('Acciones')),
          ],
          rows: fl.map((p) {
            final st = _num(p['stock_actual']);
            final mn = _num(p['stock_minimo']);
            final pc = _numD(p['precio_compra']);
            final pv = _numD(p['precio_venta']);
            final util = pv - pc;
            final margen = pv > 0 ? (util / pv * 100) : 0.0;
            final valTotal = st * pv;
            final Color stColor = st <= 0 ? Tema.danger : (mn > 0 && st <= mn) ? Colors.orange : Colors.green;
            final String estado = st <= 0 ? 'Agotado' : (mn > 0 && st <= mn) ? 'Bajo' : 'Normal';

            return DataRow(
              onSelectChanged: (_) => _abrirForm(p),
              cells: [
                DataCell(Text(p['codigo'] ?? '-')),
                DataCell(SizedBox(width: 100, child: Text(p['nombre'] ?? '-', maxLines: 1, overflow: TextOverflow.ellipsis))),
                DataCell(SizedBox(width: 70, child: Text(p['categoria_nombre'] ?? '-', maxLines: 1, overflow: TextOverflow.ellipsis))),
                DataCell(Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: stColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                  child: Text('$st', style: TextStyle(fontWeight: FontWeight.w600, color: stColor)),
                )),
                DataCell(Text('$mn')),
                DataCell(Text(Fb.formatMoney(pc))),
                DataCell(Text(Fb.formatMoney(pv))),
                DataCell(Text(Fb.formatMoney(util), style: TextStyle(color: util >= 0 ? Colors.green : Tema.danger))),
                DataCell(Text('${margen.toStringAsFixed(1)}%')),
                DataCell(Text(Fb.formatMoney(valTotal))),
                DataCell(Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: stColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                  child: Text(estado, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: stColor)),
                )),
                DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                  InkWell(onTap: () => _abrirForm(p), child: const Icon(Icons.edit, size: 16, color: Tema.primary)),
                  SizedBox(width: 4),
                  InkWell(onTap: () => _abrirAjuste(p), child: const Icon(Icons.inventory, size: 16, color: Colors.orange)),
                ])),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _mostrarDescuentosMasivos() async {
    bool aplicarTodos = true;
    final seleccionados = <int>{};
    String tipoDesc = '%';
    final valorC = TextEditingController();

    await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          final prodFiltrados = aplicarTodos ? _p : _p.where((x) {
            final id = x['id'] is int ? x['id'] as int : int.tryParse(x['id'].toString()) ?? 0;
            return seleccionados.contains(id);
          }).toList();
          final desc = double.tryParse(valorC.text) ?? 0;

          return AlertDialog(
            title: Text('Descuentos Masivos', style: TextStyle(color: Tema.textDark, fontWeight: FontWeight.w700)),
            insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  SwitchListTile(
                    title: const Text('Aplicar a todos los productos'),
                    value: aplicarTodos,
                    onChanged: (v) => setSt(() => aplicarTodos = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (!aplicarTodos) ...[
                    const Text('Seleccionar productos:', style: TextStyle(fontWeight: FontWeight.w600)),
                    SizedBox(height: 4),
                    ..._p.take(60).map((p) {
                      final id = p['id'] is int ? p['id'] as int : int.tryParse(p['id'].toString()) ?? 0;
                      return CheckboxListTile(
                        dense: true,
                        title: Text('${p['nombre']}', style: const TextStyle(fontSize: 12)),
                        subtitle: Text('P.Venta: ${Fb.formatMoney(_numD(p['precio_venta']))}', style: const TextStyle(fontSize: 10)),
                        value: seleccionados.contains(id),
                        onChanged: (v) => setSt(() {
                          if (v == true) {
                            seleccionados.add(id);
                          } else {
                            seleccionados.remove(id);
                          }
                        }),
                        contentPadding: EdgeInsets.zero,
                      );
                    }),
                  ],
                  const Divider(),
                  Row(children: [
                    const Text('Tipo:', style: TextStyle(fontSize: 13)),
                    SizedBox(width: 8),
                    DropdownButton<String>(
                      value: tipoDesc,
                      items: const [
                        DropdownMenuItem(value: '%', child: Text('% Porcentaje')),
                        DropdownMenuItem(value: '\$', child: Text('\$ Monto fijo')),
                      ],
                      onChanged: (v) => setSt(() => tipoDesc = v ?? '%'),
                    ),
                  ]),
                  SizedBox(height: 8),
                  TextField(
                    controller: valorC,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: tipoDesc == '%' ? 'Porcentaje de descuento' : 'Monto a descontar',
                      border: const OutlineInputBorder(),
                      suffixText: tipoDesc == '%' ? '%' : '\$',
                    ),
                    onChanged: (_) => setSt(() {}),
                  ),
                  if (desc > 0 && prodFiltrados.isNotEmpty) ...[
                    SizedBox(height: 12),
                    const Text('Vista previa:', style: TextStyle(fontWeight: FontWeight.w700)),
                    SizedBox(height: 4),
                    ...prodFiltrados.take(8).map((p) {
                      final pv = _numD(p['precio_venta']);
                      final npv = tipoDesc == '%' ? pv * (1 - desc / 100) : (pv - desc).clamp(0, double.infinity);
                      return ListTile(
                        dense: true,
                        title: Text('${p['nombre']}', style: const TextStyle(fontSize: 12)),
                        trailing: Text('${Fb.formatMoney(pv)} \u2192 ${Fb.formatMoney(npv)}',
                            style: TextStyle(fontSize: 11, color: npv < pv ? Colors.green : Tema.textSoft)),
                      );
                    }),
                    if (prodFiltrados.length > 8)
                      Text('...y ${prodFiltrados.length - 8} productos mas',
                          style: TextStyle(fontSize: 11, color: Tema.textMuted)),
                  ],
                ]),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: desc <= 0 ? null : () async {
                  for (final p in prodFiltrados) {
                    final idx = _p.indexWhere((x) => x['id'] == p['id']);
                    if (idx >= 0) {
                      final pv = _numD(_p[idx]['precio_venta']);
                      final npv = tipoDesc == '%' ? pv * (1 - desc / 100) : (pv - desc).clamp(0, double.infinity);
                      _p[idx]['precio_venta'] = npv.round();
                    }
                  }
                  await Fb.setList('productos', _p);
                  if (ctx.mounted) Navigator.pop(ctx, true);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Tema.primary),
                child: const FittedBox(fit: BoxFit.scaleDown, child: Text('Aplicar Descuento')),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFabMenu() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Tema.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Tema.cardBorder, width: 1),
            boxShadow: [Tema.shadowMd],
          ),
          padding: EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _fabBtn(Icons.discount, 'Descuentos', Colors.orange, _mostrarDescuentosMasivos),
              SizedBox(height: 6),
              _fabBtn(Icons.inventory_2, 'Ajuste', Tema.darkBlue, () async {
                if (_p.isEmpty) return;
                final sel = await showDialog<Map<dynamic, dynamic>>(
                  context: context,
                  builder: (ctx) => ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
                    child: SimpleDialog(
                    title: const Text('Seleccionar producto'),
                    children: _p
                        .take(80)
                        .map((p) => SimpleDialogOption(
                              onPressed: () => Navigator.pop(ctx, p),
                              child: Text('${p['nombre'] ?? ''}  (${p['codigo'] ?? '-'})',
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                  )),
                );
                if (sel != null) _abrirAjuste(sel);
              }),
              SizedBox(height: 6),
              _fabBtn(Icons.add, 'Nuevo', Tema.primary, () => _abrirForm()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fabBtn(IconData icon, String label, Color color, Future<void> Function() onTap) {
    return SizedBox(
      width: 140,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: Colors.white),
        label: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _chip(String label, String value) {
    final selected = _stockFiltro == value;
    return GestureDetector(
      onTap: () => setState(() => _stockFiltro = selected ? '' : value),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? Tema.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? Tema.primary : Tema.cardBorder),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Tema.textSoft)),
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
                icon: const Icon(Icons.close, color: Colors.white, size: 24),
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
                  child: const Text('Escanear codigo de barras', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}




class _SelectorBottomSheet extends StatefulWidget {
  final String title;
  final String hint;
  final List<Map<String, String>> options;
  final bool isCategory;
  final void Function(String nombre) onCreate;
  final void Function(Map<String, String> opt) onSelect;

  const _SelectorBottomSheet({
    required this.title,
    required this.hint,
    required this.options,
    required this.isCategory,
    required this.onCreate,
    required this.onSelect,
  });

  @override
  State<_SelectorBottomSheet> createState() => _SelectorBottomSheetState();
}

class _SelectorBottomSheetState extends State<_SelectorBottomSheet> {
  final _searchC = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'category': return Icons.category;
      case 'shopping_cart': return Icons.shopping_cart;
      case 'local_grocery_store': return Icons.local_grocery_store;
      case 'restaurant': return Icons.restaurant;
      case 'local_drink': return Icons.local_drink;
      case 'bakery_dining': return Icons.bakery_dining;
      case 'egg': return Icons.egg;
      case 'lunch_dining': return Icons.lunch_dining;
      case 'local_pizza': return Icons.local_pizza;
      case 'icecream': return Icons.icecream;
      case 'coffee': return Icons.coffee;
      case 'wine_bar': return Icons.wine_bar;
      case 'cleaning_services': return Icons.cleaning_services;
      case 'checkroom': return Icons.checkroom;
      case 'toys': return Icons.toys;
      case 'pets': return Icons.pets;
      case 'medication': return Icons.medication;
      case 'electrical_services': return Icons.electrical_services;
      case 'home': return Icons.home;
      case 'more_horiz': return Icons.more_horiz;
      default: return Icons.category;
    }
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Tema.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _filter.trim().toLowerCase();
    final filtered = widget.options.where((opt) {
      final name = opt['nombre']!.toLowerCase();
      return name.contains(query);
    }).toList();

    final exactMatch = widget.options.any((opt) => opt['nombre']!.toLowerCase() == query);
    final showCreate = query.isNotEmpty && !exactMatch;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (ctx, scrollC) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Tema.textDark,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchC,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: (v) => setState(() => _filter = v),
              ),
            ),
            if (showCreate)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Tema.primary.withValues(alpha: 0.1),
                    child: const Icon(Icons.add, color: Tema.primary),
                  ),
                  title: Text('Crear "${_filter.trim()}"'),
                  onTap: () {
                    widget.onCreate(_filter.trim());
                    Navigator.pop(context);
                  },
                ),
              ),
            Expanded(
              child: filtered.isEmpty && !showCreate
                  ? Center(
                      child: Text(
                        'No se encontraron opciones',
                        style: TextStyle(color: Tema.textMuted),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollC,
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final opt = filtered[i];
                        return ListTile(
                          leading: widget.isCategory
                              ? CircleAvatar(
                                  backgroundColor: _parseColor(opt['color']!),
                                  child: Icon(
                                    _getIcon(opt['icono']!),
                                    color: Colors.white,
                                  ),
                                )
                              : CircleAvatar(
                                  backgroundColor: Tema.primary.withValues(alpha: 0.1),
                                  child: const Icon(Icons.label_outline, color: Tema.primary),
                                ),
                          title: Text(
                            opt['nombre']!,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          onTap: () {
                            widget.onSelect(opt);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}