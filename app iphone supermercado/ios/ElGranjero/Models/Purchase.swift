import Foundation

struct PurchaseItem: Codable {
    var id: Int?
    var nombre: String?
    var cantidad: Double
    var precioUnitario: Int
    var subtotal: Int
    
    enum CodingKeys: String, CodingKey {
        case id, nombre, cantidad, subtotal
        case precioUnitario = "precio_unitario"
    }
}

struct Purchase: Codable, Identifiable {
    var id: Int
    var proveedorId: Int?
    var proveedorNombre: String?
    var fecha: String
    var items: [PurchaseItem]
    var total: Double
    var iva: Double?
    var pagado: Bool?
    var estado: String?
    var numeroFactura: String?
    
    enum CodingKeys: String, CodingKey {
        case id, fecha, items, total, iva, pagado, estado
        case proveedorId = "proveedor_id"
        case proveedorNombre = "proveedor_nombre"
        case numeroFactura = "numero_factura"
    }
}
