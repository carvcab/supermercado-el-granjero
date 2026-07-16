import UIKit

class BarDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let tableView = UITableView()
    private let totalLabel = UILabel()
    private let addProductBtn = UIButton(type: .system)
    private let checkoutBtn = UIButton(type: .system)

    private var cuenta: [String: Any]
    private var items: [[String: Any]] = []
    private var productos: [[String: Any]] = []
    private let fb = FirebaseService.shared

    init(cuenta: [String: Any]) {
        self.cuenta = cuenta
        self.items = cuenta["items"] as? [[String: Any]] ?? []
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = cuenta["cliente"] as? String ?? cuenta["mesa"] as? String ?? "Detalle Cuenta"

        setupUI()
        loadProductos()
    }

    private func setupUI() {
        // Table view
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "itemCell")
        tableView.backgroundColor = .clear
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        // Bottom Card
        let bottomCard = UIView()
        bottomCard.backgroundColor = .secondarySystemGroupedBackground
        bottomCard.layer.cornerRadius = 16
        bottomCard.layer.shadowColor = UIColor.black.cgColor
        bottomCard.layer.shadowOpacity = 0.05
        bottomCard.layer.shadowRadius = 8
        bottomCard.layer.shadowOffset = CGSize(width: 0, height: -2)
        bottomCard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomCard)

        totalLabel.font = UIFont.boldSystemFont(ofSize: 22)
        totalLabel.textColor = UIColor(red: 0.1, green: 0.3, blue: 0.24, alpha: 1)
        totalLabel.textAlignment = .center
        totalLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomCard.addSubview(totalLabel)
        updateTotalLabel()

        addProductBtn.setTitle("Agregar Producto", for: .normal)
        addProductBtn.backgroundColor = UIColor(red: 0.1, green: 0.3, blue: 0.24, alpha: 1)
        addProductBtn.setTitleColor(.white, for: .normal)
        addProductBtn.layer.cornerRadius = 12
        addProductBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        addProductBtn.addTarget(self, action: #selector(agregarProducto), for: .touchUpInside)

        checkoutBtn.setTitle("Cobrar Cuenta", for: .normal)
        checkoutBtn.backgroundColor = UIColor(red: 0.18, green: 0.48, blue: 0.37, alpha: 1)
        checkoutBtn.setTitleColor(.white, for: .normal)
        checkoutBtn.layer.cornerRadius = 12
        checkoutBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        checkoutBtn.addTarget(self, action: #selector(cobrarCuenta), for: .touchUpInside)

        let btnRow = UIStackView(arrangedSubviews: [addProductBtn, checkoutBtn])
        btnRow.axis = .horizontal
        btnRow.spacing = 12
        btnRow.distribution = .fillEqually
        btnRow.translatesAutoresizingMaskIntoConstraints = false
        bottomCard.addSubview(btnRow)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomCard.topAnchor, constant: -8),

            bottomCard.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomCard.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomCard.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            totalLabel.topAnchor.constraint(equalTo: bottomCard.topAnchor, constant: 16),
            totalLabel.leadingAnchor.constraint(equalTo: bottomCard.leadingAnchor, constant: 16),
            totalLabel.trailingAnchor.constraint(equalTo: bottomCard.trailingAnchor, constant: -16),

            btnRow.topAnchor.constraint(equalTo: totalLabel.bottomAnchor, constant: 12),
            btnRow.leadingAnchor.constraint(equalTo: bottomCard.leadingAnchor, constant: 16),
            btnRow.trailingAnchor.constraint(equalTo: bottomCard.trailingAnchor, constant: -16),
            btnRow.bottomAnchor.constraint(equalTo: bottomCard.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            btnRow.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    private func loadProductos() {
        Task {
            do {
                productos = try await fb.getList("productos")
            } catch {
                print("Error loading products: \(error)")
            }
        }
    }

    private func updateTotalLabel() {
        let total = items.reduce(0.0) { sum, item in
            let price = item["precio_venta"] as? Double ?? 0
            let qty = item["cantidad"] as? Int ?? 0
            return sum + (price * Double(qty))
        }
        totalLabel.text = "Total: \(FirebaseService.formatMoney(total))"
    }

    // MARK: - Table View
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath)
        let item = items[indexPath.row]
        let name = item["nombre"] as? String ?? ""
        let qty = item["cantidad"] as? Int ?? 0
        let price = item["precio_venta"] as? Double ?? 0
        let subtotal = price * Double(qty)

        cell.textLabel?.text = "\(name) x\(qty) = \(FirebaseService.formatMoney(subtotal))"
        cell.textLabel?.font = UIFont.systemFont(ofSize: 14)
        cell.backgroundColor = .white
        return cell
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            items.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            updateTotalLabel()
            saveCuentaChanges()
        }
    }

    // MARK: - Actions
    @objc private func agregarProducto() {
        let alert = UIAlertController(title: "Seleccionar Producto", message: "\n\n\n\n\n\n\n\n\n\n", preferredStyle: .alert)
        
        let selectVC = ProductPickerViewController(productos: productos) { [weak self] selectedProd in
            alert.dismiss(animated: true) {
                self?.promptCantidad(for: selectedProd)
            }
        }
        
        selectVC.view.frame = CGRect(x: 10, y: 50, width: 250, height: 200)
        alert.addChild(selectVC)
        alert.view.addSubview(selectVC.view)
        
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        present(alert, animated: true)
    }

    private func promptCantidad(for product: [String: Any]) {
        let alert = UIAlertController(title: "Cantidad", message: "¿Cuántos \"\(product["nombre"] as? String ?? "")\"?", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "Cantidad"
            tf.keyboardType = .numberPad
            tf.text = "1"
        }
        alert.addAction(UIAlertAction(title: "Agregar", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let qty = Int(alert.textFields?.first?.text ?? "") ?? 1
            let prodId = product["id"] as? Int ?? 0
            
            if let idx = self.items.firstIndex(where: { ($0["producto_id"] as? Int) == prodId }) {
                let oldQty = self.items[idx]["cantidad"] as? Int ?? 0
                self.items[idx]["cantidad"] = oldQty + qty
            } else {
                let newItem: [String: Any] = [
                    "producto_id": prodId,
                    "nombre": product["nombre"] as? String ?? "",
                    "cantidad": qty,
                    "precio_venta": product["precio_venta"] as? Double ?? 0,
                    "precio_compra": product["precio_compra"] as? Double ?? 0
                ]
                self.items.append(newItem)
            }
            
            self.tableView.reloadData()
            self.updateTotalLabel()
            self.saveCuentaChanges()
        })
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        present(alert, animated: true)
    }

    private func saveCuentaChanges() {
        let total = items.reduce(0.0) { sum, item in
            let price = item["precio_venta"] as? Double ?? 0
            let qty = item["cantidad"] as? Int ?? 0
            return sum + (price * Double(qty))
        }
        
        let accountId = cuenta["id"] as? Int ?? 0
        Task {
            do {
                try await fb.updateInList("bar_cuentas", idValue: accountId, updates: [
                    "items": items,
                    "total": total
                ])
            } catch {
                print("Error saving bar account updates: \(error)")
            }
        }
    }

    @objc private func cobrarCuenta() {
        guard !items.isEmpty else { return }
        
        let total = items.reduce(0.0) { sum, item in
            let price = item["precio_venta"] as? Double ?? 0
            let qty = item["cantidad"] as? Int ?? 0
            return sum + (price * Double(qty))
        }
        
        let alert = UIAlertController(title: "Cobrar Cuenta", message: "Total a pagar: \(FirebaseService.formatMoney(total))", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "Efectivo recibido (opcional)"
            tf.keyboardType = .decimalPad
        }
        
        alert.addAction(UIAlertAction(title: "Cobrar", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let recibido = Double(alert.textFields?.first?.text?.replacingOccurrences(of: ",", with: ".") ?? "") ?? total
            let accountId = self.cuenta["id"] as? Int ?? 0
            
            Task {
                do {
                    // 1. Mark account as completed (or remove it)
                    let currentCuentas = try await self.fb.getList("bar_cuentas")
                    if let idx = currentCuentas.firstIndex(where: { ($0["id"] as? Int) == accountId }) {
                        try await self.fb.removeFromList("bar_cuentas", idValue: accountId)
                    }
                    
                    // 2. Add to ventas
                    let sales = try await self.fb.getList("ventas")
                    let nextSaleId = FirebaseService.nextId(in: sales)
                    
                    let venta: [String: Any] = [
                        "id": nextSaleId,
                        "fecha": FirebaseService.nowString(),
                        "total": total,
                        "recibido": recibido,
                        "cambio": max(0, recibido - total),
                        "items": self.items,
                        "cliente": self.cuenta["cliente"] as? String ?? "Mesa Bar",
                        "estado": "completada",
                        "tipo": "bar"
                    ]
                    try await self.fb.addToList("ventas", item: venta)
                    
                    // 3. Deduct stock
                    for item in self.items {
                        if let prodId = item["producto_id"] as? Int {
                            let prods = try await self.fb.getList("productos")
                            if let p = prods.first(where: { ($0["id"] as? Int) == prodId }),
                               let currentStock = p["stock_actual"] as? Int {
                                let newStock = max(0, currentStock - (item["cantidad"] as? Int ?? 0))
                                try await self.fb.updateInList("productos", idValue: prodId, updates: ["stock_actual": newStock])
                            }
                        }
                    }
                    
                    // 4. Update Caja business balance
                    if let abierta = try await self.fb.getList("cajas").first(where: { $0["estado"] as? String == "abierta" }),
                       let cajaId = abierta["id"] as? Int {
                        let ingresos = (abierta["ingresos"] as? Double ?? 0) + total
                        try await self.fb.updateInList("cajas", idValue: cajaId, updates: ["ingresos": ingresos])
                    }
                    
                    await MainActor.run {
                        self.navigationController?.popViewController(animated: true)
                    }
                } catch {
                    print("Error checking out bar account: \(error)")
                }
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - Product Picker Helper
class ProductPickerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    private let tableView = UITableView()
    private let searchBar = UISearchBar()
    private var allProducts: [[String: Any]] = []
    private var filtered: [[String: Any]] = []
    private let onSelect: ([String: Any]) -> Void
    
    init(productos: [[String: Any]], onSelect: @escaping ([String: Any]) -> Void) {
        self.allProducts = productos
        self.filtered = productos
        self.onSelect = onSelect
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.delegate = self
        searchBar.placeholder = "Buscar..."
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "prodCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange text: String) {
        if text.isEmpty {
            filtered = allProducts
        } else {
            filtered = allProducts.filter {
                ($0["nombre"] as? String ?? "").localizedCaseInsensitiveContains(text) ||
                ($0["codigo"] as? String ?? "").localizedCaseInsensitiveContains(text)
            }
        }
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filtered.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "prodCell", for: indexPath)
        let p = filtered[indexPath.row]
        let name = p["nombre"] as? String ?? ""
        let price = FirebaseService.formatMoney(p["precio_venta"] as? Double ?? 0)
        cell.textLabel?.text = "\(name) - \(price)"
        cell.textLabel?.font = UIFont.systemFont(ofSize: 12)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        onSelect(filtered[indexPath.row])
    }
}
