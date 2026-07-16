import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/firestore_service.dart';
import '../../theme.dart';

class FacScreen extends StatefulWidget {
  const FacScreen({super.key});
  @override State<FacScreen> createState() => _FacScreenState();
}

class _FacScreenState extends State<FacScreen> {
  List<Map<dynamic,dynamic>> _productos = [];
  List<Map<dynamic,dynamic>> _distCategorias = [];
  final _searchC = TextEditingController(), _clientC = TextEditingController();
  final _focusSearch = FocusNode();
  bool _focusedSearch = false;
  String _searchF = '';
  final List<Map<dynamic,dynamic>> _cart = [];
  double _descuento = 0; bool _descuentoPct = true;
  bool _pagado = false;
  int _numFactura = 0;
  double _flete = 0;
  double _gasolina = 0;
  String _gasolinaCat = '';
  double _otrosGastos = 0;
  bool _showCostos = false;
  StreamSubscription? _subP;

  @override void initState() { super.initState(); _subP = Fb.stream('productos').listen((d) => setState(() => _productos = d)); _initNumFactura(); _loadDistCategorias(); _focusSearch.addListener(() { if (mounted) setState(() => _focusedSearch = _focusSearch.hasFocus); }); }
  @override void dispose() { _subP?.cancel(); _focusSearch.dispose(); super.dispose(); }

  Future<void> _loadDistCategorias() async {
    _distCategorias = await Fb.getList('distribuciones_categorias');
    if (_distCategorias.isNotEmpty) {
      _gasolinaCat = (_distCategorias.first['nombre'] ?? '').toString();
    }
    if (mounted) setState(() {});
  }

  Future<void> _initNumFactura() async {
    final ventas = await Fb.getList('ventas');
    final ids = ventas.map((v) => v['id'] is int ? v['id'] as int : int.tryParse(v['id'].toString()) ?? 0);
    _numFactura = ids.isEmpty ? 1 : ids.reduce((a, b) => a > b ? a : b) + 1;
    if (mounted) setState(() {});
  }

  double get _totalCostos => _flete + _gasolina + _otrosGastos;

  void _addToCartCustom(Map<dynamic,dynamic> prod) async {
    final stockReal = (prod['stock_actual'] ?? 0) as int;
    final enCarrito = _cartQty[prod['id']] ?? 0;
    if (stockReal - enCarrito <= 0) return;
    final pcC = TextEditingController(text: (prod['precio_venta'] ?? 0).toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Precio personalizado', style: TextStyle(color: Tema.textDark, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: pcC,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Precio unitario', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Tema.primary),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final customPrice = double.tryParse(pcC.text) ?? (prod['precio_venta'] ?? 0).toDouble();
    final idx = _cart.indexWhere((c) => c['id'] == prod['id']);
    if (idx >= 0) {
      _cart[idx]['cantidad']++;
      _cart[idx]['precio_unitario'] = customPrice;
      _cart[idx]['subtotal'] = _cart[idx]['cantidad'] * customPrice;
    } else {
      _cart.add({
        'id': prod['id'], 'nombre': prod['nombre'], 'codigo': prod['codigo'] ?? '',
        'cantidad': 1, 'precio_unitario': customPrice, 'subtotal': customPrice,
        'precio_compra': prod['precio_compra'] ?? 0, 'stock_actual': prod['stock_actual'] ?? 0,
      });
    }
    setState(() {});
  }

  Future<void> _distribuirGanancia() async {
    if (_cart.isEmpty) return;
    final gananciaC = TextEditingController();
    List<Map<dynamic, dynamic>> preview = [];

    await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          final g = double.tryParse(gananciaC.text) ?? 0;
          final totalBase = _cart.fold(0.0, (s, i) => s + (i['precio_unitario'] as num).toDouble() * (i['cantidad'] as int));
          preview = totalBase > 0 && g > 0 ? _cart.map((item) {
            final propor = (item['precio_unitario'] as num).toDouble() * (item['cantidad'] as int) / totalBase;
            final newPrice = (item['precio_unitario'] as num).toDouble() + g * propor / (item['cantidad'] as int);
            return {...item, '_newPrice': newPrice};
          }).toList() : [];

          return AlertDialog(
            title: Text('Distribuir Ganancia', style: TextStyle(color: Tema.textDark, fontWeight: FontWeight.w700)),
            insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(
                    controller: gananciaC,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Ganancia extra a distribuir',
                      border: OutlineInputBorder(),
                      prefixText: '\$ ',
                    ),
                    onChanged: (_) => setSt(() {}),
                  ),
                  if (preview.isNotEmpty) ...[
                    SizedBox(height: 12),
                    Text('Distribucion proporcional:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Tema.textDark)),
                    SizedBox(height: 4),
                    ...preview.map((item) => ListTile(
                      dense: true,
                      title: Text('${item['nombre']} x${item['cantidad']}', style: const TextStyle(fontSize: 12)),
                      trailing: Text(
                        '${Fb.formatMoney(item['precio_unitario'])} \u2192 ${Fb.formatMoney(item['_newPrice'])}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    )),
                  ],
                ]),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: g <= 0 ? null : () {
                  final totalBase = _cart.fold(0.0, (s, i) => s + (i['precio_unitario'] as num).toDouble() * (i['cantidad'] as int));
                  for (var item in _cart) {
                    final propor = (item['precio_unitario'] as num).toDouble() * (item['cantidad'] as int) / totalBase;
                    item['precio_unitario'] = ((item['precio_unitario'] as num).toDouble() + g * propor / (item['cantidad'] as int));
                    item['subtotal'] = item['cantidad'] * item['precio_unitario'];
                  }
                  setState(() {});
                  Navigator.pop(ctx, true);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Tema.primary),
                child: const Text('Distribuir'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _addToCart(Map<dynamic,dynamic> prod) {
    final stockReal = (prod['stock_actual'] ?? 0) as int;
    final enCarrito = _cartQty[prod['id']] ?? 0;
    if (stockReal - enCarrito <= 0) return;
    final idx = _cart.indexWhere((c) => c['id'] == prod['id']);
    if (idx >= 0) { _cart[idx]['cantidad']++; _cart[idx]['subtotal'] = _cart[idx]['cantidad'] * _cart[idx]['precio_unitario']; }
    else { _cart.add({'id': prod['id'], 'nombre': prod['nombre'], 'codigo': prod['codigo']??'', 'cantidad': 1, 'precio_unitario': prod['precio_venta']??0, 'subtotal': prod['precio_venta']??0, 'precio_compra': prod['precio_compra']??0, 'stock_actual': prod['stock_actual']??0}); }
    setState(() {});
  }

  void _mostrarScannerFac() {
    showDialog(
      context: context,
      builder: (ctx) => _ScannerInvDialog(
        onScan: (barcode) {
          if (!mounted) return;
          final matches = _productos.where((p) {
            final cod = (p['codigo'] ?? '').toString();
            final cb = (p['codigo_barras'] ?? '').toString();
            return cod == barcode || cb == barcode;
          }).toList();
          if (matches.isNotEmpty) {
            _addToCart(matches.first);
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Producto no encontrado: $barcode')),
            );
          }
        },
      ),
    );
  }

  double get _subtotal => _cart.fold(0.0, (s, i) => s + (i['subtotal']??0));
  double get _total => _subtotal - (_descuentoPct ? _subtotal * _descuento / 100 : _descuento);

  Future<void> _checkout() async {
    if (_cart.isEmpty) return;
    final venta = {
      'id': _numFactura, 'fecha': DateTime.now().toIso8601String(), 'cliente': _clientC.text.trim(),
      'items': _cart.map((c) => {'id': c['id'], 'nombre': c['nombre'], 'cantidad': c['cantidad'], 'precio_unitario': c['precio_unitario'], 'subtotal': c['subtotal']}).toList(),
      'total': _total, 'descuento': _descuento, 'metodo_pago': 'Factura', 'estado': _pagado ? 'pagado':'pendiente',
      'costos_adicionales': {'flete': _flete, 'gasolina': _gasolina, 'otros_gastos': _otrosGastos},
    };
    final ventas = await Fb.getList('ventas');
    ventas.add(venta);
    await Fb.setList('ventas', ventas);
    if (_pagado) {
      for (var ci in _cart) {
        final pi = _productos.indexWhere((p) => p['id'] == ci['id']);
        if (pi >= 0) _productos[pi]['stock_actual'] = (_productos[pi]['stock_actual']??0) - (ci['cantidad'] as int);
      }
      await Fb.setList('productos', _productos);

      // Create distribution record for gasolina (same as PC: distribucion_facturacion)
      if (_gasolina > 0 && _gasolinaCat.isNotEmpty) {
        final distribuciones = await Fb.getList('distribuciones');
        final distItem = <String, dynamic>{
          'categoria_nombre': _gasolinaCat,
          'monto': _gasolina,
        };
        distribuciones.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'tipo': 'distribucion_facturacion',
          'fecha': DateTime.now().toIso8601String().substring(0, 10),
          'items': [distItem],
          'categorias': [distItem],
          'total': _gasolina,
          'created_at': DateTime.now().toIso8601String(),
        });
        await Fb.setList('distribuciones', distribuciones);
      }
    }
    setState(() { _cart.clear(); _descuento = 0; _clientC.clear(); _searchF = ''; _searchC.clear(); _flete = 0; _gasolina = 0; _gasolinaCat = _distCategorias.isNotEmpty ? (_distCategorias.first['nombre'] ?? '').toString() : ''; _otrosGastos = 0; _showCostos = false; });
    _numFactura++;
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Factura #${_numFactura - 1} ${_pagado ? "pagada" : "pendiente"} generada')));
  }

  Map<dynamic, int> get _cartQty {
    final map = <dynamic, int>{};
    for (final item in _cart) {
      final id = item['id'];
      map[id] = (map[id] ?? 0) + (item['cantidad'] as int);
    }
    return map;
  }

  @override Widget build(BuildContext c) {
    final prods = _searchF.isEmpty ? _productos : _productos.where((p) => (p['nombre']??'').toString().toLowerCase().contains(_searchF.toLowerCase()) || (p['codigo']??'').toString().toLowerCase().contains(_searchF.toLowerCase())).toList();
    final cartQty = _cartQty;
    final children = <Widget>[
      Padding(
        padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
        child: Row(children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Tema.primary, borderRadius: BorderRadius.circular(Tema.radiusSm)),
            child: Text('Factura #$_numFactura', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          const Spacer(),
        ]),
      ),
      Padding(padding: EdgeInsets.fromLTRB(10,10,10,4), child: TextField(controller: _clientC, decoration: InputDecoration(hintText: 'Nombre del cliente', prefixIcon: const Icon(Icons.person_outline, size: 20), fillColor: Tema.cardBg, filled: true, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(Tema.radiusSm), borderSide: BorderSide.none)), style: const TextStyle(fontSize: 14))),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Tema.primary),
            onPressed: _mostrarScannerFac,
            tooltip: 'Escanear codigo de barras',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          Expanded(
            child: TextField(controller: _searchC, focusNode: _focusSearch, decoration: InputDecoration(hintText: 'Buscar producto...', prefixIcon: _focusedSearch ? null : const Icon(Icons.search, size: 20), suffixIcon: _searchF.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchC.clear(); setState(() => _searchF = ''); }) : null, fillColor: Tema.cardBg, filled: true, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(Tema.radiusSm), borderSide: BorderSide.none)), onChanged: (v) => setState(() => _searchF = v), style: const TextStyle(fontSize: 14)),
          ),
        ]),
      ),
      Expanded(flex: 3, child: GridView.builder(padding: EdgeInsets.all(8), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.0, crossAxisSpacing: 8, mainAxisSpacing: 8), itemCount: prods.length, itemBuilder: (_, i) {
        final p = prods[i];
        final stockReal = (p['stock_actual'] ?? 0) as int;
        final enCarrito = cartQty[p['id']] ?? 0;
        final stockDisponible = stockReal - enCarrito;
        return GestureDetector(
          onTap: () => _addToCart(p),
          onLongPress: () => _addToCartCustom(p),
          child: Container(decoration: Tema.cardDeco, padding: EdgeInsets.all(12), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('${p['nombre']}', textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Tema.textDark)),
          SizedBox(height: 6),
          Text(Fb.formatMoney(p['precio_venta']??0), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Tema.primary)),
          SizedBox(height: 4),
          Text('Stock: $stockDisponible', style: TextStyle(fontSize: 11, color: stockDisponible <= 0 ? Tema.danger : Tema.textSoft)),
        ])));
      })),
    ];
    if (_cart.isNotEmpty) {
      children.add(const Divider(height: 1));
      children.add(Container(decoration: BoxDecoration(color: Tema.cardBg, borderRadius: const BorderRadius.vertical(top: Radius.circular(Tema.radius)), boxShadow: [Tema.shadowSm]), padding: EdgeInsets.all(10), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Expanded(child: Text('${_cart.length} items', style: TextStyle(fontSize: 12, color: Tema.textSoft))),
          Row(children: [
            Switch(value: _descuentoPct, onChanged: (v) => setState(() { _descuentoPct = v; _descuento = 0; }), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
            Text(_descuentoPct ? '%' : '\$', style: TextStyle(fontSize: 12, color: Tema.textSoft)),
            SizedBox(width: 40, child: TextField(keyboardType: TextInputType.number, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12), decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 6)), onChanged: (v) => setState(() => _descuento = double.tryParse(v) ?? 0))),
          ]),
        ]),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Tema.textDark)),
          Text(Fb.formatMoney(_total), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Tema.primary)),
        ]),
        if (_totalCostos > 0)
          Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text('Costos adicionales: +${Fb.formatMoney(_totalCostos)}', style: TextStyle(fontSize: 11, color: Tema.textSoft)),
          ),
        SizedBox(height: 6),
        InkWell(
          onTap: () => setState(() => _showCostos = !_showCostos),
          child: Row(children: [
            Icon(_showCostos ? Icons.expand_less : Icons.expand_more, size: 18, color: Tema.textSoft),
            SizedBox(width: 4),
            Text('Costos Adicionales', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Tema.textSoft)),
            const Spacer(),
            if (_totalCostos > 0)
              Text(Fb.formatMoney(_totalCostos), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Tema.primary)),
          ]),
        ),
        if (_showCostos) ...[
          SizedBox(height: 6),
          Row(children: [
            Expanded(child: TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Flete/Transporte', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
              style: const TextStyle(fontSize: 12),
              onChanged: (v) => setState(() => _flete = double.tryParse(v) ?? 0),
            )),
            SizedBox(width: 6),
            Expanded(child: TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Gasolina', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
              style: const TextStyle(fontSize: 12),
              onChanged: (v) => setState(() => _gasolina = double.tryParse(v) ?? 0),
            )),
            SizedBox(width: 4),
            Expanded(child: DropdownButtonFormField<String>(
              value: _gasolinaCat.isNotEmpty && _distCategorias.any((c) => (c['nombre'] ?? '').toString() == _gasolinaCat) ? _gasolinaCat : null,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Categoria', border: OutlineInputBorder(), isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              style: const TextStyle(fontSize: 12),
              items: _distCategorias.map((c) => DropdownMenuItem(
                value: (c['nombre'] ?? '').toString(),
                child: Text((c['nombre'] ?? '').toString(), overflow: TextOverflow.ellipsis),
              )).toList(),
              onChanged: (v) => setState(() => _gasolinaCat = v ?? ''),
            )),
          ]),
          SizedBox(height: 4),
          Row(children: [
            Expanded(child: TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Otros Gastos', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
              style: const TextStyle(fontSize: 12),
              onChanged: (v) => setState(() => _otrosGastos = double.tryParse(v) ?? 0),
            )),
            SizedBox(width: 6),
            const Expanded(child: SizedBox()),
          ]),
          if (_totalCostos > 0)
            Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('Total costos: ${Fb.formatMoney(_totalCostos)}', style: TextStyle(fontSize: 11, color: Tema.textSoft)),
            ),
        ],
        SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _distribuirGanancia,
            icon: const Icon(Icons.account_balance_wallet, size: 16),
            label: const Text('Distribuir Ganancia', style: TextStyle(fontSize: 11)),
            style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 6)),
          ),
        ),
        SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Switch(value: _pagado, onChanged: (v) => setState(() => _pagado = v), activeColor: Tema.primary),
          Text(_pagado ? 'Pagado' : 'Pendiente', style: TextStyle(fontSize: 12, color: _pagado ? Tema.primary : Tema.textSoft)),
          const Spacer(),
          TextButton(onPressed: () => setState(() { _cart.clear(); _descuento = 0; }), child: Text('Vaciar', style: TextStyle(color: Tema.danger))),
          SizedBox(width: 8),
          ElevatedButton(onPressed: _checkout, style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10)), child: Text(_pagado ? 'Cobrar' : 'Guardar Factura')),
        ]),
      ])));
      children.add(SizedBox(height: MediaQuery.of(c).viewInsets.bottom));
    }
    return Column(children: children);
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


