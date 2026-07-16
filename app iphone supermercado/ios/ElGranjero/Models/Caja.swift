import Foundation

struct CajaMovimiento: Codable {
    var tipo: String?
    var concepto: String?
    var monto: Double
    var metodoPago: String?
    var fecha: String?
    
    enum CodingKeys: String, CodingKey {
        case tipo, concepto, monto, fecha
        case metodoPago = "metodo_pago"
    }
}

struct Caja: Codable, Identifiable {
    var id: Int
    var montoInicial: Double
    var estado: String?
    var fechaApertura: String
    var fechaCierre: String?
    var ingresos: Double?
    var egresos: Double?
    var montoFinalReal: Double?
    var movimientos: [CajaMovimiento]?
    
    enum CodingKeys: String, CodingKey {
        case id, estado, ingresos, egresos, movimientos
        case montoInicial = "monto_inicial"
        case fechaApertura = "fecha_apertura"
        case fechaCierre = "fecha_cierre"
        case montoFinalReal = "monto_final_real"
    }
}

struct CajaNegocioConfig: Codable {
    var balance: Double
    var balanceAlCierre: Double?
    var gananciasAcumuladas: Double?
    
    enum CodingKeys: String, CodingKey {
        case balance
        case balanceAlCierre = "balance_al_cierre"
        case gananciasAcumuladas = "ganancias_acumuladas"
    }
}
