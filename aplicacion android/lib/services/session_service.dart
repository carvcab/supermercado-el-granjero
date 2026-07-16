import 'package:flutter/foundation.dart';

class Session {
  static Map? _user;
  static Map<String, bool> _permMap = {};

  static const allPermisos = [
    {'id': 1, 'modulo': 'Pantallas', 'permiso': 'dashboard', 'nombre': 'Dashboard'},
    {'id': 2, 'modulo': 'Pantallas', 'permiso': 'caja', 'nombre': 'Caja'},
    {'id': 3, 'modulo': 'Pantallas', 'permiso': 'productos', 'nombre': 'Productos'},
    {'id': 4, 'modulo': 'Pantallas', 'permiso': 'clientes', 'nombre': 'Clientes'},
    {'id': 5, 'modulo': 'Pantallas', 'permiso': 'proveedores', 'nombre': 'Proveedores'},
    {'id': 6, 'modulo': 'Pantallas', 'permiso': 'ventas_super', 'nombre': 'Ventas Super'},
    {'id': 7, 'modulo': 'Pantallas', 'permiso': 'ventas_bar', 'nombre': 'Ventas Bar'},
    {'id': 8, 'modulo': 'Pantallas', 'permiso': 'fiados', 'nombre': 'Fiados'},
    {'id': 9, 'modulo': 'Pantallas', 'permiso': 'historial_ventas', 'nombre': 'Historial Ventas'},
    {'id': 10, 'modulo': 'Pantallas', 'permiso': 'compras', 'nombre': 'Compras'},
    {'id': 11, 'modulo': 'Pantallas', 'permiso': 'compras_programadas', 'nombre': 'Compras Programadas'},
    {'id': 12, 'modulo': 'Pantallas', 'permiso': 'categorias', 'nombre': 'Categorias'},
    {'id': 13, 'modulo': 'Pantallas', 'permiso': 'reportes', 'nombre': 'Reportes'},
    {'id': 14, 'modulo': 'Pantallas', 'permiso': 'cierres', 'nombre': 'Cierres'},
    {'id': 15, 'modulo': 'Pantallas', 'permiso': 'distribuciones', 'nombre': 'Distribuciones'},
    {'id': 16, 'modulo': 'Pantallas', 'permiso': 'configuracion', 'nombre': 'Configuracion'},
    {'id': 17, 'modulo': 'Pantallas', 'permiso': 'usuarios', 'nombre': 'Usuarios'},
    {'id': 18, 'modulo': 'Acciones', 'permiso': 'crear_venta', 'nombre': 'Crear Venta'},
    {'id': 19, 'modulo': 'Acciones', 'permiso': 'crear_fiado', 'nombre': 'Crear Fiado'},
    {'id': 20, 'modulo': 'Acciones', 'permiso': 'fiar', 'nombre': 'Fiar'},
    {'id': 21, 'modulo': 'Acciones', 'permiso': 'descuentos', 'nombre': 'Descuentos'},
    {'id': 22, 'modulo': 'Acciones', 'permiso': 'ajustar_stock', 'nombre': 'Ajustar Stock'},
    {'id': 23, 'modulo': 'Acciones', 'permiso': 'registrar_productos', 'nombre': 'Registrar Productos'},
    {'id': 24, 'modulo': 'Acciones', 'permiso': 'eliminar_productos', 'nombre': 'Eliminar Productos'},
    {'id': 25, 'modulo': 'Acciones', 'permiso': 'abrir_caja', 'nombre': 'Abrir Caja'},
    {'id': 26, 'modulo': 'Acciones', 'permiso': 'cerrar_caja', 'nombre': 'Cerrar Caja'},
    {'id': 27, 'modulo': 'Acciones', 'permiso': 'editar_ventas', 'nombre': 'Editar Ventas'},
    {'id': 28, 'modulo': 'Acciones', 'permiso': 'eliminar_ventas', 'nombre': 'Eliminar Ventas'},
    {'id': 29, 'modulo': 'Acciones', 'permiso': 'editar_compras', 'nombre': 'Editar Compras'},
    {'id': 30, 'modulo': 'Acciones', 'permiso': 'eliminar_compras', 'nombre': 'Eliminar Compras'},
    {'id': 31, 'modulo': 'Acciones', 'permiso': 'editar_fiados', 'nombre': 'Editar Fiados'},
    {'id': 32, 'modulo': 'Acciones', 'permiso': 'eliminar_fiados', 'nombre': 'Eliminar Fiados'},
    {'id': 33, 'modulo': 'Acciones', 'permiso': 'editar_clientes', 'nombre': 'Editar Clientes'},
    {'id': 34, 'modulo': 'Acciones', 'permiso': 'eliminar_clientes', 'nombre': 'Eliminar Clientes'},
    {'id': 35, 'modulo': 'Acciones', 'permiso': 'editar_proveedores', 'nombre': 'Editar Proveedores'},
    {'id': 36, 'modulo': 'Acciones', 'permiso': 'eliminar_proveedores', 'nombre': 'Eliminar Proveedores'},
    {'id': 37, 'modulo': 'Acciones', 'permiso': 'editar_categorias', 'nombre': 'Editar Categorias'},
    {'id': 38, 'modulo': 'Acciones', 'permiso': 'eliminar_categorias', 'nombre': 'Eliminar Categorias'},
    {'id': 39, 'modulo': 'Acciones', 'permiso': 'editar_usuarios', 'nombre': 'Editar Usuarios'},
    {'id': 40, 'modulo': 'Acciones', 'permiso': 'eliminar_usuarios', 'nombre': 'Eliminar Usuarios'},
    {'id': 41, 'modulo': 'Acciones', 'permiso': 'editar_cierres', 'nombre': 'Editar Cierres'},
    {'id': 42, 'modulo': 'Acciones', 'permiso': 'eliminar_cierres', 'nombre': 'Eliminar Cierres'},
    {'id': 43, 'modulo': 'Acciones', 'permiso': 'abono_fiado', 'nombre': 'Abonar Fiado'},
    {'id': 44, 'modulo': 'Acciones', 'permiso': 'pagar_compra', 'nombre': 'Pagar Compra'},
    {'id': 45, 'modulo': 'Acciones', 'permiso': 'cambiar_precio_venta', 'nombre': 'Cambiar Precio Venta'},
    {'id': 46, 'modulo': 'Acciones', 'permiso': 'admin', 'nombre': 'Administracion del sistema'},
    {'id': 47, 'modulo': 'Acciones', 'permiso': 'editar_distribuciones', 'nombre': 'Editar Distribuciones'},
    {'id': 48, 'modulo': 'Acciones', 'permiso': 'eliminar_distribuciones', 'nombre': 'Eliminar Distribuciones'},
    {'id': 49, 'modulo': 'Pantallas', 'permiso': 'facturacion', 'nombre': 'Facturacion'},
    {'id': 50, 'modulo': 'Pantallas', 'permiso': 'consumos', 'nombre': 'Consumos Propios'},
  ];

  static Map? get user => _user;
  static String? get username => _user?['username']?.toString();
  static String? get nombreCompleto => _user?['nombre_completo']?.toString() ?? _user?['nombre']?.toString();
  static String? get foto => _user?['foto']?.toString();
  static String? get email => _user?['email']?.toString();
  static String? get rol => _user?['rol']?.toString();
  static bool get isLogged => _user != null;
  static bool get isAdmin {
    if (_user == null) return false;
    final r = (rol ?? '').toString().toLowerCase().trim();
    return r == 'jefe' || r == 'admin' || r == 'administrador';
  }
  static int get permCount => _permMap.length;
  static List<String> get permKeys => _permMap.keys.toList();

  static void loadPermisos() {
    // Permissions are hardcoded — no Firestore dependency needed.
    // The PC defines them in api-bridge.js; we mirror them here.
  }

  static void setUser(Map user, [List<Map<dynamic, dynamic>> roles = const []]) {
    _user = user;
    _permMap = {};
    final rawIds = _user?['permiso_ids'];
    final rawPerms = _user?['permisos'];
    debugPrint('[Session] setUser: username=${user['username']}, rol=${user['rol']}, permiso_ids=$rawIds, permisos=$rawPerms');

    // Collect all permission IDs from the user
    Set<String> idSet = {};
    if (rawIds is List && rawIds.isNotEmpty) {
      idSet = rawIds.map((e) => '$e').toSet();
    } else if (rawPerms is List && rawPerms.isNotEmpty) {
      // Fallback: permisos might contain resolved keys
      for (final k in rawPerms) {
        final key = '$k';
        if (key.isNotEmpty) _permMap[key] = true;
      }
    }

    // If user has no permission IDs but has a role, resolve from role
    if (idSet.isEmpty && _permMap.isEmpty) {
      final userRol = (user['rol'] ?? '').toString();
      if (userRol.isNotEmpty) {
        for (final r in roles) {
          if ((r['nombre'] ?? '').toString().toLowerCase() == userRol.toLowerCase()) {
            final roleIds = r['permiso_ids'];
            if (roleIds is List && roleIds.isNotEmpty) {
              idSet = roleIds.map((e) => '$e').toSet();
              debugPrint('[Session] resolved ${idSet.length} perm IDs from role "$userRol"');
            }
            break;
          }
        }
      }
    }

    // Resolve permission keys from collected IDs
    if (idSet.isNotEmpty) {
      for (final p in allPermisos) {
        final pid = '${p['id']}';
        if (idSet.contains(pid)) {
          final key = p['permiso']?.toString();
          if (key != null) _permMap[key] = true;
        }
      }
    } else if (_permMap.isEmpty) {
      // No permissions at all — legacy user without role, give full access only if Jefe/Admin
      if (isAdmin) {
        for (final p in allPermisos) {
          final key = p['permiso']?.toString();
          if (key != null) _permMap[key] = true;
        }
      }
    }
    debugPrint('[Session] _permMap keys (${_permMap.length}): ${_permMap.keys.toList()}');
  }

  static void clear() {
    _user = null;
    _permMap = {};
  }

  static bool tienePermiso(String pageName) {
    if (!isLogged) return false;
    if (isAdmin) return true;
    final map = {
      'dashboard': 'dashboard',
      'caja': 'caja',
      'productos': 'productos',
      'clientes': 'clientes',
      'proveedores': 'proveedores',
      'ventas_super': 'ventas_super',
      'ventas_bar': 'ventas_bar',
      'fiados': 'fiados',
      'historial_ventas': 'historial_ventas',
      'facturacion': 'facturacion',
      'consumos': 'consumos',
      'compras': 'compras',
      'compras_programadas': 'compras_programadas',
      'categorias': 'categorias',
      'inventario': 'productos',
      'reportes': 'reportes',
      'cierres': 'cierres',
      'distribuciones': 'distribuciones',
      'configuracion': 'configuracion',
      'usuarios': 'usuarios',
    };
    final perm = map[pageName];
    if (perm == null) return false;
    return _permMap.containsKey(perm);
  }

  static bool puede(String accion) {
    if (!isLogged) return false;
    if (isAdmin) return true;
    return _permMap.containsKey(accion);
  }
}