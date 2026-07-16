import UIKit

class ConsumosViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let tableView = UITableView()
    private var consumos: [[String: Any]] = []
    private var productos: [[String: Any]] = []
    private let fb = FirebaseService.shared

    private var tempProductoId: Int? = nil
    private var tempProductoNombre = ""
    private var tempCantidad = "1"
    private var tempFecha = FirebaseService.todayString()
    private var tempMotivo = ""
    private var editingConsumo: [String: Any]? = nil
    private var productoSeleccionado: [String: Any]? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground; title = "Consumos Propios"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addConsumo))
        tableView.dataSource = self; tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.backgroundColor = .clear; tableView.separatorStyle = .none; tableView.rowHeight = 76
        tableView.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(tableView)
        NSLayoutConstraint.activate([tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor), tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor), tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
        loadData()
    }

    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); loadData() }

    private func loadData() {
        Task { do {
            async let c = fb.getList("autoconsumos")
            async let p = fb.getList("productos")
            (consumos, productos) = try await (c, p)
            await MainActor.run { tableView.reloadData() }
        } catch { print("Error: \(error)") } }
    }

    // MARK: - TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { consumos.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let c = consumos[indexPath.row]
        let prod = c["producto_nombre"] as? String ?? "?"
        let cant = c["cantidad"] as? Int ?? 0
        let fecha = c["fecha"] as? String ?? ""
        let motivo = c["motivo"] as? String ?? ""
        cell.backgroundColor = .clear; cell.selectionStyle = .none

        cell.contentView.subviews.forEach { $0.removeFromSuperview() }

        let card = UIView()
        card.backgroundColor = .secondarySystemGroupedBackground; card.layer.cornerRadius = 12
        card.layer.shadowColor = UIColor.black.cgColor; card.layer.shadowOpacity = 0.03
        card.layer.shadowRadius = 4; card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.translatesAutoresizingMaskIntoConstraints = false; cell.contentView.addSubview(card)
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 4),
            card.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -4),
            card.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 10),
            card.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -10)
        ])

        let qtyPill = UILabel()
        qtyPill.text = "×\(cant)"; qtyPill.font = .systemFont(ofSize: 16, weight: .bold)
        qtyPill.textColor = UIColor(red: 0.08, green: 0.32, blue: 0.25, alpha: 1)
        qtyPill.translatesAutoresizingMaskIntoConstraints = false; card.addSubview(qtyPill)

        let nameLbl = UILabel()
        nameLbl.text = prod; nameLbl.font = .systemFont(ofSize: 14, weight: .semibold)
        nameLbl.textColor = .label; nameLbl.translatesAutoresizingMaskIntoConstraints = false; card.addSubview(nameLbl)

        let detailLbl = UILabel()
        var parts: [String] = []
        if !fecha.isEmpty { parts.append(String(fecha.prefix(10))) }
        if !motivo.isEmpty { parts.append(motivo) }
        detailLbl.text = parts.joined(separator: " · "); detailLbl.font = .systemFont(ofSize: 11)
        detailLbl.textColor = .secondaryLabel; detailLbl.numberOfLines = 1
        detailLbl.translatesAutoresizingMaskIntoConstraints = false; card.addSubview(detailLbl)

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = .tertiaryLabel; chevron.translatesAutoresizingMaskIntoConstraints = false; card.addSubview(chevron)

        NSLayoutConstraint.activate([
            qtyPill.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            qtyPill.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            qtyPill.widthAnchor.constraint(greaterThanOrEqualToConstant: 44),
            nameLbl.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            nameLbl.leadingAnchor.constraint(equalTo: qtyPill.trailingAnchor, constant: 12),
            nameLbl.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -8),
            detailLbl.topAnchor.constraint(equalTo: nameLbl.bottomAnchor, constant: 3),
            detailLbl.leadingAnchor.constraint(equalTo: nameLbl.leadingAnchor),
            detailLbl.trailingAnchor.constraint(equalTo: nameLbl.trailingAnchor),
            detailLbl.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
            chevron.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            chevron.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            chevron.widthAnchor.constraint(equalToConstant: 8), chevron.heightAnchor.constraint(equalToConstant: 14),
        ])

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        editConsumo(consumos[indexPath.row])
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let del = UIContextualAction(style: .destructive, title: "Eliminar") { [weak self] _, _, done in
            self?.deleteConsumo(self!.consumos[indexPath.row])
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [del])
    }

    // MARK: - Actions
    @objc private func addConsumo() {
        tempProductoId = nil; tempProductoNombre = ""; tempCantidad = "1"
        tempFecha = FirebaseService.todayString(); tempMotivo = ""; editingConsumo = nil
        productoSeleccionado = nil
        showForm()
    }

    private func editConsumo(_ c: [String: Any]) {
        editingConsumo = c; tempProductoId = c["producto_id"] as? Int
        tempProductoNombre = c["producto_nombre"] as? String ?? ""
        tempCantidad = "\(c["cantidad"] as? Int ?? 1)"
        tempFecha = c["fecha"] as? String ?? FirebaseService.todayString()
        tempMotivo = c["motivo"] as? String ?? ""
        productoSeleccionado = c
        showForm()
    }

    // MARK: - Form
    private func showForm() {
        let vc = ConsumoFormVC()
        vc.productos = productos
        vc.productoSeleccionado = productoSeleccionado
        vc.tempCantidad = tempCantidad
        vc.tempFecha = tempFecha
        vc.tempMotivo = tempMotivo
        vc.editingConsumo = editingConsumo
        vc.onSave = { [weak self] pid, cant, fecha, motivo in
            self?.tempProductoId = pid
            self?.tempCantidad = "\(cant)"
            self?.tempFecha = fecha
            self?.tempMotivo = motivo
            self?.saveConsumo(productoId: pid, cantidad: cant, fecha: fecha, motivo: motivo)
        }
        vc.onDelete = { [weak self] in
            if let ec = self?.editingConsumo { self?.deleteConsumo(ec) }
        }
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }

    // MARK: - Save / Delete
    private func saveConsumo(productoId: Int, cantidad: Int, fecha: String, motivo: String) {
        Task {
            do {
                let prods = try await fb.getList("productos")
                let prodNombre = prods.first(where: { ($0["id"] as? Int) == productoId })?["nombre"] as? String ?? ""
                let now = FirebaseService.nowString()

                if let old = editingConsumo {
                    let oldId = old["id"] as? Int ?? 0
                    let oldPid = old["producto_id"] as? Int ?? 0
                    let oldQty = old["cantidad"] as? Int ?? 0

                    if let oldProd = prods.first(where: { ($0["id"] as? Int) == oldPid }) {
                        var stock = (oldProd["stock_actual"] as? Int ?? 0) + oldQty
                        if oldPid == productoId { stock = max(0, stock - cantidad) }
                        try await fb.updateInList("productos", idValue: oldPid, updates: ["stock_actual": stock])
                    }
                    if oldPid != productoId {
                        if let newProd = prods.first(where: { ($0["id"] as? Int) == productoId }) {
                            let stock = max(0, (newProd["stock_actual"] as? Int ?? 0) - cantidad)
                            try await fb.updateInList("productos", idValue: productoId, updates: ["stock_actual": stock])
                        }
                    }
                    try await fb.updateInList("autoconsumos", idValue: oldId, updates: [
                        "producto_id": productoId, "producto_nombre": prodNombre,
                        "cantidad": cantidad, "fecha": fecha, "motivo": motivo, "updated_at": now
                    ])
                } else {
                    if let prod = prods.first(where: { ($0["id"] as? Int) == productoId }) {
                        let stock = max(0, (prod["stock_actual"] as? Int ?? 0) - cantidad)
                        try await fb.updateInList("productos", idValue: productoId, updates: ["stock_actual": stock])
                    }
                    let newId = FirebaseService.nextId(in: consumos)
                    try await fb.addToList("autoconsumos", item: [
                        "id": newId, "producto_id": productoId, "producto_nombre": prodNombre,
                        "cantidad": cantidad, "fecha": fecha, "motivo": motivo,
                        "created_at": now, "updated_at": now
                    ])
                }
                await MainActor.run {
                    self.editingConsumo = nil
                    self.productoSeleccionado = nil
                    self.loadData()
                    self.dismiss(animated: true)
                }
            } catch { print("Error save: \(error)") }
        }
    }

    private func deleteConsumo(_ c: [String: Any]) {
        Task { do {
            if let pid = c["producto_id"] as? Int, let qty = c["cantidad"] as? Int {
                let prods = try await fb.getList("productos")
                if let prod = prods.first(where: { ($0["id"] as? Int) == pid }) {
                    let restored = (prod["stock_actual"] as? Int ?? 0) + qty
                    try await fb.updateInList("productos", idValue: pid, updates: ["stock_actual": restored])
                }
            }
            try await fb.removeFromList("autoconsumos", idValue: c["id"] as? Int ?? 0)
            await MainActor.run { loadData() }
        } catch { print("Error delete: \(error)") } }
    }
}

// MARK: - Form View Controller
class ConsumoFormVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {

    var productos: [[String: Any]] = []
    var productoSeleccionado: [String: Any]?
    var tempCantidad = "1"
    var tempFecha = FirebaseService.todayString()
    var tempMotivo = ""
    var editingConsumo: [String: Any]?
    var onSave: ((Int, Int, String, String) -> Void)?
    var onDelete: (() -> Void)?

    private let searchBar = UISearchBar()
    private let resultsTable = UITableView()
    private let cantField = UITextField()
    private let fechaPicker = UIDatePicker()
    private let fechaField = UITextField()
    private let motivoField = UITextField()
    private var filteredProds: [[String: Any]] = []
    private var isSearching = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = editingConsumo == nil ? "Nuevo Consumo" : "Editar Consumo"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "barcode.viewfinder"), style: .plain, target: self, action: #selector(abrirScanner))
        setupUI()
        if let sel = productoSeleccionado {
            searchBar.text = sel["producto_nombre"] as? String ?? sel["nombre"] as? String ?? ""
        }
    }

    private func setupUI() {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(scrollView)
        NSLayoutConstraint.activate([scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor), scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor), scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])

        let content = UIView(); content.translatesAutoresizingMaskIntoConstraints = false; scrollView.addSubview(content)
        NSLayoutConstraint.activate([content.topAnchor.constraint(equalTo: scrollView.topAnchor), content.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor), content.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor), content.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor), content.widthAnchor.constraint(equalTo: scrollView.widthAnchor)])

        // Product search
        searchBar.delegate = self; searchBar.placeholder = "Buscar producto..."
        searchBar.translatesAutoresizingMaskIntoConstraints = false; content.addSubview(searchBar)

        resultsTable.dataSource = self; resultsTable.delegate = self
        resultsTable.register(UITableViewCell.self, forCellReuseIdentifier: "pr")
        resultsTable.isHidden = true; resultsTable.layer.borderColor = UIColor.separator.cgColor
        resultsTable.layer.borderWidth = 0.5; resultsTable.layer.cornerRadius = 8
        resultsTable.translatesAutoresizingMaskIntoConstraints = false; content.addSubview(resultsTable)

        // Selected product card
        let selectedCard = UIView()
        selectedCard.backgroundColor = UIColor(red: 0.08, green: 0.32, blue: 0.25, alpha: 0.06)
        selectedCard.layer.cornerRadius = 12; selectedCard.layer.borderWidth = 1
        selectedCard.layer.borderColor = UIColor(red: 0.08, green: 0.32, blue: 0.25, alpha: 0.2).cgColor
        selectedCard.translatesAutoresizingMaskIntoConstraints = false; content.addSubview(selectedCard)
        selectedCard.tag = 99

        let selIcon = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        selIcon.tintColor = UIColor(red: 0.08, green: 0.32, blue: 0.25, alpha: 1)
        selIcon.translatesAutoresizingMaskIntoConstraints = false; selectedCard.addSubview(selIcon)
        let selLbl = UILabel()
        selLbl.text = productoSeleccionado != nil ? (productoSeleccionado!["producto_nombre"] as? String ?? productoSeleccionado!["nombre"] as? String ?? "—") : "Ningún producto seleccionado"
        selLbl.font = .systemFont(ofSize: 15, weight: .semibold); selLbl.textColor = .label
        selLbl.translatesAutoresizingMaskIntoConstraints = false; selectedCard.addSubview(selLbl)
        selLbl.tag = 100

        if let p = productoSeleccionado {
            let stockLbl = UILabel()
            stockLbl.text = "Stock: \(p["stock_actual"] as? Int ?? 0)"
            stockLbl.font = .systemFont(ofSize: 12); stockLbl.textColor = .secondaryLabel
            stockLbl.translatesAutoresizingMaskIntoConstraints = false; selectedCard.addSubview(stockLbl)
            NSLayoutConstraint.activate([stockLbl.topAnchor.constraint(equalTo: selLbl.bottomAnchor, constant: 2), stockLbl.leadingAnchor.constraint(equalTo: selLbl.leadingAnchor)])
        }

        NSLayoutConstraint.activate([
            selIcon.leadingAnchor.constraint(equalTo: selectedCard.leadingAnchor, constant: 12),
            selIcon.centerYAnchor.constraint(equalTo: selectedCard.centerYAnchor),
            selIcon.widthAnchor.constraint(equalToConstant: 22), selIcon.heightAnchor.constraint(equalToConstant: 22),
            selLbl.leadingAnchor.constraint(equalTo: selIcon.trailingAnchor, constant: 8),
            selLbl.trailingAnchor.constraint(equalTo: selectedCard.trailingAnchor, constant: -12),
            selLbl.centerYAnchor.constraint(equalTo: selectedCard.centerYAnchor)
        ])

        // Form fields
        let formStack = UIStackView(); formStack.axis = .vertical; formStack.spacing = 14
        formStack.translatesAutoresizingMaskIntoConstraints = false; content.addSubview(formStack)

        formStack.addArrangedSubview(buildField(label: "Cantidad *", field: cantField, placeholder: "1", keyboard: .numberPad))
        cantField.text = tempCantidad

        formStack.addArrangedSubview(buildDateField())

        formStack.addArrangedSubview(buildField(label: "Motivo", field: motivoField, placeholder: "Ej: Consumo personal"))
        motivoField.text = tempMotivo

        // Buttons
        let btnStack = UIStackView(); btnStack.axis = .horizontal; btnStack.spacing = 10; btnStack.distribution = .fillEqually
        btnStack.translatesAutoresizingMaskIntoConstraints = false; content.addSubview(btnStack)

        let saveBtn = UIButton(type: .system)
        saveBtn.setTitle(editingConsumo == nil ? "Guardar Consumo" : "Actualizar", for: .normal)
        saveBtn.backgroundColor = UIColor(red: 0.08, green: 0.32, blue: 0.25, alpha: 1)
        saveBtn.setTitleColor(.white, for: .normal); saveBtn.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        saveBtn.layer.cornerRadius = 12; saveBtn.heightAnchor.constraint(equalToConstant: 48).isActive = true
        saveBtn.addTarget(self, action: #selector(guardar), for: .touchUpInside)
        btnStack.addArrangedSubview(saveBtn)

        if editingConsumo != nil {
            let delBtn = UIButton(type: .system)
            delBtn.setTitle("Eliminar", for: .normal)
            delBtn.backgroundColor = .systemRed; delBtn.setTitleColor(.white, for: .normal)
            delBtn.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
            delBtn.layer.cornerRadius = 12; delBtn.heightAnchor.constraint(equalToConstant: 48).isActive = true
            delBtn.addTarget(self, action: #selector(eliminarTapped), for: .touchUpInside)
            btnStack.addArrangedSubview(delBtn)
        }

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: content.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            resultsTable.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            resultsTable.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 8),
            resultsTable.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -8),
            resultsTable.heightAnchor.constraint(equalToConstant: 180),
            selectedCard.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 10),
            selectedCard.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 8),
            selectedCard.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -8),
            selectedCard.heightAnchor.constraint(equalToConstant: 52),
            formStack.topAnchor.constraint(equalTo: selectedCard.bottomAnchor, constant: 16),
            formStack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 16),
            formStack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -16),
            btnStack.topAnchor.constraint(equalTo: formStack.bottomAnchor, constant: 24),
            btnStack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 16),
            btnStack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -16),
            btnStack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -30),
        ])
    }

    private func buildField(label: String, field: UITextField, placeholder: String = "", keyboard: UIKeyboardType = .default) -> UIView {
        let v = UIView()
        let lbl = UILabel(); lbl.text = label; lbl.font = .systemFont(ofSize: 12, weight: .semibold); lbl.textColor = .secondaryLabel
        lbl.translatesAutoresizingMaskIntoConstraints = false; v.addSubview(lbl)
        field.placeholder = placeholder; field.borderStyle = .roundedRect; field.font = .systemFont(ofSize: 15)
        field.keyboardType = keyboard; field.translatesAutoresizingMaskIntoConstraints = false; v.addSubview(field)
        NSLayoutConstraint.activate([
            lbl.topAnchor.constraint(equalTo: v.topAnchor), lbl.leadingAnchor.constraint(equalTo: v.leadingAnchor),
            field.topAnchor.constraint(equalTo: lbl.bottomAnchor, constant: 4),
            field.leadingAnchor.constraint(equalTo: v.leadingAnchor), field.trailingAnchor.constraint(equalTo: v.trailingAnchor),
            field.bottomAnchor.constraint(equalTo: v.bottomAnchor), field.heightAnchor.constraint(equalToConstant: 40)
        ])
        return v
    }

    private func buildDateField() -> UIView {
        let v = UIView()
        let lbl = UILabel(); lbl.text = "Fecha"; lbl.font = .systemFont(ofSize: 12, weight: .semibold); lbl.textColor = .secondaryLabel
        lbl.translatesAutoresizingMaskIntoConstraints = false; v.addSubview(lbl)
        fechaField.borderStyle = .roundedRect; fechaField.font = .systemFont(ofSize: 15)
        fechaField.translatesAutoresizingMaskIntoConstraints = false; v.addSubview(fechaField)
        fechaPicker.datePickerMode = .date; fechaPicker.preferredDatePickerStyle = .compact
        fechaPicker.translatesAutoresizingMaskIntoConstraints = false; v.addSubview(fechaPicker)
        fechaPicker.addTarget(self, action: #selector(fechaChanged), for: .valueChanged)

        if let d = ISO8601DateFormatter().date(from: tempFecha + "T00:00:00Z") ?? nil {
            fechaPicker.date = d
        } else {
            let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
            if let d = df.date(from: tempFecha) { fechaPicker.date = d }
        }
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        fechaField.text = df.string(from: fechaPicker.date)

        NSLayoutConstraint.activate([
            lbl.topAnchor.constraint(equalTo: v.topAnchor), lbl.leadingAnchor.constraint(equalTo: v.leadingAnchor),
            fechaField.topAnchor.constraint(equalTo: lbl.bottomAnchor, constant: 4),
            fechaField.leadingAnchor.constraint(equalTo: v.leadingAnchor), fechaField.trailingAnchor.constraint(equalTo: fechaPicker.leadingAnchor, constant: -8),
            fechaField.bottomAnchor.constraint(equalTo: v.bottomAnchor), fechaField.heightAnchor.constraint(equalToConstant: 40),
            fechaPicker.centerYAnchor.constraint(equalTo: fechaField.centerYAnchor),
            fechaPicker.trailingAnchor.constraint(equalTo: v.trailingAnchor),
        ])
        return v
    }

    @objc private func fechaChanged() {
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        fechaField.text = df.string(from: fechaPicker.date)
    }

    // MARK: - Search
    func searchBar(_ searchBar: UISearchBar, textDidChange text: String) {
        let q = text.trimmingCharacters(in: .whitespaces).lowercased()
        if q.isEmpty {
            filteredProds = []; resultsTable.isHidden = true; isSearching = false
        } else {
            isSearching = true
            filteredProds = productos.filter { p in
                let nom = (p["nombre"] as? String ?? "").lowercased()
                let cod = (p["codigo"] as? String ?? "").lowercased()
                return nom.contains(q) || cod.contains(q)
            }
            resultsTable.isHidden = filteredProds.isEmpty
        }
        resultsTable.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { filteredProds.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "pr", for: indexPath)
        let p = filteredProds[indexPath.row]
        cell.textLabel?.text = "\(p["nombre"] as? String ?? "") · Stock: \(p["stock_actual"] as? Int ?? 0)"
        cell.textLabel?.font = .systemFont(ofSize: 13)
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let p = filteredProds[indexPath.row]
        productoSeleccionado = p
        searchBar.text = p["nombre"] as? String ?? ""
        searchBar.resignFirstResponder()
        resultsTable.isHidden = true; isSearching = false

        if let card = view.viewWithTag(99), let lbl = card.viewWithTag(100) as? UILabel {
            lbl.text = p["nombre"] as? String ?? ""
            card.subviews.filter { $0 is UILabel && $0.tag != 100 }.forEach { $0.removeFromSuperview() }
            let stockLbl = UILabel(); stockLbl.text = "Stock: \(p["stock_actual"] as? Int ?? 0)"
            stockLbl.font = .systemFont(ofSize: 12); stockLbl.textColor = .secondaryLabel
            stockLbl.translatesAutoresizingMaskIntoConstraints = false; card.addSubview(stockLbl)
            NSLayoutConstraint.activate([stockLbl.topAnchor.constraint(equalTo: lbl.bottomAnchor, constant: 2), stockLbl.leadingAnchor.constraint(equalTo: lbl.leadingAnchor)])
        }
    }

    // MARK: - Actions
    @objc private func guardar() {
        guard let prod = productoSeleccionado, let pid = prod["id"] as? Int else {
            let a = UIAlertController(title: "Error", message: "Seleccione un producto", preferredStyle: .alert)
            a.addAction(UIAlertAction(title: "OK", style: .default)); present(a, animated: true); return
        }
        guard let cant = Int(cantField.text?.replacingOccurrences(of: ",", with: ".") ?? ""), cant > 0 else {
            let a = UIAlertController(title: "Error", message: "Ingrese una cantidad válida", preferredStyle: .alert)
            a.addAction(UIAlertAction(title: "OK", style: .default)); present(a, animated: true); return
        }
        let fecha = fechaField.text?.trimmingCharacters(in: .whitespaces) ?? FirebaseService.todayString()
        let motivo = motivoField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        onSave?(pid, cant, fecha, motivo)
    }

    @objc private func eliminarTapped() {
        let a = UIAlertController(title: "Eliminar", message: "¿Eliminar este consumo? Se restaurará el stock.", preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "Eliminar", style: .destructive) { [weak self] _ in
            self?.onDelete?()
            self?.dismiss(animated: true)
        })
        a.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        present(a, animated: true)
    }

    @objc private func cancel() { dismiss(animated: true) }

    @objc private func abrirScanner() {
        let scanner = BarcodeScannerViewController { [weak self] code in
            guard let self = self else { return }
            if let p = self.productos.first(where: { ($0["codigo"] as? String) == code || ($0["codigo_barras"] as? String) == code }) {
                DispatchQueue.main.async {
                    self.productoSeleccionado = p
                    self.searchBar.text = p["nombre"] as? String ?? ""
                    self.resultsTable.isHidden = true
                    if let card = self.view.viewWithTag(99), let lbl = card.viewWithTag(100) as? UILabel {
                        lbl.text = p["nombre"] as? String ?? ""
                        card.subviews.filter { $0 is UILabel && $0.tag != 100 }.forEach { $0.removeFromSuperview() }
                        let stockLbl = UILabel(); stockLbl.text = "Stock: \(p["stock_actual"] as? Int ?? 0)"
                        stockLbl.font = .systemFont(ofSize: 12); stockLbl.textColor = .secondaryLabel
                        stockLbl.translatesAutoresizingMaskIntoConstraints = false; card.addSubview(stockLbl)
                        NSLayoutConstraint.activate([stockLbl.topAnchor.constraint(equalTo: lbl.bottomAnchor, constant: 2), stockLbl.leadingAnchor.constraint(equalTo: lbl.leadingAnchor)])
                    }
                }
            }
        }
        present(scanner, animated: true)
    }
}
