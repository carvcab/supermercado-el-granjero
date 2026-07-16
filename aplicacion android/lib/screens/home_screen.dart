import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import '../theme.dart';
import '../services/session_service.dart';
import 'modules/dashboard.dart';
import 'modules/caja.dart';
import 'modules/pos.dart';
import 'modules/inventario.dart';
import 'modules/clientes.dart';
import 'modules/ventas_bar.dart';
import 'modules/proveedores.dart';
import 'modules/fiados.dart';
import 'modules/historial.dart';
import 'modules/compras.dart';
import 'modules/compras_programadas.dart';
import 'modules/categorias.dart';
import 'modules/reportes.dart';
import 'modules/cierres.dart';
import 'modules/distribuciones.dart';
import 'modules/configuracion.dart';
import 'modules/usuarios.dart';
import 'modules/facturacion.dart';
import 'modules/consumos.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _itemPerms = [
    'dashboard', 'caja', 'ventas_super', 'ventas_bar', 'facturacion',
    'consumos', 'historial_ventas', 'fiados', 'productos', 'compras',
    'compras_programadas', 'categorias', 'distribuciones', 'clientes',
    'proveedores', 'usuarios', 'reportes', 'cierres', 'configuracion',
  ];

  static const _items = [
    ['Dashboard', Icons.dashboard_rounded, DashScreen()],
    ['Caja', Icons.account_balance_rounded, CajaScreen()],
    ['Ventas Super', Icons.shopping_cart_rounded, PosScreen()],
    ['Ventas Bar', Icons.local_bar_rounded, BarScreen()],
    ['Facturación', Icons.receipt_rounded, FacScreen()],
    ['Consumos', Icons.person_off, ConsScreen()],
    ['Historial', Icons.receipt_long_rounded, HistScreen()],
    ['Fiados', Icons.payments_rounded, FiaScreen()],
    ['Inventario', Icons.inventory_rounded, InvScreen()],
    ['Compras', Icons.shopping_bag_rounded, CompScreen()],
    ['Compras Prog.', Icons.calendar_month_rounded, CprScreen()],
    ['Categorías', Icons.category_rounded, CatScreen()],
    ['Distribuciones', Icons.account_balance_wallet_rounded, DisScreen()],
    ['Clientes', Icons.people_rounded, CliScreen()],
    ['Proveedores', Icons.business_rounded, ProvScreen()],
    ['Usuarios', Icons.admin_panel_settings_rounded, UsuScreen()],
    ['Reportes', Icons.bar_chart_rounded, RepScreen()],
    ['Cierres', Icons.lock_rounded, CieScreen()],
    ['Configuración', Icons.settings_rounded, ConScreen()],
  ];

  static const _groups = [
    {'title': 'Principal', 'items': [
      ['Dashboard', Icons.dashboard_rounded, DashScreen()],
      ['Caja', Icons.account_balance_rounded, CajaScreen()],
    ]},
    {'title': 'Ventas', 'items': [
      ['Ventas Super', Icons.shopping_cart_rounded, PosScreen()],
      ['Ventas Bar', Icons.local_bar_rounded, BarScreen()],
      ['Facturación', Icons.receipt_rounded, FacScreen()],
      ['Historial', Icons.receipt_long_rounded, HistScreen()],
      ['Fiados', Icons.payments_rounded, FiaScreen()],
    ]},
    {'title': 'Inventario y Compras', 'items': [
      ['Inventario', Icons.inventory_rounded, InvScreen()],
      ['Compras', Icons.shopping_bag_rounded, CompScreen()],
      ['Compras Prog.', Icons.calendar_month_rounded, CprScreen()],
      ['Categorías', Icons.category_rounded, CatScreen()],
      ['Distribuciones', Icons.account_balance_wallet_rounded, DisScreen()],
      ['Consumos', Icons.person_off, ConsScreen()],
    ]},
    {'title': 'Gestión', 'items': [
      ['Clientes', Icons.people_rounded, CliScreen()],
      ['Proveedores', Icons.business_rounded, ProvScreen()],
      ['Usuarios', Icons.admin_panel_settings_rounded, UsuScreen()],
    ]},
    {'title': 'Análisis', 'items': [
      ['Reportes', Icons.bar_chart_rounded, RepScreen()],
      ['Cierres', Icons.lock_rounded, CieScreen()],
      ['Configuración', Icons.settings_rounded, ConScreen()],
    ]},
  ];

  List<List> _filteredItems() {
    return List.generate(_items.length, (i) => i)
        .where((i) => Session.tienePermiso(_itemPerms[i]))
        .map((i) => _items[i])
        .toList();
  }

  Map<int, int> _filteredIndexMap() {
    final map = <int, int>{};
    int pos = 0;
    for (int i = 0; i < _items.length; i++) {
      if (Session.tienePermiso(_itemPerms[i])) {
        map[i] = pos;
        pos++;
      }
    }
    return map;
  }

  List<Map> _filteredGroups() {
    final result = <Map>[];
    for (final group in _groups) {
      final filtered = (group['items'] as List).where((item) {
        final itemIdx = _items.indexWhere((e) => e[0] == (item as List)[0]);
        return itemIdx >= 0 && Session.tienePermiso(_itemPerms[itemIdx]);
      }).toList();
      if (filtered.isNotEmpty) {
        result.add({'title': group['title'], 'items': filtered});
      }
    }
    return result;
  }

  Widget _buildUserAvatar({double size = 36, bool showBorder = false}) {
    final foto = Session.foto;
    final nombre = Session.nombreCompleto ?? Session.username ?? 'U';
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U';
    final hasPhoto = foto != null && foto.isNotEmpty;

    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: hasPhoto ? null : Tema.primary,
        border: showBorder ? Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2) : null,
        image: hasPhoto
            ? DecorationImage(
                image: foto.startsWith('data:')
                    ? MemoryImage(base64Decode(foto.split(',').last)) as ImageProvider
                    : NetworkImage(foto),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: hasPhoto
          ? null
          : Center(child: Text(inicial, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: size * 0.42))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _filteredItems();
    final title = filtrados.isNotEmpty ? filtrados[_index][0] as String : 'Sin permisos';

    return Scaffold(
      drawerScrimColor: Colors.black87,
      appBar: AppBar(
        title: Text(title),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 4),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _showProfileSheet,
                child: Padding(
                  padding: EdgeInsets.all(6),
                  child: _buildUserAvatar(size: 34, showBorder: true),
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
        ],
      ),
      body: filtrados.isEmpty
          ? Center(child: Text('No tienes permisos para acceder a ningun modulo.', style: TextStyle(color: Tema.textMuted)))
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
              key: ValueKey(_index),
              child: filtrados[_index][2] as Widget,
            ),
      drawer: Drawer(
        width: 280,
        child: Builder(builder: (ctx) {
          final groups = _filteredGroups();
          final indexMap = _filteredIndexMap();
          final nombre = Session.nombreCompleto ?? Session.username ?? 'Usuario';
          final rolTexto = Session.rol ?? '';
          final isAdmin = Session.isAdmin;

          return Column(children: [
            // ── Header ──
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(ctx).padding.top + 16, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Tema.primary, Tema.primaryHover],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildUserAvatar(size: 56, showBorder: true),
                SizedBox(height: 14),
                Text(nombre, style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 0.2), maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: 4),
                Row(children: [
                  if (rolTexto.isNotEmpty) ...[
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isAdmin ? Color(0xFFD4A017).withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        isAdmin ? 'ADMIN' : rolTexto,
                        style: TextStyle(
                          color: isAdmin ? Color(0xFFFFD700) : Colors.white70,
                          fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                  ],
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '${Session.permCount} permisos',
                      style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                ]),
              ]),
            ),

            // ── Menu ──
            Expanded(
              child: ListView(padding: EdgeInsets.zero, children: [
                for (final group in groups) ...[
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, 14, 20, 4),
                    child: Text(
                      (group['title'] as String).toUpperCase(),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Tema.textMuted, letterSpacing: 1.2),
                    ),
                  ),
                  for (final item in (group['items'] as List)) ...[
                    Builder(builder: (_) {
                      final it = item as List;
                      final origIdx = _items.indexWhere((e) => e[0] == it[0]);
                      final fi = origIdx >= 0 ? (indexMap[origIdx] ?? 0) : 0;
                      final active = _index == fi;
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        child: Material(
                          color: active ? Tema.primary.withValues(alpha: 0.07) : Colors.transparent,
                          borderRadius: BorderRadius.circular(Tema.radiusSm),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(Tema.radiusSm),
                            onTap: () {
                              setState(() => _index = fi);
                              Navigator.pop(context);
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                              child: Row(children: [
                                Icon(it[1] as IconData, size: 20, color: active ? Tema.primary : Tema.textMuted),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    it[0] as String,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                                      color: active ? Tema.primary : Tema.textDark,
                                    ),
                                  ),
                                ),
                                if (active)
                                  Container(width: 3, height: 16, decoration: BoxDecoration(color: Tema.primary, borderRadius: BorderRadius.circular(2))),
                              ]),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ]),
            ),

            // ── Footer ──
            Container(
              decoration: BoxDecoration(
                color: Tema.cardBg,
                border: Border(top: BorderSide(color: Tema.cardBorder)),
              ),
              padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(ctx).padding.bottom + 8),
              child: Row(children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(Tema.radiusSm),
                    onTap: () {
                      Navigator.pop(context);
                      _showProfileSheet();
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.person_outline, size: 18, color: Tema.textSoft),
                        SizedBox(width: 6),
                        Text('Perfil', style: TextStyle(fontSize: 13, color: Tema.textSoft)),
                      ]),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(Tema.radiusSm),
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: ctx,
                        builder: (dCtx) => AlertDialog(
                          title: Text('Cerrar Sesión', style: TextStyle(fontWeight: FontWeight.w700)),
                          content: Text('¿Estás seguro de que deseas cerrar sesión?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(dCtx, false), child: Text('Cancelar')),
                            TextButton(onPressed: () => Navigator.pop(dCtx, true), child: Text('Salir', style: TextStyle(color: Tema.danger))),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        Session.clear();
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                      }
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.logout_rounded, size: 18, color: Tema.danger),
                        SizedBox(width: 6),
                        Text('Salir', style: TextStyle(fontSize: 13, color: Tema.danger)),
                      ]),
                    ),
                  ),
                ),
              ]),
            ),
          ]);
        }),
      ),
    );
  }

  void _showProfileSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Tema.radiusLg))),
      builder: (ctx) {
        final nombre = Session.nombreCompleto ?? Session.username ?? '—';
        final username = Session.username ?? '—';
        final rolTxt = Session.rol ?? '—';
        final isAdmin = Session.isAdmin;
        final email = Session.email ?? '—';

        return Padding(
          padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(ctx).padding.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Tema.cardBorder, borderRadius: BorderRadius.circular(2)))),
            SizedBox(height: 20),
            _buildUserAvatar(size: 72),
            SizedBox(height: 14),
            Text(nombre, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Tema.textDark)),
            SizedBox(height: 4),
            Text('@$username', style: TextStyle(fontSize: 14, color: Tema.textSoft)),
            SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 6, alignment: WrapAlignment.center, children: [
              if (isAdmin)
                _profileChip('Admin', Icons.shield, Color(0xFFD4A017)),
              _profileChip(rolTxt, Icons.badge, Tema.primary),
              _profileChip('${Session.permCount} permisos', Icons.security, Tema.darkBlue),
            ]),
            SizedBox(height: 16),
            _profileRow(Icons.email_outlined, email),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      title: Text('Cerrar Sesión', style: TextStyle(fontWeight: FontWeight.w700)),
                      content: Text('¿Estás seguro de que deseas cerrar sesión?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(dCtx, false), child: Text('Cancelar')),
                        TextButton(onPressed: () => Navigator.pop(dCtx, true), child: Text('Salir', style: TextStyle(color: Tema.danger))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    Session.clear();
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                  }
                },
                icon: Icon(Icons.logout_rounded, size: 18),
                label: Text('Cerrar Sesión'),
                style: OutlinedButton.styleFrom(foregroundColor: Tema.danger, side: BorderSide(color: Tema.danger), padding: EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _profileChip(String label, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }

  Widget _profileRow(IconData icon, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, size: 18, color: Tema.textMuted),
        SizedBox(width: 10),
        Text(value, style: TextStyle(fontSize: 14, color: Tema.textDark)),
      ]),
    );
  }
}
