import Foundation

struct SaleItem: Codable {
    var id: Int?
    var nombre: String?
    var cantidad: Double
    var precioUnitario: Int
    var precioCompra: Int?
    var subtotal: Int
    var productoId: Int?
    
    enum CodingKeys: String, CodingKey {
        case id, nombre, cantidad, subtotal
        case precioUnitario = "precio_unitario"
        case precioCompra = "precio_compra"
        case productoId = "producto_id"
    }
}

struct Sale: Codable, Identifiable {
    var id: Int
    var fecha: String
    var createdAt: String?
    var cliente: String?
    var clienteId: Int?
    var items: [SaleItem]
    var total: Double
    var descuento: Double
    var metodoPago: String
    var metodoPago2: String?
    var monto1: Double?
    var monto2: Double?
    var usuario: String?
    var cajaId: Int?
    var estado: String?
    var tipo: String?
    var mesa: String?
    
    enum CodingKeys: String, CodingKey {
        case id, fecha, cliente, items, total, descuento, usuario, estado, tipo, mesa
        case createdAt = "created_at"
        case clienteId = "cliente_id"
        case metodoPago = "metodo_pago"
        case metodoPago2 = "metodo_pago_2"
        case monto1 = "monto_1"
        case monto2 = "monto_2"
        case cajaId = "caja_id"
    }
}
