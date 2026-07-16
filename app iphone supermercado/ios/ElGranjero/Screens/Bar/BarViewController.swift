import UIKit

class BarViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let tableView = UITableView()
    private var cuentas: [[String: Any]] = []
    private let fb = FirebaseService.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground; title = "Ventas Bar"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(nuevaCuenta))
        tableView.dataSource = self; tableView.delegate = self; tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell"); tableView.backgroundColor = .clear; tableView.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(tableView)
        NSLayoutConstraint.activate([tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor), tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor), tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
        loadData()
    }
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); loadData() }

    private func loadData() { Task { do { cuentas = try await fb.getList("bar_cuentas"); tableView.reloadData() } catch { print("Error: \(error)") } } }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { cuentas.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let c = cuentas[indexPath.row]; let cliente = c["cliente"] as? String ?? "Mesa"; let total = FirebaseService.formatMoney(c["total"] as? Double ?? 0)
        cell.textLabel?.text = "\(cliente) - \(total)"; cell.textLabel?.font = UIFont.systemFont(ofSize: 13); cell.backgroundColor = .white
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let detailVC = BarDetailViewController(cuenta: cuentas[indexPath.row])
        navigationController?.pushViewController(detailVC, animated: true)
    }

    @objc private func nuevaCuenta() {
        let alert = UIAlertController(title: "Nueva Cuenta", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in tf.placeholder = "Cliente / Mesa" }
        alert.addAction(UIAlertAction(title: "Crear", style: .default) { [weak self] _ in
            guard let self = self, let name = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespaces), !name.isEmpty else { return }
            Task {
                do {
                    let data: [String: Any] = ["id": FirebaseService.nextId(in: self.cuentas), "cliente": name, "total": 0, "items": [], "fecha": FirebaseService.nowString(), "estado": "abierta"]
                    try await self.fb.addToList("bar_cuentas", item: data); self.loadData()
                } catch { print("Error: \(error)") }
            }
        })
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        present(alert, animated: true)
    }
}
