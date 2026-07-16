import 'dart:async';

import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../theme.dart';

class CliScreen extends StatefulWidget {
  const CliScreen({super.key});
  @override
  State<CliScreen> createState() => _CliScreenState();
}

class _CliScreenState extends State<CliScreen> {
  final _q = TextEditingController();
  List<Map<dynamic, dynamic>> _d = [];
  String _f = '';
  String _tipo = '';
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _sub = Fb.stream('clientes').listen((d) {
      for (var c in d) {
        c['saldo_pendiente'] ??= 0;
        c['credito_maximo'] ??= 0;
      }
      setState(() => _d = d);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  String _getEstado(Map c) {
    final saldo = (c['saldo_pendiente'] ?? 0) as num;
    final credito = (c['credito_maximo'] ?? 0) as num;
    if (saldo == 0) return 'Al dia';
    if (saldo >= credito && credito > 0) return 'Bloqueado';
    return 'Deudor';
  }

  List<Map> _filtrar() {
    return _d.where((c) {
      if (_f.isNotEmpty) {
        final q = _f.toLowerCase();
        final n = (c['nombre'] ?? '').toString().toLowerCase();
        final t = (c['telefono'] ?? '').toString();
        final d = (c['numero_documento'] ?? '').toString();
        if (!n.contains(q) && !t.contains(q) && !d.contains(q)) return false;
      }
      if (_tipo.isNotEmpty && c['tipo'] != _tipo) return false;
      return true;
    }).toList();
  }

  Future<void> _abrirForm([Map? c]) async {
    final nombreCtl = TextEditingController(text: c?['nombre'] ?? '');
    final telCtl = TextEditingController(text: c?['telefono'] ?? '');
    final docCtl = TextEditingController(text: c?['numero_documento'] ?? '');
    final emailCtl = TextEditingController(text: c?['email'] ?? '');
    final dirCtl = TextEditingController(text: c?['direccion'] ?? '');
    final creditoCtl = TextEditingController(text: (c?['credito_maximo'] ?? '').toString());
    final obsCtl = TextEditingController(text: c?['observaciones'] ?? '');
    final saldoInicialCtl = TextEditingController();
    String tipo = c?['tipo'] ?? 'Ocasional';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Row(children: [
            Expanded(child: Text(
              c != null ? 'Editar Cliente' : 'Nuevo Cliente',
              style: TextStyle(fontWeight: FontWeight.w700),
            )),
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
                Expanded(child: _fld('Nombre', nombreCtl)),
                SizedBox(width: 8),
                Expanded(child: _fld('Telefono', telCtl)),
              ]),
              Row(children: [
                Expanded(child: _fld('Documento (CC/NIT)', docCtl)),
                SizedBox(width: 8),
                Expanded(child: _fld('Email', emailCtl)),
              ]),
              _fld('Direccion', dirCtl),
              _fldDd('Tipo', tipo, ['Frecuente', 'Ocasional', 'Comercial'],
                  (v) => setSt(() => tipo = v!)),
              _fld('Credito Maximo', creditoCtl, number: true),
              if (c == null) _fld('Deuda Inicial / Saldo Anterior', saldoInicialCtl, number: true),
              _fld('Observaciones', obsCtl),
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
    if (ok != true) return;
    if (nombreCtl.text.trim().isEmpty) return;

    if (c != null) {
      c['nombre'] = nombreCtl.text.trim();
      c['telefono'] = telCtl.text.trim();
      c['numero_documento'] = docCtl.text.trim();
      c['email'] = emailCtl.text.trim();
      c['direccion'] = dirCtl.text.trim();
      c['tipo'] = tipo;
      c['credito_maximo'] = int.tryParse(creditoCtl.text) ?? 0;
      c['observaciones'] = obsCtl.text.trim();
    } else {
      final id = _d.isEmpty
          ? 1
          : _d.map((x) => (x['id'] as num?)?.toInt() ?? 0).reduce((a, b) => a > b ? a : b) + 1;
      final saldoInicial = int.tryParse(saldoInicialCtl.text) ?? 0;
      _d.add({
        'id': id,
        'nombre': nombreCtl.text.trim(),
        'telefono': telCtl.text.trim(),
        'numero_documento': docCtl.text.trim(),
        'email': emailCtl.text.trim(),
        'direccion': dirCtl.text.trim(),
        'tipo': tipo,
        'credito_maximo': int.tryParse(creditoCtl.text) ?? 0,
        'saldo_pendiente': saldoInicial,
        'observaciones': obsCtl.text.trim(),
        'activo': true,
        'fecha_registro': DateTime.now().toIso8601String(),
      });
      
      if (saldoInicial > 0) {
        try {
          final fiados = await Fb.getList('fiados');
          final newFiadoId = fiados.isEmpty
              ? 1
              : fiados.map((x) => (x['id'] as num?)?.toInt() ?? 0).reduce((a, b) => a > b ? a : b) + 1;
          fiados.add({
            'id': newFiadoId,
            'cliente_id': id,
            'cliente': nombreCtl.text.trim(),
            'monto_original': saldoInicial,
            'monto_pendiente': saldoInicial,
            'saldo': saldoInicial,
            'monto': saldoInicial,
            'fecha': DateTime.now().toIso8601String().substring(0, 10),
            'estado': 'Pendiente',
            'detalle': 'Saldo inicial / Deuda anterior cargada',
          });
          await Fb.setList('fiados', fiados);
        } catch (e) {
          debugPrint('Error al registrar fiado inicial: $e');
        }
      }
    }
    await Fb.setList('clientes', _d);
  }

  Future<void> _eliminar(Map c) async {
    _d.removeWhere((x) => x['id'] == c['id']);
    await Fb.setList('clientes', _d);
    await Fb.recordDeletion('clientes', c['id']);

    // Cascade delete related fiados
    try {
      final List<Map<dynamic, dynamic>> allFiados = await Fb.getList('fiados');
      final toDeleteFiados = allFiados.where((x) => (x['cliente_id']?.toString() ?? '') == (c['id']?.toString() ?? '')).toList();
      for (final f in toDeleteFiados) {
        await Fb.recordDeletion('fiados', f['id']);
      }
      final initialFiadosLength = allFiados.length;
      allFiados.removeWhere((x) => (x['cliente_id']?.toString() ?? '') == (c['id']?.toString() ?? ''));
      if (allFiados.length != initialFiadosLength) {
        await Fb.setList('fiados', allFiados);
      }
    } catch (e) {
      debugPrint('Error cascade deleting fiados: $e');
    }

    // Cascade delete related abonos
    try {
      final List<Map<dynamic, dynamic>> allAbonos = await Fb.getList('fiado_abonos');
      final toDeleteAbonos = allAbonos.where((x) => (x['cliente_id']?.toString() ?? '') == (c['id']?.toString() ?? '')).toList();
      for (final a in toDeleteAbonos) {
        await Fb.recordDeletion('fiado_abonos', a['id']);
      }
      final initialAbonosLength = allAbonos.length;
      allAbonos.removeWhere((x) => (x['cliente_id']?.toString() ?? '') == (c['id']?.toString() ?? ''));
      if (allAbonos.length != initialAbonosLength) {
        await Fb.setList('fiado_abonos', allAbonos);
      }
    } catch (e) {
      debugPrint('Error cascade deleting abonos: $e');
    }
  }

  void _abrirDetalle(Map c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Tema.radiusLg))),
      builder: (ctx) => _ClienteDetalle(
        cliente: c,
        onEdit: () {
          Navigator.pop(ctx);
          _abrirForm(c);
        },
      ),
    );
  }

  Widget _fld(String l, TextEditingController ctl, {bool number = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: ctl,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: l,
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  Widget _fldDd(String l, String val, List<String> items, ValueChanged<String?> onChange) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<String>(
        value: val,
        isExpanded: true,
        items: items.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
        onChanged: onChange,
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
    final fl = _filtrar();
    final total = _d.length;
    final deudaGlobal = _d.fold<num>(0, (s, c) => s + ((c['saldo_pendiente'] ?? 0) as num));
    final conDeuda = _d.where((c) => ((c['saldo_pendiente'] ?? 0) as num) > 0).length;
    final creditoTotal = _d.fold<num>(0, (s, c) => s + ((c['credito_maximo'] ?? 0) as num));

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirForm(),
        backgroundColor: Tema.primary,
        child: Icon(Icons.person_add),
      ),
      body: Column(children: [
        SizedBox(
          height: 104,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            children: [
              Tema.kpiCard('Total Clientes', '$total', Icons.people, accent: Tema.primary),
              SizedBox(width: 8),
              Tema.kpiCard('Deuda Global', Fb.formatMoney(deudaGlobal), Icons.money_off, accent: Tema.danger),
              SizedBox(width: 8),
              Tema.kpiCard('Clientes con Deuda', '$conDeuda', Icons.warning_amber, accent: Colors.orange),
              SizedBox(width: 8),
              Tema.kpiCard('Credito Total', Fb.formatMoney(creditoTotal), Icons.credit_card, accent: Tema.darkBlue),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: SearchInput(
            controller: _q,
            hintText: 'Buscar por nombre, telefono o documento...',
            onChanged: (v) => setState(() => _f = v),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            children: ['Todos', 'Frecuente', 'Ocasional', 'Comercial'].map((t) {
              final active = t == 'Todos' ? _tipo.isEmpty : _tipo == t;
              return Padding(
                padding: EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: Text(t),
                  selected: active,
                  onSelected: (_) => setState(() => _tipo = t == 'Todos' ? '' : t),
                  selectedColor: Tema.primary.withValues(alpha: 0.15),
                  checkmarkColor: Tema.primary,
                  side: BorderSide(color: active ? Tema.primary : Tema.cardBorder),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: fl.isEmpty
                ? ListView(children: [
                    Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No se encontraron clientes',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Tema.textMuted),
                      ),
                    )
                  ])
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    itemCount: fl.length,
                    itemBuilder: (_, i) => _buildCard(fl[i]),
                  ),
        ),
      ]),
    );
  }

  Widget _buildCard(Map c) {
    final nombre = c['nombre'] ?? 'C';
    final tipo = c['tipo'] ?? 'Ocasional';
    final saldo = (c['saldo_pendiente'] ?? 0) as num;
    final credito = (c['credito_maximo'] ?? 0) as num;
    final saldoPositivo = saldo < 0 ? 0 : saldo;
    final uso = credito > 0 ? ((saldoPositivo / credito) * 100).clamp(0, 100).toDouble() : (saldoPositivo > 0 ? 100.0 : 0.0);
    final estado = _getEstado(c);
    final usoColor =
        uso > 80 ? Tema.danger : uso > 50 ? Colors.orange : Tema.primary;
    final estadoCol = _estadoColor(estado);
    final tipoCol = _tipoColor(tipo as String);
    final saldoColor = saldo > 0 ? Tema.danger : (saldo == 0 ? Colors.green : Tema.textSoft);

    return Dismissible(
      key: Key('cli_${c['id']}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Eliminar cliente'),
          content: Text('¿Eliminar este cliente? Se eliminaran todos sus datos asociados.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Eliminar', style: TextStyle(color: Tema.danger)),
            ),
          ],
        ),
      ),
      onDismissed: (_) => _eliminar(c),
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Tema.danger,
          borderRadius: BorderRadius.circular(Tema.radius),
        ),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: () => _abrirDetalle(c),
        child: Container(
          margin: EdgeInsets.only(bottom: 8),
          decoration: Tema.cardDeco,
          padding: EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(
                backgroundColor: Tema.primary,
                radius: 18,
                child: Text(
                  nombre.toString()[0].toUpperCase(),
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    nombre.toString(),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Tema.textDark),
                  ),
                  SizedBox(height: 2),
                  Flexible(child: Row(children: [
                    Flexible(flex: 1, child: _badge(tipo.toString(), tipoCol)),
                    SizedBox(width: 6),
                    Flexible(flex: 1, child: _badge(estado, estadoCol)),
                  ])),
                ]),
              ),
            ]),
            SizedBox(height: 10),
            Flexible(child: Row(children: [
              Flexible(child: _infoChip(Icons.badge_outlined, c['numero_documento'] ?? '-')),
              SizedBox(width: 12),
              Flexible(child: _infoChip(Icons.phone_outlined, c['telefono'] ?? '-')),
            ])),
            SizedBox(height: 10),
            Flexible(child: Row(children: [
              Flexible(child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Cred: ', style: TextStyle(fontSize: 12, color: Tema.textSoft)),
                Text(Fb.formatMoney(credito), style: TextStyle(fontSize: 12, color: Tema.textSoft)),
                Text('  |  ', style: TextStyle(fontSize: 12, color: Tema.textSoft)),
                Text('Saldo: ', style: TextStyle(fontSize: 12, color: Tema.textSoft)),
                Text(Fb.formatMoney(saldo), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: saldoColor)),
              ])),
              SizedBox(width: 4),
              Text(
                '${uso.toInt()}%',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: usoColor),
              ),
            ])),
            SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: uso / 100,
                backgroundColor: Tema.cardBorder,
                valueColor: AlwaysStoppedAnimation<Color>(usoColor),
                minHeight: 6,
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Color _estadoColor(String e) {
    switch (e) {
      case 'Al dia':
        return Colors.green;
      case 'Deudor':
        return Colors.orange;
      case 'Bloqueado':
        return Tema.danger;
      default:
        return Tema.textSoft;
    }
  }

  Color _tipoColor(String t) {
    switch (t) {
      case 'Frecuente':
        return Tema.darkBlue;
      case 'Comercial':
        return Colors.purple;
      default:
        return Tema.textSoft;
    }
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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

  Widget _infoChip(IconData icon, String text) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: Tema.textMuted),
      SizedBox(width: 4),
      Text(text, style: TextStyle(fontSize: 12, color: Tema.textSoft)),
    ]);
  }
}

class _ClienteDetalle extends StatefulWidget {
  final Map cliente;
  final VoidCallback onEdit;

  const _ClienteDetalle({required this.cliente, required this.onEdit});

  @override
  State<_ClienteDetalle> createState() => _ClienteDetalleState();
}

class _ClienteDetalleState extends State<_ClienteDetalle>
    with SingleTickerProviderStateMixin {
  List<Map<dynamic, dynamic>> _ventas = [];
  List<Map<dynamic, dynamic>> _fiados = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _abrirDeudaManual() async {
    final montoCtl = TextEditingController();
    final detalleCtl = TextEditingController(text: 'Saldo anterior cargado');
    
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Registrar Deuda / Fiado Manual', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: montoCtl,
              decoration: const InputDecoration(labelText: 'Monto del Fiado *'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            TextField(
              controller: detalleCtl,
              decoration: const InputDecoration(labelText: 'Concepto / Detalle *'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Tema.primary),
            child: Text('Guardar'),
          ),
        ],
      ),
    );
    
    if (!mounted) return;
    if (ok != true) return;
    final monto = int.tryParse(montoCtl.text) ?? 0;
    final detalle = detalleCtl.text.trim();
    if (monto <= 0 || detalle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Monto y detalle son obligatorios')),
      );
      return;
    }
    
    try {
      final fiados = await Fb.getList('fiados');
      final newId = fiados.isEmpty
          ? 1
          : fiados.map((x) => (x['id'] as num?)?.toInt() ?? 0).reduce((a, b) => a > b ? a : b) + 1;
          
      final newFiado = {
        'id': newId,
        'cliente_id': widget.cliente['id'],
        'cliente': widget.cliente['nombre'],
        'monto_original': monto,
        'monto_pendiente': monto,
        'saldo': monto,
        'monto': monto,
        'fecha': DateTime.now().toIso8601String().substring(0, 10),
        'estado': 'Pendiente',
        'detalle': detalle,
      };
      
      fiados.add(newFiado);
      await Fb.setList('fiados', fiados);
      
      // Recalculate client's saldo_pendiente
      final clientes = await Fb.getList('clientes');
      final cliIdx = clientes.indexWhere((c) => c['id'].toString() == widget.cliente['id'].toString());
      if (cliIdx >= 0) {
        final currentSaldo = (clientes[cliIdx]['saldo_pendiente'] ?? 0) as num;
        clientes[cliIdx]['saldo_pendiente'] = currentSaldo + monto;
        await Fb.setList('clientes', clientes);
        setState(() {
          widget.cliente['saldo_pendiente'] = currentSaldo + monto;
        });
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deuda manual registrada con éxito'), backgroundColor: Tema.primary),
      );
      
      _cargarDatos();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _cargarDatos() async {
    final nombre =
        (widget.cliente['nombre'] ?? '').toString().toLowerCase();
    final ventas = await Fb.getList('ventas');
    final fiados = await Fb.getList('fiados');
    setState(() {
      _ventas = ventas
          .where((v) =>
              (v['cliente'] ?? '').toString().toLowerCase() == nombre)
          .toList();
      _ventas.sort((a, b) {
        final da = DateTime.tryParse((a['fecha'] ?? '').toString()) ??
            DateTime(2000);
        final db = DateTime.tryParse((b['fecha'] ?? '').toString()) ??
            DateTime(2000);
        return db.compareTo(da);
      });
      _fiados = fiados
          .where((f) =>
              (f['cliente'] ?? '').toString().toLowerCase() == nombre)
          .toList();
      _fiados.sort((a, b) {
        final da = DateTime.tryParse((a['fecha'] ?? '').toString()) ??
            DateTime(2000);
        final db = DateTime.tryParse((b['fecha'] ?? '').toString()) ??
            DateTime(2000);
        return db.compareTo(da);
      });
      _cargando = false;
    });
  }

  String _fmtDate(dynamic val) {
    final d = DateTime.tryParse((val ?? '').toString());
    if (d == null) return '-';
    return '${d.day}/${d.month}/${d.year}';
  }

  String _getEstado(Map c) {
    final saldo = (c['saldo_pendiente'] ?? 0) as num;
    final credito = (c['credito_maximo'] ?? 0) as num;
    if (saldo == 0) return 'Al dia';
    if (saldo >= credito && credito > 0) return 'Bloqueado';
    return 'Deudor';
  }

  Widget _infoFila(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 130,
            child: Text('$label:',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Tema.textSoft))),
        Expanded(
            child: Text(value.isEmpty ? '-' : value,
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style:
                    TextStyle(fontSize: 13, color: Tema.textDark))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.cliente;
    final nombre = (c['nombre'] ?? '').toString();
    final telefono = (c['telefono'] ?? '').toString();
    final documento = (c['numero_documento'] ?? '').toString();
    final email = (c['email'] ?? '').toString();
    final direccion = (c['direccion'] ?? '').toString();
    final tipo = (c['tipo'] ?? '').toString();
    final credito = (c['credito_maximo'] ?? 0) as num;
    final observaciones = (c['observaciones'] ?? '').toString();
    final saldo = (c['saldo_pendiente'] ?? 0) as num;
    final estado = _getEstado(c);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(Tema.radiusLg)),
        ),
        child: DefaultTabController(
          length: 3,
          child: Column(children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(children: [
                Center(
                    child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: Tema.cardBorder,
                            borderRadius: BorderRadius.circular(2)))),
                SizedBox(height: 12),
                Row(children: [
                  CircleAvatar(
                      backgroundColor: Tema.primary,
                      radius: 18,
                      child: Text(nombre[0].toUpperCase(),                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13))),
                  SizedBox(width: 10),
                  Expanded(
                      child: Text(nombre,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Tema.textDark))),
                ]),
              ]),
            ),
            TabBar(
              labelColor: Tema.primary,
              unselectedLabelColor: Tema.textMuted,
              indicatorColor: Tema.primary,
              tabs: const [
                Tab(text: 'Info'),
                Tab(text: 'Historial'),
                Tab(text: 'Fiados'),
              ],
            ),
            Expanded(
              child: TabBarView(children: [
                ListView(
                  padding: EdgeInsets.all(16),
                  children: [
                    _infoFila('Nombre', nombre),
                    _infoFila('Telefono', telefono),
                    _infoFila('Documento', documento),
                    _infoFila('Email', email),
                    _infoFila('Direccion', direccion),
                    _infoFila('Tipo', tipo),
                    _infoFila('Credito Maximo', Fb.formatMoney(credito)),
                    _infoFila('Saldo Pendiente', Fb.formatMoney(saldo)),
                    _infoFila('Estado', estado),
                    _infoFila('Observaciones', observaciones),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onEdit();
                        },
                        icon: Icon(Icons.edit),
                        label: Text('Editar Cliente'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Tema.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(Tema.radiusSm)),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _abrirDeudaManual,
                        icon: Icon(Icons.add_circle_outline, color: Tema.danger),
                        label: Text('Registrar Deuda Manual', style: TextStyle(color: Tema.danger)),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Tema.danger),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(Tema.radiusSm)),
                        ),
                      ),
                    ),
                  ],
                ),
                _cargando
                    ? Center(
                        child: CircularProgressIndicator(
                            color: Tema.primary))
                    : _ventas.isEmpty
                        ? Center(
                            child: Text('Sin historial de ventas',
                                style: TextStyle(color: Tema.textMuted)))
                        : ListView.builder(
                            padding: EdgeInsets.all(12),
                            itemCount: _ventas.length,
                            itemBuilder: (_, i) {
                              final v = _ventas[i];
                              return Card(
                                margin: EdgeInsets.only(bottom: 6),
                                child: ListTile(
                                  dense: true,
                                  leading: Icon(Icons.receipt_long,
                                      color: Tema.primary),
                                  title: Text(
                                      'Venta ${_fmtDate(v['fecha'])}',
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  subtitle: Text(
                                      '${v['metodo'] ?? '-'} | ${v['estado'] ?? '-'}',
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: Tema.textSoft)),
                                  trailing: Text(
                                      Fb.formatMoney(v['total'] ?? 0),
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: Tema.primary)),
                                ),
                              );
                            },
                          ),
                _cargando
                    ? Center(
                        child: CircularProgressIndicator(
                            color: Tema.primary))
                    : _fiados.isEmpty
                        ? Center(
                            child: Text('Sin fiados registrados',
                                style: TextStyle(color: Tema.textMuted)))
                        : ListView.builder(
                            padding: EdgeInsets.all(12),
                            itemCount: _fiados.length,
                            itemBuilder: (_, i) {
                              final f = _fiados[i];
                              final monto = (f['monto'] ?? 0) as num;
                              final abonos = (f['abonos'] is List
                                      ? (f['abonos'] as List).fold<num>(
                                          0,
                                          (s, a) =>
                                              s +
                                              ((a is Map
                                                      ? (a['monto'] ?? 0)
                                                      : 0) as num))
                                      : 0);
                              final saldoFiado = monto - abonos;
                              final pagado = saldoFiado <= 0;
                              return Card(
                                margin: EdgeInsets.only(bottom: 6),
                                child: ListTile(
                                  dense: true,
                                  leading: Icon(
                                      pagado
                                          ? Icons.check_circle
                                          : Icons.pending,
                                      color: pagado
                                          ? Colors.green
                                          : Colors.orange),
                                  title: Text(
                                      'Fiado ${_fmtDate(f['fecha'])}',
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            'Monto: ${Fb.formatMoney(monto)}  |  Abonos: ${Fb.formatMoney(abonos)}',
                                            maxLines: 1, overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                color: Tema.textSoft,
                                                fontSize: 12)),
                                        Text(
                                            'Saldo: ${Fb.formatMoney(saldoFiado)}',
                                            maxLines: 1, overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                                color: pagado
                                                    ? Colors.green
                                                    : Tema.danger)),
                                      ]),
                                  trailing: Text(
                                      pagado ? 'Pagado' : 'Pendiente',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: pagado
                                              ? Colors.green
                                              : Colors.orange,
                                          fontSize: 12)),
                                ),
                              );
                            },
                          ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}