import Foundation

class SessionManager {
    static let shared = SessionManager()
    
    private init() {}
    
    var currentUser: [String: Any]?
    var permisos: [String] = []
    var permCount: Int = 0
    
    // Permission constants - matching the 50 permission IDs (19 pantallas + 31 acciones)
    static let pantallas: [String] = [
        "dashboard", "caja", "ventas_super", "ventas_bar", "facturacion",
        "historial_ventas", "fiados", "productos", "compras", "compras_programadas",
        "categorias", "distribuciones", "clientes", "proveedores", "usuarios",
        "consumos", "reportes", "cierres", "configuracion"
    ]
    
    static let acciones: [String] = [
        "crear_venta", "editar_venta", "eliminar_venta", "crear_producto",
        "editar_producto", "eliminar_producto", "crear_cliente", "editar_cliente",
        "eliminar_cliente", "crear_compra", "editar_compra", "eliminar_compra",
        "crear_proveedor", "editar_proveedor", "eliminar_proveedor",
        "abrir_caja", "cerrar_caja", "hacer_abono", "crear_fiado",
        "editar_fiado", "eliminar_fiado", "crear_usuario", "editar_usuario",
        "eliminar_usuario", "crear_rol", "editar_rol", "eliminar_rol",
        "crear_distribucion", "ver_reportes", "exportar_datos",
        "configurar_sistema"
    ]
    
    static let allPermisosMap: [Int: String] = [
        // Matching Flutter session_service.dart IDs (1-50)
        1: "dashboard", 2: "caja", 3: "productos", 4: "clientes", 5: "proveedores",
        6: "ventas_super", 7: "ventas_bar", 8: "fiados", 9: "historial_ventas", 10: "compras",
        11: "compras_programadas", 12: "categorias", 13: "reportes", 14: "cierres", 15: "distribuciones",
        16: "configuracion", 17: "usuarios",
        18: "crear_venta", 19: "crear_fiado", 20: "fiar", 21: "descuentos", 22: "ajustar_stock",
        23: "registrar_productos", 24: "eliminar_productos", 25: "abrir_caja", 26: "cerrar_caja",
        27: "editar_ventas", 28: "eliminar_ventas", 29: "editar_compras", 30: "eliminar_compras",
        31: "editar_fiados", 32: "eliminar_fiados", 33: "editar_clientes", 34: "eliminar_clientes",
        35: "editar_proveedores", 36: "eliminar_proveedores", 37: "editar_categorias", 38: "eliminar_categorias",
        39: "editar_usuarios", 40: "eliminar_usuarios", 41: "editar_cierres", 42: "eliminar_cierres",
        43: "abono_fiado", 44: "pagar_compra", 45: "cambiar_precio_venta", 46: "admin",
        47: "editar_distribuciones", 48: "eliminar_distribuciones", 49: "facturacion", 50: "consumos",
    ]
    
    static let allPermisos: [String] = allPermisosMap.values.map { $0 }
    
    var username: String? {
        return currentUser?["username"] as? String
    }
    
    var nombreCompleto: String? {
        return currentUser?["nombre_completo"] as? String
    }
    
    var foto: String? {
        return currentUser?["foto"] as? String
    }
    
    func tienePermiso(_ permiso: String) -> Bool {
        if let userLower = username?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) {
            if userLower == "admin" || userLower == "nelson" {
                return true
            }
        }
        let roleLower = (currentUser?["rol"] as? String ?? "").lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if roleLower == "jefe" || roleLower == "admin" || roleLower == "administrador" {
            return true
        }
        return permisos.contains(permiso)
    }
    
    func puede(_ accion: String) -> Bool {
        return tienePermiso(accion)
    }
    
    func setUser(_ user: [String: Any], roles: [[String: Any]] = []) {
        currentUser = user
        let rolName = (user["rol"] as? String ?? "").lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let isUserAdmin = (user["username"] as? String ?? "").lowercased() == "admin" || (user["username"] as? String ?? "").lowercased() == "nelson" || rolName == "jefe" || rolName == "admin" || rolName == "administrador"
        
        if isUserAdmin {
            permisos = Self.allPermisosMap.values.map { $0 }
            permCount = Self.allPermisosMap.count
            return
        }
        
        var permisoIds = user["permiso_ids"] as? [Int] ?? []
        if permisoIds.isEmpty {
            if let role = roles.first(where: { ($0["nombre"] as? String ?? "").lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == rolName }) {
                permisoIds = role["permiso_ids"] as? [Int] ?? []
            }
        }
        var resolved: [String] = []
        for id in permisoIds {
            if let perm = Self.allPermisosMap[id] {
                resolved.append(perm)
            } else if id >= 0 && id < Self.allPermisos.count {
                resolved.append(Self.allPermisos[id])
            }
        }
        permisos = resolved
        permCount = resolved.count
    }
    
    func clear() {
        currentUser = nil
        permisos = []
        permCount = 0
    }
    
    var isLoggedIn: Bool {
        return currentUser != nil
    }
}
