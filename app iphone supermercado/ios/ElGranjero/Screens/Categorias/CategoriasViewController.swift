import UIKit

class CategoriasViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let tableView = UITableView()
    private var categorias: [[String: Any]] = []
    private let fb = FirebaseService.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground; title = "Categorías"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addCategoria))
        tableView.dataSource = self; tableView.delegate = self; tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell"); tableView.backgroundColor = .clear; tableView.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(tableView)
        NSLayoutConstraint.activate([tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor), tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor), tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
        loadData()
    }
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); loadData() }
    private func loadData() { Task { do { categorias = try await fb.getList("categorias"); tableView.reloadData() } catch { print("Error: \(error)") } } }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { categorias.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = categorias[indexPath.row]["nombre"] as? String ?? "?"; cell.textLabel?.font = UIFont.systemFont(ofSize: 14); cell.backgroundColor = .white
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { tableView.deselectRow(at: indexPath, animated: true); editCategoria(categorias[indexPath.row]) }

    @objc private func addCategoria() { showForm(nil) }
    private func editCategoria(_ cat: [String: Any]) { showForm(cat) }

    private func showForm(_ cat: [String: Any]?) {
        let alert = UIAlertController(title: cat == nil ? "Nueva Categoría" : "Editar Categoría", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in tf.placeholder = "Nombre"; tf.text = cat?["nombre"] as? String }
        alert.addAction(UIAlertAction(title: "Guardar", style: .default) { [weak self] _ in
            guard let self = self, let name = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespaces), !name.isEmpty else { return }
            var data: [String: Any] = ["nombre": name]
            if let id = cat?["id"] as? Int { data["id"] = id }
            Task {
                do {
                    if cat == nil { data["id"] = FirebaseService.nextId(in: self.categorias); try await self.fb.addToList("categorias", item: data) }
                    else { try await self.fb.updateInList("categorias", idValue: data["id"]!, updates: data) }
                    self.loadData()
                } catch { print("Error: \(error)") }
            }
        })
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        if cat != nil { alert.addAction(UIAlertAction(title: "Eliminar", style: .destructive) { [weak self] _ in
            guard let self = self, let id = cat?["id"] as? Int else { return }
            Task { do { try await self.fb.removeFromList("categorias", idValue: id); self.loadData() } catch { print("Error: \(error)") } }
        }) }
        present(alert, animated: true)
    }
}
