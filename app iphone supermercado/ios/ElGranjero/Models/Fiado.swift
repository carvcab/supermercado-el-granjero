import Foundation

struct FiadoAbono: Codable {
    var fecha: String?
    var monto: Double
    var metodoPago: String?
    
    enum CodingKeys: String, CodingKey {
        case fecha, monto
        case metodoPago = "metodo_pago"
    }
}

struct Fiado: Codable, Identifiable {
    var id: Int
    var clienteId: Int?
    var clienteNombre: String?
    var clienteTelefono: String?
    var productoNombre: String?
    var monto: Double
    var fecha: String
    var estado: String?
    var abonos: [FiadoAbono]?
    var observaciones: String?
    var usuario: String?
    var origen: String?
    
    enum CodingKeys: String, CodingKey {
        case id, monto, fecha, estado, abonos, observaciones, usuario, origen
        case clienteId = "cliente_id"
        case clienteNombre = "cliente_nombre"
        case clienteTelefono = "cliente_telefono"
        case productoNombre = "producto_nombre"
    }
}
