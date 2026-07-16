import UIKit

class POSViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {

    private let searchBar = UISearchBar()
    private let productosTable = UITableView()
    private let cartView = UIView()
    private let cartTable = UITableView()
    private let totalLabel = UILabel()
    private let checkoutBtn = UIButton(type: .system)
    private let clearBtn = UIButton(type: .system)

    private var productos: [[String: Any]] = []
    private var filtered: [[String: Any]] = []
    private var cart: [(producto: [String: Any], cantidad: Int)] = []
    private let fb = FirebaseService.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Ventas Super"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "barcode.viewfinder"), style: .plain, target: self, action: #selector(openScanner))

        searchBar.delegate = self; searchBar.placeholder = "Buscar producto..."; searchBar.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(searchBar)

        productosTable.dataSource = self; productosTable.delegate = self; productosTable.register(POSProductCell.self, forCellReuseIdentifier: "prodCell")
        productosTable.backgroundColor = .clear; productosTable.separatorStyle = .none; productosTable.rowHeight = 60
        productosTable.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(productosTable)

        cartView.backgroundColor = .secondarySystemGroupedBackground; cartView.layer.cornerRadius = 16
        cartView.layer.shadowColor = UIColor.black.cgColor; cartView.layer.shadowOpacity = 0.05; cartView.layer.shadowRadius = 8; cartView.layer.shadowOffset = CGSize(width: 0, height: -2)
        cartView.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(cartView)
        
        let cartTitle = UILabel(); cartTitle.text = "Carrito de Compras"; cartTitle.font = UIFont.boldSystemFont(ofSize: 15); cartTitle.textColor = .darkGray; cartTitle.translatesAutoresizingMaskIntoConstraints = false; cartView.addSubview(cartTitle)

        cartTable.dataSource = self; cartTable.delegate = self; cartTable.register(POSCartCell.self, forCellReuseIdentifier: "cartCell")
        cartTable.backgroundColor = .clear; cartTable.separatorStyle = .none; cartTable.rowHeight = 44
        cartTable.translatesAutoresizingMaskIntoConstraints = false; cartView.addSubview(cartTable)

        totalLabel.font = UIFont.boldSystemFont(ofSize: 22); totalLabel.textColor = UIColor(red: 0.1, green: 0.3, blue: 0.24, alpha: 1); totalLabel.textAlignment = .center; totalLabel.text = "$0"; totalLabel.translatesAutoresizingMaskIntoConstraints = false; cartView.addSubview(totalLabel)

        clearBtn.setTitle("Limpiar", for: .normal); clearBtn.setTitleColor(.systemRed, for: .normal); clearBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        clearBtn.addTarget(self, action: #selector(clearCart), for: .touchUpInside)
        
        checkoutBtn.setTitle("Cobrar", for: .normal); checkoutBtn.backgroundColor = UIColor(red: 0.18, green: 0.48, blue: 0.37, alpha: 1); checkoutBtn.setTitleColor(.white, for: .normal); checkoutBtn.layer.cornerRadius = 12; checkoutBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        checkoutBtn.addTarget(self, action: #selector(checkout), for: .touchUpInside)

        let btnRow = UIStackView(arrangedSubviews: [clearBtn, checkoutBtn]); btnRow.axis = .horizontal; btnRow.spacing = 12; btnRow.distribution = .fillEqually; btnRow.translatesAutoresizingMaskIntoConstraints = false; cartView.addSubview(btnRow)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor), searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            productosTable.topAnchor.constraint(equalTo: searchBar.bottomAnchor), productosTable.leadingAnchor.constraint(equalTo: view.leadingAnchor), productosTable.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cartView.topAnchor.constraint(equalTo: productosTable.bottomAnchor, constant: 8), cartView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8), cartView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8), cartView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8), cartView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.4),
            cartTitle.topAnchor.constraint(equalTo: cartView.topAnchor, constant: 12), cartTitle.leadingAnchor.constraint(equalTo: cartView.leadingAnchor, constant: 12),
            cartTable.topAnchor.constraint(equalTo: cartTitle.bottomAnchor, constant: 6), cartTable.leadingAnchor.constraint(equalTo: cartView.leadingAnchor, constant: 4), cartTable.trailingAnchor.constraint(equalTo: cartView.trailingAnchor, constant: -4),
            totalLabel.topAnchor.constraint(equalTo: cartTable.bottomAnchor, constant: 6), totalLabel.leadingAnchor.constraint(equalTo: cartView.leadingAnchor, constant: 12), totalLabel.trailingAnchor.constraint(equalTo: cartView.trailingAnchor, constant: -12),
            btnRow.topAnchor.constraint(equalTo: totalLabel.bottomAnchor, constant: 8), btnRow.leadingAnchor.constraint(equalTo: cartView.leadingAnchor, constant: 12), btnRow.trailingAnchor.constraint(equalTo: cartView.trailingAnchor, constant: -12), btnRow.bottomAnchor.constraint(equalTo: cartView.bottomAnchor, constant: -12), btnRow.heightAnchor.constraint(equalToConstant: 44)
        ])

        loadProductos()
    }

    private func loadProductos() { Task { do { productos = try await fb.getList("productos"); filtered = productos; productosTable.reloadData() } catch { print("Error: \(error)") } } }

    func searchBar(_ searchBar: UISearchBar, textDidChange text: String) {
        if text.isEmpty { filtered = productos }
        else { filtered = productos.filter { ($0["nombre"] as? String ?? "").localizedCaseInsensitiveContains(text) || ($0["codigo"] as? String ?? "").localizedCaseInsensitiveContains(text) } }
        productosTable.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { tableView == productosTable ? filtered.count : cart.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == productosTable {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "prodCell", for: indexPath) as? POSProductCell else {
                return UITableViewCell()
            }
            cell.configure(with: filtered[indexPath.row])
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "cartCell", for: indexPath) as? POSCartCell else {
                return UITableViewCell()
            }
            cell.configure(with: cart[indexPath.row])
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if tableView == productosTable {
            let p = filtered[indexPath.row]
            let alert = UIAlertController(title: "Cantidad", message: "¿Cuántos \"\(p["nombre"] as? String ?? "")\"?", preferredStyle: .alert)
            alert.addTextField { tf in tf.placeholder = "Cantidad"; tf.keyboardType = .numberPad; tf.text = "1" }
            alert.addAction(UIAlertAction(title: "Agregar", style: .default) { [weak self] _ in
                guard let self = self else { return }
                let qty = Int(alert.textFields?.first?.text ?? "") ?? 1
                if let idx = self.cart.firstIndex(where: { ($0.producto["id"] as? Int) == (p["id"] as? Int) }) { self.cart[idx].cantidad += qty }
                else { self.cart.append((p, qty)) }
                self.updateTotal(); self.cartTable.reloadData()
            })
            alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
            present(alert, animated: true)
        } else {
            cart.remove(at: indexPath.row); updateTotal(); cartTable.reloadData()
        }
    }

    private func updateTotal() {
        let total = cart.reduce(0.0) { $0 + ($1.producto["precio_venta"] as? Double ?? 0) * Double($1.cantidad) }
        totalLabel.text = FirebaseService.formatMoney(total)
    }

    @objc private func clearCart() { cart.removeAll(); updateTotal(); cartTable.reloadData() }

    @objc private func checkout() {
        guard !cart.isEmpty else { return }
        let total = cart.reduce(0.0) { $0 + ($1.producto["precio_venta"] as? Double ?? 0) * Double($1.cantidad) }
        let alert = UIAlertController(title: "Confirmar Venta", message: "Total: \(FirebaseService.formatMoney(total))", preferredStyle: .alert)
        alert.addTextField { tf in tf.placeholder = "Efectivo recibido (opcional)"; tf.keyboardType = .decimalPad }
        alert.addAction(UIAlertAction(title: "Cobrar", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let recibido = Double(alert.textFields?.first?.text?.replacingOccurrences(of: ",", with: ".") ?? "") ?? total
            Task {
                do {
                    let cajas = try await self.fb.getList("cajas")
                    guard cajas.contains(where: { ($0["estado"] as? String) == "abierta" }) else {
                        await MainActor.run { self.showAlert("Error", "No hay caja abierta") }; return
                    }
                    let ventas = try await self.fb.getList("ventas")
                    let nextId = FirebaseService.nextId(in: ventas)
                    let items: [[String: Any]] = self.cart.map {
                        ["producto_id": $0.producto["id"] as? Int ?? 0, "nombre": $0.producto["nombre"] as? String ?? "", "cantidad": $0.cantidad, "precio_venta": $0.producto["precio_venta"] as? Double ?? 0, "precio_compra": $0.producto["precio_compra"] as? Double ?? 0]
                    }
                    let v: [String: Any] = ["id": nextId, "fecha": FirebaseService.nowString(), "total": total, "recibido": recibido, "cambio": max(0, recibido - total), "items": items, "cliente": "Mostrador", "estado": "completada", "tipo": "super"]
                    try await self.fb.addToList("ventas", item: v)
                    for item in self.cart {
                        if let pid = item.producto["id"] as? Int {
                            let stock = max(0, (item.producto["stock_actual"] as? Int ?? 0) - item.cantidad)
                            try await self.fb.updateInList("productos", idValue: pid, updates: ["stock_actual": stock])
                        }
                    }
                    if let abierta = cajas.first(where: { ($0["estado"] as? String) == "abierta" }), let cid = abierta["id"] as? Int {
                        try await self.fb.updateInList("cajas", idValue: cid, updates: ["ingresos": (abierta["ingresos"] as? Double ?? 0) + total])
                    }
                    await MainActor.run { self.clearCart() }
                } catch { print("Error: \(error)") }
            }
        })
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        present(alert, animated: true)
    }

    private func showAlert(_ title: String, _ msg: String) {
        let a = UIAlertController(title: title, message: msg, preferredStyle: .alert); a.addAction(UIAlertAction(title: "OK", style: .default)); present(a, animated: true)
    }

    @objc private func openScanner() {
        present(BarcodeScannerViewController { [weak self] code in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let p = self.productos.first(where: { ($0["codigo"] as? String) == code }) {
                    if let idx = self.cart.firstIndex(where: { ($0.producto["id"] as? Int) == (p["id"] as? Int) }) { self.cart[idx].cantidad += 1 }
                    else { self.cart.append((p, 1)) }
                    self.updateTotal(); self.cartTable.reloadData()
                }
            }
        }, animated: true)
    }
}

// MARK: - POS Product Cell
class POSProductCell: UITableViewCell {
    private let cardView = UIView()
    private let nameLabel = UILabel()
    private let priceLabel = UILabel()
    private let stockLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupCell() {
        backgroundColor = .clear
        selectionStyle = .none
        
        cardView.backgroundColor = .secondarySystemGroupedBackground
        cardView.layer.cornerRadius = 10
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.03
        cardView.layer.shadowRadius = 3
        cardView.layer.shadowOffset = CGSize(width: 0, height: 1)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)

        nameLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        nameLabel.textColor = .darkText
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(nameLabel)

        stockLabel.font = .systemFont(ofSize: 11)
        stockLabel.textColor = .gray
        stockLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(stockLabel)

        priceLabel.font = .systemFont(ofSize: 14, weight: .bold)
        priceLabel.textColor = UIColor(red: 0.1, green: 0.3, blue: 0.24, alpha: 1)
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(priceLabel)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),

            nameLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 10),
            nameLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 10),
            nameLabel.trailingAnchor.constraint(equalTo: priceLabel.leadingAnchor, constant: -8),

            stockLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            stockLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            stockLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -10),

            priceLabel.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            priceLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10),
        ])
    }

    func configure(with p: [String: Any]) {
        nameLabel.text = p["nombre"] as? String ?? ""
        let stock = p["stock_actual"] as? Int ?? 0
        stockLabel.text = "Disponibles: \(stock)"
        stockLabel.textColor = stock <= (p["stock_minimo"] as? Int ?? 0) ? .systemRed : .gray
        priceLabel.text = FirebaseService.formatMoney(p["precio_venta"] as? Double ?? 0)
    }
}

// MARK: - POS Cart Cell
class POSCartCell: UITableViewCell {
    private let container = UIView()
    private let nameLabel = UILabel()
    private let qtyBadge = UIView()
    private let qtyLabel = UILabel()
    private let priceLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupCell() {
        backgroundColor = .clear
        selectionStyle = .none

        container.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1)
        container.layer.cornerRadius = 8
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)

        nameLabel.font = .systemFont(ofSize: 13, weight: .medium)
        nameLabel.textColor = .darkText
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(nameLabel)

        qtyBadge.backgroundColor = UIColor.white
        qtyBadge.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.4).cgColor
        qtyBadge.layer.borderWidth = 1
        qtyBadge.layer.cornerRadius = 6
        qtyBadge.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(qtyBadge)

        qtyLabel.font = .systemFont(ofSize: 11, weight: .bold)
        qtyLabel.textColor = .darkGray
        qtyLabel.textAlignment = .center
        qtyLabel.translatesAutoresizingMaskIntoConstraints = false
        qtyBadge.addSubview(qtyLabel)

        priceLabel.font = .systemFont(ofSize: 13, weight: .bold)
        priceLabel.textColor = .darkText
        priceLabel.textAlignment = .right
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(priceLabel)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),

            qtyBadge.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            qtyBadge.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            qtyBadge.widthAnchor.constraint(equalToConstant: 32),
            qtyBadge.heightAnchor.constraint(equalToConstant: 22),

            qtyLabel.centerXAnchor.constraint(equalTo: qtyBadge.centerXAnchor),
            qtyLabel.centerYAnchor.constraint(equalTo: qtyBadge.centerYAnchor),

            nameLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: qtyBadge.trailingAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: priceLabel.leadingAnchor, constant: -8),

            priceLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            priceLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            priceLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 80)
        ])
    }

    func configure(with item: (producto: [String: Any], cantidad: Int)) {
        nameLabel.text = item.producto["nombre"] as? String ?? ""
        qtyLabel.text = "x\(item.cantidad)"
        let price = (item.producto["precio_venta"] as? Double ?? 0) * Double(item.cantidad)
        priceLabel.text = FirebaseService.formatMoney(price)
    }
}
