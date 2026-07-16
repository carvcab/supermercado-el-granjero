import UIKit

class ComprasViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let tableView = UITableView()
    private var compras: [[String: Any]] = []
    private var productos: [[String: Any]] = []
    private let fb = FirebaseService.shared

    private var tempProv = ""
    private var tempIva = 0.0
    private var tempItems: [[String: Any]] = []
    private var tempPagado = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.95, green: 0.94, blue: 0.92, alpha: 1); title = "Compras"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(nuevaCompra))
        tableView.dataSource = self; tableView.delegate = self; tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.backgroundColor = .clear; tableView.separatorStyle = .none; tableView.rowHeight = 56
        tableView.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(tableView)
        NSLayoutConstraint.activate([tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor), tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor), tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
        loadData()
    }
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); loadData() }

    private func loadData() {
        Task { do { async let c = fb.getList("compras"); async let p = fb.getList("productos"); (compras, productos) = try await (c, p); tableView.reloadData() } catch { print("Error: \(error)") } }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { compras.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let c = compras[indexPath.row]; cell.textLabel?.numberOfLines = 2
        cell.textLabel?.text = "\(c["proveedor"] as? String ?? "?")\n\((c["items"] as? [[String: Any]] ?? []).count) items | IVA \(Int(c["iva"] as? Double ?? 0))% | \(FirebaseService.formatMoney(c["total"] as? Double ?? 0)) | \((c["fecha"] as? String ?? "").prefix(10))"
        cell.textLabel?.font = .systemFont(ofSize: 12); cell.backgroundColor = .white; cell.layer.cornerRadius = 8; cell.layer.masksToBounds = true
        return cell
    }

    @objc private func nuevaCompra() {
        tempProv = ""
        tempIva = 0.0
        tempItems = []
        tempPagado = false
        showForm()
    }

    private func showForm() {
        let alert = UIAlertController(title: "Nueva Compra", message: "\n\n\n\n\n", preferredStyle: .alert)
        let wid: CGFloat = 270

        let provTF = UITextField()
        provTF.placeholder = "Proveedor"
        provTF.borderStyle = .roundedRect
        provTF.font = .systemFont(ofSize: 14)
        provTF.text = tempProv
        provTF.frame = CGRect(x: 8, y: 10, width: wid - 16, height: 32)
        alert.view.addSubview(provTF)

        let ivaTF = UITextField()
        ivaTF.placeholder = "IVA %"
        ivaTF.borderStyle = .roundedRect
        ivaTF.keyboardType = .decimalPad
        ivaTF.font = .systemFont(ofSize: 14)
        ivaTF.text = tempIva > 0 ? String(format: "%.0f", tempIva) : "0"
        ivaTF.frame = CGRect(x: 8, y: 48, width: wid - 16, height: 32)
        alert.view.addSubview(ivaTF)

        let itemsBtn = UIButton(type: .system)
        itemsBtn.setTitle(tempItems.isEmpty ? "+ Agregar Productos" : "\(tempItems.count) producto(s) - tocar para editar", for: .normal)
        itemsBtn.titleLabel?.font = .systemFont(ofSize: 13)
        itemsBtn.frame = CGRect(x: 8, y: 86, width: wid - 16, height: 32)
        
        itemsBtn.addAction(UIAction(handler: { [weak self, weak alert] _ in
            guard let self = self, let alert = alert else { return }
            self.tempProv = provTF.text ?? ""
            self.tempIva = Double(ivaTF.text?.replacingOccurrences(of: ",", with: ".") ?? "") ?? 0.0
            
            alert.dismiss(animated: true) { [weak self] in
                guard let self = self else { return }
                self.showItemPicker(currentItems: self.tempItems) { [weak self] picked in
                    guard let self = self else { return }
                    self.tempItems = picked
                    self.showForm()
                }
            }
        }), for: .touchUpInside)
        alert.view.addSubview(itemsBtn)

        let pagadoLabel = UILabel()
        pagadoLabel.text = "Pagado de Caja:"
        pagadoLabel.font = .systemFont(ofSize: 13)
        pagadoLabel.frame = CGRect(x: 8, y: 124, width: 150, height: 28)
        alert.view.addSubview(pagadoLabel)
        
        let pagadoSw = UISwitch()
        pagadoSw.isOn = tempPagado
        pagadoSw.frame = CGRect(x: wid - 70, y: 120, width: 51, height: 31)
        pagadoSw.addAction(UIAction(handler: { [weak self] _ in
            self?.tempPagado = pagadoSw.isOn
        }), for: .valueChanged)
        alert.view.addSubview(pagadoSw)

        alert.addAction(UIAlertAction(title: "Guardar", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let prov = provTF.text?.trimmingCharacters(in: .whitespaces) ?? ""
            guard !prov.isEmpty else { return }
            let iva = Double(ivaTF.text?.replacingOccurrences(of: ",", with: ".") ?? "") ?? 0
            let finalItems = self.tempItems
            let total = finalItems.reduce(0.0) { s, i in s + Double(i["cantidad"] as? Int ?? 0) * (i["precio_compra"] as? Double ?? 0) }
            let isPagado = pagadoSw.isOn
            guard !finalItems.isEmpty else { return }
            Task {
                do {
                    let data: [String: Any] = ["id": FirebaseService.nextId(in: self.compras), "proveedor": prov, "total": total, "iva": iva, "pagado": isPagado, "items": finalItems, "fecha": FirebaseService.nowString()]
                    try await self.fb.addToList("compras", item: data)
                    for it in finalItems {
                        if let pid = it["producto_id"] as? Int {
                            let prods = try await self.fb.getList("productos")
                            if let p = prods.first(where: { ($0["id"] as? Int) == pid }) {
                                let newStock = (p["stock_actual"] as? Int ?? 0) + (it["cantidad"] as? Int ?? 0)
                                let cost = it["precio_compra"] as? Double ?? 0; let pv = it["precio_venta"] as? Double ?? 0
                                try await self.fb.updateInList("productos", idValue: pid, updates: ["stock_actual": newStock, "precio_compra": cost, "precio_venta": pv])
                            }
                        }
                    }
                    if isPagado, let ab = (try await self.fb.getList("cajas")).first(where: { ($0["estado"] as? String) == "abierta" }), let cid = ab["id"] as? Int {
                        try await self.fb.updateInList("cajas", idValue: cid, updates: ["egresos": (ab["egresos"] as? Double ?? 0) + total])
                    }
                    self.loadData()
                } catch { print("Error save: \(error)") }
            }
        })
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        present(alert, animated: true)
    }

    private func showItemPicker(currentItems: [[String: Any]], completion: @escaping ([[String: Any]]) -> Void) {
        let vc = CompraItemPickerVC(productos: productos, items: currentItems, onDone: completion)
        let nav = UINavigationController(rootViewController: vc); nav.modalPresentationStyle = .pageSheet; present(nav, animated: true)
    }
}

class CompraItemPickerVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    private let tableView = UITableView(); private let searchBar = UISearchBar()
    private var allProds: [[String: Any]] = []; private var filtered: [[String: Any]] = []; private var selected: [[String: Any]] = []
    private let onDone: ([[String: Any]]) -> Void

    init(productos: [[String: Any]], items: [[String: Any]], onDone: @escaping ([[String: Any]]) -> Void) {
        self.allProds = productos; self.filtered = productos; self.selected = items; self.onDone = onDone
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad(); title = "Productos"; view.backgroundColor = UIColor(red: 0.95, green: 0.94, blue: 0.92, alpha: 1)
        let d = UIBarButtonItem(title: "Listo (\(selected.count))", style: .done, target: self, action: #selector(done))
        let s = UIBarButtonItem(image: UIImage(systemName: "barcode.viewfinder"), style: .plain, target: self, action: #selector(openScanner))
        navigationItem.rightBarButtonItems = [d, s]

        searchBar.delegate = self; searchBar.placeholder = "Buscar..."; searchBar.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(searchBar)
        tableView.dataSource = self; tableView.delegate = self; tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ic"); tableView.backgroundColor = .clear; tableView.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(tableView)
        NSLayoutConstraint.activate([searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor), searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor), tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor), tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor), tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor), tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange text: String) { filtered = text.isEmpty ? allProds : allProds.filter { ($0["nombre"] as? String ?? "").localizedCaseInsensitiveContains(text) }; tableView.reloadData() }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { filtered.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ic", for: indexPath); let p = filtered[indexPath.row]; let pid = p["id"] as? Int ?? 0
        if let ex = selected.first(where: { ($0["producto_id"] as? Int) == pid }) { cell.textLabel?.text = "✓ \(p["nombre"] as? String ?? "") — x\(ex["cantidad"] as? Int ?? 0)" }
        else { cell.textLabel?.text = "\(p["nombre"] as? String ?? "") — Stock: \(p["stock_actual"] as? Int ?? 0) | \(FirebaseService.formatMoney(p["precio_compra"] as? Double ?? 0))" }
        cell.textLabel?.font = .systemFont(ofSize: 12); cell.backgroundColor = .white; return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true); let p = filtered[indexPath.row]; let pid = p["id"] as? Int ?? 0; let name = p["nombre"] as? String ?? ""
        let a = UIAlertController(title: name, message: "Costo: \(FirebaseService.formatMoney(p["precio_compra"] as? Double ?? 0))", preferredStyle: .alert)
        a.addTextField { tf in tf.placeholder = "Cantidad"; tf.keyboardType = .numberPad; tf.text = "1" }
        a.addTextField { tf in tf.placeholder = "Precio Compra"; tf.keyboardType = .decimalPad; tf.text = "\(p["precio_compra"] as? Double ?? 0)" }
        a.addTextField { tf in tf.placeholder = "Precio Venta"; tf.keyboardType = .decimalPad; tf.text = "\(p["precio_venta"] as? Double ?? 0)" }
        a.addAction(UIAlertAction(title: "Agregar", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let q = Int(a.textFields?[0].text ?? "") ?? 1
            let pc = Double(a.textFields?[1].text?.replacingOccurrences(of: ",", with: ".") ?? "") ?? 0
            let pv = Double(a.textFields?[2].text?.replacingOccurrences(of: ",", with: ".") ?? "") ?? 0
            self.selected.removeAll(where: { ($0["producto_id"] as? Int) == pid })
            self.selected.append(["producto_id": pid, "nombre": name, "cantidad": q, "precio_compra": pc, "precio_venta": pv])
            self.tableView.reloadData(); self.navigationItem.rightBarButtonItem?.title = "Listo (\(self.selected.count))"
        })
        a.addAction(UIAlertAction(title: "Cancelar", style: .cancel)); present(a, animated: true)
    }
    @objc private func openScanner() {
        present(BarcodeScannerViewController { [weak self] code in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let p = self.allProds.first(where: { ($0["codigo"] as? String) == code }) {
                    let pid = p["id"] as? Int ?? 0; let nm = p["nombre"] as? String ?? ""
                    let c = p["precio_compra"] as? Double ?? 0; let v = p["precio_venta"] as? Double ?? 0
                    self.selected.removeAll(where: { ($0["producto_id"] as? Int) == pid })
                    self.selected.append(["producto_id": pid, "nombre": nm, "cantidad": 1, "precio_compra": c, "precio_venta": v])
                    self.tableView.reloadData()
                    self.navigationItem.rightBarButtonItems?[0].title = "Listo (\(self.selected.count))"
                } else {
                    let alert = UIAlertController(title: "Código no encontrado", message: "No hay producto con código: \(code)\n¿Desea usar este código?", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }, animated: true)
    }

    @objc private func done() { dismiss(animated: true) { self.onDone(self.selected) } }
}
