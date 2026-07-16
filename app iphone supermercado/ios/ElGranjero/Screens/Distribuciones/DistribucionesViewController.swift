import UIKit

class DistribucionesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let tableView = UITableView()
    private var distribuciones: [[String: Any]] = []
    private let fb = FirebaseService.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.95, green: 0.94, blue: 0.92, alpha: 1); title = "Distribuciones"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(nuevaDistribucion))
        tableView.dataSource = self; tableView.delegate = self; tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell"); tableView.backgroundColor = .clear; tableView.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(tableView)
        NSLayoutConstraint.activate([tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor), tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor), tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
        loadData()
    }
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); loadData() }

    private func loadData() { Task { do { distribuciones = try await fb.getList("distribuciones"); tableView.reloadData() } catch { print("Error: \(error)") } } }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { distribuciones.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let d = distribuciones[indexPath.row]
        cell.textLabel?.numberOfLines = 2; cell.textLabel?.font = .systemFont(ofSize: 13); cell.backgroundColor = .white
        cell.textLabel?.text = "\(d["concepto"] as? String ?? "?")\n\(FirebaseService.formatMoney(d["monto"] as? Double ?? 0)) — \((d["fecha"] as? String ?? "").prefix(10))"
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { tableView.deselectRow(at: indexPath, animated: true) }

    @objc private func nuevaDistribucion() {
        let alert = UIAlertController(title: "Nueva Distribución", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in tf.placeholder = "Concepto" }
        alert.addTextField { tf in tf.placeholder = "Monto"; tf.keyboardType = .decimalPad }
        alert.addTextField { tf in tf.placeholder = "Beneficiario (opcional)" }
        alert.addAction(UIAlertAction(title: "Guardar", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let f = alert.textFields ?? []; let concepto = f[0].text?.trimmingCharacters(in: .whitespaces) ?? ""
            let monto = Double(f[1].text?.replacingOccurrences(of: ",", with: ".") ?? "") ?? 0
            guard !concepto.isEmpty, monto > 0 else { return }
            Task {
                do {
                    let cajas = try await self.fb.getList("cajas")
                    let saldo = cajas.reduce(0.0) { s, c in
                        if c["estado"] as? String == "cerrada" { return s + (c["total_cierre"] as? Double ?? 0) }
                        return s + (c["ingresos"] as? Double ?? 0) - (c["egresos"] as? Double ?? 0)
                    }
                    if monto > saldo {
                        await MainActor.run {
                            let a = UIAlertController(title: "Fondos Insuficientes", message: "Saldo caja: \(FirebaseService.formatMoney(saldo))", preferredStyle: .alert); a.addAction(UIAlertAction(title: "OK", style: .default)); self.present(a, animated: true)
                        }; return
                    }
                    let data: [String: Any] = ["id": FirebaseService.nextId(in: self.distribuciones), "concepto": concepto, "monto": monto, "beneficiario": f[2].text ?? "", "fecha": FirebaseService.nowString()]
                    try await self.fb.addToList("distribuciones", item: data)
                    if let abierta = cajas.first(where: { ($0["estado"] as? String) == "abierta" }), let cid = abierta["id"] as? Int {
                        try await self.fb.updateInList("cajas", idValue: cid, updates: ["egresos": (abierta["egresos"] as? Double ?? 0) + monto])
                    }
                    self.loadData()
                } catch { print("Error: \(error)") }
            }
        })
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel)); present(alert, animated: true)
    }
}
