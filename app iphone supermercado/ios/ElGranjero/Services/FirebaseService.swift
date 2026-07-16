import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

class FirebaseService {
    static let shared = FirebaseService()
    
    private var _db: Firestore?
    private var _datosRef: CollectionReference?
    
    private init() {}
    
    func configure() {
        if FirebaseApp.allApps?.isEmpty ?? true {
            FirebaseApp.configure()
        }
        _db = Firestore.firestore()
        _datosRef = _db!.collection("datos")
    }
    
    var db: Firestore {
        return _db!
    }
    
    private var datosRef: CollectionReference {
        return _datosRef!
    }
    
    // MARK: - Auth
    func signInAnonymously() async throws {
        try await Auth.auth().signInAnonymously()
    }
    
    func signInWithEmail(email: String = "pos-client@elgranjero.com", password: String = "granjeroclient123!") async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }
    
    func createAccount(email: String = "pos-client@elgranjero.com", password: String = "granjeroclient123!") async throws {
        try await Auth.auth().createUser(withEmail: email, password: password)
    }
    
    func signOut() {
        try? Auth.auth().signOut()
    }
    
    var currentUser: User? {
        return Auth.auth().currentUser
    }
    
    // MARK: - Firestore List CRUD
    func getList(_ doc: String) async throws -> [[String: Any]] {
        let snapshot = try await datosRef.document(doc).getDocument()
        guard let data = snapshot.data(), let lista = data["lista"] as? [[String: Any]] else {
            return []
        }
        return lista
    }
    
    func setList(_ doc: String, list: [[String: Any]]) async throws {
        try await datosRef.document(doc).setData(["lista": list], merge: true)
    }
    
    func addToList(_ doc: String, item: [String: Any]) async throws {
        var list = try await getList(doc)
        list.append(item)
        try await setList(doc, list: list)
    }
    
    func updateInList(_ doc: String, idKey: String = "id", idValue: Any, updates: [String: Any]) async throws {
        var list = try await getList(doc)
        if let index = list.firstIndex(where: { $0[idKey] as? Int == idValue as? Int }) {
            var item = list[index]
            for (key, value) in updates {
                item[key] = value
            }
            list[index] = item
            try await setList(doc, list: list)
        }
    }
    
    func removeFromList(_ doc: String, idKey: String = "id", idValue: Any) async throws {
        var list = try await getList(doc)
        list.removeAll { $0[idKey] as? Int == idValue as? Int }
        try await setList(doc, list: list)
    }
    
    // MARK: - Firestore Document CRUD (for config_caja_negocio etc.)
    func getDocument(_ doc: String) async throws -> [String: Any]? {
        let snapshot = try await datosRef.document(doc).getDocument()
        return snapshot.data()
    }
    
    func setDocument(_ doc: String, data: [String: Any]) async throws {
        try await datosRef.document(doc).setData(data, merge: true)
    }
    
    // MARK: - Helpers
    static func decodificarFoto(_ foto: String?) -> UIImage? {
        guard let foto = foto, !foto.isEmpty else { return nil }
        if foto.hasPrefix("data:") {
            guard let commaIdx = foto.firstIndex(of: ",") else { return nil }
            let b64 = String(foto[foto.index(after: commaIdx)...])
            guard let data = Data(base64Encoded: b64) else { return nil }
            return UIImage(data: data)
        }
        if foto.hasPrefix("http") {
            guard let url = URL(string: foto) else { return nil }
            if let data = try? Data(contentsOf: url) { return UIImage(data: data) }
            return nil
        }
        return nil
    }

    static func formatMoney(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        formatter.locale = Locale(identifier: "es_CO")
        if let formatted = formatter.string(from: NSNumber(value: Int(amount))) {
            return "$\(formatted)"
        }
        return "$\(Int(amount))"
    }
    
    static func todayString() -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: Date())
    }
    
    static func nowString() -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return df.string(from: Date())
    }
    
    static func nextId(in list: [[String: Any]]) -> Int {
        let maxId = list.compactMap { $0["id"] as? Int }.max() ?? 0
        return maxId + 1
    }
}
