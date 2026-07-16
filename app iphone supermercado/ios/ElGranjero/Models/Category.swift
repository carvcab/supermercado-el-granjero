import Foundation

struct Category: Codable, Identifiable {
    var id: Int?
    var nombre: String
    var color: String?
    var icono: String?
    var orden: Int?
    var descripcion: String?
}
