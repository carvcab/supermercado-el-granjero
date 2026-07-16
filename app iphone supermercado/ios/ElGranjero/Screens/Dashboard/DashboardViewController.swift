import UIKit

class DashboardViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private var kpiCollection: UICollectionView!
    private var recentsStack: UIStackView!
    private var lowStockStack: UIStackView!
    private var kpiValues: [String] = ["$0", "$0", "$0", "0", "$0", "0"]

    private struct KPI { let title: String; let icon: String }
    private let kpis: [KPI] = [
        KPI(title: "Ventas Hoy", icon: "dollarsign.circle"),
        KPI(title: "Ventas Mes", icon: "chart.line.uptrend.xyaxis"),
        KPI(title: "Ganancias Hoy", icon: "arrow.up.forward"),
        KPI(title: "Deudores", icon: "person.2"),
        KPI(title: "Inventario", icon: "shippingbox"),
        KPI(title: "Stock Bajo", icon: "exclamationmark.triangle"),
    ]

    private var tint: UIColor { UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.35, green: 0.75, blue: 0.55, alpha: 1) : UIColor(red: 0.08, green: 0.32, blue: 0.25, alpha: 1) } }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        loadData()
    }

    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); loadData() }

    private func setupUI() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])

        let pad: CGFloat = 14
        let width = UIScreen.main.bounds.width - pad * 2

        // Greeting card
        let greetCard = cardView()
        contentView.addSubview(greetCard)
        let avatarView = UIImageView()
        avatarView.contentMode = .scaleAspectFill
        avatarView.layer.cornerRadius = 24
        avatarView.clipsToBounds = true
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        let foto = SessionManager.shared.foto
        if let img = FirebaseService.decodificarFoto(foto) {
            avatarView.image = img
        } else {
            avatarView.image = HomeViewController.personAvatar(size: 48)
        }
        greetCard.addSubview(avatarView)
        let nameLbl = UILabel(); nameLbl.text = SessionManager.shared.username ?? "Usuario"
        nameLbl.font = .systemFont(ofSize: 26, weight: .bold); nameLbl.textColor = tint
        nameLbl.translatesAutoresizingMaskIntoConstraints = false; greetCard.addSubview(nameLbl)
        let dateLbl = UILabel()
        let df = DateFormatter(); df.dateFormat = "EEEE, d 'de' MMMM"; df.locale = Locale(identifier: "es_CO")
        dateLbl.text = df.string(from: Date()).capitalized; dateLbl.font = .systemFont(ofSize: 13); dateLbl.textColor = .secondaryLabel
        dateLbl.translatesAutoresizingMaskIntoConstraints = false; greetCard.addSubview(dateLbl)
        NSLayoutConstraint.activate([
            greetCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: pad),
            greetCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            greetCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            avatarView.topAnchor.constraint(equalTo: greetCard.topAnchor, constant: 18),
            avatarView.leadingAnchor.constraint(equalTo: greetCard.leadingAnchor, constant: 18),
            avatarView.widthAnchor.constraint(equalToConstant: 48),
            avatarView.heightAnchor.constraint(equalToConstant: 48),
            nameLbl.topAnchor.constraint(equalTo: greetCard.topAnchor, constant: 18),
            nameLbl.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            nameLbl.trailingAnchor.constraint(equalTo: greetCard.trailingAnchor, constant: -18),
            dateLbl.topAnchor.constraint(equalTo: nameLbl.bottomAnchor, constant: 4),
            dateLbl.leadingAnchor.constraint(equalTo: nameLbl.leadingAnchor),
            dateLbl.bottomAnchor.constraint(equalTo: greetCard.bottomAnchor, constant: -18),
        ])

        // KPI grid
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 10; layout.minimumLineSpacing = 10
        let itemW = (width - 10) / 2; layout.itemSize = CGSize(width: itemW, height: 95)
        kpiCollection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        kpiCollection.dataSource = self; kpiCollection.delegate = self
        kpiCollection.register(KPICell.self, forCellWithReuseIdentifier: "kpi")
        kpiCollection.backgroundColor = .clear; kpiCollection.isScrollEnabled = false
        kpiCollection.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(kpiCollection)

        let kpiH = ceil(CGFloat(kpis.count) / 2) * (95 + 10) - 10
        NSLayoutConstraint.activate([
            kpiCollection.topAnchor.constraint(equalTo: greetCard.bottomAnchor, constant: 14),
            kpiCollection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            kpiCollection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            kpiCollection.heightAnchor.constraint(equalToConstant: kpiH),
        ])

        // Recent sales
        let salesCard = cardView()
        contentView.addSubview(salesCard)
        salesCard.translatesAutoresizingMaskIntoConstraints = false
        let salesHdr = sectionHeader("Últimas Ventas", color: tint)
        salesCard.addSubview(salesHdr)
        recentsStack = UIStackView(); recentsStack.axis = .vertical; recentsStack.spacing = 6
        recentsStack.translatesAutoresizingMaskIntoConstraints = false; salesCard.addSubview(recentsStack)
        NSLayoutConstraint.activate([
            salesCard.topAnchor.constraint(equalTo: kpiCollection.bottomAnchor, constant: 14),
            salesCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            salesCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            salesHdr.topAnchor.constraint(equalTo: salesCard.topAnchor, constant: 14),
            salesHdr.leadingAnchor.constraint(equalTo: salesCard.leadingAnchor, constant: 16),
            recentsStack.topAnchor.constraint(equalTo: salesHdr.bottomAnchor, constant: 10),
            recentsStack.leadingAnchor.constraint(equalTo: salesCard.leadingAnchor, constant: 16),
            recentsStack.trailingAnchor.constraint(equalTo: salesCard.trailingAnchor, constant: -16),
            recentsStack.bottomAnchor.constraint(equalTo: salesCard.bottomAnchor, constant: -14),
        ])

        // Low stock
        let stockCard = cardView()
        contentView.addSubview(stockCard)
        stockCard.translatesAutoresizingMaskIntoConstraints = false
        let stockHdr = sectionHeader("Stock Bajo", color: .systemRed)
        stockCard.addSubview(stockHdr)
        lowStockStack = UIStackView(); lowStockStack.axis = .vertical; lowStockStack.spacing = 6
        lowStockStack.translatesAutoresizingMaskIntoConstraints = false; stockCard.addSubview(lowStockStack)
        NSLayoutConstraint.activate([
            stockCard.topAnchor.constraint(equalTo: salesCard.bottomAnchor, constant: 14),
            stockCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            stockCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            stockHdr.topAnchor.constraint(equalTo: stockCard.topAnchor, constant: 14),
            stockHdr.leadingAnchor.constraint(equalTo: stockCard.leadingAnchor, constant: 16),
            lowStockStack.topAnchor.constraint(equalTo: stockHdr.bottomAnchor, constant: 10),
            lowStockStack.leadingAnchor.constraint(equalTo: stockCard.leadingAnchor, constant: 16),
            lowStockStack.trailingAnchor.constraint(equalTo: stockCard.trailingAnchor, constant: -16),
            lowStockStack.bottomAnchor.constraint(equalTo: stockCard.bottomAnchor, constant: -14),
            stockCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -pad),
        ])
    }

    private func sectionHeader(_ text: String, color: UIColor) -> UILabel {
        let l = UILabel(); l.text = text; l.font = .systemFont(ofSize: 15, weight: .bold)
        l.textColor = color; l.translatesAutoresizingMaskIntoConstraints = false; return l
    }

    private func cardView() -> UIView {
        let v = UIView(); v.backgroundColor = .secondarySystemGroupedBackground; v.layer.cornerRadius = 14
        v.layer.shadowColor = UIColor.black.cgColor; v.layer.shadowOpacity = 0.04
        v.layer.shadowRadius = 6; v.layer.shadowOffset = CGSize(width: 0, height: 2); return v
    }

    // MARK: - Collection View
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { kpis.count }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "kpi", for: indexPath) as! KPICell
        let k = kpis[indexPath.row]
        cell.configure(title: k.title, icon: k.icon, value: indexPath.row < kpiValues.count ? kpiValues[indexPath.row] : "$0")
        return cell
    }

    // MARK: - Data
    private func loadData() {
        Task {
            do {
                let fb = FirebaseService.shared
                async let prods = fb.getList("productos")
                async let sales = fb.getList("ventas")
                async let clients = fb.getList("clientes")
                async let cajasData = fb.getList("cajas")
                let (productos, ventas, clientes, cajas) = try await (prods, sales, clients, cajasData)
                await MainActor.run { update(productos: productos, ventas: ventas, clientes: clientes, cajas: cajas) }
            } catch { print("Dashboard error: \(error)") }
        }
    }

    private func update(productos: [[String: Any]], ventas: [[String: Any]], clientes: [[String: Any]], cajas: [[String: Any]]) {
        let today = FirebaseService.todayString(); let month = today.prefix(7)
        let hoy = ventas.filter { ($0["fecha"] as? String ?? "").hasPrefix(today) && ($0["estado"] as? String) != "anulada" }
        let mes = ventas.filter { ($0["fecha"] as? String ?? "").hasPrefix(month) && ($0["estado"] as? String) != "anulada" }
        let ventasHoy = hoy.compactMap { $0["total"] as? Double }.reduce(0, +)
        let ventasMes = mes.compactMap { $0["total"] as? Double }.reduce(0, +)
        let ganancias = hoy.reduce(0.0) { sum, v in
            let items = v["items"] as? [[String: Any]] ?? []
            let cost = items.reduce(0.0) { s, item in
                let qty = Double(item["cantidad"] as? Int ?? 1)
                let c = item["precio_compra"] as? Double ?? 0
                return s + (c * qty)
            }
            return sum + (v["total"] as? Double ?? 0) - cost
        }
        let deudores = clientes.filter { ($0["saldo_pendiente"] as? Double ?? 0) > 0 }.count
        let valInv = productos.compactMap { p -> Double? in
            let s = p["stock_actual"] as? Int ?? 0; return s > 0 ? Double(s) * (p["precio_compra"] as? Double ?? 0) : nil
        }.reduce(0, +)
        let bajo = productos.filter {
            let s = $0["stock_actual"] as? Int ?? 0; return s > 0 && s <= ($0["stock_minimo"] as? Int ?? 0)
        }

        kpiValues = [FirebaseService.formatMoney(ventasHoy), FirebaseService.formatMoney(ventasMes), FirebaseService.formatMoney(ganancias), "\(deudores)", FirebaseService.formatMoney(valInv), "\(bajo.count)"]
        kpiCollection.reloadData()

        // Recent sales
        recentsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for v in hoy.prefix(5) {
            let l = UILabel(); l.font = .systemFont(ofSize: 13); l.textColor = .label
            l.text = "\(v["cliente"] as? String ?? "Mostrador") — \(FirebaseService.formatMoney(v["total"] as? Double ?? 0)) [\((v["fecha"] as? String ?? "").suffix(8))]"
            recentsStack.addArrangedSubview(l)
        }
        if hoy.isEmpty { recentsStack.addArrangedSubview(emptyLabel("Sin ventas hoy")) }

        // Low stock
        lowStockStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for p in bajo.prefix(10) {
            let l = UILabel(); l.font = .systemFont(ofSize: 13); l.textColor = .systemRed
            l.text = "\(p["nombre"] as? String ?? "?") — Stock: \(p["stock_actual"] as? Int ?? 0)/\(p["stock_minimo"] as? Int ?? 0)"
            lowStockStack.addArrangedSubview(l)
        }
        if bajo.isEmpty { lowStockStack.addArrangedSubview(emptyLabel("Todo en orden")) }
    }

    private func emptyLabel(_ text: String) -> UILabel { let l = UILabel(); l.text = text; l.font = .systemFont(ofSize: 13); l.textColor = .secondaryLabel; return l }
}

// MARK: - KPI Cell
class KPICell: UICollectionViewCell {
    private let icon = UIImageView(); private let title = UILabel(); private let value = UILabel()
    private var accent: UIColor { UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.3, green: 0.7, blue: 0.5, alpha: 1) : UIColor(red: 0.1, green: 0.3, blue: 0.24, alpha: 1) } }
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .secondarySystemGroupedBackground; layer.cornerRadius = 12
        layer.shadowColor = UIColor.black.cgColor; layer.shadowOpacity = 0.03; layer.shadowRadius = 4; layer.shadowOffset = CGSize(width: 0, height: 1)
        icon.contentMode = .scaleAspectFit; icon.translatesAutoresizingMaskIntoConstraints = false
        title.font = .systemFont(ofSize: 11); title.textColor = .secondaryLabel; title.translatesAutoresizingMaskIntoConstraints = false
        value.font = .systemFont(ofSize: 20, weight: .bold); value.textColor = accent
        value.adjustsFontSizeToFitWidth = true; value.minimumScaleFactor = 0.5; value.translatesAutoresizingMaskIntoConstraints = false
        [icon, title, value].forEach { contentView.addSubview($0) }
        NSLayoutConstraint.activate([
            icon.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14), icon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            icon.widthAnchor.constraint(equalToConstant: 22), icon.heightAnchor.constraint(equalToConstant: 22),
            title.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 8), title.leadingAnchor.constraint(equalTo: icon.leadingAnchor),
            value.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 2), value.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            value.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
        ])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    func configure(title t: String, icon name: String, value v: String) {
        title.text = t; value.text = v; icon.image = UIImage(systemName: name); icon.tintColor = accent
    }
}
