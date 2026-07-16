import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme.dart';
import '../../services/firestore_service.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});
  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final _searchCtl = TextEditingController();
  final _discCtl = TextEditingController(text: '0');
  final _efectivoCtl = TextEditingController();
  final _tarjetaRefCtl = TextEditingController();
  final _clientCtl = TextEditingController();

  List<Map<dynamic, dynamic>> _productos = [];
  List<Map<dynamic, dynamic>> _categorias = [];
  List<Map<dynamic, dynamic>> _clientes = [];
  List<Map<dynamic, dynamic>> _cajas = [];

  final _cart = <Map<dynamic, dynamic>>[];
  String _searchQ = '';
  String _selectedCat = '';
  String _discType = '%';
  String _payMethod = 'efectivo';
  bool _cartExpanded = true;
  final _selectedItems = <int>{};
  bool _cartPaused = false;
  bool _guardandoVenta = false;
  Map<dynamic, dynamic>? _selectedClient;
  StreamSubscription? _subProds;
  StreamSubscription? _subClients;
  StreamSubscription? _subCajas;

  // Split payment state
  final _splitEfecCtl = TextEditingController(text: '0');
  final _splitTarjCtl = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _loadAll();
    _subProds = Fb.stream('productos').listen((d) => setState(() => _productos = d));
    _subClients = Fb.stream('clientes').listen((d) => setState(() => _clientes = d));
    _subCajas = Fb.stream('cajas').listen((d) => setState(() => _cajas = d));
  }

  @override
  void dispose() {
    _subProds?.cancel();
    _subClients?.cancel();
    _subCajas?.cancel();
    _searchCtl.dispose();
    _discCtl.dispose();
    _efectivoCtl.dispose();
    _tarjetaRefCtl.dispose();
    _clientCtl.dispose();
    _splitEfecCtl.dispose();
    _splitTarjCtl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final res = await Future.wait([
      Fb.getList('productos'),
      Fb.getList('categorias'),
      Fb.getList('clientes'),
      Fb.getList('cajas'),
    ]);
    if (!mounted) return;
    setState(() {
      _productos = res[0];
      _categorias = res[1];
      _clientes = res[2];
      _cajas = res[3];
    });
  }

  // --- Helpers ---

  double get _bruto =>
      _cart.fold(0.0, (s, x) => s + ((x['cantidad'] as num?)?.toDouble() ?? 0) * ((x['precio_unitario'] as num?)?.toDouble() ?? 0));

  double get _descuentoCalc {
    final v = double.tryParse(_discCtl.text) ?? 0;
    if (_discType == '%') {
      return (_bruto * v / 100).roundToDouble();
    }
    return v.clamp(0, _bruto);
  }

  double get _totalConDesc => (_bruto - _descuentoCalc).clamp(0, double.infinity);

  double _brutoOf(List<Map<dynamic, dynamic>> items) =>
      items.fold(0.0, (s, x) => s + ((x['cantidad'] as num?)?.toDouble() ?? 0) * ((x['precio_unitario'] as num?)?.toDouble() ?? 0));

  double _descuentoOf(double bruto) {
    final v = double.tryParse(_discCtl.text) ?? 0;
    if (_discType == '%') return (bruto * v / 100).roundToDouble();
    return v.clamp(0, bruto);
  }

  double _totalOf(double bruto, double desc) => (bruto - desc).clamp(0, double.infinity);

  List<Map<dynamic, dynamic>> get _productosFiltrados {
    var list = _productos;
    if (_searchQ.isNotEmpty) {
      final q = _searchQ.toLowerCase();
      list = list.where((p) {
        final n = (p['nombre'] ?? '').toString().toLowerCase();
        final c = (p['codigo'] ?? '').toString().toLowerCase();
        return n.contains(q) || c.contains(q);
      }).toList();
    }
    if (_selectedCat.isNotEmpty) {
      list = list.where((p) => (p['categoria_id'] ?? '').toString() == _selectedCat).toList();
    }
    return list;
  }

  double _stockDisponible(Map<dynamic, dynamic> p) {
    final real = (p['stock_actual'] as num?)?.toDouble() ?? 0;
    final enCarrito = _cart
        .where((c) => (c['id'] ?? '').toString() == (p['id'] ?? '').toString())
        .fold<double>(0, (s, c) => s + ((c['cantidad'] as num?)?.toDouble() ?? 0));
    return (real - enCarrito).clamp(0, double.infinity);
  }

  String _unidadLabel(Map<dynamic, dynamic> p) {
    final u = (p['unidad_medida'] ?? p['unidad'] ?? 'und').toString();
    return u;
  }

  double _stepForUnit(String unidad) {
    final u = unidad.toLowerCase();
    return (['kg', 'g', 'lb', 'l', 'ml'].contains(u)) ? 0.1 : 1;
  }

  double _stepForProducto(Map<dynamic, dynamic> p) => _stepForUnit(_unidadLabel(p));

  double _stepForCartItem(int i) => _stepForUnit((_cart[i]['unidad'] ?? 'und').toString());

  bool _cajaAbierta() {
    if (_cajas.isEmpty) return false;
    return (_cajas.last['estado'] ?? '') == 'abierta';
  }

  Map<dynamic, dynamic>? _cajaActual() {
    if (!_cajaAbierta()) return null;
    return _cajas.last;
  }

  Map<dynamic, dynamic>? _findCliente(String query) {
    for (final c in _clientes) {
      if ((c['nombre'] ?? '').toString().toLowerCase() == query.toLowerCase()) return c;
    }
    return null;
  }

  // --- Cart Actions ---

  void _addToCart(Map<dynamic, dynamic> p) {
    final stockDisp = _stockDisponible(p);
    if (stockDisp <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stock agotado')),
      );
      return;
    }
    final pid = (p['id'] ?? '').toString();
    final i = _cart.indexWhere((c) => (c['id'] ?? '').toString() == pid);
    final step = _stepForProducto(p);
    setState(() {
      if (i >= 0) {
        _cart[i]['cantidad'] = ((_cart[i]['cantidad'] as num?)?.toDouble() ?? 0) + step;
      } else {
        _cart.add({
          'id': pid,
          'nombre': p['nombre'],
          'cantidad': step < 1 ? step : 1,
          'precio_unitario': p['precio_venta'],
          'stock_actual': p['stock_actual'],
          'precio_compra': p['precio_compra'] ?? 0,
          'codigo': p['codigo'] ?? '',
          'unidad': _unidadLabel(p),
        });
      }
    });
  }

  void _cambiarCantidad(int i, double delta) {
    if (i < 0 || i >= _cart.length) return;
    final item = _cart[i];
    final curr = (item['cantidad'] as num?)?.toDouble() ?? 1;
    final nueva = curr + delta;
    if (nueva <= 0) {
      _removerItem(i);
      return;
    }
    final stock = (item['stock_actual'] as num?)?.toDouble() ?? 0;
    if (nueva > stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stock insuficiente. Disponible: $stock')),
      );
      return;
    }
    setState(() => item['cantidad'] = nueva);
  }

  void _removerItem(int i) {
    setState(() {
      _cart.removeAt(i);
      _selectedItems.clear();
    });
  }

  void _toggleSelect(int i) {
    setState(() {
      if (_selectedItems.contains(i)) {
        _selectedItems.remove(i);
      } else {
        _selectedItems.add(i);
      }
    });
  }

  List<Map<dynamic, dynamic>> get _selectedCartItems =>
      _cart.asMap().entries.where((e) => _selectedItems.contains(e.key)).map((e) => e.value).toList();

  Future<void> _pausarVenta() async {
    if (_cart.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final json = _cart.map((c) => Map<String, dynamic>.from(c)).toList();
    await prefs.setString('venta_pausada', jsonEncode(json));
    setState(() {
      _cart.clear();
      _selectedItems.clear();
      _cartPaused = true;
    });
  }

  Future<void> _reanudarVenta() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('venta_pausada');
    if (raw == null) return;
    final list = (jsonDecode(raw) as List).map((e) => Map<dynamic, dynamic>.from(e as Map)).toList();
    await prefs.remove('venta_pausada');
    setState(() {
      _cart.addAll(list);
      _cartPaused = false;
    });
  }

  // --- Payment ---

  Future<void> _cobrar(String metodo, [List<Map<dynamic, dynamic>>? items]) async {
    if (_guardandoVenta) return;
    final aPagar = items ?? _cart;
    if (aPagar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El carrito esta vacio')),
      );
      return;
    }
    if (metodo != 'fiado' && !_cajaAbierta()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe abrir la caja antes de vender')),
      );
      return;
    }

    setState(() { _guardandoVenta = true; });

    try {
      final aPagarBruto = aPagar.fold(0.0, (s, x) => s + ((x['cantidad'] as num?)?.toDouble() ?? 0) * ((x['precio_unitario'] as num?)?.toDouble() ?? 0));
      double aPagarDescuento;
      final v = double.tryParse(_discCtl.text) ?? 0;
      if (_discType == '%') {
        aPagarDescuento = (aPagarBruto * v / 100).roundToDouble();
      } else {
        aPagarDescuento = v.clamp(0, aPagarBruto);
      }
      final aPagarTotal = (aPagarBruto - aPagarDescuento).clamp(0, double.infinity);

      // For fiado, require client
      if (metodo == 'fiado') {
        final name = _clientCtl.text.trim();
        if (name.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Escriba el nombre del cliente para fiar')),
          );
          return;
        }
        final cleanName = name.toLowerCase();
        var cliente = _selectedClient;
        if (cliente == null) {
          // Search in list case-insensitively and trimmed
          for (final c in _clientes) {
            if ((c['nombre'] ?? '').toString().trim().toLowerCase() == cleanName) {
              cliente = c;
              break;
            }
          }
        }
        if (cliente == null) {
          // auto-create client for fiado
          final nuevoCli = <dynamic, dynamic>{
            'id': DateTime.now().millisecondsSinceEpoch,
            'nombre': name,
            'credito_maximo': 0,
            'saldo_pendiente': 0,
          };
          _clientes.add(nuevoCli);
          _selectedClient = nuevoCli;
          await Fb.setList('clientes', _clientes);
        } else {
          _selectedClient = cliente;
        }
        if (!mounted) return;
        // Check credit limit
        if (_selectedClient != null) {
          final credMax = ((_selectedClient!['credito_maximo'] ?? _selectedClient!['creditoMaximo']) as num?)?.toDouble() ?? 0;
          final saldoPen = ((_selectedClient!['saldo_pendiente'] ?? _selectedClient!['saldoPendiente']) as num?)?.toDouble() ?? 0;
          if (credMax > 0 && (saldoPen + aPagarTotal) > credMax) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Supera el cupo de credito (\$${credMax.round()}). Debe: \$${saldoPen.round()}')),
            );
            return;
          }
        }
      }

      final ventasList = await Fb.getList('ventas');
      final nuevoId = ventasList.isEmpty
          ? 1
          : (ventasList.map((x) => (x['id'] as num?)?.toInt() ?? 0).reduce((a, b) => a > b ? a : b) + 1);

      final itemsVenta = aPagar.map((c) => <dynamic, dynamic>{
        'id': c['id'],
        'nombre': c['nombre'],
        'cantidad': c['cantidad'],
        'precio_unitario': c['precio_unitario'],
        'precio_compra': c['precio_compra'] ?? 0,
        'subtotal': ((c['cantidad'] as num?)?.toDouble() ?? 0) * ((c['precio_unitario'] as num?)?.toDouble() ?? 0),
      }).toList();

      final venta = <dynamic, dynamic>{
        'id': nuevoId,
        'fecha': DateTime.now().toIso8601String().substring(0, 10),
        'created_at': DateTime.now().toIso8601String(),
'cliente': _selectedClient?['nombre'] ?? (_clientCtl.text.trim().isEmpty ? 'Mostrador' : _clientCtl.text.trim()),
        'cliente_id': _selectedClient?['id'],
        'items': itemsVenta,
        'total': aPagarTotal,
        'descuento': aPagarDescuento,
        'metodo_pago': metodo,
        'metodo_pago_2': null,
        'monto_1': aPagarTotal,
        'monto_2': 0,
        'usuario': 'Sistema',
        'caja_id': _cajaActual()?['id'],
      };

      ventasList.add(venta);
      await Fb.setList('ventas', ventasList);

      // Update product stock
      for (final c in aPagar) {
        final pid = (c['id'] ?? '').toString();
        final idx = _productos.indexWhere((p) => (p['id'] ?? '').toString() == pid);
        if (idx >= 0) {
          final currentStock = (_productos[idx]['stock_actual'] as num?)?.toDouble() ?? 0;
          final qty = (c['cantidad'] as num?)?.toDouble() ?? 0;
          _productos[idx]['stock_actual'] = (currentStock - qty).clamp(0, double.infinity);
        }
      }
      await Fb.setList('productos', _productos);

      // Update caja: add movimiento and recalculate accumulators
      if (metodo != 'fiado' && _cajaAbierta()) {
        final actual = _cajaActual()!;
        final idx = _cajas.indexWhere((x) => x['id'] == actual['id']);
        if (idx >= 0) {
          final movs = List<Map<dynamic, dynamic>>.from(_cajas[idx]['movimientos'] ?? []);
          movs.add({
            'tipo': 'ingreso',
            'concepto': 'Venta #$nuevoId',
            'monto': aPagarTotal,
            'metodo_pago': metodo,
            'fecha': DateTime.now().toIso8601String(),
          });
          _cajas[idx]['movimientos'] = movs;
          _cajas[idx]['ingresos'] = movs
              .where((m) => m['tipo'] == 'ingreso')
              .fold<double>(0, (s, m) => s + ((m['monto'] as num?)?.toDouble() ?? 0));
          _cajas[idx]['egresos'] = movs
              .where((m) => m['tipo'] != 'ingreso')
              .fold<double>(0, (s, m) => s + ((m['monto'] as num?)?.toDouble() ?? 0));
          await Fb.setList('cajas', _cajas);
        }
      }

      // Create fiado record if fiado
      if (metodo == 'fiado' && _selectedClient != null) {
        final fiadosList = await Fb.getList('fiados');
        final fiadoId = fiadosList.isEmpty
            ? 1
            : (fiadosList.map((x) => (x['id'] as num?)?.toInt() ?? 0).reduce((a, b) => a > b ? a : b) + 1);
        for (final c in aPagar) {
          fiadosList.add(<dynamic, dynamic>{
            'id': fiadoId + fiadosList.length,
            'venta_id': nuevoId,
            'cliente_id': _selectedClient!['id'],
            'cliente_nombre': _selectedClient!['nombre'],
            'producto_id': c['id'],
            'producto_nombre': c['nombre'],
            'cantidad': c['cantidad'],
            'precio_unitario': c['precio_unitario'],
            'monto': ((c['cantidad'] as num?)?.toDouble() ?? 0) * ((c['precio_unitario'] as num?)?.toDouble() ?? 0),
            'saldo': ((c['cantidad'] as num?)?.toDouble() ?? 0) * ((c['precio_unitario'] as num?)?.toDouble() ?? 0),
            'fecha': DateTime.now().toIso8601String().substring(0, 10),
            'estado': 'Pendiente',
          });
        }
        await Fb.setList('fiados', fiadosList);

        // Update client saldo pendiente
        if (_selectedClient != null) {
          final cliIdx = _clientes.indexWhere((x) => x['id'] == _selectedClient!['id']);
          if (cliIdx >= 0) {
            final current = (_clientes[cliIdx]['saldo_pendiente'] ?? _clientes[cliIdx]['saldoPendiente'] ?? 0).toDouble();
            _clientes[cliIdx]['saldo_pendiente'] = current + aPagarTotal;
            await Fb.setList('clientes', _clientes);
          }
        }
      }

      // Remove paid items from cart
      final paidIds = aPagar.map((c) => (c['id'] ?? '').toString()).toSet();
      setState(() {
        _cart.removeWhere((c) => paidIds.contains((c['id'] ?? '').toString()));
        _selectedItems.clear();
        _clientCtl.clear();
        _selectedClient = null;
        _discCtl.text = '0';
      });

      if (mounted) {
        _mostrarRecibo(venta);
      }
    } finally {
      if (mounted) {
        setState(() { _guardandoVenta = false; });
      }
    }
  }

  Future<void> _cobrarMixto() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El carrito esta vacio')),
      );
      return;
    }
    if (!_cajaAbierta()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe abrir la caja antes de vender')),
      );
      return;
    }

    final ef = double.tryParse(_splitEfecCtl.text) ?? 0;
    final tj = double.tryParse(_splitTarjCtl.text) ?? 0;

    if ((ef + tj) < _totalConDesc - 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El monto no cubre el total')),
      );
      return;
    }

    final ventasList = await Fb.getList('ventas');
    final nuevoId = ventasList.isEmpty
        ? 1
        : (ventasList.map((x) => (x['id'] as num?)?.toInt() ?? 0).reduce((a, b) => a > b ? a : b) + 1);

    final itemsVenta = _cart.map((c) => <dynamic, dynamic>{
      'id': c['id'],
      'nombre': c['nombre'],
      'cantidad': c['cantidad'],
      'precio_unitario': c['precio_unitario'],
      'precio_compra': c['precio_compra'] ?? 0,
      'subtotal': ((c['cantidad'] as num?)?.toDouble() ?? 0) * ((c['precio_unitario'] as num?)?.toDouble() ?? 0),
    }).toList();

    final venta = <dynamic, dynamic>{
      'id': nuevoId,
      'fecha': DateTime.now().toIso8601String().substring(0, 10),
      'cliente': _selectedClient?['nombre'] ?? (_clientCtl.text.trim().isEmpty ? 'Mostrador' : _clientCtl.text.trim()),
      'cliente_id': _selectedClient?['id'],
      'items': itemsVenta,
      'total': _totalConDesc,
      'descuento': _descuentoCalc,
      'metodo_pago': 'efectivo',
      'metodo_pago_2': 'tarjeta',
      'monto_1': ef,
      'monto_2': tj,
      'usuario': 'Sistema',
      'caja_id': _cajaActual()?['id'],
    };

    ventasList.add(venta);
    await Fb.setList('ventas', ventasList);

    // Update stock
    for (final c in _cart) {
      final pid = (c['id'] ?? '').toString();
      final idx = _productos.indexWhere((p) => (p['id'] ?? '').toString() == pid);
      if (idx >= 0) {
        final currentStock = (_productos[idx]['stock_actual'] as num?)?.toDouble() ?? 0;
        final qty = (c['cantidad'] as num?)?.toDouble() ?? 0;
        _productos[idx]['stock_actual'] = (currentStock - qty).clamp(0, double.infinity);
      }
    }
    await Fb.setList('productos', _productos);

    // Update caja: add movimientos and recalculate accumulators
    if (_cajaAbierta()) {
      final actual = _cajaActual()!;
      final idx = _cajas.indexWhere((x) => x['id'] == actual['id']);
      if (idx >= 0) {
        final movs = List<Map<dynamic, dynamic>>.from(_cajas[idx]['movimientos'] ?? []);
        if (ef > 0) {
          movs.add({
            'tipo': 'ingreso',
            'concepto': 'Venta #$nuevoId (efectivo)',
            'monto': ef,
            'metodo_pago': 'efectivo',
            'fecha': DateTime.now().toIso8601String(),
          });
        }
        if (tj > 0) {
          movs.add({
            'tipo': 'ingreso',
            'concepto': 'Venta #$nuevoId (tarjeta)',
            'monto': tj,
            'metodo_pago': 'tarjeta',
            'fecha': DateTime.now().toIso8601String(),
          });
        }
        _cajas[idx]['movimientos'] = movs;
        _cajas[idx]['ingresos'] = movs
            .where((m) => m['tipo'] == 'ingreso')
            .fold<double>(0, (s, m) => s + ((m['monto'] as num?)?.toDouble() ?? 0));
        _cajas[idx]['egresos'] = movs
            .where((m) => m['tipo'] != 'ingreso')
            .fold<double>(0, (s, m) => s + ((m['monto'] as num?)?.toDouble() ?? 0));
        await Fb.setList('cajas', _cajas);
      }
    }

    setState(() {
      _cart.clear();
      _selectedItems.clear();
      _clientCtl.clear();
      _selectedClient = null;
      _discCtl.text = '0';
    });

    if (mounted) _mostrarRecibo(venta);
  }

  void _mostrarRecibo(Map<dynamic, dynamic> venta) {
    final items = (venta['items'] as List?) ?? [];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        title: Row(children: [
          const Icon(Icons.check_circle, color: Tema.primary, size: 28),
          SizedBox(width: 8),
          const Text('Venta Registrada', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ]),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _reciboLine('Cliente', '${venta['cliente'] ?? 'Mostrador'}'),
              _reciboLine('Fecha', '${venta['fecha']}'),
              _reciboLine('Metodo', '${venta['metodo_pago']}${venta['metodo_pago_2'] != null ? ' + ${venta['metodo_pago_2']}' : ''}'),
              const Divider(),
              ...items.map((it) => Padding(
                padding: EdgeInsets.symmetric(vertical: 2),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Expanded(child: Text('${it['cantidad']}x ${it['nombre']}', style: const TextStyle(fontSize: 12))),
                  Text(Fb.formatMoney(it['subtotal'] ?? 0), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              )),
              const Divider(),
              _reciboLine('Total', Fb.formatMoney(venta['total'] ?? 0), bold: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _reciboLine(String label, String value, {bool bold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: 13, color: Tema.textSoft)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: Tema.textDark)),
      ]),
    );
  }

  // --- Barcode Scanner ---

  void _mostrarScannerPos() {
    showDialog(
      context: context,
      builder: (ctx) => _ScannerDialog(
        onScan: (barcode) {
          final matches = _productos.where((p) {
            final cod = (p['codigo'] ?? '').toString();
            final cb = (p['codigo_barras'] ?? '').toString();
            return cod == barcode || cb == barcode;
          }).toList();
          if (matches.isNotEmpty) {
            _addToCart(matches.first);
          } else {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text('Producto no encontrado: $barcode')),
            );
          }
        },
      ),
    );
  }

  // --- Payment Modal ---

  void _mostrarPagoModal({List<Map<dynamic, dynamic>>? items}) {
    final payItems = items ?? _cart;
    final payBruto = _brutoOf(payItems);
    final payDesc = _descuentoOf(payBruto);
    final payTotal = _totalOf(payBruto, payDesc);

    if (payItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El carrito esta vacio')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Tema.radiusLg)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Tema.cardBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Text('Cobrar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Tema.textDark)),
                SizedBox(height: 4),
                Text('Total: ${Fb.formatMoney(payTotal)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Tema.primary)),
                SizedBox(height: 16),
                // Payment method tabs
                Row(children: [
                  _payTab('Efectivo', Icons.money, Tema.primary, _payMethod == 'efectivo', () => setSheet(() => _payMethod = 'efectivo')),
                  SizedBox(width: 8),
                  _payTab('Tarjeta', Icons.credit_card, Tema.darkBlue, _payMethod == 'tarjeta', () => setSheet(() => _payMethod = 'tarjeta')),
                  SizedBox(width: 8),
                  _payTab('Fiado', Icons.credit_score, Tema.kpiAccents[2], _payMethod == 'fiado', () => setSheet(() => _payMethod = 'fiado')),
                ]),
                SizedBox(height: 16),
                // Client field
                TextField(
                  controller: _clientCtl,
                  decoration: InputDecoration(
                    labelText: _payMethod == 'fiado' ? 'Cliente (obligatorio para fiado)' : 'Cliente (opcional)',
                    prefixIcon: Icon(Icons.person, color: Tema.textMuted),
                    suffixIcon: _clientCtl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _clientCtl.clear();
                              setSheet(() => _selectedClient = null);
                            },
                          )
                        : null,
                  ),
                  onChanged: (v) => setSheet(() {
                    _selectedClient = _findCliente(v);
                  }),
                ),
                if (_clientCtl.text.isNotEmpty && _selectedClient == null)
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: TextButton(
                      onPressed: () {
                        final nuevo = <dynamic, dynamic>{
                          'id': DateTime.now().millisecondsSinceEpoch,
                          'nombre': _clientCtl.text.trim(),
                          'credito_maximo': 0,
                          'saldo_pendiente': 0,
                        };
                        _clientes.add(nuevo);
                        _selectedClient = nuevo;
                        Fb.setList('clientes', _clientes);
                        setSheet(() {});
                      },
                      child: Text('Crear cliente "${_clientCtl.text.trim()}"'),
                    ),
                  ),
                // Client suggestions
                if (_clientCtl.text.length >= 2)
                  ..._clientes
                      .where((c) => (c['nombre'] ?? '').toString().toLowerCase().contains(_clientCtl.text.toLowerCase()))
                      .take(5)
                      .map((c) => ListTile(
                            dense: true,
                            leading: const Icon(Icons.person_outline, size: 18),
                            title: Text('${c['nombre']}', style: const TextStyle(fontSize: 13)),
                            trailing: Text(
                              'Cred: \$${(c['credito_maximo'] ?? c['creditoMaximo'] ?? 0).round()}',
                              style: TextStyle(fontSize: 11, color: Tema.textSoft),
                            ),
                            onTap: () {
                              _clientCtl.text = '${c['nombre']}';
                              _selectedClient = c;
                              setSheet(() {});
                            },
                          )),
                SizedBox(height: 12),
                // Efectivo fields
                if (_payMethod == 'efectivo') ...[
                  TextField(
                    controller: _efectivoCtl,
                    decoration: InputDecoration(
                      labelText: 'Monto recibido',
                      prefixText: '\$ ',
                      prefixIcon: Icon(Icons.payments, color: Tema.textMuted),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setSheet(() {}),
                  ),
                  if ((double.tryParse(_efectivoCtl.text) ?? 0) > 0)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(Tema.radiusSm),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('Cambio:', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                            Fb.formatMoney(((double.tryParse(_efectivoCtl.text) ?? 0) - payTotal).clamp(0, double.infinity)),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.green),
                          ),
                        ]),
                      ),
                    ),
                  // Quick amounts
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Wrap(spacing: 6, runSpacing: 6, children: [2000, 5000, 10000, 20000, 50000].map((v) {
                      return ActionChip(
                        label: Text(Fb.formatMoney(v), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        onPressed: () {
                          _efectivoCtl.text = '$v';
                          setSheet(() {});
                        },
                      );
                    }).toList()),
                  ),
                ],
                // Tarjeta fields
                if (_payMethod == 'tarjeta') ...[
                  TextField(
                    controller: _tarjetaRefCtl,
                    decoration: InputDecoration(
                      labelText: 'No. de referencia (opcional)',
                      prefixIcon: Icon(Icons.credit_card, color: Tema.textMuted),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
                // Fiado info
                if (_payMethod == 'fiado' && _selectedClient != null) ...[
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(Tema.radiusSm),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(children: [
                      const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        'Cupo: \$${((_selectedClient!['credito_maximo'] ?? _selectedClient!['creditoMaximo'] ?? 0) as num).round()} | '
                        'Debe: \$${((_selectedClient!['saldo_pendiente'] ?? _selectedClient!['saldoPendiente'] ?? 0) as num).round()}',
                        style: TextStyle(fontSize: 12, color: Tema.textDark),
                      ),
                    ]),
                  ),
                ],
                SizedBox(height: 16),
                // Cobrar button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                  onPressed: () {
                      Navigator.pop(ctx);
                      final metodo = _payMethod;
                      if (metodo == 'efectivo') {
                        final montoRec = double.tryParse(_efectivoCtl.text) ?? 0;
                        if (montoRec < payTotal) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('El monto recibido no cubre el total')),
                          );
                          return;
                        }
                      }
                      _cobrar(metodo, items);
                      _efectivoCtl.clear();
                      _tarjetaRefCtl.clear();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _payMethod == 'fiado' ? Tema.kpiAccents[2] : Tema.primary,
                    ),
                    child: Text(
                      _payMethod == 'efectivo'
                          ? 'Cobrar Efectivo'
                          : _payMethod == 'tarjeta'
                              ? 'Cobrar Tarjeta'
                              : 'Registrar Fiado',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                // Split payment button (full cart only)
                if (items == null) ...[
                SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _mostrarSplitPago();
                    },
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Pago Mixto (Efectivo + Tarjeta)'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Tema.kpiAccents[3],
                      side: BorderSide(color: Tema.kpiAccents[3]),
                    ),
                    ),
                  ),
            ],
          ],
        )),
      ),
    ),
  );
}

  Widget _payTab(String label, IconData icon, Color color, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.92) : Colors.white,
            borderRadius: BorderRadius.circular(Tema.radiusSm),
            border: Border.all(color: selected ? color : Tema.cardBorder),
          ),
          child: Column(children: [
            Icon(icon, color: selected ? Colors.white : color, size: 22),
            SizedBox(height: 4),
            Text(label, style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : Tema.textDark,
            )),
          ]),
        ),
      ),
    );
  }

  // --- Split Payment Modal ---

  void _mostrarSplitPago() {
    final efecCtl = TextEditingController();
    final tarjCtl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          final ef = double.tryParse(efecCtl.text) ?? 0;
          final tj = double.tryParse(tarjCtl.text) ?? 0;
          final restante = _totalConDesc - ef - tj;
          final cubre = restante <= 0;

          return AlertDialog(
            insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            title: Row(children: [
              const Icon(Icons.swap_horiz, color: Color(0xFF3b5998)),
              SizedBox(width: 8),
              const Text('Pago Mixto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ]),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
              child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Total a pagar: ${Fb.formatMoney(_totalConDesc)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Tema.primary)),
                SizedBox(height: 16),
                TextField(
                  controller: efecCtl,
                  decoration: const InputDecoration(labelText: 'Efectivo', prefixText: '\$ '),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setDlg(() {}),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: tarjCtl,
                  decoration: const InputDecoration(labelText: 'Tarjeta', prefixText: '\$ '),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setDlg(() {}),
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cubre ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(Tema.radiusSm),
                  ),
                  child: Text(
                    cubre ? 'Cubre! Vuelto: ${Fb.formatMoney(restante.abs())}' : 'Faltan: ${Fb.formatMoney(restante)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: cubre ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ))),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: cubre
                    ? () {
                        _splitEfecCtl.text = efecCtl.text;
                        _splitTarjCtl.text = tarjCtl.text;
                        Navigator.pop(ctx);
                        _cobrarMixto();
                      }
                    : null,
                child: const Text('Pagar'),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    final filtrados = _productosFiltrados;
    final cajaOk = _cajaAbierta();

    return SafeArea(
      child: Column(children: [
      // Search bar
      Padding(
        padding: EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Tema.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Tema.radiusSm),
              border: Border.all(color: Tema.primary.withValues(alpha: 0.3)),
            ),
            child: IconButton(
              icon: const Icon(Icons.qr_code_scanner, color: Tema.primary, size: 22),
              onPressed: _mostrarScannerPos,
              tooltip: 'Escanear codigo de barras',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            ),
          ),
          Expanded(
            child: SearchInput(
              controller: _searchCtl,
              hintText: 'Buscar producto o codigo...',
              onChanged: (v) => setState(() => _searchQ = v),
            ),
          ),
          if (_searchQ.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear, size: 20, color: Tema.textMuted),
              onPressed: () {
                _searchCtl.clear();
                setState(() => _searchQ = '');
              },
            ),
        ]),
      ),
      // Category filter chips
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(children: [
          _catChip('Todas', '', _selectedCat.isEmpty),
          ..._categorias.map((cat) => _catChip(
                '${cat['nombre']}',
                '${cat['id']}',
                _selectedCat == '${cat['id']}',
              )),
        ]),
      ),
      // Caja status badge
      if (!cajaOk)
        Container(
          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(Tema.radiusSm),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.warning_amber, size: 16, color: Tema.danger),
            SizedBox(width: 6),
            Text('Caja cerrada. Solo ventas a fiado.', style: TextStyle(fontSize: 12, color: Tema.danger, fontWeight: FontWeight.w600)),
          ]),
        ),
      // Paused sale badge
      if (_cartPaused)
        GestureDetector(
          onTap: () => _reanudarVenta(),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(Tema.radiusSm),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.pause_circle_filled, size: 18, color: Color(0xFFb8860b)),
              SizedBox(width: 8),
              Text('Venta Pausada', style: TextStyle(fontSize: 13, color: Color(0xFFb8860b), fontWeight: FontWeight.w700)),
              Spacer(),
              Icon(Icons.touch_app, size: 16, color: Color(0xFFb8860b)),
              SizedBox(width: 4),
              Text('Toca para restaurar', style: TextStyle(fontSize: 11, color: Color(0xFFb8860b))),
            ]),
          ),
        ),
      // Product grid
      Expanded(
        child: filtrados.isEmpty
            ? Center(child: Text('No se encontraron productos', style: TextStyle(color: Tema.textMuted)))
            : GridView.builder(
                padding: EdgeInsets.fromLTRB(12, 6, 12, 12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: filtrados.length,
                itemBuilder: (_, i) => _productoCard(filtrados[i]),
              ),
      ),
      // Cart panel
      if (_cart.isNotEmpty)
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(Tema.radiusLg)),
            boxShadow: [Tema.shadowLg],
            border: Border.all(color: Tema.cardBorder),
          ),
          margin: EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cart header
              InkWell(
                onTap: () => setState(() => _cartExpanded = !_cartExpanded),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(children: [
                    const Icon(Icons.shopping_cart, size: 18, color: Tema.primary),
                    SizedBox(width: 6),
                    Text('Carrito (${_cart.length})', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Tema.textDark)),
                    const Spacer(),
                    Text(Fb.formatMoney(_totalConDesc), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Tema.primary)),
                    SizedBox(width: 6),
                    Icon(_cartExpanded ? Icons.expand_more : Icons.expand_less, color: Tema.textSoft),
                  ]),
                ),
              ),
              if (_cartExpanded) ...[
                const Divider(height: 1),
                // Discount section
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(children: [
                    const Icon(Icons.local_offer, size: 16, color: Colors.orange),
                    SizedBox(width: 6),
                    Text('Descuento', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Tema.textDark)),
                    SizedBox(width: 8),
                    SizedBox(
                      width: 70,
                      height: 32,
                      child: TextField(
                        controller: _discCtl,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Tema.cardBorder)),
                        ),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    SizedBox(width: 4),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: '%', label: Text('%', style: TextStyle(fontSize: 11))),
                        ButtonSegment(value: '\$', label: Text('\$', style: TextStyle(fontSize: 11))),
                      ],
                      selected: {_discType},
                      onSelectionChanged: (v) => setState(() {
                        _discType = v.first;
                        _discCtl.text = '0';
                      }),
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const Spacer(),
                    if (_descuentoCalc > 0)
                      Text('-\$${_descuentoCalc.round()}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.orange)),
                  ]),
                ),
                const Divider(height: 1),
                // Cart items
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.40),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    itemCount: _cart.length,
                    itemBuilder: (_, i) => _cartItem(i),
                  ),
                ),
                const Divider(height: 1),
                // Buttons
                if (_selectedItems.isNotEmpty) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: SizedBox(
                      height: 40,
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _mostrarPagoModal(items: _selectedCartItems),
                        icon: const Icon(Icons.checklist, size: 18),
                        label: Text('Pagar Seleccionados (${_selectedItems.length})', style: const TextStyle(fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Tema.kpiAccents[2],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tema.radiusSm)),
                        ),
                      ),
                    ),
                  ),
                ],
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Row(children: [
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: () => _mostrarPagoModal(),
                          icon: const Icon(Icons.payment, size: 18),
                          label: const Text('Cobrar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Tema.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tema.radiusSm)),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          onPressed: () => _pausarVenta(),
                          style: OutlinedButton.styleFrom(foregroundColor: Tema.darkBlue),
                          child: const Text('Pausar', style: TextStyle(fontSize: 11)),
                        ),
                      ),
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          onPressed: () => setState(() { _cart.clear(); _selectedItems.clear(); }),
                          style: OutlinedButton.styleFrom(foregroundColor: Tema.danger),
                          child: const Text('Vaciar', style: TextStyle(fontSize: 11)),
                        ),
                      ),
                    ),
                  ]),
                ),
              ],
            ],
          ),
        ),
    ]));
  }

  Widget _catChip(String label, String catId, bool selected) {
    return Padding(
      padding: EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : Tema.textDark)),
        selected: selected,
        onSelected: (_) => setState(() => _selectedCat = selected ? '' : catId),
        selectedColor: Tema.primary,
        checkmarkColor: Colors.white,
        backgroundColor: Colors.white,
        side: BorderSide(color: selected ? Tema.primary : Tema.cardBorder),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _productoCard(Map<dynamic, dynamic> p) {
    final stockDisp = _stockDisponible(p);
    final stockReal = (p['stock_actual'] as num?)?.toDouble() ?? 0;
    final minStock = (p['stock_minimo'] as num?)?.toDouble() ?? 5;
    final agotado = stockDisp <= 0;
    final bajo = !agotado && stockReal <= minStock;
    final enCarrito = _cart
        .where((c) => (c['id'] ?? '').toString() == (p['id'] ?? '').toString())
        .fold<double>(0, (s, c) => s + ((c['cantidad'] as num?)?.toDouble() ?? 0));
    final unidad = _unidadLabel(p);
    final isDecimal = ['kg', 'g', 'lb', 'l', 'ml'].contains(unidad.toLowerCase());

    return Container(
      decoration: Tema.cardDeco,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(Tema.radius),
        child: InkWell(
          onTap: agotado ? null : () => _addToCart(p),
          borderRadius: BorderRadius.circular(Tema.radius),
          child: Padding(
            padding: EdgeInsets.all(10),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${p['nombre']}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: agotado ? Tema.textMuted : Tema.textDark,
                      ),
                    ),
                    const Spacer(),
                    Row(children: [
                      Text(
                        Fb.formatMoney(p['precio_venta'] ?? 0),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: agotado ? Tema.textMuted : Tema.primary,
                        ),
                      ),
                      SizedBox(width: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '/ $unidad',
                          style: TextStyle(fontSize: 9, color: Tema.textSoft, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ]),
                    SizedBox(height: 4),
                    Row(children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: agotado
                              ? Colors.red.shade50
                              : bajo
                                  ? Colors.orange.shade50
                                  : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: agotado
                                ? Colors.red.shade200
                                : bajo
                                    ? Colors.orange.shade200
                                    : Colors.green.shade200,
                          ),
                        ),
                        child: Text(
                          '${isDecimal ? stockDisp.toStringAsFixed(1) : stockDisp.toInt().toString()} $unidad',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: agotado
                                ? Colors.red.shade700
                                : bajo
                                    ? Colors.orange.shade700
                                    : Colors.green.shade700,
                          ),
                        ),
                      ),
                      if (enCarrito > 0) ...[
                        SizedBox(width: 4),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Tema.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '+${isDecimal ? enCarrito.toStringAsFixed(1) : enCarrito.toInt().toString()}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Tema.primary),
                          ),
                        ),
                      ],
                    ]),
                  ],
                ),
                if (enCarrito > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Tema.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${isDecimal ? enCarrito.toStringAsFixed(1) : enCarrito.toInt()}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cartItem(int i) {
    final item = _cart[i];
    final qty = (item['cantidad'] as num?)?.toDouble() ?? 1;
    final precio = (item['precio_unitario'] as num?)?.toDouble() ?? 0;
    final subtotal = qty * precio;
    final unidad = (item['unidad'] ?? 'und').toString();
    final step = _stepForCartItem(i);
    final checked = _selectedItems.contains(i);
    final isDecimal = ['kg', 'g', 'lb', 'l', 'ml'].contains(unidad.toLowerCase());

    return Dismissible(
      key: Key('cart_${item['id']}_$i'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.delete, color: Tema.danger),
      ),
      onDismissed: (_) => _removerItem(i),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 3),
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: checked ? Tema.primary.withValues(alpha: 0.5) : Tema.cardBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          SizedBox(
            width: 28,
            height: 28,
            child: Checkbox(
              value: checked,
              onChanged: (_) => _toggleSelect(i),
              activeColor: Tema.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${item['nombre']}', maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Tema.textDark)),
                Text('${Fb.formatMoney(precio)} / $unidad',
                    style: TextStyle(fontSize: 11, color: Tema.textSoft)),
              ],
            ),
          ),
          Row(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              width: 28,
              height: 28,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.remove_circle_outline, size: 20, color: Tema.textSoft),
                onPressed: () => _cambiarCantidad(i, -step),
              ),
            ),
            SizedBox(
              width: 40,
              child: Text(
                isDecimal ? qty.toStringAsFixed(1) : '${qty.toInt()}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Tema.textDark),
              ),
            ),
            SizedBox(
              width: 28,
              height: 28,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.add_circle, size: 20, color: Tema.primary),
                onPressed: () => _cambiarCantidad(i, step),
              ),
            ),
            SizedBox(width: 6),
            SizedBox(
              width: 60,
              child: Text(
                Fb.formatMoney(subtotal),
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Tema.textDark),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _ScannerDialog extends StatefulWidget {
  final void Function(String barcode) onScan;
  const _ScannerDialog({required this.onScan});
  @override
  State<_ScannerDialog> createState() => _ScannerDialogState();
}

class _ScannerDialogState extends State<_ScannerDialog> {
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
                  _scanned = true;
                  widget.onScan(barcode);
                  Navigator.pop(context);
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

