import UIKit

class HistorialViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let tableView = UITableView()
    private let segControl = UISegmentedControl(items: ["Hoy", "Mes", "Todo"])
    private var ventas: [[String: Any]] = []
    private let fb = FirebaseService.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground; title = "Historial"

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
                let todas = try await fb.getList("ventas")
                let today = FirebaseService.todayString(); let month = today.prefix(7)
                switch segControl.selectedSegmentIndex {
                case 0: ventas = todas.filter { ($0["fecha"] as? String ?? "").hasPrefix(today) }
                case 1: ventas = todas.filter { ($0["fecha"] as? String ?? "").hasPrefix(month) }
                default: ventas = todas
                }
                ventas.sort { ($0["fecha"] as? String ?? "") > ($1["fecha"] as? String ?? "") }
                tableView.reloadData()
            } catch { print("Error: \(error)") }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { ventas.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let v = ventas[indexPath.row]
        let total = FirebaseService.formatMoney(v["total"] as? Double ?? 0)
        let cliente = v["cliente"] as? String ?? "Mostrador"
        let fecha = (v["fecha"] as? String ?? "").prefix(19)
        cell.textLabel?.text = "\(cliente) - \(total) [\(fecha)]"
        cell.textLabel?.font = UIFont.systemFont(ofSize: 13); cell.backgroundColor = .white
        let estado = v["estado"] as? String ?? ""
        cell.textLabel?.textColor = estado == "anulada" ? .red : .darkText
        return cell
    }
}
