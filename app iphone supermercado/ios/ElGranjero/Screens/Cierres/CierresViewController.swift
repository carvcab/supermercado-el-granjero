import UIKit

class CierresViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let tableView = UITableView()
    private var cierres: [[String: Any]] = []
    private let fb = FirebaseService.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground; title = "Cierres de Caja"
        tableView.dataSource = self; tableView.delegate = self; tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell"); tableView.backgroundColor = .clear; tableView.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(tableView)
        NSLayoutConstraint.activate([tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor), tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor), tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
        loadData()
    }
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); loadData() }

    private func loadData() { Task { do { cierres = try await fb.getList("cajas"); tableView.reloadData() } catch { print("Error: \(error)") } } }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { cierres.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let c = cierres[indexPath.row]
        let estado = c["estado"] as? String ?? "cerrada"
        let real = FirebaseService.formatMoney(c["monto_final_real"] as? Double ?? 0)
        let ganancias = FirebaseService.formatMoney(c["ganancias"] as? Double ?? 0)
        let fecha = (c["fecha_cierre"] as? String ?? "").prefix(10)
        cell.textLabel?.numberOfLines = 2
        cell.textLabel?.text = "Efectivo: \(real) | Ganancia: \(ganancias) [\(fecha)]\nEstado: \(estado)"
        cell.textLabel?.font = UIFont.systemFont(ofSize: 12); cell.backgroundColor = .white
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { tableView.deselectRow(at: indexPath, animated: true) }
}
