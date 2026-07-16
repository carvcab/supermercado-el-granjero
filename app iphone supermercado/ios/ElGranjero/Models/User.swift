import Foundation

struct AppUser: Codable, Identifiable {
    var id: Int?
    var username: String
    var password: String?
    var nombreCompleto: String?
    var email: String?
    var telefono: String?
    var foto: String?
    var rol: String?
    var permisoIds: [Int]?
    var activo: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id, username, password, email, telefono, foto, rol, activo
        case nombreCompleto = "nombre_completo"
        case permisoIds = "permiso_ids"
    }
}

struct AppRole: Codable, Identifiable {
    var id: Int?
    var nombre: String
    var permisoIds: [Int]?
    
    enum CodingKeys: String, CodingKey {
        case id, nombre
        case permisoIds = "permiso_ids"
    }
}

struct AppAction: Codable, Identifiable {
    var id: Int?
    var usuario: String?
    var accion: String?
    var detalle: String?
    var timestamp: String?
    var tipo: String?
}
