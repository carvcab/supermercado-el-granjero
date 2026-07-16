import Foundation

struct Product: Codable, Identifiable {
    var id: Int
    var codigo: String
    var nombre: String
    var categoriaId: String?
    var categoriaNombre: String?
    var marca: String?
    var precioCompra: Int
    var precioVenta: Int
    var stockActual: Int
    var stockMinimo: Int
    var unidadMedida: String
    var codigoBarras: String?
    var esAlcohol: Bool
    var activo: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case codigo
        case nombre
        case categoriaId = "categoria_id"
        case categoriaNombre = "categoria_nombre"
        case marca
        case precioCompra = "precio_compra"
        case precioVenta = "precio_venta"
        case stockActual = "stock_actual"
        case stockMinimo = "stock_minimo"
        case unidadMedida = "unidad_medida"
        case codigoBarras = "codigo_barras"
        case esAlcohol = "es_alcohol"
        case activo
    }
}
