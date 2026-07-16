import UIKit

class ClientesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {

    private let searchBar = UISearchBar()
    private let tableView = UITableView()
    private var clientes: [[String: Any]] = []
    private var filtered: [[String: Any]] = []
    private let fb = FirebaseService.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Clientes"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addCliente))

        searchBar.delegate = self; searchBar.placeholder = "Buscar cliente..."; searchBar.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(searchBar)
        tableView.dataSource = self; tableView.delegate = self; tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell"); tableView.backgroundColor = .clear; tableView.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(tableView)
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor), searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor), tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor), tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor), tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        loadData()
    }
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); loadData() }

    private func loadData() { Task { do { clientes = try await fb.getList("clientes"); filtered = clientes; tableView.reloadData() } catch { print("Error: \(error)") } } }

    func searchBar(_ searchBar: UISearchBar, textDidChange text: String) {
        if text.isEmpty { filtered = clientes }
        else { filtered = clientes.filter { ($0["nombre"] as? String ?? "").localizedCaseInsensitiveContains(text) || ($0["telefono"] as? String ?? "").contains(text) } }
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { filtered.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let c = filtered[indexPath.row]
        let name = c["nombre"] as? String ?? "?"
        let tel = c["telefono"] as? String ?? ""
        let deuda = FirebaseService.formatMoney(c["saldo_pendiente"] as? Double ?? 0)
        cell.textLabel?.text = "\(name) - \(tel) | Deuda: \(deuda)"
        cell.textLabel?.font = UIFont.systemFont(ofSize: 13); cell.backgroundColor = .white; cell.accessoryType = .disclosureIndicator
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { tableView.deselectRow(at: indexPath, animated: true); showClienteForm(filtered[indexPath.row]) }

    @objc private func addCliente() { showClienteForm(nil) }

    private func showClienteForm(_ cliente: [String: Any]?) {
        let alert = UIAlertController(title: cliente == nil ? "Nuevo Cliente" : "Editar Cliente", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in tf.placeholder = "Nombre"; tf.text = cliente?["nombre"] as? String }
        alert.addTextField { tf in tf.placeholder = "Teléfono"; tf.text = cliente?["telefono"] as? String; tf.keyboardType = .phonePad }
        alert.addTextField { tf in tf.placeholder = "Dirección"; tf.text = cliente?["direccion"] as? String }
        alert.addTextField { tf in tf.placeholder = "Email"; tf.text = cliente?["email"] as? String; tf.autocapitalizationType = .none; tf.keyboardType = .emailAddress }

        alert.addAction(UIAlertAction(title: "Guardar", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let f = alert.textFields ?? []
            guard let name = f[0].text?.trimmingCharacters(in: .whitespaces), !name.isEmpty else { return }
            var data: [String: Any] = ["nombre": name, "telefono": f[1].text ?? "", "direccion": f[2].text ?? "", "email": f[3].text ?? "", "saldo_pendiente": cliente?["saldo_pendiente"] as? Double ?? 0]
            if let id = cliente?["id"] as? Int { data["id"] = id }
            Task {
                do {
                    if cliente == nil { data["id"] = FirebaseService.nextId(in: self.clientes); try await self.fb.addToList("clientes", item: data) }
                    else { try await self.fb.updateInList("clientes", idValue: data["id"]!, updates: data) }
                    self.loadData()
                } catch { print("Error: \(error)") }
            }
        })
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        if cliente != nil {
            alert.addAction(UIAlertAction(title: "Eliminar", style: .destructive) { [weak self] _ in
                guard let self = self, let id = cliente?["id"] as? Int else { return }
                Task { do { try await self.fb.removeFromList("clientes", idValue: id); self.loadData() } catch { print("Error: \(error)") } }
            })
        }
        present(alert, animated: true)
    }
}
