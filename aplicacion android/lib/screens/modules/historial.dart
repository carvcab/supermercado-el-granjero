import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/firestore_service.dart';
import '../../theme.dart';

class HistScreen extends StatefulWidget {
  const HistScreen({super.key});
  @override
  State<HistScreen> createState() => _HistScreenState();
}

class _HistScreenState extends State<HistScreen> {
  List<Map<dynamic, dynamic>> _ventas = [];
  List<Map<dynamic, dynamic>> _productos = [];
  List<Map<dynamic, dynamic>> _cajas = [];
  List<Map<dynamic, dynamic>> _clientes = [];

  final _searchCtl = TextEditingController();
  String _searchQ = '';
  String _metodoFiltro = 'Todos';
  DateTime? _desde;
  DateTime? _hasta;

  bool _loading = true;
  StreamSubscription? _sub;

  // ─── helpers ───
  List<dynamic> _items(Map<dynamic, dynamic> v) {
    final raw = v['items'] ?? v['productos'];
    if (raw is List) return raw;
    return [];
  }

  int _itemsCount(Map<dynamic, dynamic> v) =>
      _items(v).fold<int>(0, (s, i) => s + ((i['cantidad'] as num?)?.toInt() ?? 0));

  String _estado(Map<dynamic, dynamic> v) =>
      (v['estado'] as String?) ?? 'Completada';

  String _metodo(Map<dynamic, dynamic> v) {
    final m1 = (v['metodo_pago'] as String?) ?? 'efectivo';
    final m2 = v['metodo_pago_2'] as String?;
    if (m2 != null && m2.isNotEmpty) return 'mixto';
    return m1;
  }

  String _metodoLabel(String m) {
    switch (m) {
      case 'efectivo': return 'Efectivo';
      case 'tarjeta': return 'Tarjeta';
      case 'fiado': return 'Fiado';
      case 'mixto': return 'Mixto';
      default: return m;
    }
  }

  Color _metodoColor(String m) {
    switch (m) {
      case 'efectivo': return Tema.primary;
      case 'tarjeta': return Tema.darkBlue;
      case 'fiado': return Tema.kpiAccents[2];
      case 'mixto': return Tema.kpiAccents[3];
      default: return Tema.textSoft;
    }
  }

  IconData _metodoIcon(String m) {
    switch (m) {
      case 'efectivo': return Icons.money;
      case 'tarjeta': return Icons.credit_card;
      case 'fiado': return Icons.credit_score;
      case 'mixto': return Icons.swap_horiz;
      default: return Icons.payment;
    }
  }

  String _fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final dPart = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    if (iso.contains('T') || iso.length > 10) {
      final hPart = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      return '$dPart $hPart';
    }
    return dPart;
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  // ─── load ───
  @override
  void initState() {
    super.initState();
    _sub = Fb.stream('ventas').listen((d) {
      d.sort((a, b) {
        final fa = (a['fecha'] ?? '').toString();
        final fb = (b['fecha'] ?? '').toString();
        final cmp = fb.compareTo(fa);
        if (cmp != 0) return cmp;
        return ((b['id'] as num?)?.toInt() ?? 0).compareTo((a['id'] as num?)?.toInt() ?? 0);
      });
      setState(() { _ventas = d; _loading = false; });
    });
    Future.wait([Fb.getList('productos'), Fb.getList('cajas'), Fb.getList('clientes')]).then((res) {
      setState(() { _productos = res[0]; _cajas = res[1]; _clientes = res[2]; });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _searchCtl.dispose();
    super.dispose();
  }

  // ─── filtered list ───
  List<Map<dynamic, dynamic>> _filtered() {
    return _ventas.where((v) {
      if (_searchQ.isNotEmpty) {
        final q = _searchQ.toLowerCase();
        final cliente = (v['cliente'] ?? '').toString().toLowerCase();
        final idStr = (v['id'] ?? '').toString();
        if (!cliente.contains(q) && !idStr.contains(q)) return false;
      }
      if (_metodoFiltro != 'Todos') {
        final m = _metodo(v);
        if (_metodoFiltro == 'Mixto' && m != 'mixto') return false;
        if (_metodoFiltro == 'Efectivo' && m != 'efectivo') return false;
        if (_metodoFiltro == 'Tarjeta' && m != 'tarjeta') return false;
        if (_metodoFiltro == 'Fiado' && m != 'fiado') return false;
      }
      if (_desde != null || _hasta != null) {
        final fechaStr = (v['fecha'] ?? '').toString();
        if (fechaStr.isEmpty) return false;
        final dt = DateTime.tryParse(fechaStr);
        if (dt == null) return false;
        if (_desde != null && dt.isBefore(_desde!)) return false;
        if (_hasta != null && dt.isAfter(_hasta!)) return false;
      }
      return true;
    }).toList();
  }

  // ─── stats ───
  List<Map<String, dynamic>> _computeStats() {
    final fl = _filtered();
    final completadas = fl.where((v) => _estado(v) != 'anulada').toList();
    final totalVentas = completadas.length;
    final totalMonto = completadas.fold<double>(0, (s, v) => s + ((v['total'] as num?)?.toDouble() ?? 0));
    final promedio = totalVentas > 0 ? totalMonto / totalVentas : 0.0;
    return [
      {'label': 'Total Ventas', 'value': '$totalVentas', 'icon': Icons.receipt_long, 'accent': Tema.primary},
      {'label': 'Total Monto', 'value': Fb.formatMoney(totalMonto), 'icon': Icons.monetization_on, 'accent': Tema.primary},
      {'label': 'Promedio Venta', 'value': Fb.formatMoney(promedio), 'icon': Icons.trending_up, 'accent': Tema.darkBlue},
    ];
  }

  // ─── pick date ───
  Future<void> _pickDate(bool isDesde) async {
    final initial = isDesde ? (_desde ?? DateTime.now()) : (_hasta ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('es'),
    );
    if (picked == null) return;
    setState(() {
      if (isDesde) {
        _desde = DateTime(picked.year, picked.month, picked.day);
      } else {
        _hasta = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      }
    });
  }

  // ─── date presets ───
  void _setDatePreset(String preset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (preset) {
      case 'Hoy':
        setState(() {
          _desde = today;
          _hasta = DateTime(now.year, now.month, now.day, 23, 59, 59);
        });
        break;
      case 'Ayer':
        final ayer = today.subtract(const Duration(days: 1));
        setState(() {
          _desde = ayer;
          _hasta = DateTime(ayer.year, ayer.month, ayer.day, 23, 59, 59);
        });
        break;
      case 'Semana':
        setState(() {
          _desde = today.subtract(const Duration(days: 7));
          _hasta = DateTime(now.year, now.month, now.day, 23, 59, 59);
        });
        break;
      case 'Mes':
        setState(() {
          _desde = today.subtract(const Duration(days: 30));
          _hasta = DateTime(now.year, now.month, now.day, 23, 59, 59);
        });
        break;
    }
  }

  // ─── detail bottom sheet ───
  void _showDetail(Map<dynamic, dynamic> venta) {
    final items = _items(venta);
    final rawItems = List<Map<dynamic, dynamic>>.from(
      items.map((e) => Map<dynamic, dynamic>.from(e as Map)),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.7,
        decoration: BoxDecoration(
          color: Tema.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(Tema.radiusLg)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Tema.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: _metodoColor(_metodo(venta)).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(Tema.radiusSm),
                  ),
                  child: Icon(_metodoIcon(_metodo(venta)), color: _metodoColor(_metodo(venta)), size: 22),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Venta #${venta['id']}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Tema.textDark)),
                    Text('${_fmtDate(venta['fecha'] as String?)}  \u2022  ${_metodoLabel(_metodo(venta))}',
                        style: TextStyle(fontSize: 13, color: Tema.textSoft)),
                  ]),
                ),
                Text(Fb.formatMoney(venta['total'] ?? 0),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Tema.primary)),
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
                  _infoRow('Cliente', '${venta['cliente'] ?? 'Mostrador'}'),
                  _infoRow('Fecha', _fmtDate(venta['fecha'] as String?)),
                  _infoRow('Metodo de Pago', _metodoLabel(_metodo(venta))),
                  if (venta['metodo_pago_2'] != null && (venta['metodo_pago_2'] as String?)!.isNotEmpty) ...[
                    _infoRow('Segundo Metodo', _metodoLabel(venta['metodo_pago_2'] as String)),
                    _infoRow('Monto 1', Fb.formatMoney(venta['monto_1'] ?? 0)),
                    _infoRow('Monto 2', Fb.formatMoney(venta['monto_2'] ?? 0)),
                  ],
                  if ((venta['descuento'] as num?)?.toDouble() != null && (venta['descuento'] as num) > 0)
                    _infoRow('Descuento', Fb.formatMoney(venta['descuento'])),
                  _infoRow('Estado', _estado(venta)),
                  _infoRow('Usuario', '${venta['usuario'] ?? 'Sistema'}'),
                  _infoRow('Caja ID', '${venta['caja_id'] ?? '-'}'),
                ]),
              ),
              SizedBox(height: 16),
              Text('Productos', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Tema.textDark)),
              SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Tema.radiusSm),
                  border: Border.all(color: Tema.cardBorder),
                ),
                clipBehavior: Clip.antiAlias,
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(3),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(1.5),
                    3: FlexColumnWidth(1.5),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: Tema.primary.withValues(alpha: 0.08)),
                      children: [
                        _th('Producto'),
                        _th('Cant'),
                        _th('P.Unit'),
                        _th('Subtotal'),
                      ],
                    ),
                    ...rawItems.map((it) => TableRow(
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: Tema.cardBorder, width: 0.5)),
                      ),
                      children: [
                        _td('${it['nombre'] ?? '-'}', TextAlign.left),
                        _td('${it['cantidad'] ?? 0}', TextAlign.center),
                        _td(Fb.formatMoney(it['precio_unitario'] ?? 0), TextAlign.right),
                        _td(Fb.formatMoney(it['subtotal'] ?? 0), TextAlign.right),
                      ],
                    )),
                  ],
                ),
              ),
              SizedBox(height: 20),
              if (_estado(venta) != 'anulada') ...[
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showEditModal(venta);
                      },
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Editar Venta'),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _anularVenta(venta);
                      },
                      icon: const Icon(Icons.cancel, size: 16),
                      label: const Text('Anular Venta'),
                      style: OutlinedButton.styleFrom(foregroundColor: Tema.danger),
                    ),
                  ),
                ]),
                SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showReceipt(venta);
                  },
                  icon: const Icon(Icons.print, size: 16),
                  label: const Text('Reimprimir Ticket'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── receipt / reimprimir ticket ───
  void _showReceipt(Map<dynamic, dynamic> venta) {
    final items = _items(venta);
    final buf = StringBuffer();
    const w = 42;
    String center(String s) => s.padLeft((w + s.length) ~/ 2).padRight(w);

    buf.writeln('=' * w);
    buf.writeln(center('SUPERMERCADO EL GRANJERO'));
    buf.writeln('=' * w);
    buf.writeln('Venta N\u00b0 ${venta['id']}');
    buf.writeln('Fecha : ${_fmtDate(venta['fecha'] as String?)}');
    buf.writeln('Cliente: ${venta['cliente'] ?? 'Mostrador'}');
    buf.writeln('Metodo : ${_metodoLabel(_metodo(venta))}');
    if (venta['descuento'] != null && (venta['descuento'] as num) > 0) {
      buf.writeln('Desc.  : ${Fb.formatMoney(venta['descuento'])}');
    }
    buf.writeln('-' * w);
    buf.writeln('Producto               Cant   P.Unit    Subt');
    buf.writeln('-' * w);
    for (final it in items) {
      final nombre = (it['nombre'] ?? '').toString();
      final cant = '${it['cantidad'] ?? 0}';
      final pu = Fb.formatMoney(it['precio_unitario'] ?? 0);
      final subt = Fb.formatMoney(it['subtotal'] ?? 0);
      // Truncate product name to fit
      final nameTrunc = nombre.length > 22 ? '${nombre.substring(0, 21)}.' : nombre;
      buf.writeln('${nameTrunc.padRight(22)} ${cant.padLeft(4)} ${pu.padLeft(8)} ${subt.padLeft(7)}');
    }
    buf.writeln('-' * w);
    buf.writeln('TOTAL: ${Fb.formatMoney(venta['total'] ?? 0).padLeft(w - 7)}');
    buf.writeln('=' * w);
    buf.writeln(center('\u00a1Gracias por su compra!'));
    buf.writeln('=' * w);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          const Icon(Icons.receipt_long, size: 20, color: Tema.primary),
          SizedBox(width: 8),
          Text('Ticket Venta #${venta['id']}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Tema.textDark)),
        ]),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Tema.bg,
                borderRadius: BorderRadius.circular(Tema.radiusSm),
                border: Border.all(color: Tema.cardBorder),
              ),
              child: SelectableText(
                buf.toString(),
                style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Tema.textDark, height: 1.4),
              ),
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: buf.toString()));
              Navigator.pop(ctx);
              _snack('Ticket copiado al portapapeles');
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copiar'),
          ),
          SizedBox(width: 8),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  // ─── full edit modal ───
  void _showEditModal(Map<dynamic, dynamic> venta) {
    final scroll = ScrollController();
    final clienteCtl = TextEditingController(text: venta['cliente'] ?? '');
    String metodo = _metodo(venta);
    DateTime fecha = DateTime.tryParse((venta['fecha'] ?? '').toString()) ?? DateTime.now();

    final itemsRaw = _items(venta);
    final List<Map<dynamic, dynamic>> editItems =
        itemsRaw.map((e) => Map<dynamic, dynamic>.from(e as Map)).toList();
    final List<Map<dynamic, dynamic>> originalItems =
        itemsRaw.map((e) => Map<dynamic, dynamic>.from(e as Map)).toList();

    double calcTotal() {
      double t = editItems.fold<double>(0, (s, it) => s + ((it['subtotal'] as num?)?.toDouble() ?? 0));
      return t;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          height: MediaQuery.of(ctx).size.height * 0.85,
          decoration: BoxDecoration(
            color: Tema.cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(Tema.radiusLg)),
          ),
          child: SingleChildScrollView(
            controller: scroll,
            padding: EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Tema.cardBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Tema.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(Tema.radiusSm),
                    ),
                    child: const Icon(Icons.edit, color: Tema.primary, size: 20),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Editar Venta #${venta['id']}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Tema.textDark)),
                  ),
                ]),
                SizedBox(height: 16),

                // ── Client ──
                Autocomplete<String>(
                  optionsBuilder: (v) {
                    if (v.text.isEmpty) {
                      return _clientes
                          .map((c) => (c['nombre'] ?? '').toString())
                          .where((n) => n.isNotEmpty);
                    }
                    return _clientes
                        .map((c) => (c['nombre'] ?? '').toString())
                        .where((n) => n.toLowerCase().contains(v.text.toLowerCase()));
                  },
                  initialValue: TextEditingValue(text: clienteCtl.text),
                  onSelected: (sel) => clienteCtl.text = sel,
                  fieldViewBuilder: (ctx, ctl, node, _) => TextField(
                    controller: ctl,
                    focusNode: node,
                    decoration: const InputDecoration(labelText: 'Cliente', isDense: true),
                    onChanged: (_) => setSheet(() {}),
                  ),
                ),
                SizedBox(height: 12),

                // ── Date ──
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: fecha,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      locale: const Locale('es'),
                    );
                    if (picked != null) setSheet(() => fecha = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha',
                      isDense: true,
                    ),
                    child: Text(_fmtDate(fecha.toIso8601String()),
                        style: TextStyle(fontSize: 14, color: Tema.textDark)),
                  ),
                ),
                SizedBox(height: 12),

                // ── Payment method ──
                DropdownButtonFormField<String>(
                  value: metodo == 'mixto' ? 'efectivo' : metodo,
                  decoration: const InputDecoration(labelText: 'Metodo de Pago', isDense: true),
                  items: const [
                    DropdownMenuItem(value: 'efectivo', child: Text('Efectivo')),
                    DropdownMenuItem(value: 'tarjeta', child: Text('Tarjeta')),
                    DropdownMenuItem(value: 'fiado', child: Text('Fiado')),
                  ],
                  onChanged: (v) => setSheet(() => metodo = v!),
                ),
                SizedBox(height: 20),

                // ── Items header ──
                Row(children: [
                  Text('Productos',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Tema.textDark)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _addItemToEditSale(ctx, setSheet, editItems),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Agregar'),
                  ),
                ]),
                SizedBox(height: 6),

                // ── Items list ──
                if (editItems.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text('Sin productos', style: TextStyle(color: Tema.textMuted, fontSize: 13)),
                    ),
                  )
                else
                  ...List.generate(editItems.length, (idx) {
                    final it = editItems[idx];
                    return _buildEditItemRow(ctx, setSheet, editItems, idx, it);
                  }),

                SizedBox(height: 16),

                // ── Totals ──
                Container(
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Tema.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(Tema.radiusSm),
                    border: Border.all(color: Tema.primary.withValues(alpha: 0.2)),
                  ),
                  child: Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Items', style: TextStyle(fontSize: 14, color: Tema.textSoft)),
                      Text('${editItems.length}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Tema.textDark)),
                    ]),
                    SizedBox(height: 4),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Tema.textDark)),
                      Text(Fb.formatMoney(calcTotal()),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Tema.primary)),
                    ]),
                  ]),
                ),
                SizedBox(height: 20),

                // ── Action buttons ──
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final newTotal = calcTotal();
                        if (editItems.isEmpty) {
                          _snack('La venta debe tener al menos un producto');
                          return;
                        }

                        // 1. Reverse old stock
                        for (final oldItem in originalItems) {
                          final pid = (oldItem['id'] ?? '').toString();
                          final pIdx =
                              _productos.indexWhere((p) => (p['id'] ?? '').toString() == pid);
                          if (pIdx >= 0) {
                            final currentStock =
                                (_productos[pIdx]['stock_actual'] as num?)?.toInt() ?? 0;
                            final oldQty = (oldItem['cantidad'] as num?)?.toInt() ?? 0;
                            _productos[pIdx]['stock_actual'] = currentStock + oldQty;
                          }
                        }

                        // 2. Apply new stock
                        for (final newItem in editItems) {
                          final pid = (newItem['id'] ?? '').toString();
                          final pIdx =
                              _productos.indexWhere((p) => (p['id'] ?? '').toString() == pid);
                          if (pIdx >= 0) {
                            final currentStock =
                                (_productos[pIdx]['stock_actual'] as num?)?.toInt() ?? 0;
                            final newQty = (newItem['cantidad'] as num?)?.toInt() ?? 0;
                            _productos[pIdx]['stock_actual'] =
                                (currentStock - newQty).clamp(0, double.infinity).toInt();
                          }
                        }

                        // 3. Update venta record
                        final vIdx = _ventas.indexWhere((v) => v['id'] == venta['id']);
                        if (vIdx >= 0) {
                          _ventas[vIdx]['cliente'] = clienteCtl.text.trim().isEmpty
                              ? 'Mostrador'
                              : clienteCtl.text.trim();
                          _ventas[vIdx]['fecha'] = fecha.toIso8601String().substring(0, 10);
                          _ventas[vIdx]['metodo_pago'] = metodo;
                          _ventas[vIdx]['items'] = editItems;
                          _ventas[vIdx]['total'] = newTotal;
                          if (metodo != 'mixto') {
                            _ventas[vIdx]['metodo_pago_2'] = null;
                          }
                        }

                        await Fb.setList('productos', _productos);
                        await Fb.setList('ventas', _ventas);

                        if (ctx.mounted) Navigator.pop(ctx);
                        _snack('Venta #${venta['id']} actualizada');
                      },
                      icon: const Icon(Icons.save, size: 18),
                      label: const Text('Guardar Cambios'),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── edit helpers ───

  Widget _buildEditItemRow(
    BuildContext sheetCtx,
    StateSetter setSheet,
    List<Map<dynamic, dynamic>> items,
    int idx,
    Map<dynamic, dynamic> it,
  ) {
    final qty = (it['cantidad'] as num?)?.toInt() ?? 1;
    final pu = (it['precio_unitario'] as num?)?.toDouble() ?? 0;
    final subtotal = qty * pu;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Tema.bg,
        borderRadius: BorderRadius.circular(Tema.radiusSm),
        border: Border.all(color: Tema.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product name row
          Row(children: [
            Expanded(
              child: InkWell(
                onTap: () => _pickProductForItem(sheetCtx, setSheet, items, idx, it),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Tema.cardBorder),
                  ),
                  child: Row(children: [
                    Icon(Icons.shopping_basket, size: 16, color: Tema.textMuted),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        it['nombre'] ?? 'Seleccionar producto',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: it['nombre'] != null ? Tema.textDark : Tema.textMuted,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 16, color: Tema.textMuted),
                  ]),
                ),
              ),
            ),
            SizedBox(width: 6),
            InkWell(
              onTap: () => setSheet(() => items.removeAt(idx)),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: Tema.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.close, size: 16, color: Tema.danger),
              ),
            ),
          ]),
          SizedBox(height: 8),

          // Qty / Price / Subtotal row
          Row(children: [
            // Quantity
            GestureDetector(
              onTap: () => _editItemNumber(sheetCtx, setSheet, it, 'cantidad', 'Cantidad'),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Tema.cardBorder),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.numbers, size: 14, color: Tema.textMuted),
                  SizedBox(width: 4),
                  Text('$qty', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Tema.textDark)),
                  SizedBox(width: 4),
                  Icon(Icons.edit, size: 12, color: Tema.textMuted),
                ]),
              ),
            ),

            SizedBox(width: 8),

            // +/- quick buttons
            InkWell(
              onTap: () {
                if (qty > 1) {
                  setSheet(() {
                    it['cantidad'] = qty - 1;
                    it['subtotal'] = (qty - 1) * pu;
                  });
                }
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Tema.cardBorder),
                ),
                child: Icon(Icons.remove, size: 16, color: Tema.textSoft),
              ),
            ),
            SizedBox(width: 4),
            InkWell(
              onTap: () {
                setSheet(() {
                  it['cantidad'] = qty + 1;
                  it['subtotal'] = (qty + 1) * pu;
                });
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Tema.cardBorder),
                ),
                child: const Icon(Icons.add, size: 16, color: Tema.primary),
              ),
            ),

            SizedBox(width: 12),

            // Unit price
            GestureDetector(
              onTap: () => _editItemNumber(sheetCtx, setSheet, it, 'precio_unitario', 'Precio Unitario'),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Tema.cardBorder),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.attach_money, size: 14, color: Tema.textMuted),
                  Text(Fb.formatMoney(pu), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Tema.textDark)),
                  SizedBox(width: 4),
                  Icon(Icons.edit, size: 12, color: Tema.textMuted),
                ]),
              ),
            ),

            const Spacer(),

            // Subtotal
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('Subtotal', style: TextStyle(fontSize: 10, color: Tema.textMuted)),
              Text(Fb.formatMoney(subtotal),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Tema.primary)),
            ]),
          ]),
        ],
      ),
    );
  }

  Future<void> _editItemNumber(
    BuildContext ctx,
    StateSetter setSheet,
    Map<dynamic, dynamic> item,
    String field,
    String title,
  ) async {
    final ctl = TextEditingController(text: '${item[field] ?? 0}');
    final result = await showDialog<String>(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Tema.textDark)),
        content: TextField(
          controller: ctl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Ingrese valor'),
          onSubmitted: (v) => Navigator.pop(dCtx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dCtx, ctl.text),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );

    if (result == null) return;
    final val = double.tryParse(result);
    if (val == null) return;

    setSheet(() {
      if (field == 'cantidad') {
        item['cantidad'] = val.round().clamp(1, double.infinity).toInt();
      } else {
        item['precio_unitario'] = val;
      }
      final qty = (item['cantidad'] as num?)?.toInt() ?? 1;
      final pu = (item['precio_unitario'] as num?)?.toDouble() ?? 0;
      item['subtotal'] = qty * pu;
    });
  }

  void _pickProductForItem(
    BuildContext sheetCtx,
    StateSetter setSheet,
    List<Map<dynamic, dynamic>> items,
    int idx,
    Map<dynamic, dynamic> currentItem,
  ) {
    showDialog(
      context: sheetCtx,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          String search = '';
          return AlertDialog(
            title: Text('Seleccionar Producto',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Tema.textDark)),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Buscar producto...',
                      prefixIcon: Icon(Icons.search, size: 18),
                      isDense: true,
                    ),
                    onChanged: (v) => setDlg(() => search = v),
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    height: 300,
                    child: Builder(builder: (ctx) {
                      final filtered = _productos.where((p) {
                        if (search.isEmpty) return true;
                        final name = (p['nombre'] ?? '').toString().toLowerCase();
                        return name.contains(search.toLowerCase());
                      }).toList();

                      if (filtered.isEmpty) {
                        return Center(
                            child: Text('Sin resultados', style: TextStyle(color: Tema.textMuted)));
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final p = filtered[i];
                          final stock = (p['stock_actual'] as num?)?.toInt() ?? 0;
                          final price = p['precio_venta'] ?? 0;
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: Tema.primary.withValues(alpha: 0.1),
                              child: const Icon(Icons.inventory_2, size: 16, color: Tema.primary),
                            ),
                            title: Text('${p['nombre'] ?? '?'}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            subtitle: Text('Stock: $stock  |  ${Fb.formatMoney(price)}',
                                style: TextStyle(fontSize: 11, color: Tema.textSoft)),
                            onTap: () {
                              setSheet(() {
                                items[idx]['id'] = p['id'];
                                items[idx]['nombre'] = p['nombre'];
                                items[idx]['precio_unitario'] = p['precio_venta'] ?? items[idx]['precio_unitario'] ?? 0;
                                final qty = (items[idx]['cantidad'] as num?)?.toInt() ?? 1;
                                final pu = (items[idx]['precio_unitario'] as num?)?.toDouble() ?? 0;
                                items[idx]['subtotal'] = qty * pu;
                              });
                              Navigator.pop(ctx);
                            },
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ],
          );
        },
      ),
    );
  }

  void _addItemToEditSale(
    BuildContext sheetCtx,
    StateSetter setSheet,
    List<Map<dynamic, dynamic>> items,
  ) {
    showDialog(
      context: sheetCtx,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          String search = '';
          return AlertDialog(
            title: Text('Agregar Producto',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Tema.textDark)),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Buscar producto...',
                      prefixIcon: Icon(Icons.search, size: 18),
                      isDense: true,
                    ),
                    onChanged: (v) => setDlg(() => search = v),
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    height: 300,
                    child: Builder(builder: (ctx) {
                      final filtered = _productos.where((p) {
                        if (search.isEmpty) return true;
                        final name = (p['nombre'] ?? '').toString().toLowerCase();
                        return name.contains(search.toLowerCase());
                      }).toList();

                      if (filtered.isEmpty) {
                        return Center(
                            child: Text('Sin resultados', style: TextStyle(color: Tema.textMuted)));
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final p = filtered[i];
                          final stock = (p['stock_actual'] as num?)?.toInt() ?? 0;
                          final price = p['precio_venta'] ?? 0;
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: Tema.primary.withValues(alpha: 0.1),
                              child: const Icon(Icons.add_shopping_cart, size: 16, color: Tema.primary),
                            ),
                            title: Text('${p['nombre'] ?? '?'}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            subtitle: Text('Stock: $stock  |  ${Fb.formatMoney(price)}',
                                style: TextStyle(fontSize: 11, color: Tema.textSoft)),
                            onTap: () {
                              setSheet(() {
                                items.add({
                                  'id': p['id'],
                                  'nombre': p['nombre'],
                                  'cantidad': 1,
                                  'precio_unitario': price,
                                  'subtotal': price,
                                });
                              });
                              Navigator.pop(ctx);
                            },
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ],
          );
        },
      ),
    );
  }

  // ─── anular venta ───
  Future<void> _anularVenta(Map<dynamic, dynamic> venta) async {
    if (_estado(venta) == 'anulada') {
      _snack('La venta ya esta anulada');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.warning_amber, color: Tema.danger, size: 24),
          SizedBox(width: 8),
          Text('Anular Venta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Tema.danger)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Venta #${venta['id']} - ${Fb.formatMoney(venta['total'] ?? 0)}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          SizedBox(height: 8),
          Text('Esta accion:\n'
              '1. Marcara la venta como anulada\n'
              '2. Devolvera el stock al inventario\n'
              '3. Restara los ingresos de la caja\n'
              '4. Si es fiado, cancelara los registros\n\n'
              'Esta accion no se puede deshacer.',
              style: TextStyle(fontSize: 13, color: Tema.textSoft)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Tema.danger),
            child: const Text('Anular Venta'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final vIdx = _ventas.indexWhere((v) => v['id'] == venta['id']);
    if (vIdx < 0) { _snack('Venta no encontrada'); return; }
    _ventas[vIdx]['estado'] = 'anulada';
    await Fb.setList('ventas', _ventas);

    final items = _items(_ventas[vIdx]);
    if (items.isNotEmpty) {
      for (final it in items) {
        final pid = (it['id'] ?? '').toString();
        final pIdx = _productos.indexWhere((p) => (p['id'] ?? '').toString() == pid);
        if (pIdx >= 0) {
          final currentStock = (_productos[pIdx]['stock_actual'] as num?)?.toInt() ?? 0;
          final qty = (it['cantidad'] as num?)?.toInt() ?? 0;
          _productos[pIdx]['stock_actual'] = currentStock + qty;
        }
      }
      await Fb.setList('productos', _productos);
    }

    final metodo = _metodo(venta);
    if (metodo != 'fiado') {
      final cajaId = venta['caja_id'];
      if (cajaId != null) {
        final cIdx = _cajas.indexWhere((c) => c['id'] == cajaId);
        if (cIdx >= 0) {
          final total = (venta['total'] as num?)?.toDouble() ?? 0;
          final movs = List<Map<dynamic, dynamic>>.from(_cajas[cIdx]['movimientos'] ?? []);
          movs.add({
            'tipo': 'egreso',
            'concepto': 'Reversion Venta #${venta['id']}',
            'monto': total,
            'metodo_pago': metodo,
            'fecha': DateTime.now().toIso8601String(),
          });
          _cajas[cIdx]['movimientos'] = movs;
          _cajas[cIdx]['ingresos'] = movs
              .where((m) => m['tipo'] == 'ingreso')
              .fold<double>(0, (s, m) => s + ((m['monto'] as num?)?.toDouble() ?? 0));
          _cajas[cIdx]['egresos'] = movs
              .where((m) => m['tipo'] != 'ingreso')
              .fold<double>(0, (s, m) => s + ((m['monto'] as num?)?.toDouble() ?? 0));
          await Fb.setList('cajas', _cajas);
        }
      }
    }

    if (metodo == 'fiado') {
      final fiadosList = await Fb.getList('fiados');
      var fiadoChanged = false;
      for (var f in fiadosList) {
        if (f['venta_id'] == venta['id']) {
          f['estado'] = 'anulado';
          fiadoChanged = true;
        }
      }
      if (fiadoChanged) await Fb.setList('fiados', fiadosList);

      final clienteId = venta['cliente_id'];
      if (clienteId != null) {
        final cliIdx = _clientes.indexWhere((c) => c['id'] == clienteId);
        if (cliIdx >= 0) {
          final current = ((_clientes[cliIdx]['saldo_pendiente'] ?? _clientes[cliIdx]['saldoPendiente'] ?? 0) as num).toDouble();
          final total = (venta['total'] as num?)?.toDouble() ?? 0;
          _clientes[cliIdx]['saldo_pendiente'] = (current - total).clamp(0, double.infinity);
          await Fb.setList('clientes', _clientes);
        }
      }
    }

    _snack('Venta #${venta['id']} anulada. Stock y caja revertidos.');
  }

  // ─── build ───
  @override
  Widget build(BuildContext context) {
    final fl = _filtered();
    final stats = _computeStats();

    return _loading
        ? const Center(child: CircularProgressIndicator())
        : Column(children: [
            Padding(
              padding: EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(children: stats.map((s) => Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 3),
                  child: Tema.kpiCard(
                    s['label'] as String,
                    s['value'] as String,
                    s['icon'] as IconData,
                    accent: s['accent'] as Color,
                  ),
                ),
              )).toList()),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Row(children: [
                Expanded(
                  child: SearchInput(
                    controller: _searchCtl,
                    hintText: 'Buscar por cliente o ID de venta...',
                    onChanged: (v) => setState(() => _searchQ = v),
                  ),
                ),
                if (_searchQ.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.clear, size: 18, color: Tema.textMuted),
                    onPressed: () {
                      _searchCtl.clear();
                      setState(() => _searchQ = '');
                    },
                  ),
              ]),
            ),
            SizedBox(height: 6),

            // ── Date presets row ──
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Row(children: [
                ...['Hoy', 'Ayer', 'Semana', 'Mes'].map((p) => Padding(
                  padding: EdgeInsets.only(right: 5),
                  child: _datePresetChip(p),
                )),
                Container(width: 1, height: 20, color: Tema.cardBorder),
                SizedBox(width: 6),
                _dateChip('Desde', _desde, () => _pickDate(true)),
                SizedBox(width: 6),
                _dateChip('Hasta', _hasta, () => _pickDate(false)),
                if (_desde != null || _hasta != null) ...[
                  SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => setState(() { _desde = null; _hasta = null; }),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: Tema.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.clear, size: 14, color: Tema.danger),
                    ),
                  ),
                ],
              ]),
            ),
            SizedBox(height: 4),

            // ── Payment method row ──
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Row(children: [
                ...['Todos', 'Efectivo', 'Tarjeta', 'Fiado'].map((m) => Padding(
                  padding: EdgeInsets.only(right: 5),
                  child: _methodChip(m),
                )),
              ]),
            ),

            SizedBox(height: 6),
            Expanded(
              child: fl.isEmpty
                  ? ListView(children: [
                      SizedBox(height: 80),
                      Center(child: Text('No se encontraron ventas', style: TextStyle(color: Tema.textMuted))),
                    ])
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      itemCount: fl.length,
                      itemBuilder: (_, i) => _ventaCard(fl[i]),
          )),
        ]);
  }

  // ─── widgets ───
  Widget _ventaCard(Map<dynamic, dynamic> v) {
    final anulada = _estado(v) == 'anulada';
    final metodo = _metodo(v);
    final items = _items(v);
    final itemsLen = _itemsCount(v);

    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDetail(v),
          borderRadius: BorderRadius.circular(Tema.radius),
          child: Container(
            decoration: anulada
                ? Tema.cardDeco.copyWith(color: Colors.red.shade50, border: Border.all(color: Colors.red.shade200))
                : Tema.cardDeco,
            padding: EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: anulada ? Colors.red.shade100 : _metodoColor(metodo).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(Tema.radiusSm),
                  ),
                  child: Icon(
                    anulada ? Icons.cancel : _metodoIcon(metodo),
                    color: anulada ? Tema.danger : _metodoColor(metodo),
                    size: 18,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text('Venta #${v['id']}',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                              color: anulada ? Tema.textMuted : Tema.textDark,
                              decoration: anulada ? TextDecoration.lineThrough : null)),
                      SizedBox(width: 8),
                      _badge(metodo),
                      SizedBox(width: 4),
                      _badge(_estado(v)),
                    ]),
                    SizedBox(height: 2),
                    Text('${v['cliente'] ?? 'Mostrador'}  \u2022  ${_fmtDate(v['fecha'] as String?)}',
                        style: TextStyle(fontSize: 12, color: anulada ? Tema.textMuted : Tema.textSoft)),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(Fb.formatMoney(v['total'] ?? 0),
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                          color: anulada ? Tema.textMuted : Tema.primary,
                          decoration: anulada ? TextDecoration.lineThrough : null)),
                  Text('$itemsLen items', style: TextStyle(fontSize: 11, color: anulada ? Tema.textMuted : Tema.textSoft)),
                ]),
              ]),
              if (items.isNotEmpty) ...[
                SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: items.take(4).map<Widget>((it) => Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${it['cantidad']}x ${it['nombre']}',
                      style: TextStyle(fontSize: 10, color: anulada ? Tema.textMuted : Tema.textSoft),
                    ),
                  )).toList(),
                ),
                if (items.length > 4)
                  Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text('+${items.length - 4} mas...',
                        style: TextStyle(fontSize: 10, color: anulada ? Tema.textMuted : Tema.primary)),
                  ),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  Widget _badge(String label) {
    final isAnulada = label == 'anulada' || label == 'Anulada';
    final isCompletada = label == 'Completada';
    final isFiado = label == 'fiado' || label == 'Fiado';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isAnulada
            ? Colors.red.shade50
            : isCompletada
                ? Colors.green.shade50
                : isFiado
                    ? Colors.orange.shade50
                    : Tema.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isAnulada
              ? Colors.red.shade200
              : isCompletada
                  ? Colors.green.shade200
                  : isFiado
                      ? Colors.orange.shade200
                      : Tema.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isAnulada
              ? Tema.danger
              : isCompletada
                  ? Colors.green.shade700
                  : isFiado
                      ? Colors.orange.shade700
                      : Tema.primary,
        ),
      ),
    );
  }

  Widget _datePresetChip(String label) {
    final isActive = _isPresetActive(label);
    return GestureDetector(
      onTap: () => _setDatePreset(label),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Tema.darkBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? Tema.darkBlue : Tema.cardBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : Tema.textSoft,
          ),
        ),
      ),
    );
  }

  bool _isPresetActive(String label) {
    if (_desde == null || _hasta == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final ayer = today.subtract(const Duration(days: 1));
    final ayerEnd = DateTime(ayer.year, ayer.month, ayer.day, 23, 59, 59);

    switch (label) {
      case 'Hoy':
        return _desde == today && _hasta == todayEnd;
      case 'Ayer':
        return _desde == ayer && _hasta == ayerEnd;
      case 'Semana':
        return _desde == today.subtract(const Duration(days: 7)) && _hasta == todayEnd;
      case 'Mes':
        return _desde == today.subtract(const Duration(days: 30)) && _hasta == todayEnd;
      default:
        return false;
    }
  }

  Widget _dateChip(String label, DateTime? date, VoidCallback onTap) {
    final hasVal = date != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: hasVal ? Tema.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: hasVal ? Tema.primary : Tema.cardBorder),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.calendar_today, size: 13, color: hasVal ? Colors.white : Tema.textMuted),
          SizedBox(width: 4),
          Text(
            hasVal ? '$label: ${_fmtDate(date.toIso8601String().substring(0, 10))}' : label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: hasVal ? Colors.white : Tema.textSoft),
          ),
        ]),
      ),
    );
  }

  Widget _methodChip(String label) {
    final selected = _metodoFiltro == label;
    return GestureDetector(
      onTap: () => setState(() => _metodoFiltro = selected ? 'Todos' : label),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Tema.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? Tema.primary : Tema.cardBorder),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Tema.textSoft)),
      ),
    );
  }

  static Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: 13, color: Tema.textSoft)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Tema.textDark)),
      ]),
    );
  }

  static Widget _th(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Tema.textSoft)),
    );
  }

  static Widget _td(String text, TextAlign align) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Tema.textDark),
      ),
    );
  }
}