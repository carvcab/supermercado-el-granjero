import UIKit

class ReportesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let tableView = UITableView()
    private let segControl = UISegmentedControl(items: ["Ventas", "Ganancias", "Productos", "Consumos"])
    private var reportData: [[String: Any]] = []
    private var consumos: [[String: Any]] = []
    private var resumenConsumos = ""
    private var titleText = ""
    private let fb = FirebaseService.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground; title = "Reportes"
        segControl.selectedSegmentIndex = 0; segControl.addTarget(self, action: #selector(loadData), for: .valueChanged); segControl.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(segControl)
        tableView.dataSource = self; tableView.delegate = self; tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell"); tableView.backgroundColor = .clear; tableView.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(tableView)
        NSLayoutConstraint.activate([
            segControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8), segControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16), segControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.topAnchor.constraint(equalTo: segControl.bottomAnchor, constant: 8), tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor), tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor), tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        loadData()
    }

    @objc private func loadData() {
        Task {
            do {
                switch segControl.selectedSegmentIndex {
                case 0:
                    titleText = "Ventas del Mes"
                    let ventas = try await fb.getList("ventas")
                    let month = FirebaseService.todayString().prefix(7)
                    let delMes = ventas.filter { ($0["fecha"] as? String ?? "").hasPrefix(month) && $0["estado"] as? String != "anulada" }
                    reportData = delMes.sorted { ($0["fecha"] as? String ?? "") > ($1["fecha"] as? String ?? "") }
                case 1:
                    titleText = "Ganancias (Hoy)"
                    let ventas = try await fb.getList("ventas")
                    let today = FirebaseService.todayString()
                    let deHoy = ventas.filter { ($0["fecha"] as? String ?? "").hasPrefix(today) && $0["estado"] as? String != "anulada" }
                    reportData = deHoy.map { v in
                        let total = v["total"] as? Double ?? 0
                        let items = v["items"] as? [[String: Any]] ?? []
                        let cost = items.reduce(0.0) { sum, it in
                            let qty = Double(it["cantidad"] as? Int ?? 1)
                            let pc = it["precio_compra"] as? Double ?? 0
                            return sum + (qty * pc)
                        }
                        var r = v; r["ganancia"] = total - cost; return r
                    }
                case 3:
                    titleText = "Consumos"
                    consumos = try await fb.getList("autoconsumos")
                    let prods = try await fb.getList("productos")
                    for i in 0..<consumos.count {
                        let c = consumos[i]
                        if let pid = c["producto_id"] as? Int {
                            if let prod = prods.first(where: { ($0["id"] as? Int) == pid }) {
                                consumos[i]["precio_compra"] = prod["precio_compra"]
                            }
                        }
                    }
                    consumos.sort { ($0["fecha"] as? String ?? "") > ($1["fecha"] as? String ?? "") }
                    let totalUnids = consumos.reduce(0) { $0 + ($1["cantidad"] as? Int ?? 0) }
                    let costoTotal = consumos.reduce(0.0) { sum, c in
                        let cant = Double(c["cantidad"] as? Int ?? 0)
                        let pc = c["precio_compra"] as? Double ?? 0
                        return sum + (cant * pc)
                    }
                    resumenConsumos = "Unidades: \(totalUnids) | Costo: \(FirebaseService.formatMoney(costoTotal)) | Registros: \(consumos.count)"
                default:
                    titleText = "Top Productos"
                    let productos = try await fb.getList("productos")
                    reportData = productos.sorted { ($0["stock_actual"] as? Int ?? 0) < ($1["stock_actual"] as? Int ?? 0) }
                }
                tableView.reloadData()
            } catch { print("Error: \(error)") }
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int { 1 }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        segControl.selectedSegmentIndex == 3 ? resumenConsumos : nil
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        segControl.selectedSegmentIndex == 3 ? consumos.count : reportData.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.font = UIFont.systemFont(ofSize: 13); cell.backgroundColor = .white
        switch segControl.selectedSegmentIndex {
        case 0:
            let v = reportData[indexPath.row]; let total = FirebaseService.formatMoney(v["total"] as? Double ?? 0)
            let cliente = v["cliente"] as? String ?? "Mostrador"; let fecha = (v["fecha"] as? String ?? "").prefix(16)
            cell.textLabel?.text = "\(cliente) - \(total) [\(fecha)]"
        case 1:
            let v = reportData[indexPath.row]; let ganancia = FirebaseService.formatMoney(v["ganancia"] as? Double ?? 0)
            let cliente = v["cliente"] as? String ?? "Mostrador"
            cell.textLabel?.text = "\(cliente) - Ganancia: \(ganancia)"
        case 3:
            let c = consumos[indexPath.row]
            let prod = c["producto_nombre"] as? String ?? "?"
            let cant = c["cantidad"] as? Int ?? 0
            let fecha = (c["fecha"] as? String ?? "").prefix(10)
            let pc = c["precio_compra"] as? Double ?? 0
            let costo = Double(cant) * pc
            cell.textLabel?.text = "\(prod) — \(cant) unids. (\(fecha))"
            cell.detailTextLabel?.text = "Costo: \(FirebaseService.formatMoney(costo))"
        default:
            let p = reportData[indexPath.row]; let name = p["nombre"] as? String ?? "?"
            let stock = p["stock_actual"] as? Int ?? 0
            cell.textLabel?.text = "\(name) - Stock: \(stock)"
        }
        return cell
    }
}
