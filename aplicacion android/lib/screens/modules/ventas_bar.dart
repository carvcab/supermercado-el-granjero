import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/firestore_service.dart';
import '../../theme.dart';

class BarScreen extends StatefulWidget {
  const BarScreen({super.key});
  @override
  State<BarScreen> createState() => _BarScreenState();
}

class _BarScreenState extends State<BarScreen> {
  List<Map<dynamic, dynamic>> _cuentas = [];
  List<Map<dynamic, dynamic>> _clientes = [];
  StreamSubscription? _subAc;
  StreamSubscription? _subCl;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _subAc = Fb.stream('ventas_bar_cuentas').listen((d) => setState(() => _cuentas = d));
    _subCl = Fb.stream('clientes').listen((d) => setState(() => _clientes = d));
    _loadClientes();
  }

  Future<void> _loadClientes() async {
    final l = await Fb.getList('clientes');
    if (mounted) setState(() => _clientes = l);
  }

  @override
  void dispose() {
    _subAc?.cancel();
    _subCl?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  String _tiempoDesde(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays >= 1) return '${diff.inDays}d';
      if (diff.inHours >= 1) return '${diff.inHours}h';
      if (diff.inMinutes >= 1) return '${diff.inMinutes}min';
      return 'ahora';
    } catch (_) {
      return '';
    }
  }

  Future<void> _nuevaCuenta() async {
    final mesaCtrl = TextEditingController();
    final clienteCtrl = TextEditingController();
    dynamic clienteId;
    String clienteNom = '';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          final q = clienteCtrl.text.toLowerCase();
          final sugerencias = q.isEmpty
              ? <Map<dynamic, dynamic>>[]
              : _clientes.where((c) {
                  final n = (c['nombre'] ?? '').toString().toLowerCase();
                  final d = (c['numero_documento'] ?? '').toString().toLowerCase();
                  return n.contains(q) || d.contains(q);
                }).take(5).toList();
          return AlertDialog(
            title: const Text('Nueva Cuenta', style: TextStyle(fontWeight: FontWeight.w700, color: Tema.primary)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tema.radiusLg)),
            content: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.65),
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(
                    controller: mesaCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Nombre / Mesa',
                      hintText: 'Ej: Mesa 5',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: clienteCtrl,
                    decoration: InputDecoration(
                      labelText: 'Cliente',
                      hintText: 'Buscar o escribir nombre...',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      prefixIcon: const Icon(Icons.person_outline, size: 20),
                      suffixIcon: clienteNom.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.check_circle, size: 18, color: Tema.primary),
                              onPressed: null,
                            )
                          : null,
                    ),
                    onChanged: (v) => setSt(() {
                      clienteId = null;
                      clienteNom = '';
                    }),
                  ),
                  if (sugerencias.isNotEmpty) ...[
                    SizedBox(height: 4),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 160),
                      decoration: BoxDecoration(
                        border: Border.all(color: Tema.cardBorder),
                        borderRadius: BorderRadius.circular(Tema.radiusSm),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: sugerencias.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final c = sugerencias[i];
                          final nom = c['nombre'] ?? '';
                          final doc = c['numero_documento'] ?? '';
                          final tel = c['telefono'] ?? '';
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              backgroundColor: Tema.primary,
                              radius: 14,
                              child: Text(nom.toString().isNotEmpty ? nom.toString()[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                            ),
                            title: Text(nom.toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            subtitle: Text([doc, tel].where((s) => s.toString().isNotEmpty).join(' - '),
                                style: TextStyle(fontSize: 11, color: Tema.textMuted)),
                            onTap: () {
                              clienteCtrl.text = nom.toString();
                              clienteId = c['id'];
                              clienteNom = nom.toString();
                              setSt(() {});
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ]),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () {
                  if (mesaCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Ingrese un nombre de mesa')));
                    return;
                  }
                  if (clienteNom.isEmpty) clienteNom = clienteCtrl.text.trim();
                  if (clienteNom.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Ingrese o seleccione un cliente')));
                    return;
                  }
                  Navigator.pop(ctx, true);
                },
                child: const Text('Crear'),
              ),
            ],
          );
        },
      ),
    );
    if (ok != true || mesaCtrl.text.trim().isEmpty) return;
    if (clienteNom.isEmpty) clienteNom = clienteCtrl.text.trim();
    if (clienteNom.isEmpty) return;

    final id = _cuentas.isEmpty ? 1 : _cuentas.map((x) => x['id'] as int).reduce((a, b) => a > b ? a : b) + 1;
    _cuentas.add({
      'id': id,
      'mesa': mesaCtrl.text.trim(),
      'cliente_id': clienteId,
      'cliente_nombre': clienteNom,
      'items': <Map<dynamic, dynamic>>[],
      'total': 0,
      'estado': 'activa',
      'fecha_apertura': DateTime.now().toIso8601String(),
    });
    await Fb.setList('ventas_bar_cuentas', _cuentas);
  }

  Future<void> _cancelarCuenta(Map<dynamic, dynamic> cuenta) async {
    final conf = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar Cuenta'),
        content: Text('¿Cancelar la cuenta "${cuenta['mesa']}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, cancelar', style: TextStyle(color: Tema.danger)),
          ),
        ],
      ),
    );
    if (conf != true) return;
    _cuentas.removeWhere((c) => c['id'] == cuenta['id']);
    await Fb.setList('ventas_bar_cuentas', _cuentas);
  }

  @override
  Widget build(BuildContext context) {
    final filtradas = _searchQuery.isEmpty
        ? _cuentas
        : _cuentas.where((x) {
            final mesa = (x['mesa'] ?? '').toString().toLowerCase();
            final cliente = (x['cliente_nombre'] ?? '').toString().toLowerCase();
            final q = _searchQuery.toLowerCase();
            return mesa.contains(q) || cliente.contains(q);
          }).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _nuevaCuenta,
        child: const Icon(Icons.add),
      ),
      body: Column(children: [
        Padding(
          padding: EdgeInsets.all(10),
          child: SearchInput(
            controller: _searchCtrl,
            hintText: 'Buscar cuenta...',
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        Expanded(
          child: filtradas.isEmpty
              ? ListView(
                  children: [
                    SizedBox(height: 80),
                    Icon(Icons.receipt_long, color: Tema.textMuted, size: 48),
                    SizedBox(height: 12),
                    Text('Sin cuentas activas', textAlign: TextAlign.center,
                        style: TextStyle(color: Tema.textMuted, fontSize: 15)),
                  ],
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  itemCount: filtradas.length,
                  itemBuilder: (_, i) {
                    final x = filtradas[i];
                    final activa = x['estado'] == 'activa';
                    final items = (x['items'] as List?) ?? [];
                    final total = (x['total'] ?? 0).toDouble();
                    return _buildCuentaCard(x, activa, items.length, total);
                  },
                ),
        ),
      ]),
    );
  }

  Widget _buildCuentaCard(Map<dynamic, dynamic> x, bool activa, int count, double total) {
    final mesa = x['mesa'] ?? 'Sin nombre';
    final cliente = x['cliente_nombre'] ?? '';
    final tiempo = _tiempoDesde(x['fecha_apertura'] as String?);

    return Dismissible(
      key: ValueKey('cuenta_${x['id']}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await _cancelarCuenta(x);
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        margin: EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: Tema.danger,
          borderRadius: BorderRadius.circular(Tema.radius),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cancel, color: Colors.white),
            SizedBox(height: 2),
            Text('Cancelar', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: Tema.cardBg,
          borderRadius: BorderRadius.circular(Tema.radius),
          border: Border.all(color: activa ? Tema.primary.withValues(alpha: 0.35) : Tema.cardBorder, width: 1.5),
          boxShadow: [Tema.shadowSm],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(Tema.radius),
          child: InkWell(
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => _CuentaDetailScreen(cuenta: x, onUpdate: () {
                Fb.getList('ventas_bar_cuentas').then((l) => setState(() => _cuentas = l));
              })));
              Fb.getList('ventas_bar_cuentas').then((l) => setState(() => _cuentas = l));
            },
            borderRadius: BorderRadius.circular(Tema.radius),
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Row(children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: activa ? Tema.primary : Tema.textMuted,
                    borderRadius: BorderRadius.circular(Tema.radiusSm),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    (mesa.toString().isNotEmpty ? mesa.toString()[0] : 'M').toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                ),
                SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(mesa.toString(),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w700, color: Tema.textDark, fontSize: 15)),
                    if (cliente.toString().isNotEmpty) ...[
                      SizedBox(height: 2),
                      Row(children: [
                        Icon(Icons.person_outline, size: 12, color: Tema.textSoft),
                        SizedBox(width: 3),
                        Flexible(
                          child: Text(cliente.toString(),
                              style: TextStyle(fontSize: 12, color: Tema.textSoft),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ]),
                    ],
                    SizedBox(height: 3),
                    Row(children: [
                      Icon(Icons.shopping_basket_outlined, size: 13, color: Tema.textSoft),
                      SizedBox(width: 3),
                      Text('$count items', style: TextStyle(fontSize: 12, color: Tema.textSoft)),
                      SizedBox(width: 10),
                      Text(Fb.formatMoney(total),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Tema.primary)),
                      if (tiempo.isNotEmpty) ...[
                        SizedBox(width: 10),
                        Icon(Icons.access_time, size: 12, color: Tema.textSoft),
                        SizedBox(width: 2),
                        Text(tiempo, style: TextStyle(fontSize: 11, color: Tema.textSoft)),
                      ],
                    ]),
                  ]),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: activa ? const Color(0xFFe6f4ea) : const Color(0xFFf3f4f6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    activa ? 'Activa' : 'Cerrada',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: activa ? const Color(0xFF1e7e34) : Tema.textMuted,
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _CuentaDetailScreen extends StatefulWidget {
  final Map<dynamic, dynamic> cuenta;
  final VoidCallback onUpdate;
  const _CuentaDetailScreen({required this.cuenta, required this.onUpdate});
  @override
  State<_CuentaDetailScreen> createState() => _CuentaDetailScreenState();
}

class _CuentaDetailScreenState extends State<_CuentaDetailScreen> {
  List<Map<dynamic, dynamic>> _productos = [];
  List<Map<dynamic, dynamic>> _categorias = [];
  dynamic _catActiva;
  final _searchC = TextEditingController();
  final _focusSearchC = FocusNode();
  bool _focusedSearchC = false;
  String _search = '';
  Map<dynamic, dynamic> _cuenta = {};
  StreamSubscription? _subP;
  StreamSubscription? _subC;

  @override
  void initState() {
    super.initState();
    _cuenta = Map<dynamic, dynamic>.from(widget.cuenta);
    _subP = Fb.stream('productos').listen((d) => setState(() => _productos = d));
    _subC = Fb.stream('categorias').listen((d) => setState(() => _categorias = d));
    _focusSearchC.addListener(() {
      if (mounted) setState(() => _focusedSearchC = _focusSearchC.hasFocus);
    });
    Fb.getList('ventas_bar_cuentas').then((cuentas) {
      final idx = cuentas.indexWhere((c) => c['id'] == _cuenta['id']);
      if (idx >= 0 && mounted) setState(() => _cuenta = cuentas[idx]);
    });
  }

  @override
  void dispose() {
    _subP?.cancel();
    _subC?.cancel();
    _searchC.dispose();
    _focusSearchC.dispose();
    super.dispose();
  }

  double get _total {
    final items = (_cuenta['items'] as List?) ?? [];
    double t = 0;
    for (final x in items) {
      t += (x['subtotal'] ?? 0).toDouble();
    }
    return t;
  }

  List<Map<dynamic, dynamic>> get _items {
    return List<Map<dynamic, dynamic>>.from((_cuenta['items'] as List?) ?? []);
  }

  List<Map<dynamic, dynamic>> get _filtrados {
    var p = _productos;
    if (_catActiva != null) {
      final cid = _catActiva.toString();
      p = p.where((x) => (x['categoria_id'] ?? x['categoria'])?.toString() == cid).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      p = p.where((x) {
        final n = (x['nombre'] ?? '').toString().toLowerCase();
        final c = (x['codigo'] ?? x['codigo_barras'] ?? '').toString().toLowerCase();
        return n.contains(q) || c.contains(q);
      }).toList();
    }
    return p;
  }

  Future<void> _guardarCuenta() async {
    final cuentas = await Fb.getList('ventas_bar_cuentas');
    final idx = cuentas.indexWhere((c) => c['id'] == _cuenta['id']);
    if (idx >= 0) {
      cuentas[idx] = _cuenta;
    } else {
      cuentas.add(_cuenta);
    }
    await Fb.setList('ventas_bar_cuentas', cuentas);
    widget.onUpdate();
    setState(() {});
  }

  void _addItem(Map<dynamic, dynamic> prod) {
    final items = _items;
    final pid = prod['id']?.toString();
    final idx = items.indexWhere((x) => x['id_prod']?.toString() == pid);
    if (idx >= 0) {
      items[idx]['cantidad'] = (items[idx]['cantidad'] ?? 0) + 1;
      items[idx]['subtotal'] = (items[idx]['cantidad'] as num) * (items[idx]['precio_unitario'] as num);
    } else {
      items.add({
        'id_prod': prod['id'],
        'nombre': prod['nombre'],
        'codigo': prod['codigo'] ?? prod['codigo_barras'] ?? '',
        'cantidad': 1,
        'precio_unitario': prod['precio_venta'] ?? 0,
        'subtotal': prod['precio_venta'] ?? 0,
      });
    }
    _cuenta['items'] = items;
    _cuenta['total'] = _total;
    _guardarCuenta();
  }

  void _changeQty(int idx, int delta) {
    final items = _items;
    items[idx]['cantidad'] = (items[idx]['cantidad'] ?? 0) + delta;
    items[idx]['subtotal'] = (items[idx]['cantidad'] as num) * (items[idx]['precio_unitario'] as num);
    if (items[idx]['cantidad'] <= 0) {
      items.removeAt(idx);
    }
    _cuenta['items'] = items;
    _cuenta['total'] = _total;
    _guardarCuenta();
  }

  void _removeItem(int idx) {
    final items = _items;
    items.removeAt(idx);
    _cuenta['items'] = items;
    _cuenta['total'] = _total;
    _guardarCuenta();
  }

  void _scanBarcode() {
    showDialog(
      context: context,
      builder: (ctx) => _ScannerBarDialog(
        onScan: (barcode) {
          if (!mounted) return;
          final prod = _productos.firstWhere(
            (p) => (p['codigo_barras'] ?? p['codigo'] ?? '').toString() == barcode,
            orElse: () => <dynamic, dynamic>{},
          );
          if (prod.isNotEmpty) {
            _addItem(prod);
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Producto no encontrado: $barcode')),
            );
          }
        },
      ),
    );
  }

  Future<void> _pagarItem(int idx) async {
    final items = _items;
    if (idx < 0 || idx >= items.length) return;
    final it = items[idx];
    final subtotal = (it['subtotal'] ?? 0).toDouble();

    final metodo = await _showMetodoPagoDialog(subtotal);
    if (metodo == null) return;

    if (metodo == 'Efectivo' || metodo == 'Tarjeta') {
      final cajas = await Fb.getList('cajas');
      final cajaAbierta = cajas.isNotEmpty && (cajas.last['estado'] ?? '') == 'abierta';
      if (!cajaAbierta) {
        if (mounted) {
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Sin caja abierta'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tema.radiusLg)),
              content: const Text('Debe abrir una caja antes de cobrar con efectivo o tarjeta.'),
              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendido'))],
            ),
          );
        }
        return;
      }
    }

    if (metodo == 'Fiado') {
      final okCrear = await _crearFiado(subtotal, it['nombre'] ?? 'Producto');
      if (!okCrear) return;
    }

    if (metodo == 'FiarTodo') {
      final okCrear = await _crearFiado(subtotal, it['nombre'] ?? 'Producto');
      if (!okCrear) return;
      items.removeAt(idx);
      _cuenta['items'] = items;
      _cuenta['total'] = _total;
      await _guardarCuenta();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Item fiado: ${Fb.formatMoney(subtotal)}')),
        );
      }
      if (items.isEmpty && mounted) {
        Navigator.pop(context);
      }
      return;
    }

    final ventas = await Fb.getList('ventas');
    final idV = ventas.isEmpty ? 1 : ventas.map((x) => x['id'] as int).reduce((a, b) => a > b ? a : b) + 1;
    ventas.add({
      'id': idV,
      'fecha': DateTime.now().toIso8601String().substring(0, 10),
      'created_at': DateTime.now().toIso8601String(),
      'total': subtotal,
      'metodo_pago': metodo,
      'estado': 'completada',
      'tipo': 'bar',
      'mesa': _cuenta['mesa'],
      'cliente_nombre': _cuenta['cliente_nombre'] ?? '',
      'items': [
        {
          'producto_id': it['id_prod'],
          'nombre': it['nombre'],
          'cantidad': it['cantidad'],
          'precio_unitario': it['precio_unitario'],
        }
      ],
    });
    await Fb.setList('ventas', ventas);

    items.removeAt(idx);
    _cuenta['items'] = items;
    _cuenta['total'] = _total;
    await _guardarCuenta();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item pagado: ${Fb.formatMoney(subtotal)} ($metodo)')),
      );
    }

    if (items.isEmpty && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _cobrar() async {
    final total = _total;
    if (total <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay productos en la cuenta')));
      }
      return;
    }
    final metodo = await _showMetodoPagoDialog(total);
    if (metodo == null) return;

    if (metodo == 'Efectivo' || metodo == 'Tarjeta') {
      final cajas = await Fb.getList('cajas');
      final cajaAbierta = cajas.isNotEmpty && (cajas.last['estado'] ?? '') == 'abierta';
      if (!cajaAbierta) {
        if (mounted) {
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Sin caja abierta'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tema.radiusLg)),
              content: const Text('Debe abrir una caja antes de cobrar con efectivo o tarjeta.'),
              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendido'))],
            ),
          );
        }
        return;
      }
    }

    if (metodo == 'Fiado') {
      final desc = _items.map((x) => '${x['nombre']} x${x['cantidad']}').join(', ');
      final okCrear = await _crearFiado(total, desc);
      if (!okCrear) return;
    }

    if (metodo == 'FiarTodo') {
      final desc = _items.map((x) => '${x['nombre']} x${x['cantidad']}').join(', ');
      final okCrear = await _crearFiado(total, desc);
      if (!okCrear) return;
      _cuenta['estado'] = 'cerrada';
      final cuentas = await Fb.getList('ventas_bar_cuentas');
      final idx = cuentas.indexWhere((c) => c['id'] == _cuenta['id']);
      if (idx >= 0) cuentas[idx] = _cuenta;
      await Fb.setList('ventas_bar_cuentas', cuentas);
      widget.onUpdate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cuenta fiada: ${Fb.formatMoney(total)}')),
        );
        Navigator.pop(context);
      }
      return;
    }

    final ventas = await Fb.getList('ventas');
    final idV = ventas.isEmpty ? 1 : ventas.map((x) => x['id'] as int).reduce((a, b) => a > b ? a : b) + 1;
    ventas.add({
      'id': idV,
      'fecha': DateTime.now().toIso8601String().substring(0, 10),
      'created_at': DateTime.now().toIso8601String(),
      'total': total,
      'metodo_pago': metodo,
      'estado': 'completada',
      'tipo': 'bar',
      'mesa': _cuenta['mesa'],
      'cliente_nombre': _cuenta['cliente_nombre'] ?? '',
      'items': _items
          .map((x) => {
                'producto_id': x['id_prod'],
                'nombre': x['nombre'],
                'cantidad': x['cantidad'],
                'precio_unitario': x['precio_unitario'],
              })
          .toList(),
    });
    await Fb.setList('ventas', ventas);

    _cuenta['estado'] = 'cerrada';
    final cuentas = await Fb.getList('ventas_bar_cuentas');
    final idx = cuentas.indexWhere((c) => c['id'] == _cuenta['id']);
    if (idx >= 0) cuentas[idx] = _cuenta;
    await Fb.setList('ventas_bar_cuentas', cuentas);
    widget.onUpdate();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cuenta cobrada: ${Fb.formatMoney(total)} ($metodo)')),
      );
      Navigator.pop(context);
    }
  }

  Future<bool> _crearFiado(num monto, String desc) async {
    final clienteId = _cuenta['cliente_id'];
    final clienteNombre = _cuenta['cliente_nombre'] ?? 'Cliente';

    if (clienteId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Esta cuenta no tiene un cliente asociado para fiar.')),
        );
      }
      return false;
    }

    final fiados = await Fb.getList('fiados');
    final idF = fiados.isEmpty ? 1 : fiados.map((x) => x['id'] as int).reduce((a, b) => a > b ? a : b) + 1;
    fiados.add({
      'id': idF,
      'cliente_id': clienteId,
      'cliente_nombre': clienteNombre.toString(),
      'fecha': DateTime.now().toIso8601String(),
      'monto': monto,
      'producto_nombre': desc,
      'estado': 'pendiente',
      'abonos': <Map<dynamic, dynamic>>[],
      'usuario': '',
      'origen': 'bar',
    });
    await Fb.setList('fiados', fiados);

    final clientes = await Fb.getList('clientes');
    final ci = clientes.indexWhere((c) => c['id'] == clienteId);
    if (ci >= 0) {
      final actual = (clientes[ci]['saldo_pendiente'] ?? 0).toDouble();
      clientes[ci]['saldo_pendiente'] = actual + monto.toDouble();
      await Fb.setList('clientes', clientes);
    }

    return true;
  }

  Future<String?> _showMetodoPagoDialog(num total) async {
    final tieneCliente = _cuenta['cliente_id'] != null;
    final screenH = MediaQuery.of(context).size.height;
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Método de Pago'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tema.radiusLg)),
        content: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: screenH * 0.6),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Total: ${Fb.formatMoney(total)}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Tema.primary)),
              SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                    backgroundColor: Color(0xFFe6f4ea), child: Icon(Icons.money, color: Color(0xFF1e7e34))),
                title: const Text('Efectivo'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tema.radiusSm)),
                onTap: () => Navigator.pop(ctx, 'Efectivo'),
              ),
              ListTile(
                leading: const CircleAvatar(
                    backgroundColor: Color(0xFFe3f2fd), child: Icon(Icons.credit_card, color: Color(0xFF1565c0))),
                title: const Text('Tarjeta'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tema.radiusSm)),
                onTap: () => Navigator.pop(ctx, 'Tarjeta'),
              ),
              if (tieneCliente)
                ListTile(
                  leading: const CircleAvatar(
                      backgroundColor: Color(0xFFfff3e0), child: Icon(Icons.assignment_return, color: Color(0xFFe65100))),
                  title: const Text('Fiado'),
                  subtitle: Text('Cliente: ${_cuenta['cliente_nombre'] ?? ''}',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Tema.textMuted)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tema.radiusSm)),
                  onTap: () => Navigator.pop(ctx, 'Fiado'),
                ),
              ListTile(
                leading: CircleAvatar(
                    backgroundColor: tieneCliente ? const Color(0xFFfce4ec) : const Color(0xFFf3f4f6),
                    child: Icon(Icons.assignment_return,
                        color: tieneCliente ? const Color(0xFFc62828) : Tema.textMuted)),
                title: const Text('Fiar Todo'),
                subtitle: tieneCliente
                    ? Text('Cliente: ${_cuenta['cliente_nombre'] ?? ''}',
                        style: TextStyle(fontSize: 11, color: Tema.textMuted))
                    : const Text('Requiere cliente asignado',
                        style: TextStyle(fontSize: 11, color: Tema.danger)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tema.radiusSm)),
                onTap: () {
                  if (!tieneCliente) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Asigne un cliente primero')));
                    return;
                  }
                  Navigator.pop(ctx, 'FiarTodo');
                },
              ),
            ]),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar'))],
      ),
    );
  }

  Future<void> _splitCuenta() async {
    final cuentas = await Fb.getList('ventas_bar_cuentas');
    final activas = cuentas.where((c) => c['id'] != _cuenta['id'] && c['estado'] == 'activa').toList();
    if (activas.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('No hay otras cuentas activas para dividir')));
      }
      return;
    }
    if (!mounted) return;
    final target = await showDialog<Map<dynamic, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dividir Cuenta'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tema.radiusLg)),
        content: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.55),
          child: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(activas.length, (i) => ListTile(
                  title: Text(activas[i]['mesa'] ?? 'Cuenta ${activas[i]['id']}'),
                  subtitle: Text(
                      '${Fb.formatMoney(activas[i]['total'] ?? 0)} - ${(activas[i]['items'] as List?)?.length ?? 0} items'),
                  leading: const Icon(Icons.call_merge),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tema.radiusSm)),
                  onTap: () => Navigator.pop(ctx, activas[i]),
                )),
              ),
            ),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar'))],
      ),
    );
    if (target == null) return;

    final src = _items;
    final tgt = List<Map<dynamic, dynamic>>.from((target['items'] as List?) ?? []);
    tgt.addAll(src);
    target['items'] = tgt;
    target['total'] = tgt.fold<num>(0, (s, x) => s + (x['subtotal'] ?? 0));

    _cuenta['items'] = <Map<dynamic, dynamic>>[];
    _cuenta['total'] = 0;

    final idxT = cuentas.indexWhere((c) => c['id'] == target['id']);
    final idxS = cuentas.indexWhere((c) => c['id'] == _cuenta['id']);
    if (idxT >= 0) cuentas[idxT] = target;
    if (idxS >= 0) cuentas[idxS] = _cuenta;
    await Fb.setList('ventas_bar_cuentas', cuentas);
    widget.onUpdate();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Cuenta dividida'), backgroundColor: Tema.primary));
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final total = _total;
    final filtrados = _filtrados;
    final activa = _cuenta['estado'] == 'activa';

    return Scaffold(
      appBar: AppBar(
        title: Column(children: [
          Flexible(child: Text(_cuenta['mesa'] ?? 'Cuenta', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16))),
          if ((_cuenta['cliente_nombre'] ?? '').toString().isNotEmpty)
            Flexible(child: Text(_cuenta['cliente_nombre'].toString(),
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400))),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Imprimir',
            onPressed: () {
              if (mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Impresión no disponible en esta versión')));
              }
            },
          ),
        ],
      ),
      body: Column(children: [
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 8),
            itemCount: _categorias.length + 1,
            itemBuilder: (_, i) {
              final sel =
                  i == 0 ? _catActiva == null : _catActiva?.toString() == _categorias[i - 1]['id']?.toString();
              final label = i == 0 ? 'Todos' : (_categorias[i - 1]['nombre'] ?? '');
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 3, vertical: 6),
                child: ChoiceChip(
                  label: Text(label,
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : Tema.textDark)),
                  selected: sel,
                  selectedColor: Tema.primary,
                  backgroundColor: Tema.cardBg,
                  side: BorderSide(color: sel ? Tema.primary : Tema.cardBorder),
                  onSelected: (_) => setState(() => _catActiva = i == 0 ? null : _categorias[i - 1]['id']),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: TextField(
            controller: _searchC,
            focusNode: _focusSearchC,
            decoration: InputDecoration(
              hintText: 'Buscar producto...',
              prefixIcon: _focusedSearchC ? null : const Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_search.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchC.clear();
                        setState(() => _search = '');
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner, size: 20),
                    tooltip: 'Escanear código de barras',
                    onPressed: _scanBarcode,
                  ),
                ],
              ),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        Expanded(
          flex: 3,
          child: filtrados.isEmpty
              ? Center(child: Text('Sin productos', style: TextStyle(color: Tema.textMuted)))
              : GridView.builder(
                  padding: EdgeInsets.fromLTRB(10, 4, 10, 4),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: filtrados.length,
                  itemBuilder: (_, i) {
                    final p = filtrados[i];
                    final st = p['stock_actual'] ?? p['stock'] ?? 0;
                    final agotado = st <= 0;
                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(Tema.radiusSm),
                      elevation: agotado ? 0 : 1,
                      shadowColor: Colors.black12,
                      child: InkWell(
                        onTap: (!activa || agotado) ? null : () => _addItem(p),
                        borderRadius: BorderRadius.circular(Tema.radiusSm),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(Tema.radiusSm),
                            border: Border.all(color: Tema.cardBorder),
                            color: agotado ? const Color(0xFFf9f9f9) : Colors.white,
                          ),
                          padding: EdgeInsets.all(6),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Expanded(
                              child: Center(
                                child: Text(
                                  p['nombre'] ?? '',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                      color: agotado ? Tema.textMuted : Tema.textDark),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            Text(
                              Fb.formatMoney(p['precio_venta'] ?? 0),
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: agotado ? Tema.textMuted : Tema.primary,
                                  fontSize: 13),
                            ),
                            SizedBox(height: 1),
                            Text(
                              agotado ? 'AGOTADO' : '$st ${p['unidad_medida'] ?? p['unidad'] ?? 'und'}',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: agotado ? Tema.danger : Tema.textMuted,
                              ),
                            ),
                          ]),
                        ),
                      ),
                    );
                  },
                ),
        ),
        const Divider(height: 1),
        Expanded(
          flex: 3,
          child: items.isEmpty
              ? ListView(
                  children: [
                    SizedBox(height: 60),
                    Icon(Icons.receipt_long, color: Tema.textMuted, size: 40),
                    SizedBox(height: 8),
                    Text('Sin productos en la cuenta',
                        textAlign: TextAlign.center, style: TextStyle(color: Tema.textMuted, fontSize: 14)),
                  ],
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final it = items[i];
                    return Dismissible(
                      key: ValueKey('${it['id_prod']}_$i'),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) async {
                        _removeItem(i);
                        return false;
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 20),
                        margin: EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: Tema.danger,
                          borderRadius: BorderRadius.circular(Tema.radiusSm),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 2),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(Tema.radiusSm),
                          border: Border.all(color: Tema.cardBorder),
                        ),
                        child: Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(it['nombre'] ?? '',
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Tema.textDark)),
                            Text(
                              '${Fb.formatMoney(it['precio_unitario'] ?? 0)} c/u',
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: Tema.textSoft),
                            ),
                          ]),
                        ),
                          Container(
                            decoration: BoxDecoration(
                              color: Tema.bg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              InkWell(
                                onTap: () => _changeQty(i, -1),
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding: EdgeInsets.all(6),
                                  child: Icon(Icons.remove, size: 16, color: Tema.textDark),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                child: Text('${it['cantidad']}',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              ),
                              InkWell(
                                onTap: () => _changeQty(i, 1),
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding: EdgeInsets.all(6),
                                  child: Icon(Icons.add, size: 16, color: Tema.textDark),
                                ),
                              ),
                            ]),
                          ),
                          SizedBox(width: 8),
                          Text(
                            Fb.formatMoney(it['subtotal'] ?? 0),
                            style: const TextStyle(fontWeight: FontWeight.w800, color: Tema.primary, fontSize: 15),
                          ),
                          if (activa) ...[
                            SizedBox(width: 6),
                            InkWell(
                              onTap: () => _pagarItem(i),
                              borderRadius: BorderRadius.circular(Tema.radiusSm),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Tema.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(Tema.radiusSm),
                                ),
                                child: const Icon(Icons.payment, size: 18, color: Tema.primary),
                              ),
                            ),
                          ],
                        ]),
                      ),
                    );
                  },
                ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(14, 10, 14, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.06), offset: const Offset(0, -2), blurRadius: 10)
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text('Total', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Tema.textSoft)),
                  SizedBox(height: 1),
                  Text(Fb.formatMoney(total),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Tema.primary)),
                ]),
              ),
              OutlinedButton.icon(
                onPressed: activa ? _splitCuenta : null,
                icon: const Icon(Icons.call_split, size: 18),
                label: const Text('Dividir'),
              ),
              SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: activa ? _cobrar : null,
                icon: const Icon(Icons.payment, size: 18),
                label: const Text('Cobrar'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _ScannerBarDialog extends StatefulWidget {
  final void Function(String barcode) onScan;
  const _ScannerBarDialog({required this.onScan});
  @override
  State<_ScannerBarDialog> createState() => _ScannerBarDialogState();
}

class _ScannerBarDialogState extends State<_ScannerBarDialog> {
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