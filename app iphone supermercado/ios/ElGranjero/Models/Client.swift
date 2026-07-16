import Foundation

struct Client: Codable, Identifiable {
    var id: Int?
    var nombre: String
    var telefono: String?
    var numeroDocumento: String?
    var email: String?
    var direccion: String?
    var tipo: String?
    var creditoMaximo: Double
    var saldoPendiente: Double
    var observaciones: String?
    var activo: Bool?
    var fechaRegistro: String?
    
    enum CodingKeys: String, CodingKey {
        case id, nombre, telefono, email, direccion, tipo, observaciones, activo
        case numeroDocumento = "numero_documento"
        case creditoMaximo = "credito_maximo"
        case saldoPendiente = "saldo_pendiente"
        case fechaRegistro = "fecha_registro"
    }
}
