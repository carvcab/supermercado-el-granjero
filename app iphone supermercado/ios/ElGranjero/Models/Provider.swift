import Foundation

struct Provider: Codable, Identifiable {
    var id: Int?
    var nombre: String
    var contacto: String?
    var telefono: String?
    var email: String?
    var direccion: String?
    var tipo: String?
    var activo: Bool?
    var notas: String?
    var diasVisita: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id, nombre, contacto, telefono, email, direccion, tipo, activo, notas
        case diasVisita = "dias_visita"
    }
}
