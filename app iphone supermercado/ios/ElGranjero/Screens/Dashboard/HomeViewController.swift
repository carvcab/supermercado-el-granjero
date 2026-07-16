import UIKit

class HomeViewController: UIViewController {

    private let sidebarView = UIView()
    private let containerView = UIView()
    private let dimmingView = UIView()
    private var sidebarLeadingConstraint: NSLayoutConstraint!
    private var isSidebarOpen = false
    private let sidebarWidth: CGFloat = 260

    private var currentIndex = 0
    private let session = SessionManager.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        _filteredItems = Self.allModules.enumerated().compactMap { (i, item) in
            session.tienePermiso(Self.modulePerms[i]) ? item : nil
        }
        setupLayout()
        setupSidebar()
        showModule(at: 0)
    }

    // MARK: - Layout
    private func setupLayout() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        dimmingView.translatesAutoresizingMaskIntoConstraints = false
        dimmingView.alpha = 0
        view.addSubview(dimmingView)
        NSLayoutConstraint.activate([
            dimmingView.topAnchor.constraint(equalTo: view.topAnchor),
            dimmingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimmingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimmingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideSidebar))
        dimmingView.addGestureRecognizer(tap)

        sidebarView.backgroundColor = UIColor(red: 0.04, green: 0.18, blue: 0.14, alpha: 0.65)
        sidebarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sidebarView)

        let blurEffect = UIBlurEffect(style: .systemMaterialDark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        sidebarView.addSubview(blurView)
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: sidebarView.topAnchor),
            blurView.bottomAnchor.constraint(equalTo: sidebarView.bottomAnchor),
            blurView.leadingAnchor.constraint(equalTo: sidebarView.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: sidebarView.trailingAnchor)
        ])

        sidebarLeadingConstraint = sidebarView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -sidebarWidth)
        NSLayoutConstraint.activate([
            sidebarView.topAnchor.constraint(equalTo: view.topAnchor),
            sidebarView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sidebarView.widthAnchor.constraint(equalToConstant: sidebarWidth),
            sidebarLeadingConstraint
        ])
    }

    // MARK: - Sidebar
    private func setupSidebar() {
        let avatarSize: CGFloat = 56
        let avatarView = UIImageView()
        avatarView.contentMode = .scaleAspectFill
        avatarView.layer.cornerRadius = avatarSize / 2
        avatarView.clipsToBounds = true
        avatarView.layer.borderWidth = 2
        avatarView.layer.borderColor = UIColor.white.withAlphaComponent(0.25).cgColor
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        let foto = session.foto
        if let img = FirebaseService.decodificarFoto(foto) {
            avatarView.image = img
        } else {
            avatarView.image = Self.personAvatar(size: avatarSize)
        }
        sidebarView.addSubview(avatarView)
        NSLayoutConstraint.activate([
            avatarView.topAnchor.constraint(equalTo: sidebarView.safeAreaLayoutGuide.topAnchor, constant: 20),
            avatarView.centerXAnchor.constraint(equalTo: sidebarView.centerXAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: avatarSize),
            avatarView.heightAnchor.constraint(equalToConstant: avatarSize)
        ])

        let nameLabel = UILabel()
        nameLabel.text = session.username ?? "El Granjero"
        nameLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        nameLabel.textColor = .white
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        sidebarView.addSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: 8),
            nameLabel.centerXAnchor.constraint(equalTo: sidebarView.centerXAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: sidebarView.leadingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: sidebarView.trailingAnchor, constant: -12)
        ])

        let roleLabel = UILabel()
        let rolName = (session.currentUser?["rol"] as? String ?? "").lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let isUserAdmin = session.username?.lowercased() == "admin" || session.username?.lowercased() == "nelson" || rolName == "jefe" || rolName == "admin" || rolName == "administrador"
        if isUserAdmin {
            roleLabel.text = "Acceso Total"
            roleLabel.textColor = UIColor(red: 0.95, green: 0.78, blue: 0.22, alpha: 1)
            roleLabel.font = .systemFont(ofSize: 10, weight: .bold)
        } else {
            roleLabel.text = "\(session.permCount) permisos"
            roleLabel.textColor = UIColor.white.withAlphaComponent(0.55)
            roleLabel.font = .systemFont(ofSize: 10)
        }
        roleLabel.textAlignment = .center
        roleLabel.translatesAutoresizingMaskIntoConstraints = false
        sidebarView.addSubview(roleLabel)
        NSLayoutConstraint.activate([
            roleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 3),
            roleLabel.centerXAnchor.constraint(equalTo: sidebarView.centerXAnchor)
        ])

        let sep = UIView()
        sep.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        sep.translatesAutoresizingMaskIntoConstraints = false
        sidebarView.addSubview(sep)
        NSLayoutConstraint.activate([
            sep.topAnchor.constraint(equalTo: roleLabel.bottomAnchor, constant: 14),
            sep.leadingAnchor.constraint(equalTo: sidebarView.leadingAnchor, constant: 20),
            sep.trailingAnchor.constraint(equalTo: sidebarView.trailingAnchor, constant: -20),
            sep.heightAnchor.constraint(equalToConstant: 1)
        ])

        // Scrollable menu
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        sidebarView.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: sep.bottomAnchor, constant: 4),
            scrollView.leadingAnchor.constraint(equalTo: sidebarView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: sidebarView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: sidebarView.bottomAnchor, constant: -56)
        ])

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        let items = filteredItems
        var itemIdx = 0
        for group in Self.moduleGroups {
            let filtered = group.indices.filter { i in
                guard let moduleIdx = Self.allModules.firstIndex(where: { $0.title == Self.allModules[i].title }) else { return false }
                return session.tienePermiso(Self.modulePerms[moduleIdx])
            }
            if filtered.isEmpty { continue }

            let sectionLabel = UILabel()
            sectionLabel.text = "  \(group.title.uppercased())"
            sectionLabel.font = .systemFont(ofSize: 10, weight: .bold)
            sectionLabel.textColor = UIColor.white.withAlphaComponent(0.4)
            sectionLabel.translatesAutoresizingMaskIntoConstraints = false
            sectionLabel.heightAnchor.constraint(equalToConstant: 28).isActive = true
            stackView.addArrangedSubview(sectionLabel)

            for i in filtered {
                let module = Self.allModules[i]
                let btn = UIButton(type: .system)
                btn.contentHorizontalAlignment = .left
                btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 0)
                btn.setTitle("  \(module.title)", for: .normal)
                btn.setImage(UIImage(systemName: module.icon), for: .normal)
                let active = currentIndex == itemIdx
                btn.tintColor = active ? UIColor(red: 0.95, green: 0.78, blue: 0.22, alpha: 1) : UIColor.white.withAlphaComponent(0.7)
                btn.setTitleColor(active ? .white : UIColor.white.withAlphaComponent(0.8), for: .normal)
                btn.titleLabel?.font = .systemFont(ofSize: 13.5, weight: active ? .semibold : .regular)
                btn.tag = itemIdx
                btn.addTarget(self, action: #selector(moduleSelected(_:)), for: .touchUpInside)
                btn.heightAnchor.constraint(equalToConstant: 42).isActive = true
                btn.backgroundColor = active ? UIColor.white.withAlphaComponent(0.12) : .clear
                btn.layer.cornerRadius = 8
                btn.layer.masksToBounds = true

                // Add premium left-border indicator
                let indicator = UIView()
                indicator.backgroundColor = UIColor(red: 0.95, green: 0.78, blue: 0.22, alpha: 1)
                indicator.layer.cornerRadius = 2
                indicator.tag = 99
                indicator.alpha = active ? 1.0 : 0.0
                indicator.translatesAutoresizingMaskIntoConstraints = false
                btn.addSubview(indicator)

                NSLayoutConstraint.activate([
                    indicator.leadingAnchor.constraint(equalTo: btn.leadingAnchor, constant: 8),
                    indicator.centerYAnchor.constraint(equalTo: btn.centerYAnchor),
                    indicator.widthAnchor.constraint(equalToConstant: 4),
                    indicator.heightAnchor.constraint(equalToConstant: 18)
                ])

                stackView.addArrangedSubview(btn)
                itemIdx += 1
            }
        }

        // Logout button
        let logoutButton = UIButton(type: .system)
        logoutButton.setTitle("  Cerrar Sesión", for: .normal)
        logoutButton.setImage(UIImage(systemName: "rectangle.portrait.and.arrow.right"), for: .normal)
        logoutButton.tintColor = UIColor(red: 0.95, green: 0.35, blue: 0.35, alpha: 1)
        logoutButton.setTitleColor(UIColor.white.withAlphaComponent(0.7), for: .normal)
        logoutButton.titleLabel?.font = .systemFont(ofSize: 13)
        logoutButton.contentHorizontalAlignment = .left
        logoutButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 0)
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        logoutButton.backgroundColor = UIColor.white.withAlphaComponent(0.06)
        logoutButton.layer.cornerRadius = 8
        logoutButton.layer.masksToBounds = true
        sidebarView.addSubview(logoutButton)
        NSLayoutConstraint.activate([
            logoutButton.leadingAnchor.constraint(equalTo: sidebarView.leadingAnchor, constant: 10),
            logoutButton.trailingAnchor.constraint(equalTo: sidebarView.trailingAnchor, constant: -10),
            logoutButton.bottomAnchor.constraint(equalTo: sidebarView.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            logoutButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
    }

    // MARK: - Module Navigation
    func showModule(at index: Int) {
        guard index >= 0, index < filteredItems.count else { return }
        currentIndex = index

        for child in children {
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }

        let vc = filteredItems[index].vc
        addChild(vc)
        // Access view to force loadView/viewDidLoad on child
        let _ = vc.view
        vc.view.frame = containerView.bounds
        vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.addSubview(vc.view)
        vc.didMove(toParent: self)

        // Sync navigation bar items from the active child
        title = filteredItems[index].title
        navigationItem.rightBarButtonItems = vc.navigationItem.rightBarButtonItems
        navigationItem.rightBarButtonItem = vc.navigationItem.rightBarButtonItem
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "line.3.horizontal"), style: .plain, target: self, action: #selector(menuSidebarTapped))

        // Refresh sidebar highlights
        for case let stackView as UIStackView in sidebarView.subviews.compactMap({ $0 as? UIScrollView }).first?.subviews.compactMap({ $0 as? UIStackView }) ?? [] {
            for case let btn as UIButton in stackView.arrangedSubviews {
                let idx = btn.tag
                let isActive = idx == index
                btn.tintColor = isActive ? UIColor(red: 1, green: 0.84, blue: 0.2, alpha: 1) : UIColor.white.withAlphaComponent(0.8)
                btn.backgroundColor = isActive ? UIColor.white.withAlphaComponent(0.12) : .clear
                btn.viewWithTag(99)?.alpha = isActive ? 1.0 : 0.0
            }
        }
        
        hideSidebar()
    }

    @objc private func menuSidebarTapped() {
        if isSidebarOpen {
            hideSidebar()
        } else {
            showSidebar()
        }
    }

    @objc private func showSidebar() {
        isSidebarOpen = true
        sidebarLeadingConstraint.constant = 0
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            self.dimmingView.alpha = 1
            self.view.layoutIfNeeded()
        }, completion: { [weak self] _ in
            self?.animateSidebarItems()
        })
    }

    private func animateSidebarItems() {
        guard let scroll = sidebarView.subviews.compactMap({ $0 as? UIScrollView }).first,
              let stack = scroll.subviews.compactMap({ $0 as? UIStackView }).first else { return }
        
        let buttons = stack.arrangedSubviews.compactMap { $0 as? UIButton }
        for (index, btn) in buttons.enumerated() {
            btn.alpha = 0
            btn.transform = CGAffineTransform(translationX: -16, y: 0)
            UIView.animate(withDuration: 0.25, delay: Double(index) * 0.02, options: .curveEaseOut, animations: {
                btn.alpha = 1
                btn.transform = .identity
            }, completion: nil)
        }
    }

    @objc private func hideSidebar() {
        isSidebarOpen = false
        sidebarLeadingConstraint.constant = -sidebarWidth
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
            self.dimmingView.alpha = 0
            self.view.layoutIfNeeded()
        }, completion: nil)
    }

    @objc private func moduleSelected(_ sender: UIButton) {
        showModule(at: sender.tag)
    }

    @objc private func logoutTapped() {
        let alert = UIAlertController(title: "Cerrar Sesión", message: "¿Estás seguro?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Salir", style: .destructive) { [weak self] _ in
            self?.session.clear()
            FirebaseService.shared.signOut()
            self?.dismiss(animated: true)
        })
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - Module Definitions
    struct ModuleItem {
        let title: String
        let icon: String
        let vc: UIViewController
    }

    static let modulePerms: [String] = [
        "dashboard", "caja", "ventas_super", "ventas_bar", "facturacion",
        "historial_ventas", "fiados", "productos", "compras", "compras_programadas",
        "categorias", "distribuciones", "clientes", "proveedores", "usuarios",
        "consumos", "reportes", "cierres", "configuracion"
    ]

    static let allModules: [ModuleItem] = [
        ModuleItem(title: "Dashboard", icon: "square.grid.2x2", vc: DashboardViewController()),
        ModuleItem(title: "Caja", icon: "banknote", vc: CajaViewController()),
        ModuleItem(title: "Ventas Super", icon: "cart", vc: POSViewController()),
        ModuleItem(title: "Ventas Bar", icon: "wineglass", vc: BarViewController()),
        ModuleItem(title: "Facturación", icon: "doc.text", vc: FacturacionViewController()),
        ModuleItem(title: "Historial", icon: "clock.arrow.circlepath", vc: HistorialViewController()),
        ModuleItem(title: "Fiados", icon: "creditcard", vc: FiadosViewController()),
        ModuleItem(title: "Inventario", icon: "shippingbox", vc: InventarioViewController()),
        ModuleItem(title: "Compras", icon: "bag", vc: ComprasViewController()),
        ModuleItem(title: "Compras Prog.", icon: "calendar", vc: ComprasProgramadasViewController()),
        ModuleItem(title: "Categorías", icon: "folder", vc: CategoriasViewController()),
        ModuleItem(title: "Distribuciones", icon: "wallet.pass", vc: DistribucionesViewController()),
        ModuleItem(title: "Clientes", icon: "person.2", vc: ClientesViewController()),
        ModuleItem(title: "Proveedores", icon: "building.2", vc: ProveedoresViewController()),
        ModuleItem(title: "Usuarios", icon: "shield", vc: UsuariosViewController()),
        ModuleItem(title: "Consumos", icon: "person.badge.minus", vc: ConsumosViewController()),
        ModuleItem(title: "Reportes", icon: "chart.bar", vc: ReportesViewController()),
        ModuleItem(title: "Cierres", icon: "lock", vc: CierresViewController()),
        ModuleItem(title: "Configuración", icon: "gearshape", vc: ConfiguracionViewController()),
    ]

    private var _filteredItems: [ModuleItem]?
    var filteredItems: [ModuleItem] {
        if let items = _filteredItems { return items }
        let items = Self.allModules.enumerated().compactMap { (i, item) in
            session.tienePermiso(Self.modulePerms[i]) ? item : nil
        }
        _filteredItems = items
        return items
    }

    static let moduleGroups: [(title: String, indices: [Int])] = [
        ("Principal", [0, 1]),
        ("Ventas", [2, 3, 4, 5, 6]),
        ("Inventario y Compras", [7, 8, 9, 10, 11, 15]),
        ("Gestión", [12, 13, 14]),
        ("Análisis", [16, 17, 18])
    ]

    static func personAvatar(size: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: CGSize(width: size, height: size))
            let path = UIBezierPath(roundedRect: rect, cornerRadius: size / 2)
            path.addClip()
            UIColor.white.withAlphaComponent(0.15).setFill()
            path.fill()
            let config = UIImage.SymbolConfiguration(pointSize: size * 0.5, weight: .medium)
            if let icon = UIImage(systemName: "person.fill", withConfiguration: config)?
                .withTintColor(UIColor.white.withAlphaComponent(0.6), renderingMode: .alwaysOriginal) {
                let iconSize = icon.size
                let iconRect = CGRect(x: (size - iconSize.width) / 2, y: (size - iconSize.height) / 2, width: iconSize.width, height: iconSize.height)
                icon.draw(in: iconRect)
            }
        }
    }
}
