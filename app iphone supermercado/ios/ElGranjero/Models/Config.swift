import Foundation

struct AppConfig: Codable {
    var nombreNegocio: String?
    var alertaStock: Bool?
    var stockMinimoGlobal: Int?
    var limiteDescuento: Double?
    var diasRecordatorio: Int?
    
    enum CodingKeys: String, CodingKey {
        case nombreNegocio = "nombre_negocio"
        case alertaStock = "alerta_stock"
        case stockMinimoGlobal = "stock_minimo_global"
        case limiteDescuento = "limite_descuento"
        case diasRecordatorio = "dias_recordatorio"
    }
}

struct ScheduledPurchase: Codable, Identifiable {
    var id: Int
    var nombre: String?
    var proveedorId: Int?
    var items: [PurchaseItem]?
    var frecuencia: String?
    var dia: Int?
    var activo: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id, nombre, items, frecuencia, dia, activo
        case proveedorId = "proveedor_id"
    }
}

struct BarCuenta: Codable, Identifiable {
    var id: Int
    var mesa: String?
    var clienteId: Int?
    var clienteNombre: String?
    var items: [SaleItem]?
    var total: Double?
    var estado: String?
    var fechaApertura: String?
    
    enum CodingKeys: String, CodingKey {
        case id, mesa, items, total, estado
        case clienteId = "cliente_id"
        case clienteNombre = "cliente_nombre"
        case fechaApertura = "fecha_apertura"
    }
}

struct Distribution: Codable, Identifiable {
    var id: Int
    var tipo: String?
    var fecha: String
    var items: [DistributionItem]?
    var total: Double
    var createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, tipo, fecha, items, total
        case createdAt = "created_at"
    }
}

struct DistributionItem: Codable {
    var categoriaNombre: String?
    var monto: Double
    
    enum CodingKeys: String, CodingKey {
        case categoriaNombre = "categoria_nombre"
        case monto
    }
}

struct DistributionCategory: Codable, Identifiable {
    var id: Int?
    var nombre: String
}

struct Cierre: Codable, Identifiable {
    var id: Int
    var cajaId: Int?
    var fecha: String?
    var montoInicial: Double?
    var ingresos: Double?
    var egresos: Double?
    var esperado: Double?
    var real: Double?
    var diferencia: Double?
    var observaciones: String?
    
    enum CodingKeys: String, CodingKey {
        case id, fecha, ingresos, egresos, esperado, real, diferencia, observaciones
        case cajaId = "caja_id"
        case montoInicial = "monto_inicial"
    }
}
