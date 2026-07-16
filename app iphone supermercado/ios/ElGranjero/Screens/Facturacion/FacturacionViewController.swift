import UIKit

class FacturacionViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {

    private let searchBar = UISearchBar()
    private let productosTable = UITableView()
    private let cartView = UIView()
    private let cartTable = UITableView()
    private let totalLabel = UILabel()
    private var productos: [[String: Any]] = []
    private var filtered: [[String: Any]] = []
    private var cart: [(producto: [String: Any], cantidad: Int)] = []
    private let fb = FirebaseService.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.95, green: 0.94, blue: 0.92, alpha: 1); title = "Facturación"
        let h = UIBarButtonItem(title: "Facturas", style: .plain, target: self, action: #selector(verFacturas))
        let s = UIBarButtonItem(image: UIImage(systemName: "barcode.viewfinder"), style: .plain, target: self, action: #selector(openScanner))
        navigationItem.rightBarButtonItems = [h, s]

        searchBar.delegate = self; searchBar.placeholder = "Buscar producto..."; searchBar.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(searchBar)
        productosTable.dataSource = self; productosTable.delegate = self; productosTable.register(UITableViewCell.self, forCellReuseIdentifier: "pc"); productosTable.backgroundColor = .clear; productosTable.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(productosTable)

        cartView.backgroundColor = .white; cartView.layer.cornerRadius = 14; cartView.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(cartView)
        let ct = UILabel(); ct.text = "Carrito"; ct.font = .boldSystemFont(ofSize: 15); ct.translatesAutoresizingMaskIntoConstraints = false; cartView.addSubview(ct)
        cartTable.dataSource = self; cartTable.delegate = self; cartTable.register(UITableViewCell.self, forCellReuseIdentifier: "cc"); cartTable.backgroundColor = .clear; cartTable.translatesAutoresizingMaskIntoConstraints = false; cartView.addSubview(cartTable)
        totalLabel.font = .boldSystemFont(ofSize: 20); totalLabel.textColor = UIColor(red: 0.1, green: 0.3, blue: 0.24, alpha: 1); totalLabel.textAlignment = .center; totalLabel.text = "$0"; totalLabel.translatesAutoresizingMaskIntoConstraints = false; cartView.addSubview(totalLabel)
        let emitir = UIButton(type: .system); emitir.setTitle("Emitir Factura", for: .normal); emitir.backgroundColor = UIColor(red: 0.18, green: 0.48, blue: 0.37, alpha: 1); emitir.setTitleColor(.white, for: .normal); emitir.layer.cornerRadius = 10; emitir.titleLabel?.font = .boldSystemFont(ofSize: 15); emitir.addTarget(self, action: #selector(emitirFactura), for: .touchUpInside); emitir.translatesAutoresizingMaskIntoConstraints = false; cartView.addSubview(emitir)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor), searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            productosTable.topAnchor.constraint(equalTo: searchBar.bottomAnchor), productosTable.leadingAnchor.constraint(equalTo: view.leadingAnchor), productosTable.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cartView.topAnchor.constraint(equalTo: productosTable.bottomAnchor), cartView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8), cartView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8), cartView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8), cartView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.4),
            ct.topAnchor.constraint(equalTo: cartView.topAnchor, constant: 8), ct.leadingAnchor.constraint(equalTo: cartView.leadingAnchor, constant: 12),
            cartTable.topAnchor.constraint(equalTo: ct.bottomAnchor, constant: 4), cartTable.leadingAnchor.constraint(equalTo: cartView.leadingAnchor, constant: 4), cartTable.trailingAnchor.constraint(equalTo: cartView.trailingAnchor, constant: -4),
            totalLabel.topAnchor.constraint(equalTo: cartTable.bottomAnchor, constant: 4), totalLabel.centerXAnchor.constraint(equalTo: cartView.centerXAnchor),
            emitir.topAnchor.constraint(equalTo: totalLabel.bottomAnchor, constant: 8), emitir.centerXAnchor.constraint(equalTo: cartView.centerXAnchor), emitir.widthAnchor.constraint(equalToConstant: 200), emitir.heightAnchor.constraint(equalToConstant: 40), emitir.bottomAnchor.constraint(equalTo: cartView.bottomAnchor, constant: -10),
        ])
        loadProductos()
    }

    private func loadProductos() { Task { do { productos = try await fb.getList("productos"); filtered = productos; productosTable.reloadData() } catch { print("Error: \(error)") } } }

    func searchBar(_ searchBar: UISearchBar, textDidChange text: String) {
        filtered = text.isEmpty ? productos : productos.filter { ($0["nombre"] as? String ?? "").localizedCaseInsensitiveContains(text) || ($0["codigo"] as? String ?? "").localizedCaseInsensitiveContains(text) }; productosTable.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { tableView == productosTable ? filtered.count : cart.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == productosTable {
            let cell = tableView.dequeueReusableCell(withIdentifier: "pc", for: indexPath)
            let p = filtered[indexPath.row]; cell.textLabel?.text = "\(p["nombre"] as? String ?? "") — \(FirebaseService.formatMoney(p["precio_venta"] as? Double ?? 0))"; cell.textLabel?.font = .systemFont(ofSize: 13); cell.backgroundColor = .white; return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cc", for: indexPath)
            let it = cart[indexPath.row]; cell.textLabel?.text = "\(it.producto["nombre"] as? String ?? "") x\(it.cantidad) = \(FirebaseService.formatMoney((it.producto["precio_venta"] as? Double ?? 0) * Double(it.cantidad)))"; cell.textLabel?.font = .systemFont(ofSize: 13); cell.backgroundColor = .clear; return cell
        }
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if tableView == productosTable {
            let p = filtered[indexPath.row]; promptQty(p)
        } else { cart.remove(at: indexPath.row); refreshCart() }
    }

    private func promptQty(_ p: [String: Any]) {
        let a = UIAlertController(title: p["nombre"] as? String, message: nil, preferredStyle: .alert)
        a.addTextField { tf in tf.placeholder = "Cantidad"; tf.keyboardType = .numberPad; tf.text = "1" }
        a.addAction(UIAlertAction(title: "Agregar", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let q = Int(a.textFields?.first?.text ?? "") ?? 1
            let pid = p["id"] as? Int ?? 0
            if let i = self.cart.firstIndex(where: { ($0.producto["id"] as? Int) == pid }) { self.cart[i].cantidad += q } else { self.cart.append((p, q)) }
            self.refreshCart()
        })
        a.addAction(UIAlertAction(title: "Cancelar", style: .cancel)); present(a, animated: true)
    }

    private func refreshCart() { cartTable.reloadData(); totalLabel.text = FirebaseService.formatMoney(cart.reduce(0) { $0 + ($1.producto["precio_venta"] as? Double ?? 0) * Double($1.cantidad) }) }

    @objc private func emitirFactura() {
        guard !cart.isEmpty else { return }
        let total = cart.reduce(0.0) { $0 + ($1.producto["precio_venta"] as? Double ?? 0) * Double($1.cantidad) }
        let a = UIAlertController(title: "Datos de Factura", message: nil, preferredStyle: .alert)
        a.addTextField { tf in tf.placeholder = "Cliente" }
        a.addTextField { tf in tf.placeholder = "RUT/DNI" }
        a.addTextField { tf in tf.placeholder = "Dirección (opcional)" }
        a.addAction(UIAlertAction(title: "Emitir", style: .default) { [weak self] _ in
            guard let self = self else { return }; let f = a.textFields ?? []
            let items: [[String: Any]] = self.cart.map { ["producto_id": $0.producto["id"] as? Int ?? 0, "nombre": $0.producto["nombre"] as? String ?? "", "cantidad": $0.cantidad, "precio_venta": $0.producto["precio_venta"] as? Double ?? 0, "precio_compra": $0.producto["precio_compra"] as? Double ?? 0] }
            Task {
                do {
                    let facturas = try await self.fb.getList("facturas")
                    let data: [String: Any] = ["id": FirebaseService.nextId(in: facturas), "cliente": f[0].text ?? "", "rut": f[1].text ?? "", "direccion": f[2].text ?? "", "total": total, "items": items, "fecha": FirebaseService.nowString(), "estado": "emitida"]
                    try await self.fb.addToList("facturas", item: data)
                    // Deduct stock
                    for it in self.cart { if let pid = it.producto["id"] as? Int {
                        let prods = try await self.fb.getList("productos"); if let p = prods.first(where: { ($0["id"] as? Int) == pid }) {
                            try await self.fb.updateInList("productos", idValue: pid, updates: ["stock_actual": max(0, (p["stock_actual"] as? Int ?? 0) - it.cantidad)])
                        }
                    }}
                    // Register as sale too
                    let ventas = try await self.fb.getList("ventas")
                    let venta: [String: Any] = ["id": FirebaseService.nextId(in: ventas), "fecha": FirebaseService.nowString(), "total": total, "items": items, "cliente": f[0].text ?? "Mostrador", "estado": "completada", "tipo": "factura"]
                    try await self.fb.addToList("ventas", item: venta)
                    if let abierta = (try await self.fb.getList("cajas")).first(where: { ($0["estado"] as? String) == "abierta" }), let cid = abierta["id"] as? Int {
                        try await self.fb.updateInList("cajas", idValue: cid, updates: ["ingresos": (abierta["ingresos"] as? Double ?? 0) + total])
                    }
                    await MainActor.run { self.cart.removeAll(); self.refreshCart() }
                } catch { print("Error: \(error)") }
            }
        })
        a.addAction(UIAlertAction(title: "Cancelar", style: .cancel)); present(a, animated: true)
    }

    @objc private func openScanner() {
        present(BarcodeScannerViewController { [weak self] code in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let p = self.productos.first(where: { ($0["codigo"] as? String) == code }) {
                    let pid = p["id"] as? Int ?? 0
                    if let i = self.cart.firstIndex(where: { ($0.producto["id"] as? Int) == pid }) { self.cart[i].cantidad += 1 }
                    else { self.cart.append((p, 1)) }
                    self.refreshCart()
                }
            }
        }, animated: true)
    }

    @objc private func verFacturas() {
        let vc = FacturaListVC(); navigationController?.pushViewController(vc, animated: true)
    }
}

class FacturaListVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tv = UITableView(); private var facts: [[String: Any]] = []
    override func viewDidLoad() {
        super.viewDidLoad(); title = "Facturas Emitidas"; view.backgroundColor = UIColor(red: 0.95, green: 0.94, blue: 0.92, alpha: 1)
        tv.dataSource = self; tv.delegate = self; tv.register(UITableViewCell.self, forCellReuseIdentifier: "f"); tv.backgroundColor = .clear; tv.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(tv)
        NSLayoutConstraint.activate([tv.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), tv.leadingAnchor.constraint(equalTo: view.leadingAnchor), tv.trailingAnchor.constraint(equalTo: view.trailingAnchor), tv.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
        Task { do { facts = try await FirebaseService.shared.getList("facturas"); tv.reloadData() } catch { print("Error: \(error)") } }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { facts.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let c = tableView.dequeueReusableCell(withIdentifier: "f", for: indexPath); let f = facts[indexPath.row]
        c.textLabel?.numberOfLines = 2; c.textLabel?.font = .systemFont(ofSize: 12); c.backgroundColor = .white
        c.textLabel?.text = "\(f["cliente"] as? String ?? "?") | RUT \(f["rut"] as? String ?? "—")\n\(FirebaseService.formatMoney(f["total"] as? Double ?? 0)) — \((f["fecha"] as? String ?? "").prefix(10))"
        return c
    }
}
