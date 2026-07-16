import UIKit

class FiadosViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let tableView = UITableView()
    private let segment = UISegmentedControl(items: ["Activos", "Pagados"])
    private var fiados: [[String: Any]] = []
    private let fb = FirebaseService.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground; title = "Fiados"

        segment.selectedSegmentIndex = 0; segment.addTarget(self, action: #selector(segmentChanged), for: .valueChanged); segment.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(segment)
        tableView.dataSource = self; tableView.delegate = self; tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell"); tableView.backgroundColor = .clear; tableView.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(tableView)
        NSLayoutConstraint.activate([
            segment.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8), segment.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16), segment.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.topAnchor.constraint(equalTo: segment.bottomAnchor, constant: 8), tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor), tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor), tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        loadData()
    }
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); loadData() }

    private func loadData() { Task { do { fiados = try await fb.getList("fiados"); tableView.reloadData() } catch { print("Error: \(error)") } } }

    @objc private func segmentChanged() { tableView.reloadData() }

    private var filtered: [[String: Any]] {
        let pagados = segment.selectedSegmentIndex == 1
        return fiados.filter { ($0["pagado"] as? Bool ?? false) == pagados }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { filtered.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let f = filtered[indexPath.row]
        let cliente = f["cliente"] as? String ?? "?"
        let monto = FirebaseService.formatMoney(f["monto"] as? Double ?? 0)
        let saldo = FirebaseService.formatMoney(f["saldo"] as? Double ?? 0)
        cell.textLabel?.text = "\(cliente) - Monto: \(monto) | Saldo: \(saldo)"
        cell.textLabel?.font = UIFont.systemFont(ofSize: 13); cell.backgroundColor = .white; cell.accessoryType = .disclosureIndicator
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let f = filtered[indexPath.row]
        guard !(f["pagado"] as? Bool ?? false) else { return }
        let alert = UIAlertController(title: "Abonar a Fiado", message: "Cliente: \(f["cliente"] as? String ?? "")", preferredStyle: .alert)
        alert.addTextField { tf in tf.placeholder = "Monto abono"; tf.keyboardType = .decimalPad }
        alert.addAction(UIAlertAction(title: "Abonar", style: .default) { [weak self] _ in
            guard let self = self, let id = f["id"] as? Int else { return }
            let monto = Double(alert.textFields?.first?.text?.replacingOccurrences(of: ",", with: ".") ?? "") ?? 0
            guard monto > 0 else { return }
            Task {
                do {
                    let saldoActual = f["saldo"] as? Double ?? 0
                    let nuevoSaldo = saldoActual - monto
                    var updates: [String: Any] = ["saldo": max(0, nuevoSaldo)]
                    if nuevoSaldo <= 0 { updates["pagado"] = true; updates["fecha_pago"] = FirebaseService.nowString() }
                    try await self.fb.updateInList("fiados", idValue: id, updates: updates)

                    let cajas = try await self.fb.getList("cajas")
                    if let abierta = cajas.first(where: { $0["estado"] as? String == "abierta" }), let cajaId = abierta["id"] as? Int {
                        let ingresos = (abierta["ingresos"] as? Double ?? 0) + monto
                        try await self.fb.updateInList("cajas", idValue: cajaId, updates: ["ingresos": ingresos])
                    }
                    self.loadData()
                } catch { print("Error: \(error)") }
            }
        })
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        present(alert, animated: true)
    }
}
