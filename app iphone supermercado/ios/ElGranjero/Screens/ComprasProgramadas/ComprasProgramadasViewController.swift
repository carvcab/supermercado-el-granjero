import UIKit

class ComprasProgramadasViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let tableView = UITableView()
    private var comprasProg: [[String: Any]] = []
    private let fb = FirebaseService.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground; title = "Compras Programadas"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addCompraProgramada))
        tableView.dataSource = self; tableView.delegate = self; tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell"); tableView.backgroundColor = .clear; tableView.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(tableView)
        NSLayoutConstraint.activate([tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor), tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor), tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
        loadData()
    }
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); loadData() }

    private func loadData() { Task { do { comprasProg = try await fb.getList("compras_programadas"); tableView.reloadData() } catch { print("Error: \(error)") } } }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { comprasProg.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let c = comprasProg[indexPath.row]; let prov = c["proveedor"] as? String ?? "?"; let fecha = (c["fecha_programada"] as? String ?? "").prefix(10)
        cell.textLabel?.text = "\(prov) - \(fecha)"; cell.textLabel?.font = UIFont.systemFont(ofSize: 13); cell.backgroundColor = .white
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { tableView.deselectRow(at: indexPath, animated: true) }

    @objc private func addCompraProgramada() {
        let alert = UIAlertController(title: "Nueva Compra Programada", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in tf.placeholder = "Proveedor" }
        alert.addTextField { tf in tf.placeholder = "Fecha (YYYY-MM-DD)"; tf.text = FirebaseService.todayString() }
        alert.addAction(UIAlertAction(title: "Guardar", style: .default) { [weak self] _ in
            guard let self = self, let prov = alert.textFields?[0].text?.trimmingCharacters(in: .whitespaces), !prov.isEmpty else { return }
            let fecha = alert.textFields?[1].text ?? FirebaseService.todayString()
            Task {
                do {
                    let data: [String: Any] = ["id": FirebaseService.nextId(in: self.comprasProg), "proveedor": prov, "fecha_programada": fecha, "estado": "pendiente"]
                    try await self.fb.addToList("compras_programadas", item: data); self.loadData()
                } catch { print("Error: \(error)") }
            }
        })
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        present(alert, animated: true)
    }
}
