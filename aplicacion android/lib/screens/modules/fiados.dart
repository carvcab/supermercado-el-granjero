import 'dart:async';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/firestore_service.dart';
import '../../theme.dart';

class FiaScreen extends StatefulWidget {
  const FiaScreen({super.key});
  @override
  State<FiaScreen> createState() => _FiaScreenState();
}

class _FiaScreenState extends State<FiaScreen> {
  final _q = TextEditingController();
  List<Map<dynamic, dynamic>> _fiados = [];
  List<Map<dynamic, dynamic>> _clientesData = [];
  List<Map<dynamic, dynamic>> _deudores = [];
  Map<dynamic, dynamic>? _sel;
  String _f = '';
  StreamSubscription? _sub;

  String _tab = 'pendientes';
  final Set<dynamic> _checked = {};
  final _montoCtl = TextEditingController();
  String _metodo = 'Efectivo';
  final _obsCtl = TextEditingController();

  StreamSubscription? _subClients;

  @override
  void initState() {
    super.initState();
    _subClients = Fb.stream('clientes').listen((d) => setState(() {
      _clientesData = d;
      _buildDeudores();
    }));
    _sub = Fb.stream('fiados').listen((d) {
      setState(() {
        _fiados = d;
        _buildDeudores();
        if (_sel != null) {
          final found = _deudores.where((d2) => d2['id'] == _sel!['id']).toList();
          _sel = found.isNotEmpty ? found.first : null;
        }
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _subClients?.cancel();
    _q.dispose();
    _montoCtl.dispose();
    _obsCtl.dispose();
    super.dispose();
  }

  void _buildDeudores() {
    final map = <dynamic, Map<dynamic, dynamic>>{};
    for (var f in _fiados) {
      final cid = f['cliente_id'];
      if (cid == null) continue;
      final saldo = _saldo(f);
      if (saldo <= 0) continue;
      if (!map.containsKey(cid)) {
        map[cid] = {
          'id': cid,
          'nombre': f['cliente_nombre'] ?? 'Cliente #$cid',
          'telefono': f['cliente_telefono'] ?? '',
          'total_deuda': 0,
          'fiados_activos': 0,
          'ultimo_abono': null as String?,
        };
      }
      map[cid]!['total_deuda'] = (map[cid]!['total_deuda'] as num) + saldo;
      map[cid]!['fiados_activos'] = (map[cid]!['fiados_activos'] as int) + 1;
      for (var ab in (f['abonos'] as List? ?? [])) {
        final fa = ab['fecha'] as String?;
        if (fa != null && (map[cid]!['ultimo_abono'] == null || fa.compareTo(map[cid]!['ultimo_abono']!) > 0)) {
          map[cid]!['ultimo_abono'] = fa;
  }
}

    }
    for (var c in _clientesData) {
      final cid = c['id'];
      if (cid != null && map.containsKey(cid)) {
        map[cid]!['nombre'] = c['nombre'] ?? map[cid]!['nombre'];
        map[cid]!['telefono'] = c['telefono'] ?? map[cid]!['telefono'];
      }
    }
    _deudores = map.values.toList()..sort((a, b) => (b['total_deuda'] as num).compareTo(a['total_deuda'] as num));
  }

  num _saldo(Map f) {
    final monto = (f['monto'] ?? 0) as num;
    final pagado = (f['abonos'] as List? ?? []).fold<num>(0, (s, a) => s + ((a['monto'] ?? 0) as num));
    return monto - pagado;
  }

  int _nextFiadoId() {
    if (_fiados.isEmpty) return 1;
    return _fiados.map((x) => (x['id'] as num?)?.toInt() ?? 0).reduce((a, b) => a > b ? a : b) + 1;
  }

  num _abonosMes() {
    final mes = DateTime.now().toIso8601String().substring(0, 7);
    num t = 0;
    for (var f in _fiados) {
      for (var a in (f['abonos'] as List? ?? [])) {
        if ((a['fecha'] ?? '').toString().startsWith(mes)) t += (a['monto'] ?? 0) as num;
      }
    }
    return t;
  }

  List<Map<dynamic, dynamic>> get _clienteFiados => _sel == null
      ? []
      : _fiados.where((f) => f['cliente_id'] == _sel!['id']).toList();

  List<Map<dynamic, dynamic>> get _pendientes =>
      _clienteFiados.where((f) => _saldo(f) > 0).toList();

  List<Map<String, dynamic>> get _historialAbonos {
    final res = <Map<String, dynamic>>[];
    for (var f in _clienteFiados) {
      for (var a in (f['abonos'] as List? ?? [])) {
        res.add({
          ...Map<String, dynamic>.from(a as Map),
          'fiado_id': f['id'],
          'fiado_producto': f['producto_nombre'] ?? '',
          'fiado_fecha': f['fecha'] ?? '',
        });
      }
    }
    res.sort((a, b) => (b['fecha'] ?? '').toString().compareTo(a['fecha'] ?? ''));
    return res;
  }

  num get _totalChecked {
    num t = 0;
    for (var f in _pendientes) {
      if (_checked.contains(f['id'])) t += _saldo(f);
    }
    return t;
  }

  List<Map<dynamic, dynamic>> _filtrarDeudores() {
    if (_f.isEmpty) return _deudores;
    final q = _f.toLowerCase();
    return _deudores.where((d) {
      final n = (d['nombre'] ?? '').toString().toLowerCase();
      final t = (d['telefono'] ?? '').toString();
      return n.contains(q) || t.contains(q);
    }).toList();
  }

  void _seleccionarCliente(dynamic clienteId) {
    final d = _deudores.where((d) => d['id'] == clienteId).toList();
    setState(() {
      _sel = d.isNotEmpty ? d.first : null;
      _tab = 'pendientes';
      _checked.clear();
      _montoCtl.clear();
      _obsCtl.clear();
      _metodo = 'Efectivo';
    });
  }

  void _cerrarDetalle() => setState(() {
    _sel = null;
    _checked.clear();
    _montoCtl.clear();
    _obsCtl.clear();
  });

  void _toggleAll(bool v) {
    setState(() {
      if (v) {
        for (var f in _pendientes) { _checked.add(f['id']); }
      } else {
        _checked.clear();
      }
    });
  }

  void _onCheckChange(dynamic id, bool v) {
    setState(() {
      if (v) { _checked.add(id); } else { _checked.remove(id); }
    });
  }

  Future<void> _registrarAbono(String tipo) async {
    final monto = num.tryParse(_montoCtl.text) ?? 0;
    if (monto <= 0) { _toast('Ingrese un monto valido'); return; }

    List<Map<dynamic, dynamic>> targets;
    if (tipo == 'manual') {
      if (_checked.isEmpty) { _toast('Seleccione al menos un fiado'); return; }
      targets = _pendientes.where((f) => _checked.contains(f['id'])).toList();
    } else {
      targets = List<Map<dynamic, dynamic>>.from(_pendientes);
      targets.sort((a, b) {
        final da = (a['fecha'] ?? '').toString();
        final db = (b['fecha'] ?? '').toString();
        final cmp = tipo == 'fifo' ? da.compareTo(db) : db.compareTo(da);
        if (cmp != 0) return cmp;
        final ia = (a['id'] is int) ? a['id'] as int : 0;
        final ib = (b['id'] is int) ? b['id'] as int : 0;
        return tipo == 'fifo' ? ia.compareTo(ib) : ib.compareTo(ia);
      });
    }

    var resto = monto;
    final preview = <Map<String, dynamic>>[];
    for (var f in targets) {
      if (resto <= 0) break;
      final s = _saldo(f);
      final pago = resto > s ? s : resto;
      preview.add({
        'id': f['id'],
        'fecha': f['fecha'] ?? '',
        'producto': f['producto_nombre'] ?? '-',
        'monto_original': f['monto'] ?? 0,
        'saldo': s,
        'pago': pago,
        'nuevo_saldo': s - pago,
      });
      resto -= pago;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tipo == 'fifo' ? 'Vista Previa FIFO' : tipo == 'lifo' ? 'Vista Previa LIFO' : 'Confirmar Abono'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Info section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(color: Tema.bg, borderRadius: BorderRadius.circular(Tema.radiusSm), border: Border.all(color: Tema.cardBorder)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _infoRow('Tipo', tipo == 'fifo' ? 'FIFO (Principio a Fin)' : tipo == 'lifo' ? 'LIFO (Fin a Inicio)' : 'Manual'),
                _infoRow('Monto ingresado', Fb.formatMoney(monto)),
                _infoRow('Total a pagar', Fb.formatMoney(monto - resto)),
                _infoRow('Metodo', _metodo),
                if (_obsCtl.text.trim().isNotEmpty) _infoRow('Observaciones', _obsCtl.text.trim()),
                if (resto > 0) _infoRow('Restante sin aplicar', Fb.formatMoney(resto)),
              ]),
            ),
            SizedBox(height: 12),
            Text('Desglose:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Tema.textDark)),
            SizedBox(height: 6),
            ...preview.map((p) => Container(
              margin: EdgeInsets.only(bottom: 4),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(border: Border.all(color: Tema.cardBorder), borderRadius: BorderRadius.circular(8)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text('${p['producto']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                  Text(p['fecha'].toString(), style: TextStyle(fontSize: 11, color: Tema.textMuted)),
                ]),
                SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Saldo: ${Fb.formatMoney(p['saldo'])}', style: const TextStyle(fontSize: 12, color: Tema.danger)),
                  Icon(Icons.arrow_forward, size: 14, color: Tema.textMuted),
                  Text('Pago: ${Fb.formatMoney(p['pago'])}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Tema.primary)),
                  Icon(Icons.arrow_forward, size: 14, color: Tema.textMuted),
                  Text('Nuevo: ${Fb.formatMoney(p['nuevo_saldo'])}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: (p['nuevo_saldo'] as num) > 0 ? Tema.danger : Colors.green)),
                ]),
              ]),
            )),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Tema.primary, foregroundColor: Colors.white), child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirm != true) return;

    final now = DateTime.now().toIso8601String();
    for (var p in preview) {
      if ((p['pago'] as num) <= 0) continue;
      final idx = _fiados.indexWhere((f) => f['id'] == p['id']);
      if (idx == -1) continue;
      final fiado = _fiados[idx];
      var abonos = (fiado['abonos'] as List?)?.map((e) => Map<dynamic, dynamic>.from(e as Map)).toList() ?? [];
      abonos.add({
        'fecha': now,
        'monto': p['pago'],
        'metodo_pago': _metodo,
        'observaciones': _obsCtl.text.trim(),
        'tipo_amortizacion': tipo,
      });
      fiado['abonos'] = abonos;
      if ((p['nuevo_saldo'] as num) <= 0) {
        fiado['estado'] = 'pagado';
      }
    }
    await Fb.setList('fiados', _fiados);

    final totalCobrado = monto - resto;

    try {
      final cajaN = await Fb.getDoc('config_caja_negocio');
      final currentBal = (cajaN['balance'] ?? 0) as num;
      final currentBalCierre = (cajaN['balance_al_cierre'] ?? 0) as num;
      cajaN['balance'] = currentBal + totalCobrado.toDouble();
      cajaN['balance_al_cierre'] = currentBalCierre + totalCobrado.toDouble();
      cajaN['updated_at'] = DateTime.now().toIso8601String();
      await Fb.setDoc('config_caja_negocio', cajaN);
    } catch (_) {}

    if (_sel != null) {
      final cid = _sel!['id'];
      final cliIdx = _clientesData.indexWhere((x) => x['id'] == cid);
      if (cliIdx >= 0) {
        final current = (_clientesData[cliIdx]['saldo_pendiente'] as num?)?.toDouble() ?? 0;
        _clientesData[cliIdx]['saldo_pendiente'] = (current - totalCobrado.toDouble()).clamp(0, double.infinity);
        await Fb.setList('clientes', _clientesData);
      }
    }

    _montoCtl.clear();
    _obsCtl.clear();
    _checked.clear();
    _toast('Abono registrado correctamente');
  }

  Future<void> _mostrarNuevoFiado() async {
    final clienteCtl = TextEditingController();
    Map<dynamic, dynamic>? clienteSel;
    final montoCtl = TextEditingController();
    DateTime fechaSel = DateTime.now();
    final obsCtl = TextEditingController();
    final concepto = TextEditingController(text: 'Fiado');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.8),
            child: AlertDialog(
              title: Text('Nuevo Fiado', style: TextStyle(fontWeight: FontWeight.w700, color: Tema.textDark)),
              content: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Autocomplete<Map<dynamic, dynamic>>(
                    displayStringForOption: (c) => (c['nombre'] ?? '').toString(),
                    optionsBuilder: (v) {
                      final q = v.text.toLowerCase();
                      return _clientesData.where((c) => (c['nombre'] ?? '').toString().toLowerCase().contains(q));
                    },
                    onSelected: (c) => setSt(() {
                      clienteSel = c;
                      clienteCtl.text = (c['nombre'] ?? '').toString();
                    }),
                    fieldViewBuilder: (ctx, ctl, node, onSubmitted) => TextField(
                      controller: clienteCtl,
                      focusNode: node,
                      decoration: const InputDecoration(
                        labelText: 'Cliente *',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onSubmitted: (_) => onSubmitted(),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: concepto,
                    decoration: const InputDecoration(labelText: 'Concepto', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: montoCtl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Monto *', prefixText: '\$ ', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                  ),
                  SizedBox(height: 10),
                  InkWell(
                    onTap: () async {
                      final d = await showDatePicker(context: ctx, initialDate: fechaSel, firstDate: DateTime(2020), lastDate: DateTime(2100));
                      if (d != null) setSt(() => fechaSel = d);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Fecha', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10), suffixIcon: Icon(Icons.calendar_today, size: 18)),
                      child: Text(fechaSel.toIso8601String().substring(0, 10), style: const TextStyle(fontSize: 14)),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: obsCtl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Observaciones', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                  ),
                ]),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () {
                    if (clienteSel == null && clienteCtl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Seleccione un cliente')));
                      return;
                    }
                    final monto = num.tryParse(montoCtl.text) ?? 0;
                    if (monto <= 0) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Ingrese un monto valido')));
                      return;
                    }
                    Navigator.pop(ctx, true);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Tema.primary),
                  child: const Text('Guardar'),
                ),
              ],
            ),
          );
        },
      ),
    );
    if (ok != true) return;

    final monto = num.tryParse(montoCtl.text) ?? 0;
    if (clienteSel == null) {
      final q = clienteCtl.text.trim().toLowerCase();
      final found = _clientesData.where((c) => (c['nombre'] ?? '').toString().toLowerCase() == q).toList();
      if (found.isNotEmpty) clienteSel = found.first;
    }

    final fiado = <dynamic, dynamic>{
      'id': _nextFiadoId(),
      'cliente_id': clienteSel?['id'],
      'cliente_nombre': clienteSel?['nombre'] ?? clienteCtl.text.trim(),
      'cliente_telefono': clienteSel?['telefono'] ?? '',
      'producto_nombre': concepto.text.trim().isEmpty ? 'Fiado' : concepto.text.trim(),
      'monto': monto,
      'fecha': fechaSel.toIso8601String().substring(0, 10),
      'estado': 'Pendiente',
      'abonos': <Map<dynamic, dynamic>>[],
      'observaciones': obsCtl.text.trim(),
      'usuario': 'Sistema',
    };
    _fiados.add(fiado);
    await Fb.setList('fiados', _fiados);

    if (clienteSel != null) {
      final cliIdx = _clientesData.indexWhere((x) => x['id'] == clienteSel!['id']);
      if (cliIdx >= 0) {
        final current = (_clientesData[cliIdx]['saldo_pendiente'] as num?)?.toDouble() ?? 0;
        _clientesData[cliIdx]['saldo_pendiente'] = current + monto.toDouble();
        await Fb.setList('clientes', _clientesData);
      }
    }
    if (mounted) _toast('Fiado registrado correctamente');
  }

  Future<void> _mostrarPagarFiado(Map f) async {
    final s = _saldo(f);
    final montoCtl = TextEditingController(text: s.toString());
    String metodo = 'Efectivo';
    final obsCtl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.8),
            child: AlertDialog(
              title: Text('Pagar Fiado', style: TextStyle(fontWeight: FontWeight.w700, color: Tema.textDark)),
              content: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Tema.bg, borderRadius: BorderRadius.circular(Tema.radiusSm), border: Border.all(color: Tema.cardBorder)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _infoRow('Cliente', (f['cliente_nombre'] ?? '').toString()),
                      _infoRow('Concepto', (f['producto_nombre'] ?? 'Fiado').toString()),
                      _infoRow('Fecha', (f['fecha'] ?? '').toString()),
                      _infoRow('Saldo pendiente', Fb.formatMoney(s)),
                    ]),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: montoCtl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Monto a pagar', prefixText: '\$ ', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                    onChanged: (_) => setSt(() {}),
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: metodo,
                    decoration: const InputDecoration(labelText: 'Metodo de pago', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                    items: ['Efectivo', 'Tarjeta', 'Transferencia'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (v) => setSt(() => metodo = v ?? 'Efectivo'),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: obsCtl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Observaciones', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                  ),
                ]),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () {
                    final monto = num.tryParse(montoCtl.text) ?? 0;
                    if (monto <= 0) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Ingrese un monto valido')));
                      return;
                    }
                    if (monto > s) {
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('El monto maximo es ${Fb.formatMoney(s)}')));
                      return;
                    }
                    Navigator.pop(ctx, true);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Tema.primary),
                  child: const Text('Confirmar'),
                ),
              ],
            ),
          );
        },
      ),
    );
    if (ok != true) return;

    final montoPago = num.tryParse(montoCtl.text) ?? 0;
    final now = DateTime.now().toIso8601String();

    final idx = _fiados.indexWhere((x) => x['id'] == f['id']);
    if (idx >= 0) {
      var abonos = (_fiados[idx]['abonos'] as List?)
          ?.map((e) => Map<dynamic, dynamic>.from(e as Map))
          .toList() ?? [];
      abonos.add({
        'fecha': now,
        'monto': montoPago,
        'metodo_pago': metodo,
        'observaciones': obsCtl.text.trim(),
        'tipo_amortizacion': 'directo',
      });
      _fiados[idx]['abonos'] = abonos;
      if (_saldo(_fiados[idx]) <= 0) {
        _fiados[idx]['estado'] = 'pagado';
      }
    }
    await Fb.setList('fiados', _fiados);

    // Payments go directly to caja negocio
    try {
      final cajaN = await Fb.getDoc('config_caja_negocio');
      final currentBal = (cajaN['balance'] ?? 0) as num;
      final currentBalCierre = (cajaN['balance_al_cierre'] ?? 0) as num;
      cajaN['balance'] = currentBal + montoPago.toDouble();
      cajaN['balance_al_cierre'] = currentBalCierre + montoPago.toDouble();
      cajaN['updated_at'] = DateTime.now().toIso8601String();
      await Fb.setDoc('config_caja_negocio', cajaN);
    } catch (_) {}

    final cid = f['cliente_id'];
    if (cid != null) {
      final cliIdx = _clientesData.indexWhere((x) => x['id'] == cid);
      if (cliIdx >= 0) {
        final current = (_clientesData[cliIdx]['saldo_pendiente'] as num?)?.toDouble() ?? 0;
        _clientesData[cliIdx]['saldo_pendiente'] = (current - montoPago.toDouble()).clamp(0, double.infinity);
        await Fb.setList('clientes', _clientesData);
      }
    }

    if (mounted) _toast('Pago registrado correctamente');
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }

  void _compartirCuenta() {
    final c = _sel;
    if (c == null) return;
    final nombre = c['nombre'] ?? 'Cliente';
    final telefono = c['telefono'] ?? '';
    final deuda = c['total_deuda'] ?? 0;

    final buf = StringBuffer();
    buf.writeln('*CUENTA DE FIADOS - $nombre*');
    if (telefono.isNotEmpty) buf.writeln('Tel: $telefono');
    buf.writeln('Deuda total: ${Fb.formatMoney(deuda)}');
    buf.writeln('Fiados activos: ${c['fiados_activos'] ?? 0}');
    buf.writeln('');

    final pendientes = _pendientes;
    if (pendientes.isNotEmpty) {
      buf.writeln('--- FIADOS PENDIENTES ---');
      for (final f in pendientes) {
        final s = _saldo(f);
        buf.writeln('• ${f['producto_nombre'] ?? "Fiado #${f['id']}"}');
        buf.writeln('  Monto: ${Fb.formatMoney(f['monto'] ?? 0)} | Saldo: ${Fb.formatMoney(s)} | Fecha: ${f['fecha'] ?? "-"}');
      }
      buf.writeln('');
    }

    final abonos = _historialAbonos;
    if (abonos.isNotEmpty) {
      buf.writeln('--- HISTORIAL DE PAGOS ---');
      for (final a in abonos.take(20)) {
        buf.writeln('• ${Fb.formatMoney(a['monto'] ?? 0)} - ${a['fecha'] ?? "-"} (${a['metodo_pago'] ?? "-"})');
      }
      if (abonos.length > 20) buf.writeln('... y ${abonos.length - 20} abonos mas');
    }

    buf.writeln('');
    buf.writeln('Generado por Supermercado El Granjero');
    buf.writeln(DateTime.now().toString().substring(0, 10));

    Share.share(buf.toString(), subject: 'Cuenta de Fiados - $nombre');
  }

  static Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Text('$label: ', style: TextStyle(fontSize: 12, color: Tema.textSoft)),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Tema.textDark)),
      ]),
    );
  }



  // ─── MAIN VIEW ──────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_sel != null) return _buildDetalle();
    return _buildMain();
  }

  Widget _buildMain() {
    final fl = _filtrarDeudores();
    final fa = _fiados.where((f) => _saldo(f) > 0).length;
    return Stack(children: [
      Column(children: [
      SizedBox(
        height: 104,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          children: [
            Tema.kpiCard('Deuda Global', Fb.formatMoney(_deudores.fold<num>(0, (s, d) => s + (d['total_deuda'] as num))), Icons.money_off, accent: Tema.danger),
            SizedBox(width: 8),
            Tema.kpiCard('Deudores Activos', '${_deudores.length}', Icons.people, accent: Colors.orange),
            SizedBox(width: 8),
            Tema.kpiCard('Fiados Activos', '$fa', Icons.receipt_long, accent: Tema.darkBlue),
            SizedBox(width: 8),
            Tema.kpiCard('Abonos del Mes', Fb.formatMoney(_abonosMes()), Icons.payments, accent: Tema.primary),
          ],
        ),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: SearchInput(
          controller: _q,
          hintText: 'Buscar deudor...',
          onChanged: (v) => setState(() => _f = v),
        ),
      ),
      SizedBox(height: 4),
      Expanded(
        child: fl.isEmpty
              ? ListView(children: [Padding(padding: EdgeInsets.all(40), child: Text('No se encontraron deudores', textAlign: TextAlign.center, style: TextStyle(color: Tema.textMuted)))])
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  itemCount: fl.length,
                  itemBuilder: (_, i) => _buildDeudorCard(fl[i]),
                ),
      ),
    ]),
    Positioned(
      bottom: 20,
      right: 16,
      child: FloatingActionButton(
        onPressed: _mostrarNuevoFiado,
        backgroundColor: Tema.primary,
        child: const Icon(Icons.add),
      ),
    ),
    ]);
  }

  Widget _buildDeudorCard(Map d) {
    final nombre = d['nombre'] ?? 'Cliente';
    final telefono = d['telefono'] ?? '-';
    final deuda = (d['total_deuda'] ?? 0) as num;
    final activos = d['fiados_activos'] ?? 0;
    final ultimo = d['ultimo_abono'] as String?;
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => _seleccionarCliente(d['id']),
        child: Container(
          decoration: Tema.cardDeco,
          padding: EdgeInsets.all(14),
          child: Row(children: [
            CircleAvatar(backgroundColor: Tema.danger, radius: 18, child: Text(nombre.toString()[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
            SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(nombre.toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Tema.textDark))),
                  Flexible(child: Text(Fb.formatMoney(deuda), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Tema.danger))),
                ]),
                SizedBox(height: 4),
                Flexible(child: Row(children: [
                  Icon(Icons.phone, size: 12, color: Tema.textMuted),
                  SizedBox(width: 4),
                  Flexible(child: Text(telefono.toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Tema.textSoft))),
                  SizedBox(width: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Tema.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(99)),
                    child: Text('$activos activos', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Tema.primary)),
                  ),
                  const Spacer(),
                  if (ultimo != null) ...[
                    Icon(Icons.history, size: 11, color: Tema.textMuted),
                    SizedBox(width: 3),
                    Text(ultimo.substring(0, 10), style: TextStyle(fontSize: 10, color: Tema.textMuted)),
                  ],
                ])),
              ]),
            ),
            SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Tema.textMuted),
          ]),
        ),
      ),
    );
  }

  // ─── DETAIL VIEW ────────────────────────────────
  Widget _buildDetalle() {
    final c = _sel!;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // Header
      Container(
        decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Tema.cardBorder))),
        padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(children: [
          IconButton(icon: const Icon(Icons.arrow_back), onPressed: _cerrarDetalle, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
          SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c['nombre'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Tema.textDark)),
              Flexible(child: Row(children: [
                if ((c['telefono'] ?? '').toString().isNotEmpty) ...[
                  Icon(Icons.phone, size: 12, color: Tema.textMuted),
                  SizedBox(width: 4),
                  Text(c['telefono'].toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Tema.textSoft)),
                  SizedBox(width: 16),
                ],
                Flexible(child: Text('Deuda: ${Fb.formatMoney(c['total_deuda'] ?? 0)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Tema.danger))),
                SizedBox(width: 12),
                Flexible(child: Text('Fiados: ${c['fiados_activos'] ?? 0}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Tema.textSoft))),
                ])),
              ]),
          ),
          IconButton(
            icon: const Icon(Icons.share, size: 20),
            onPressed: _compartirCuenta,
            tooltip: 'Compartir cuenta del cliente',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ]),
      ),
      // Tabs
      Container(
        decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Tema.cardBorder))),
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Row(children: [
          _tabBtn('Fiados Pendientes', 'pendientes'),
          SizedBox(width: 4),
          _tabBtn('Historial Abonos', 'abonos'),
        ]),
      ),

      SizedBox(height: 8),

      // Content
      Expanded(child: _tab == 'pendientes' ? _buildPendientes() : _buildHistorial()),
    ]);
  }

  Widget _tabBtn(String label, String tab) {
    final active = _tab == tab;
    return GestureDetector(
      onTap: () => setState(() => _tab = tab),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: active ? Tema.primary : Colors.transparent, width: 2)),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: active ? Tema.primary : Tema.textMuted)),
      ),
    );
  }

  Widget _buildPendientes() {
    final pendientes = _pendientes;
    if (pendientes.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.check_circle, size: 48, color: Tema.textMuted),
        SizedBox(height: 12),
        Text('Sin fiados pendientes', style: TextStyle(color: Tema.textMuted, fontSize: 15)),
        Text('Este cliente no tiene creditos pendientes.', style: TextStyle(color: Tema.textMuted, fontSize: 12)),
      ]));
    }

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 8),
      children: [
        // Select all
        Container(
          margin: EdgeInsets.only(bottom: 8),
          decoration: Tema.cardDeco,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            Checkbox(
              value: _checked.length == pendientes.length && pendientes.isNotEmpty,
              tristate: false,
              onChanged: (v) => _toggleAll(v ?? false),
              activeColor: Tema.primary,
            ),
            SizedBox(width: 4),
            Text('Seleccionar todos', style: TextStyle(fontSize: 13, color: Tema.textSoft)),
            const Spacer(),
            Text('${Fb.formatMoney(_totalChecked)} seleccionado', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Tema.primary)),
          ]),
        ),

        // Fiados list
        ...pendientes.map((f) => _buildFiadoCard(f)),

        SizedBox(height: 12),

        // Abono form
        Container(
          margin: EdgeInsets.only(bottom: 16),
          decoration: Tema.cardDeco,
          padding: EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Registrar Abono', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Tema.textDark)),
            SizedBox(height: 12),
            TextField(
              controller: _montoCtl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Monto a abonar', prefixText: '\$ '),
            ),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _metodo,
              decoration: const InputDecoration(labelText: 'Metodo de pago'),
              items: ['Efectivo', 'Tarjeta', 'Transferencia'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) => setState(() => _metodo = v ?? 'Efectivo'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _obsCtl,
              decoration: const InputDecoration(labelText: 'Observaciones'),
              maxLines: 2,
            ),
            SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _checked.isEmpty ? null : () => _registrarAbono('manual'),
                  icon: const Icon(Icons.check_circle, size: 16),
                  label: const Text('Pagar Seleccion'),
                  style: ElevatedButton.styleFrom(backgroundColor: Tema.primary, foregroundColor: Colors.white, padding: EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
            ]),
            SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _registrarAbono('fifo'),
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: const Text('FIFO'),
                  style: OutlinedButton.styleFrom(foregroundColor: Tema.primary, padding: EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _registrarAbono('lifo'),
                  icon: const Icon(Icons.skip_next, size: 16),
                  label: const Text('LIFO'),
                  style: OutlinedButton.styleFrom(foregroundColor: Tema.primary, padding: EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
            ]),
          ]),
        ),
      ],
    );
  }

  Widget _buildFiadoCard(Map f) {
    final check = _checked.contains(f['id']);
    final s = _saldo(f);
    return Container(
      margin: EdgeInsets.only(bottom: 6),
      decoration: Tema.cardDeco,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(children: [
        Checkbox(
          value: check,
          onChanged: (v) => _onCheckChange(f['id'], v ?? false),
          activeColor: Tema.primary,
        ),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(f['producto_nombre'] ?? 'Fiado #${f['id']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Tema.textDark))),
              SizedBox(width: 8),
              Flexible(child: Text(Fb.formatMoney(s), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Tema.danger))),
            ]),
            SizedBox(height: 2),
            Row(children: [
              Icon(Icons.calendar_today, size: 10, color: Tema.textMuted),
              SizedBox(width: 3),
              Text(f['fecha'] ?? '', style: TextStyle(fontSize: 11, color: Tema.textSoft)),
              SizedBox(width: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)),
                child: Text(f['estado'] ?? 'pendiente', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.orange)),
              ),
              SizedBox(width: 12),
              if (f['usuario'] != null) ...[
                Icon(Icons.person, size: 10, color: Tema.textMuted),
                SizedBox(width: 3),
                Text(f['usuario'].toString(), style: TextStyle(fontSize: 11, color: Tema.textMuted)),
              ],
            ]),
          ]),
        ),
        SizedBox(width: 4),
        SizedBox(
          height: 34,
          child: ElevatedButton.icon(
            onPressed: () => _mostrarPagarFiado(f),
            icon: const Icon(Icons.payments, size: 14),
            label: const Text('Pagar', style: TextStyle(fontSize: 11)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Tema.primary,
              padding: EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tema.radiusSm)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildHistorial() {
    final abonos = _historialAbonos;
    if (abonos.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.receipt_long, size: 48, color: Tema.textMuted),
        SizedBox(height: 12),
        Text('Sin abonos registrados', style: TextStyle(color: Tema.textMuted, fontSize: 15)),
        Text('No hay pagos registrados para este cliente.', style: TextStyle(color: Tema.textMuted, fontSize: 12)),
      ]));
    }

    return ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        itemCount: abonos.length,
        itemBuilder: (_, i) {
          final a = abonos[i];
          final tipo = (a['tipo_amortizacion'] ?? '').toString().toUpperCase();
          final tipoColors = tipo == 'FIFO' ? Tema.darkBlue : tipo == 'LIFO' ? Colors.orange : Tema.textSoft;
          return Container(
            margin: EdgeInsets.only(bottom: 8),
            decoration: Tema.cardDeco,
            padding: EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(backgroundColor: Tema.primary, radius: 16, child: const Icon(Icons.payment, color: Colors.white, size: 14)),
                SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(Fb.formatMoney(a['monto'] ?? 0), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Tema.primary)),
                    Text(a['fecha'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Tema.textMuted)),
                  ]),
                ),
                if (tipo.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: tipoColors.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)),
                    child: Text(tipo, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: tipoColors)),
                  ),
              ]),
              SizedBox(height: 8),
              Row(children: [
                _chp(Icons.credit_card, a['metodo_pago'] ?? '-'),
                SizedBox(width: 16),
                _chp(Icons.receipt, a['fiado_producto'] ?? '-'),
              ]),
              if ((a['observaciones'] ?? '').toString().isNotEmpty) ...[
                SizedBox(height: 6),
                _chp(Icons.chat_outlined, a['observaciones'] ?? ''),
              ],
              GestureDetector(
                onTap: () => _verDetalleAbono(a),
                child: Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Text('Ver detalle', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Tema.primary.withValues(alpha: 0.8))),
                    SizedBox(width: 4),
                    const Icon(Icons.open_in_new, size: 12, color: Tema.primary),
                  ]),
                ),
              ),
            ]),
          );
        },
      );
  }

  Widget _chp(IconData icon, String text) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: Tema.textMuted),
      SizedBox(width: 4),
      Text(text, style: TextStyle(fontSize: 11, color: Tema.textSoft)),
    ]);
  }

  void _verDetalleAbono(Map<String, dynamic> a) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Detalle del Abono', style: TextStyle(fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(color: Tema.bg, borderRadius: BorderRadius.circular(Tema.radiusSm), border: Border.all(color: Tema.cardBorder)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _infoRow('Fecha', a['fecha'] ?? '-'),
                _infoRow('Monto', Fb.formatMoney(a['monto'] ?? 0)),
                _infoRow('Metodo', a['metodo_pago'] ?? '-'),
                _infoRow('Tipo', (a['tipo_amortizacion'] ?? '-').toString().toUpperCase()),
                if ((a['observaciones'] ?? '').toString().isNotEmpty) _infoRow('Observaciones', a['observaciones'] ?? ''),
              ]),
            ),
            SizedBox(height: 12),
            Text('Fiado asociado:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Tema.textDark)),
            SizedBox(height: 4),
            _infoRow('Producto', a['fiado_producto'] ?? '-'),
            _infoRow('Fecha fiado', a['fiado_fecha'] ?? '-'),
          ]),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar'))],
      ),
    );
  }
}

