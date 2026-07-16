import UIKit

class UsuariosViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    private let tableView = UITableView()
    private var usuarios: [[String: Any]] = []
    private let fb = FirebaseService.shared
    private var pendingFotoBase64: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Usuarios"

        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addUser))
        navigationItem.rightBarButtonItem = addButton

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.backgroundColor = .clear
        tableView.rowHeight = 50
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        loadUsers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadUsers()
    }

    private func loadUsers() {
        Task {
            do {
                usuarios = try await fb.getList("usuarios")
                await MainActor.run { tableView.reloadData() }
            } catch { print("Error loading users: \(error)") }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { usuarios.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let u = usuarios[indexPath.row]
        let username = u["username"] as? String ?? ""
        let nombre = u["nombre_completo"] as? String ?? ""
        let rol = u["rol"] as? String ?? ""
        let activo = u["activo"] as? Bool ?? true
        let foto = u["foto"] as? String ?? ""

        cell.textLabel?.attributedText = nil
        cell.imageView?.image = nil

        let avatar = makeAvatarView(foto: foto, name: username, size: 36)
        cell.imageView?.image = avatar

        let displayName = nombre.isEmpty ? username : nombre
        let attrStr = NSMutableAttributedString(string: "\(displayName)  ", attributes: [.font: UIFont.systemFont(ofSize: 14)])
        attrStr.append(NSAttributedString(string: "(\(rol))", attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.secondaryLabel]))
        cell.textLabel?.attributedText = attrStr
        cell.backgroundColor = activo ? .systemBackground : UIColor.systemGray5
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let user = usuarios[indexPath.row]
        showUserActions(user, index: indexPath.row)
    }

    private func showUserActions(_ user: [String: Any], index: Int) {
        let alert = UIAlertController(title: user["username"] as? String ?? "Usuario", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Editar", style: .default) { [weak self] _ in
            self?.pendingFotoBase64 = user["foto"] as? String
            self?.showUserForm(user: user, index: index)
        })
        alert.addAction(UIAlertAction(title: "Cambiar Foto", style: .default) { [weak self] _ in
            self?.pendingFotoBase64 = user["foto"] as? String
            self?.showPhotoSourcePicker(for: user, index: index)
        })
        alert.addAction(UIAlertAction(title: "Eliminar", style: .destructive) { [weak self] _ in
            self?.deleteUser(user, index: index)
        })
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func addUser() {
        pendingFotoBase64 = nil
        let picker = UIAlertController(title: "Nuevo Usuario", message: "¿Agregar foto de perfil?", preferredStyle: .alert)
        picker.addAction(UIAlertAction(title: "Con Foto", style: .default) { [weak self] _ in
            self?.showPhotoSourcePicker(for: nil, index: nil)
        })
        picker.addAction(UIAlertAction(title: "Sin Foto", style: .cancel) { [weak self] _ in
            self?.pendingFotoBase64 = nil
            self?.showUserForm(user: nil, index: nil)
        })
        present(picker, animated: true)
    }

    private func showPhotoSourcePicker(for user: [String: Any]?, index: Int?) {
        let alert = UIAlertController(title: "Foto de Perfil", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Cámara", style: .default) { [weak self] _ in
            self?.openImagePicker(source: .camera, user: user, index: index)
        })
        alert.addAction(UIAlertAction(title: "Galería", style: .default) { [weak self] _ in
            self?.openImagePicker(source: .photoLibrary, user: user, index: index)
        })
        if pendingFotoBase64 != nil && !(pendingFotoBase64 ?? "").isEmpty {
            alert.addAction(UIAlertAction(title: "Quitar Foto", style: .destructive) { [weak self] _ in
                self?.pendingFotoBase64 = ""
                self?.showUserForm(user: user, index: index)
            })
        }
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel) { [weak self] _ in
            self?.showUserForm(user: user, index: index)
        })
        present(alert, animated: true)
    }

    private func openImagePicker(source: UIImagePickerController.SourceType, user: [String: Any]?, index: Int?) {
        guard UIImagePickerController.isSourceTypeAvailable(source) else {
            let a = UIAlertController(title: "No disponible", message: "Esta opción no está disponible en este dispositivo.", preferredStyle: .alert)
            a.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in self?.showUserForm(user: user, index: index) })
            present(a, animated: true)
            return
        }
        let picker = UIImagePickerController()
        picker.sourceType = source
        picker.delegate = self
        picker.allowsEditing = true
        picker.view.tag = index ?? -1
        objc_setAssociatedObject(picker, "userKey", user, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        picker.modalPresentationStyle = .fullScreen
        present(picker, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let edited = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
            let resized = resizeImage(edited, maxSize: 200)
            pendingFotoBase64 = "data:image/jpeg;base64," + (resized.jpegData(compressionQuality: 0.7)?.base64EncodedString() ?? "")
        }
        let user = objc_getAssociatedObject(picker, "userKey") as? [String: Any]
        let idx = picker.view.tag
        picker.dismiss(animated: true) { [weak self] in
            self?.showUserForm(user: user, index: idx >= 0 ? idx : nil)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        let user = objc_getAssociatedObject(picker, "userKey") as? [String: Any]
        let idx = picker.view.tag
        picker.dismiss(animated: true) { [weak self] in
            self?.showUserForm(user: user, index: idx >= 0 ? idx : nil)
        }
    }

    private func resizeImage(_ image: UIImage, maxSize: CGFloat) -> UIImage {
        let size = image.size
        let ratio = min(maxSize / size.width, maxSize / size.height)
        if ratio >= 1.0 { return image }
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        UIGraphicsBeginImageContextWithOptions(newSize, true, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? image
    }

    private func showUserForm(user: [String: Any]?, index: Int?) {
        let alert = UIAlertController(title: user == nil ? "Nuevo Usuario" : "Editar Usuario", message: nil, preferredStyle: .alert)

        alert.addTextField { tf in tf.placeholder = "Username"; tf.text = user?["username"] as? String; tf.autocapitalizationType = .none }
        alert.addTextField { tf in tf.placeholder = "Nombre completo"; tf.text = user?["nombre_completo"] as? String }
        alert.addTextField { tf in tf.placeholder = "Email"; tf.text = user?["email"] as? String; tf.autocapitalizationType = .none; tf.keyboardType = .emailAddress }
        alert.addTextField { tf in tf.placeholder = "Teléfono"; tf.text = user?["telefono"] as? String }
        alert.addTextField { tf in tf.placeholder = "Contraseña"; tf.isSecureTextEntry = true }
        alert.addTextField { tf in tf.placeholder = "Rol"; tf.text = user?["rol"] as? String }

        let saveAction = UIAlertAction(title: "Guardar", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let fields = alert.textFields ?? []
            let username = fields[0].text?.trimmingCharacters(in: .whitespaces) ?? ""
            guard !username.isEmpty else { return }

            let foto = self.pendingFotoBase64 ?? user?["foto"] as? String ?? ""
            var data: [String: Any] = [
                "username": username,
                "nombre_completo": fields[1].text ?? "",
                "email": fields[2].text ?? "",
                "telefono": fields[3].text ?? "",
                "password": fields[4].text ?? (user?["password"] as? String ?? ""),
                "rol": fields[5].text ?? "",
                "foto": foto,
                "activo": true
            ]
            if let existingId = user?["id"] as? Int {
                data["id"] = existingId
            }

            Task {
                do {
                    if user == nil {
                        data["id"] = FirebaseService.nextId(in: self.usuarios)
                        try await self.fb.addToList("usuarios", item: data)
                    } else {
                        try await self.fb.updateInList("usuarios", idValue: data["id"]!, updates: data)
                    }
                    self.pendingFotoBase64 = nil
                    self.loadUsers()
                } catch { print("Error saving user: \(error)") }
            }
        }
        alert.addAction(saveAction)
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel) { [weak self] _ in
            self?.pendingFotoBase64 = nil
        })
        present(alert, animated: true)
    }

    private func deleteUser(_ user: [String: Any], index: Int) {
        guard let id = user["id"] as? Int else { return }
        let confirm = UIAlertController(title: "Eliminar", message: "¿Eliminar usuario \(user["username"] as? String ?? "")?", preferredStyle: .alert)
        confirm.addAction(UIAlertAction(title: "Eliminar", style: .destructive) { [weak self] _ in
            Task {
                do {
                    try await self?.fb.removeFromList("usuarios", idValue: id)
                    self?.loadUsers()
                } catch { print("Error deleting user: \(error)") }
            }
        })
        confirm.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        present(confirm, animated: true)
    }

    private func makeAvatarView(foto: String, name: String, size: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: CGSize(width: size, height: size))
            let path = UIBezierPath(roundedRect: rect, cornerRadius: size / 2)
            path.addClip()

            if let decoded = FirebaseService.decodificarFoto(foto) {
                decoded.draw(in: rect)
            } else {
                UIColor.systemGray4.setFill()
                path.fill()
                let config = UIImage.SymbolConfiguration(pointSize: size * 0.5, weight: .medium)
                if let icon = UIImage(systemName: "person.fill", withConfiguration: config)?
                    .withTintColor(.white, renderingMode: .alwaysOriginal) {
                    let iconSize = icon.size
                    let iconRect = CGRect(x: (size - iconSize.width) / 2, y: (size - iconSize.height) / 2 + 1, width: iconSize.width, height: iconSize.height)
                    icon.draw(in: iconRect)
                }
            }
        }
    }
}
