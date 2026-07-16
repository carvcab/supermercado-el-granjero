import 'dart:async';

import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../theme.dart';

class ProvScreen extends StatefulWidget {
  const ProvScreen({super.key});
  @override
  State<ProvScreen> createState() => _ProvScreenState();
}

class _ProvScreenState extends State<ProvScreen> {
  final _q = TextEditingController();
  List<Map<dynamic, dynamic>> _d = [];
  List<Map<dynamic, dynamic>> _compras = [];
  String _f = '';
  String _filtro = '';
  bool _mostrarCalendario = false;
  int _mesActual = DateTime.now().month;
  int _anoActual = DateTime.now().year;
  StreamSubscription? _sub;

  static const _diasSemana = ['Lunes', 'Martes', 'Miercoles', 'Jueves', 'Viernes', 'Sabado', 'Domingo'];
  static const _tipos = ['Fijo', 'Ocasional', 'Distribuidor'];

  @override
  void initState() {
    super.initState();
    Fb.getList('compras').then((c) => setState(() { _compras = c; _updateStats(); }));
    _sub = Fb.stream('proveedores').listen((d) {
      setState(() {
        _d = d;
        _updateStats();
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _q.dispose();
    super.dispose();
  }

  void _updateStats() {
    final hoy = DateTime.now();
    final inicioMes = DateTime(hoy.year, hoy.month, 1);
    for (var p in _d) {
      final provCompras = _compras.where((c) {
        final pid = c['proveedor_id'] ?? c['prov_id'];
        return pid != null && pid.toString() == (p['id'] ?? '').toString();
      }).toList();
      p['_total_compras'] = provCompras.fold<num>(0, (s, c) => s + ((c['total'] ?? 0) as num));
      final comprasMes = provCompras.where((c) {
        final fecha = _parseDate(c['fecha']);
        return fecha != null && fecha.isAfter(inicioMes.subtract(const Duration(days: 1)));
      }).toList();
      p['_compras_mes'] = comprasMes.fold<num>(0, (s, c) => s + ((c['total'] ?? 0) as num));
      p['_visitas_mes'] = comprasMes.length;
    }
  }

  DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    final s = val.toString();
    return DateTime.tryParse(s);
  }

  int _visitasDelMes() {
    final hoy = DateTime.now();
    final inicioMes = DateTime(hoy.year, hoy.month, 1);
    return _compras.where((c) {
      final fecha = _parseDate(c['fecha']);
      return fecha != null && fecha.isAfter(inicioMes.subtract(const Duration(days: 1)));
    }).length;
  }

  num _comprasDelMes() {
    final hoy = DateTime.now();
    final inicioMes = DateTime(hoy.year, hoy.month, 1);
    return _compras.where((c) {
      final fecha = _parseDate(c['fecha']);
      return fecha != null && fecha.isAfter(inicioMes.subtract(const Duration(days: 1)));
    }).fold<num>(0, (s, c) => s + ((c['total'] ?? 0) as num));
  }

  List<Map> _filtrar() {
    return _d.where((p) {
      if (_f.isNotEmpty) {
        final q = _f.toLowerCase();
        final n = (p['nombre'] ?? '').toString().toLowerCase();
        final c = (p['contacto'] ?? '').toString().toLowerCase();
        final t = (p['telefono'] ?? '').toString();
        if (!n.contains(q) && !c.contains(q) && !t.contains(q)) return false;
      }
      if (_filtro.isNotEmpty) {
        if (_filtro == 'Frecuente' && (p['tipo'] ?? '') != 'Frecuente') return false;
        if (_filtro == 'Activo' && (p['activo'] ?? true) != true) return false;
      }
      return true;
    }).toList();
  }

  String _getUltimaVisita(Map p) {
    final visitas = _compras.where((c) {
      final pid = c['proveedor_id'] ?? c['prov_id'];
      return pid != null && pid.toString() == (p['id'] ?? '').toString();
    }).toList();
    visitas.sort((a, b) {
      final da = _parseDate(a['fecha'] ?? '');
      final db = _parseDate(b['fecha'] ?? '');
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });
    if (visitas.isEmpty) return '-';
    final ult = visitas.first;
    final fecha = _parseDate(ult['fecha'] ?? '');
    if (fecha == null) return '-';
    final dias = DateTime.now().difference(fecha).inDays;
    final fechaStr = '${fecha.day}/${fecha.month}/${fecha.year}';
    return '$fechaStr - Hace $dias dias';
  }

  Future<void> _abrirForm([Map? p]) async {
    final nombreCtl = TextEditingController(text: p?['nombre'] ?? '');
    final contactoPaxf = TextEditingController(text: p?['contacto'] ?? '');
    final telPaxf = TextEditingController(text: p?['telefono'] ?? '');
    final emailPaxf = TextEditingController(text: p?['email'] ?? '');
    final nitPaxf = TextEditingController(text: p?['nit'] ?? '');
    final dirPaxf = TextEditingController(text: p?['direccion'] ?? '');
    final obsPaxf = TextEditingController(text: p?['observaciones'] ?? '');
    String tipo = p?['tipo'] ?? _tipos[0];
    List<String> dias = List<String>.from(p?['dias_visita'] ?? []);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Row(children: [
            Expanded(child: Text(
              p != null ? 'Editar Proveedor' : 'Nuevo Proveedor',
              style: const TextStyle(fontWeight: FontWeight.w700),
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
                Expanded(child: _fld('Contacto', contactoPaxf)),
              ]),
              Row(children: [
                Expanded(child: _fld('Telefono', telPaxf)),
                SizedBox(width: 8),
                Expanded(child: _fld('Email', emailPaxf)),
              ]),
              _fldDd('Tipo', tipo, _tipos, (v) => setSt(() => tipo = v!)),
              _fld('NIT', nitPaxf),
              _fld('Direccion', dirPaxf),
              _fld('Observaciones', obsPaxf),
              SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Dias de Visita', style: TextStyle(fontSize: 12, color: Tema.textSoft, fontWeight: FontWeight.w600)),
              ),
              SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _diasSemana.map((d) {
                  final sel = dias.contains(d);
                  return FilterChip(
                    label: Text(d.substring(0, 3)),
                    selected: sel,
                    onSelected: (v) {
                      setSt(() {
                        if (v) { dias.add(d); } else { dias.remove(d); }
                      });
                    },
                    selectedColor: Tema.primary.withValues(alpha: 0.15),
                    checkmarkColor: Tema.primary,
                    side: BorderSide(color: sel ? Tema.primary : Tema.cardBorder),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
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
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Tema.primary,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Tema.radiusSm),
                      ),
                    ),
                    child: const Text('Guardar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (ok != true || nombreCtl.text.trim().isEmpty) return;

    if (p != null) {
      p['nombre'] = nombreCtl.text.trim();
      p['contacto'] = contactoPaxf.text.trim();
      p['telefono'] = telPaxf.text.trim();
      p['email'] = emailPaxf.text.trim();
      p['tipo'] = tipo;
      p['nit'] = nitPaxf.text.trim();
      p['direccion'] = dirPaxf.text.trim();
      p['observaciones'] = obsPaxf.text.trim();
      p['dias_visita'] = dias;
    } else {
      final id = _d.isEmpty
          ? 1
          : (_d.map((x) => (x['id'] as num?)?.toInt() ?? 0).reduce((a, b) => a > b ? a : b) + 1).toString();
      _d.add({
        'id': id,
        'nombre': nombreCtl.text.trim(),
        'contacto': contactoPaxf.text.trim(),
        'telefono': telPaxf.text.trim(),
        'email': emailPaxf.text.trim(),
        'tipo': tipo,
        'nit': nitPaxf.text.trim(),
        'direccion': dirPaxf.text.trim(),
        'observaciones': obsPaxf.text.trim(),
        'dias_visita': dias,
        'activo': true,
        'fecha_registro': DateTime.now().toIso8601String(),
      });
    }
    await Fb.setList('proveedores', _d);
  }

  Future<void> _eliminar(Map p) async {
    _d.removeWhere((x) => (x['id'] ?? '').toString() == (p['id'] ?? '').toString());
    await Fb.setList('proveedores', _d);
  }

  void _abrirDetalle(Map p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Tema.radiusLg))),
      builder: (ctx) => _ProveedorDetalle(
        proveedor: p,
        compras: _compras,
        onEdit: () { Navigator.pop(ctx); _abrirForm(p); },
        onRegistrarVisita: () => _registrarVisita(p),
        onProgramarVisita: () => _programarVisita(p),
        onDelete: () async {
          final ok = await showDialog<bool>(
            context: ctx,
            builder: (dctx) => AlertDialog(
              title: const Text('Eliminar proveedor'),
              content: const Text('Se eliminaran todos sus datos asociados.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dctx, false), child: const Text('Cancelar')),
                TextButton(onPressed: () => Navigator.pop(dctx, true), child: const Text('Eliminar', style: TextStyle(color: Tema.danger))),
              ],
            ),
          );
          if (ok == true) {
            if (!ctx.mounted) return;
            Navigator.pop(ctx);
            _eliminar(p);
          }
        },
      ),
    );
  }

  Future<void> _registrarVisita(Map p) async {
    final fechaCtl = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
    final obsCtl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar Visita'),
        insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: fechaCtl,
            decoration: const InputDecoration(labelText: 'Fecha', border: OutlineInputBorder()),
            onTap: () async {
              final picked = await showDatePicker(
                context: ctx,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) fechaCtl.text = picked.toIso8601String().substring(0, 10);
            },
            readOnly: true,
          ),
          SizedBox(height: 8),
          TextField(
            controller: obsCtl,
            decoration: const InputDecoration(labelText: 'Observaciones', border: OutlineInputBorder()),
            maxLines: 2,
          ),
        ]))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Registrar')),
        ],
      ),
    );
    if (ok != true) return;
    final id = (_compras.isEmpty
        ? 1
        : (_compras.map((x) => (x['id'] as num?)?.toInt() ?? 0).reduce((a, b) => a > b ? a : b) + 1)).toString();
    _compras.add({
      'id': id,
      'proveedor_id': (p['id'] ?? '').toString(),
      'fecha': fechaCtl.text,
      'observaciones': obsCtl.text.trim(),
      'total': 0,
      'items': [],
      'estado': 'Pendiente',
      'tipo': 'visita',
    });
    await Fb.setList('compras', _compras);

    final visitas = List<Map>.from(p['visitas'] ?? []);
    visitas.add({
      'fecha': fechaCtl.text,
      'observaciones': obsCtl.text.trim(),
    });
    p['visitas'] = visitas;

    final diasVisita = List<String>.from(p['dias_visita'] ?? []);
    if (diasVisita.isNotEmpty) {
      final fechaVisita =
          DateTime.tryParse(fechaCtl.text) ?? DateTime.now();
      var busqueda = fechaVisita.add(const Duration(days: 1));
      for (var i = 0; i < 14; i++) {
        final nombreDia = _diasSemana[busqueda.weekday - 1];
        if (diasVisita.contains(nombreDia)) {
          p['proxima_visita'] =
              busqueda.toIso8601String().substring(0, 10);
          break;
        }
        busqueda = busqueda.add(const Duration(days: 1));
      }
    }
    await Fb.setList('proveedores', _d);
  }

  Future<void> _programarVisita(Map p) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    p['proxima_visita'] = picked.toIso8601String().substring(0, 10);
    if (p['visitas'] == null) p['visitas'] = [];
    await Fb.setList('proveedores', _d);
  }

  Widget _buildCalendario() {
    final hoy = DateTime.now();
    final primerDia = DateTime(_anoActual, _mesActual, 1);
    final ultimoDia = DateTime(_anoActual, _mesActual + 1, 0);
    final diasEnMes = ultimoDia.day;
    final offset = primerDia.weekday % 7;

    final Map<int, int> visitasPorDia = {};
    for (var p in _d) {
      final visitas = List<Map>.from(p['visitas'] ?? []);
      for (var v in visitas) {
        final f =
            DateTime.tryParse((v['fecha'] ?? '').toString());
        if (f != null &&
            f.year == _anoActual &&
            f.month == _mesActual) {
          visitasPorDia[f.day] = (visitasPorDia[f.day] ?? 0) + 1;
        }
      }
    }

    final Map<int, int> proximasPorDia = {};
    for (var p in _d) {
      final pv = (p['proxima_visita'] ?? '').toString();
      if (pv.isNotEmpty) {
        final f = DateTime.tryParse(pv);
        if (f != null &&
            f.year == _anoActual &&
            f.month == _mesActual) {
          proximasPorDia[f.day] = (proximasPorDia[f.day] ?? 0) + 1;
        }
      }
    }

    final meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    final headers = ['D', 'L', 'M', 'X', 'J', 'V', 'S'];

    return Column(children: [
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                  onPressed: () => setState(() {
                        if (_mesActual == 1) {
                          _mesActual = 12;
                          _anoActual--;
                        } else {
                          _mesActual--;
                        }
                      }),
                  icon: const Icon(Icons.chevron_left)),
              Text('${meses[_mesActual - 1]} $_anoActual',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Tema.textDark)),
              IconButton(
                  onPressed: () => setState(() {
                        if (_mesActual == 12) {
                          _mesActual = 1;
                          _anoActual++;
                        } else {
                          _mesActual++;
                        }
                      }),
                  icon: const Icon(Icons.chevron_right)),
            ]),
      ),
      Row(
          children: headers
              .map((h) => Expanded(
                  child: Center(
                      child: Text(h,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Tema.textSoft,
                              fontSize: 12)))))
              .toList()),
      SizedBox(height: 4),
      ...List.generate(6, (semana) {
        return Row(
            children: List.generate(7, (col) {
          final dia = semana * 7 + col - offset + 1;
          if (dia < 1 || dia > diasEnMes) {
            return const Expanded(child: SizedBox.shrink());
          }
          final esHoy = hoy.year == _anoActual &&
              hoy.month == _mesActual &&
              hoy.day == dia;
          final vHoy = visitasPorDia[dia] ?? 0;
          final pHoy = proximasPorDia[dia] ?? 0;
          final tieneMarcas = vHoy > 0 || pHoy > 0;
          return Expanded(
            child: GestureDetector(
              onTap:
                  tieneMarcas ? () => _abrirDiaVisitas(dia) : null,
              child: Container(
                height: 40,
                margin: EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: esHoy ? Tema.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$dia',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: esHoy
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: esHoy
                                  ? Colors.white
                                  : Tema.textDark)),
                      if (tieneMarcas)
                        Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              if (vHoy > 0)
                                Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                        color: Tema.danger,
                                        shape: BoxShape.circle)),
                              if (vHoy > 0 && pHoy > 0)
                                SizedBox(width: 2),
                              if (pHoy > 0)
                                Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                        color: Tema.primary,
                                        shape: BoxShape.circle)),
                            ]),
                    ]),
              ),
            ),
          );
        }));
      }),
    ]);
  }

  void _abrirDiaVisitas(int dia) {
    final fechaStr =
        '$_anoActual-${_mesActual.toString().padLeft(2, '0')}-${dia.toString().padLeft(2, '0')}';
    final proveedoresDelDia = _d.where((p) {
      final visitas = List<Map>.from(p['visitas'] ?? []);
      final tieneVisita = visitas
          .any((v) => (v['fecha'] ?? '').toString() == fechaStr);
      final tieneProxima =
          (p['proxima_visita'] ?? '').toString() == fechaStr;
      return tieneVisita || tieneProxima;
    }).toList();

    if (proveedoresDelDia.isEmpty) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(Tema.radiusLg))),
      builder: (ctx) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Tema.cardBorder,
                          borderRadius:
                              BorderRadius.circular(2)))),
              SizedBox(height: 12),
              Text(
                  'Visitas del $dia/${_mesActual.toString().padLeft(2, '0')}/$_anoActual',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Tema.textDark)),
              SizedBox(height: 12),
              ...proveedoresDelDia.map((p) {
                final visitas =
                    List<Map>.from(p['visitas'] ?? []);
                final visita = visitas
                    .where((v) =>
                        (v['fecha'] ?? '').toString() ==
                        fechaStr)
                    .firstOrNull;
                final esProxima =
                    (p['proxima_visita'] ?? '').toString() ==
                        fechaStr;
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                      backgroundColor: Tema.primary,
                      radius: 18,
                      child: Text(
                          (p['nombre'] ?? 'P')
                              .toString()[0]
                              .toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13))),
                  title: Text((p['nombre'] ?? '').toString(),
                      style: const TextStyle(
                          fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      esProxima
                          ? 'Proxima visita'
                          : (visita?['observaciones'] ?? '')
                                  .toString()
                                  .isEmpty
                              ? 'Sin observaciones'
                              : (visita?['observaciones'] ?? '')
                                  .toString(),
                      style: TextStyle(
                          color: Tema.textSoft)),
                  trailing: esProxima
                      ? Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: Tema.primary
                                  .withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(99)),
                          child: const Text('Pendiente',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Tema.primary)))
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    _abrirDetalle(p);
                  },
                );
              }),
            ]),
      ),
    );
  }

  Widget _fld(String l, TextEditingController ctl, {bool number = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: ctl,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: l, border: const OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
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
        decoration: InputDecoration(labelText: l, border: const OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fl = _filtrar();
    final total = _d.length;
    final visitasMes = _visitasDelMes();
    final comprasMes = Fb.formatMoney(_comprasDelMes());

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirForm(),
        backgroundColor: Tema.primary,
        child: const Icon(Icons.add),
      ),
      body: Column(children: [
        SizedBox(
          height: 104,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            children: [
              Tema.kpiCard('Total Proveedores', '$total', Icons.business, accent: Tema.primary),
              SizedBox(width: 8),
              Tema.kpiCard('Visitas este Mes', '$visitasMes', Icons.calendar_today, accent: Tema.darkBlue),
              SizedBox(width: 8),
              Tema.kpiCard('Compras del Mes', comprasMes, Icons.shopping_cart, accent: const Color(0xFFb8860b)),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: SearchInput(
            controller: _q,
            hintText: 'Buscar proveedor...',
            onChanged: (v) => setState(() => _f = v),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            children: [
              ...['Todos', 'Frecuente', 'Activo'].map((t) {
                final active = t == 'Todos' ? _filtro.isEmpty : _filtro == t;
                return Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(t),
                    selected: active,
                    onSelected: (_) => setState(() => _filtro = t == 'Todos' ? '' : t),
                    selectedColor: Tema.primary.withValues(alpha: 0.15),
                    checkmarkColor: Tema.primary,
                    side: BorderSide(color: active ? Tema.primary : Tema.cardBorder),
                  ),
                );
              }),
              Padding(
                padding: EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: const Text('Calendario'),
                  selected: _mostrarCalendario,
                  onSelected: (_) => setState(() => _mostrarCalendario = !_mostrarCalendario),
                  selectedColor: Tema.primary.withValues(alpha: 0.15),
                  checkmarkColor: Tema.primary,
                  side: BorderSide(color: _mostrarCalendario ? Tema.primary : Tema.cardBorder),
                  avatar: Icon(_mostrarCalendario ? Icons.calendar_month : Icons.calendar_today, size: 18, color: _mostrarCalendario ? Tema.primary : Tema.textMuted),
                ),
              ),
            ].toList(),
          ),
        ),
        Expanded(
          child: _mostrarCalendario
              ? _buildCalendario()
              : fl.isEmpty
                    ? ListView(children: [Padding(padding: EdgeInsets.all(32), child: Text('No se encontraron proveedores', textAlign: TextAlign.center, style: TextStyle(color: Tema.textMuted)))])
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        itemCount: fl.length,
                        itemBuilder: (_, i) => _buildCard(fl[i]),
                      ),
        ),
      ]),
    );
  }

  Widget _buildCard(Map p) {
    final nombre = (p['nombre'] ?? 'P').toString();
    final tipo = (p['tipo'] ?? 'Fijo').toString();
    final contacto = (p['contacto'] ?? '').toString();
    final telefono = (p['telefono'] ?? '').toString();
    final ultVisita = _getUltimaVisita(p);
    final tipoCol = _tipoColor(tipo);

    return Dismissible(
      key: Key('prov_${p['id']}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Eliminar proveedor'),
          content: Text('Eliminar $nombre? Se eliminaran todos sus datos asociados.', maxLines: 2, overflow: TextOverflow.ellipsis),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: Tema.danger))),
          ],
        ),
      ),
      onDismissed: (_) => _eliminar(p),
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: Tema.danger, borderRadius: BorderRadius.circular(Tema.radius)),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: () => _abrirDetalle(p),
        child: Container(
          margin: EdgeInsets.only(bottom: 8),
          decoration: Tema.cardDeco,
          padding: EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(
                backgroundColor: Tema.primary,
                radius: 18,
                child: Text(nombre[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(nombre, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Tema.textDark)),
                  SizedBox(height: 2),
                  Flexible(child: _badge(tipo, tipoCol)),
                ]),
              ),
              Icon(Icons.chevron_right, color: Tema.textMuted),
            ]),
            if (contacto.isNotEmpty || telefono.isNotEmpty) ...[
              SizedBox(height: 10),
              Flexible(child: Row(children: [
                if (contacto.isNotEmpty) Flexible(child: _infoChip(Icons.person_outline, contacto)),
                if (contacto.isNotEmpty && telefono.isNotEmpty) SizedBox(width: 12),
                if (telefono.isNotEmpty) Flexible(child: _infoChip(Icons.phone_outlined, telefono)),
              ])),
            ],
            SizedBox(height: 8),
            Flexible(child: Row(children: [
              Icon(Icons.history, size: 14, color: Tema.textMuted),
              SizedBox(width: 4),
              Flexible(child: Text(ultVisita, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Tema.textSoft))),
              SizedBox(width: 8),
              Text('Compras: ${Fb.formatMoney(p['_total_compras'] ?? 0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Tema.primary)),
            ])),
          ]),
        ),
      ),
    );
  }

  Color _tipoColor(String t) {
    switch (t) {
      case 'Fijo':
        return Tema.darkBlue;
      case 'Distribuidor':
        return Colors.purple;
      default:
        return Tema.textSoft;
    }
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
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

class _ProveedorDetalle extends StatelessWidget {
  final Map proveedor;
  final List<Map<dynamic, dynamic>> compras;
  final VoidCallback onEdit;
  final VoidCallback onRegistrarVisita;
  final VoidCallback onProgramarVisita;
  final VoidCallback onDelete;

  const _ProveedorDetalle({
    required this.proveedor,
    required this.compras,
    required this.onEdit,
    required this.onRegistrarVisita,
    required this.onProgramarVisita,
    required this.onDelete,
  });

  DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    return DateTime.tryParse(val.toString());
  }

  String _fmtDate(dynamic val) {
    final d = _parseDate(val);
    if (d == null) return '-';
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final nombre = (proveedor['nombre'] ?? '').toString();
    final tipo = (proveedor['tipo'] ?? 'Fijo').toString();
    final contacto = (proveedor['contacto'] ?? '').toString();
    final telefono = (proveedor['telefono'] ?? '').toString();
    final email = (proveedor['email'] ?? '').toString();
    final nit = (proveedor['nit'] ?? '').toString();
    final direccion = (proveedor['direccion'] ?? '').toString();
    final observaciones = (proveedor['observaciones'] ?? '').toString();
    final diasVisita = List<String>.from(proveedor['dias_visita'] ?? []);
    final proximaVisita = (proveedor['proxima_visita'] ?? '').toString();

    final provCompras = compras.where((c) {
      final pid = c['proveedor_id'] ?? c['prov_id'];
      return pid != null && pid.toString() == (proveedor['id'] ?? '').toString();
    }).toList();
    provCompras.sort((a, b) {
      final da = _parseDate(b['fecha'] ?? '');
      final db = _parseDate(a['fecha'] ?? '');
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });
    final visitas = provCompras.where((c) => (c['tipo'] ?? '') == 'visita').toList();
    final comprasReales = provCompras.where((c) => (c['tipo'] ?? '') != 'visita').toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
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
              Row(children: [
               CircleAvatar(backgroundColor: Tema.primary, radius: 22, child: Text(nombre[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
               SizedBox(width: 12),
               Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                 Text(nombre, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Tema.textDark)),
                 Flexible(child: _badge(tipo, _tipoColor(tipo))),
               ])),
              IconButton(onPressed: onEdit, icon: const Icon(Icons.edit, color: Tema.primary)),
              IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline, color: Tema.danger)),
            ]),
            const Divider(height: 24),
            _detalleRow(Icons.person, 'Contacto', contacto),
            _detalleRow(Icons.phone, 'Telefono', telefono),
            _detalleRow(Icons.email_outlined, 'Email', email),
            _detalleRow(Icons.badge_outlined, 'NIT', nit),
            _detalleRow(Icons.location_on_outlined, 'Direccion', direccion),
            _detalleRow(Icons.chat_outlined, 'Observaciones', observaciones),
            if (diasVisita.isNotEmpty)
              _detalleRow(Icons.calendar_month, 'Dias de Visita', diasVisita.join(', ')),
            if (proximaVisita.isNotEmpty)
              _detalleRow(Icons.event, 'Proxima Visita', proximaVisita),
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRegistrarVisita,
                icon: const Icon(Icons.add),
                label: const Text('Registrar Visita'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Tema.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tema.radiusSm)),
                ),
              ),
            ),
            SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onProgramarVisita,
                icon: const Icon(Icons.date_range),
                label: const Text('Programar Visita'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Tema.darkBlue,
                  side: const BorderSide(color: Tema.darkBlue),
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tema.radiusSm)),
                ),
              ),
            ),
            SizedBox(height: 16),
            _seccionTitulo('Visitas Registradas'),
            if (visitas.isEmpty)
              Padding(padding: EdgeInsets.all(16), child: Text('Sin visitas registradas', style: TextStyle(color: Tema.textMuted)))
            else
              ...visitas.take(10).map((v) => Card(
                margin: EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.calendar_today, color: Tema.primary),
                  title: Text(_fmtDate(v['fecha']), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text((v['observaciones'] ?? '').toString().isEmpty ? 'Sin observaciones' : (v['observaciones'] ?? '').toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Tema.textSoft)),
                ),
              )),
            SizedBox(height: 8),
            _seccionTitulo('Ultimas Compras'),
            if (comprasReales.isEmpty)
              Padding(padding: EdgeInsets.all(16), child: Text('Sin compras registradas', style: TextStyle(color: Tema.textMuted)))
            else
              ...comprasReales.take(10).map((c) => Card(
                margin: EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.shopping_cart, color: Tema.darkBlue),
                  title: Text('Factura #${(c['numero_factura'] ?? c['id'] ?? '').toString()}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(_fmtDate(c['fecha']), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Tema.textSoft)),
                  trailing: Text(Fb.formatMoney(c['total'] ?? 0), style: const TextStyle(fontWeight: FontWeight.w700, color: Tema.primary, fontSize: 14)),
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _detalleRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, size: 18, color: Tema.textMuted),
        SizedBox(width: 10),
        Flexible(child: Text('$label: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Tema.textSoft))),
        Expanded(child: Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: Tema.textDark))),
      ]),
    );
  }

  Widget _seccionTitulo(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Tema.textDark)),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      margin: EdgeInsets.only(top: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Color _tipoColor(String t) {
    switch (t) {
      case 'Fijo':
        return Tema.darkBlue;
      case 'Distribuidor':
        return Colors.purple;
      default:
        return Tema.textSoft;
    }
  }
}

