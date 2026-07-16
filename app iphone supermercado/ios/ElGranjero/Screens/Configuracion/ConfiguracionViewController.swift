import UIKit

class ConfiguracionViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let fb = FirebaseService.shared
    private let session = SessionManager.shared
    private var config: [String: Any] = [:]

    private let items: [(section: String, rows: [(label: String, key: String, type: Int)])] = [
        ("General", [
            ("Nombre del Negocio", "nombre_negocio", 0),
            ("IVA Default (%)", "iva_default", 1),
        ]),
        ("Caja", [
            ("Usar Caja Negocio", "usar_caja_negocio", 2),
            ("Monto Inicial Default", "monto_inicial_default", 1),
        ]),
        ("Info", [
            ("Versión: El Granjero iOS v1.1.2", "", 3),
            ("Usuario: \(SessionManager.shared.username ?? "—")", "", 3),
            ("Permisos: \(SessionManager.shared.permCount)", "", 3),
        ]),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Configuración"
        view.backgroundColor = .systemBackground
        tableView.dataSource = self; tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.backgroundColor = .clear; tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor), tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor), tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
        loadConfig()
    }

    private func loadConfig() {
        Task {
            do {
                let list = try await fb.getList("configuracion")
                config = list.first ?? [:]
                tableView.reloadData()
            } catch { print("Error: \(error)") }
        }
    }

    private func persistConfig() async throws {
        var list = try await fb.getList("configuracion")
        if list.isEmpty {
            list = [config]
        } else {
            list[0] = config
        }
        try await fb.setList("configuracion", list: list)
    }

    func numberOfSections(in tableView: UITableView) -> Int { items.count }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { items[section].rows.count }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { items[section].section }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.backgroundColor = .white; cell.textLabel?.font = UIFont.systemFont(ofSize: 14); cell.selectionStyle = .none; cell.accessoryView = nil
        let row = items[indexPath.section].rows[indexPath.row]
        cell.textLabel?.text = row.label
        if row.type == 2 {
            let sw = UISwitch(); sw.isOn = config[row.key] as? Bool ?? false; sw.tag = indexPath.section * 100 + indexPath.row
            sw.addTarget(self, action: #selector(toggleChanged(_:)), for: .valueChanged); cell.accessoryView = sw
        } else if row.type == 0 || row.type == 1 {
            let val = config[row.key] as? String ?? ""
            let detail = UILabel(); detail.text = val.isEmpty ? "—" : (row.type == 1 ? "\(val)%" : val)
            detail.font = .systemFont(ofSize: 13); detail.textColor = .gray; detail.sizeToFit(); cell.accessoryView = detail
        } else {
            cell.textLabel?.textColor = .gray; cell.textLabel?.font = .systemFont(ofSize: 13)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row = items[indexPath.section].rows[indexPath.row]
        guard row.type == 0 || row.type == 1 else { return }
        let alert = UIAlertController(title: "Editar \(row.label)", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in tf.text = self.config[row.key] as? String ?? ""; if row.type == 1 { tf.keyboardType = .decimalPad } }
        alert.addAction(UIAlertAction(title: "Guardar", style: .default) { [weak self] _ in
            guard let self = self, let val = alert.textFields?.first?.text else { return }
            self.config[row.key] = val
            Task { do {
                try await self.persistConfig()
                self.tableView.reloadData()
            } catch { print("Error: \(error)") } }
        })
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func toggleChanged(_ sender: UISwitch) {
        let section = sender.tag / 100; let rowIdx = sender.tag % 100
        guard section < items.count, rowIdx < items[section].rows.count else { return }
        let key = items[section].rows[rowIdx].key
        config[key] = sender.isOn
        Task { do { try await persistConfig() } catch { print("Error: \(error)") } }
    }
}
