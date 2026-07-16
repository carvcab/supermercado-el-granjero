import UIKit

class CajaViewController: UIViewController {

    private let fb = FirebaseService.shared
    private let stackView = UIStackView()
    private let estadoLabel = UILabel()
    private let balanceLabel = UILabel()
    private let ingresosLabel = UILabel()
    private let egresosLabel = UILabel()
    private let actionBtn = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Caja"

        stackView.axis = .vertical; stackView.spacing = 16; stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])

        let card = UIView(); card.backgroundColor = .secondarySystemGroupedBackground; card.layer.cornerRadius = 16; card.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(card)

        let innerStack = UIStackView(); innerStack.axis = .vertical; innerStack.spacing = 12; innerStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(innerStack)
        NSLayoutConstraint.activate([innerStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 20), innerStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20), innerStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20), innerStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20)])

        estadoLabel.font = UIFont.boldSystemFont(ofSize: 22); estadoLabel.textAlignment = .center; innerStack.addArrangedSubview(estadoLabel)
        balanceLabel.font = UIFont.boldSystemFont(ofSize: 32); balanceLabel.textAlignment = .center; balanceLabel.textColor = UIColor(red: 0.1, green: 0.3, blue: 0.24, alpha: 1); innerStack.addArrangedSubview(balanceLabel)
        ingresosLabel.font = UIFont.systemFont(ofSize: 14); ingresosLabel.textColor = .gray; innerStack.addArrangedSubview(ingresosLabel)
        egresosLabel.font = UIFont.systemFont(ofSize: 14); egresosLabel.textColor = .gray; innerStack.addArrangedSubview(egresosLabel)

        actionBtn.backgroundColor = UIColor(red: 0.18, green: 0.48, blue: 0.37, alpha: 1); actionBtn.setTitleColor(.white, for: .normal); actionBtn.layer.cornerRadius = 14; actionBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17); actionBtn.heightAnchor.constraint(equalToConstant: 50).isActive = true; actionBtn.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
        stackView.addArrangedSubview(actionBtn)

        refresh()
    }
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); refresh() }

    private func refresh() {
        Task {
            do {
                let cajas = try await fb.getList("cajas")
                if let abierta = cajas.first(where: { $0["estado"] as? String == "abierta" }) {
                    estadoLabel.text = "Caja Abierta"
                    let ingresos = abierta["ingresos"] as? Double ?? 0; let egresos = abierta["egresos"] as? Double ?? 0
                    balanceLabel.text = FirebaseService.formatMoney(ingresos - egresos)
                    ingresosLabel.text = "Ingresos: \(FirebaseService.formatMoney(ingresos))"
                    egresosLabel.text = "Egresos: \(FirebaseService.formatMoney(egresos))"
                    actionBtn.setTitle("Cerrar Caja", for: .normal)
                } else {
                    estadoLabel.text = "Caja Cerrada"; balanceLabel.text = "$0"; ingresosLabel.text = ""; egresosLabel.text = ""
                    actionBtn.setTitle("Abrir Caja", for: .normal)
                }
            } catch { print("Error: \(error)") }
        }
    }

    @objc private func actionTapped() {
        Task {
            do {
                let cajas = try await fb.getList("cajas")
                if let abierta = cajas.first(where: { $0["estado"] as? String == "abierta" }), let id = abierta["id"] as? Int {
                    await MainActor.run { self.pedirCierre(abierta: abierta, id: id) }
                } else {
                    var caja: [String: Any] = ["id": FirebaseService.nextId(in: cajas), "estado": "abierta", "monto_inicial": 0, "ingresos": 0, "egresos": 0, "fecha_apertura": FirebaseService.nowString(), "fecha_cierre": ""]
                    try await fb.addToList("cajas", item: caja)
                    await MainActor.run { refresh() }
                }
            } catch { print("Error: \(error)") }
        }
    }

    private func pedirCierre(abierta: [String: Any], id: Int) {
        let alert = UIAlertController(title: "Cerrar Caja", message: "Ingrese el dinero contado en físico", preferredStyle: .alert)
        alert.addTextField { tf in tf.placeholder = "Monto real en caja"; tf.keyboardType = .decimalPad }
        alert.addTextField { tf in tf.placeholder = "Observaciones (opcional)"; tf.text = "" }
        alert.addAction(UIAlertAction(title: "Cerrar", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let realStr = alert.textFields?[0].text?.replacingOccurrences(of: ",", with: ".") ?? "0"
            let montoReal = Double(realStr) ?? 0
            let obs = alert.textFields?[1].text ?? ""
            Task { await self.ejecutarCierre(abierta: abierta, id: id, montoReal: montoReal, obs: obs) }
        })
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        present(alert, animated: true)
    }

    private func ejecutarCierre(abierta: [String: Any], id: Int, montoReal: Double, obs: String) async {
        do {
            let ventas = try await fb.getList("ventas")
            let productos = try await fb.getList("productos")
            let consumos = try await fb.getList("autoconsumos")
            let openDate = (abierta["fecha_apertura"] as? String ?? "").prefix(10)
            let now = FirebaseService.nowString()
            let inicial = abierta["monto_inicial"] as? Double ?? 0
            let ingresos = abierta["ingresos"] as? Double ?? 0
            let egresos = abierta["egresos"] as? Double ?? 0

            var totalVenta = 0.0, totalCosto = 0.0
            for v in ventas {
                let created = (v["created_at"] as? String ?? v["fecha"] as? String ?? "").prefix(10)
                if created >= openDate, (v["metodo_pago"] as? String) != "fiado" {
                    totalVenta += v["total"] as? Double ?? 0
                    let items = v["items"] as? [[String: Any]] ?? []
                    for it in items {
                        let qty = Double(it["cantidad"] as? Int ?? 1)
                        let pc = it["precio_compra"] as? Double ?? 0
                        totalCosto += qty * pc
                    }
                }
            }

            var totalConsumosCosto = 0.0
            for c in consumos {
                let cFecha = (c["fecha"] as? String ?? "").prefix(10)
                if cFecha >= openDate {
                    let cant = Double(c["cantidad"] as? Int ?? 0)
                    if let pid = c["producto_id"] as? Int,
                       let prod = productos.first(where: { ($0["id"] as? Int) == pid }) {
                        let pc = prod["precio_compra"] as? Double ?? 0
                        totalConsumosCosto += cant * pc
                    }
                }
            }

            let ganancias = totalVenta - totalCosto - totalConsumosCosto
            let esperado = inicial + ingresos - egresos
            let diferencia = esperado - montoReal

            try await fb.updateInList("cajas", idValue: id, updates: [
                "estado": "cerrada",
                "fecha_cierre": now,
                "monto_final_real": montoReal,
                "ingresos": ingresos,
                "egresos": egresos,
                "esperado": esperado,
                "diferencia": diferencia,
                "ganancias": ganancias,
                "capital_productos": totalCosto,
                "consumos_propios": totalConsumosCosto,
                "observaciones": obs
            ])

            if var cfg = try? await fb.getDocument("config_caja_negocio") {
                if cfg.isEmpty { cfg = ["balance": 0.0, "ganancias_acumuladas": 0.0, "balance_al_cierre": 0.0] }
                var balance = (cfg["balance"] as? Double ?? 0) + inicial + totalCosto - diferencia
                var ganAcum = (cfg["ganancias_acumuladas"] as? Double ?? 0) + ganancias
                cfg["balance"] = balance
                cfg["ganancias_acumuladas"] = ganAcum
                cfg["balance_al_cierre"] = balance
                cfg["updated_at"] = now
                try await fb.setDocument("config_caja_negocio", data: cfg)
            }

            await MainActor.run { refresh() }
        } catch { print("Error cierre: \(error)") }
    }
}
