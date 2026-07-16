import UIKit

class ProveedoresViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let tableView = UITableView()
    private var proveedores: [[String: Any]] = []
    private let fb = FirebaseService.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground; title = "Proveedores"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addProveedor))
        tableView.dataSource = self; tableView.delegate = self; tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell"); tableView.backgroundColor = .clear; tableView.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(tableView)
        NSLayoutConstraint.activate([tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor), tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor), tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
        loadData()
    }
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); loadData() }

    private func loadData() { Task { do { proveedores = try await fb.getList("proveedores"); tableView.reloadData() } catch { print("Error: \(error)") } } }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { proveedores.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let p = proveedores[indexPath.row]
        cell.textLabel?.text = "\(p["nombre"] as? String ?? "?") - \(p["telefono"] as? String ?? "")"
        cell.textLabel?.font = UIFont.systemFont(ofSize: 13); cell.backgroundColor = .white; cell.accessoryType = .disclosureIndicator
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { tableView.deselectRow(at: indexPath, animated: true); showForm(proveedores[indexPath.row]) }

    @objc private func addProveedor() { showForm(nil) }

    private func showForm(_ prov: [String: Any]?) {
        let alert = UIAlertController(title: prov == nil ? "Nuevo Proveedor" : "Editar Proveedor", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in tf.placeholder = "Nombre"; tf.text = prov?["nombre"] as? String }
        alert.addTextField { tf in tf.placeholder = "Teléfono"; tf.text = prov?["telefono"] as? String; tf.keyboardType = .phonePad }
        alert.addTextField { tf in tf.placeholder = "Dirección"; tf.text = prov?["direccion"] as? String }
        alert.addTextField { tf in tf.placeholder = "Email"; tf.text = prov?["email"] as? String; tf.autocapitalizationType = .none; tf.keyboardType = .emailAddress }
        alert.addAction(UIAlertAction(title: "Guardar", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let f = alert.textFields ?? []; let name = f[0].text?.trimmingCharacters(in: .whitespaces) ?? ""
            guard !name.isEmpty else { return }
            var data: [String: Any] = ["nombre": name, "telefono": f[1].text ?? "", "direccion": f[2].text ?? "", "email": f[3].text ?? ""]
            if let id = prov?["id"] as? Int { data["id"] = id }
            Task {
                do {
                    if prov == nil { data["id"] = FirebaseService.nextId(in: self.proveedores); try await self.fb.addToList("proveedores", item: data) }
                    else { try await self.fb.updateInList("proveedores", idValue: data["id"]!, updates: data) }
                    self.loadData()
                } catch { print("Error: \(error)") }
            }
        })
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        if prov != nil { alert.addAction(UIAlertAction(title: "Eliminar", style: .destructive) { [weak self] _ in
            guard let self = self, let id = prov?["id"] as? Int else { return }
            Task { do { try await self.fb.removeFromList("proveedores", idValue: id); self.loadData() } catch { print("Error: \(error)") } }
        }) }
        present(alert, animated: true)
    }
}
