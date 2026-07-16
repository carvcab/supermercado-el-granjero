import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    private let userTextField = UITextField()
    private let passTextField = UITextField()
    private let loginButton = UIButton(type: .system)
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let logoContainer = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let cardView = UIView()
    private let rememberSwitch = UISwitch()
    private let rememberLabel = UILabel()
    private var particleLayers: [CAShapeLayer] = []
    private var displayLink: CADisplayLink?
    private var shakeAnim: UIViewPropertyAnimator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradientBackground()
        setupParticles()
        setupUI()
        startParticleAnimation()
        loadSavedCredentials()
        setupKeyboardDismiss()
    }
    
    private func setupKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        userTextField.delegate = self
        passTextField.delegate = self
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func setupGradientBackground() {
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(red: 0.04, green: 0.16, blue: 0.10, alpha: 1).cgColor,
            UIColor(red: 0.05, green: 0.23, blue: 0.16, alpha: 1).cgColor,
            UIColor(red: 0.04, green: 0.16, blue: 0.10, alpha: 1).cgColor,
            UIColor(red: 0.02, green: 0.12, blue: 0.09, alpha: 1).cgColor
        ]
        gradient.locations = [0, 0.35, 0.65, 1]
        gradient.frame = view.bounds
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        view.layer.insertSublayer(gradient, at: 0)
    }
    
    private func setupParticles() {
        for _ in 0..<30 {
            let layer = CAShapeLayer()
            let radius = CGFloat.random(in: 1...3)
            let rect = CGRect(x: CGFloat.random(in: 0...view.bounds.width),
                            y: CGFloat.random(in: 0...view.bounds.height),
                            width: radius * 2, height: radius * 2)
            layer.path = UIBezierPath(ovalIn: rect).cgPath
            layer.fillColor = UIColor.white.withAlphaComponent(0.08).cgColor
            view.layer.insertSublayer(layer, at: 1)
            particleLayers.append(layer)
        }
    }
    
    private func startParticleAnimation() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateParticles))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func updateParticles() {
        let time = CACurrentMediaTime()
        for (i, layer) in particleLayers.enumerated() {
            let baseX = (CGFloat(i) * 0.137 + 0.05).truncatingRemainder(dividingBy: 1)
            let baseY = (CGFloat(i) * 0.287 + 0.03).truncatingRemainder(dividingBy: 1)
            let x = (baseX * view.bounds.width + sin(time * 1.3 + CGFloat(i) * 0.8) * 18).truncatingRemainder(dividingBy: view.bounds.width)
            let y = (baseY * view.bounds.height + cos(time * 1.7 + CGFloat(i) * 0.6) * 14).truncatingRemainder(dividingBy: view.bounds.height)
            let radius = 1 + sin(time * 2.5 + CGFloat(i)) * 0.6
            let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
            layer.path = UIBezierPath(ovalIn: rect).cgPath
        }
    }
    
    private func setupUI() {
        // Scroll view for smaller screens
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // Logo
        logoContainer.translatesAutoresizingMaskIntoConstraints = false
        logoContainer.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        logoContainer.layer.cornerRadius = 22
        logoContainer.layer.borderWidth = 1.5
        logoContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        logoContainer.layer.shadowColor = UIColor(red: 0.1, green: 0.3, blue: 0.22, alpha: 1).cgColor
        logoContainer.layer.shadowOpacity = 0.5
        logoContainer.layer.shadowRadius = 24
        logoContainer.layer.shadowOffset = CGSize(width: 0, height: 8)
        contentView.addSubview(logoContainer)
        
        let storeIcon = UIImageView(image: UIImage(systemName: "store.fill"))
        storeIcon.tintColor = .white
        storeIcon.contentMode = .scaleAspectFit
        storeIcon.translatesAutoresizingMaskIntoConstraints = false
        logoContainer.addSubview(storeIcon)
        NSLayoutConstraint.activate([
            logoContainer.widthAnchor.constraint(equalToConstant: 90),
            logoContainer.heightAnchor.constraint(equalToConstant: 90),
            logoContainer.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            logoContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 80),
            storeIcon.centerXAnchor.constraint(equalTo: logoContainer.centerXAnchor),
            storeIcon.centerYAnchor.constraint(equalTo: logoContainer.centerYAnchor),
            storeIcon.widthAnchor.constraint(equalToConstant: 42),
            storeIcon.heightAnchor.constraint(equalToConstant: 42)
        ])
        
        // Title
        titleLabel.text = "El Granjero"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 28)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        subtitleLabel.text = "Sistema POS"
        subtitleLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: logoContainer.bottomAnchor, constant: 20),
            subtitleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4)
        ])
        
        // Card view (glassmorphism)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        cardView.layer.cornerRadius = 24
        cardView.layer.borderWidth = 1.2
        cardView.layer.borderColor = UIColor.white.withAlphaComponent(0.25).cgColor
        
        // Blur effect
        let blurEffect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.layer.cornerRadius = 24
        blurView.clipsToBounds = true
        cardView.insertSubview(blurView, at: 0)
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: cardView.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor)
        ])
        
        contentView.addSubview(cardView)
        
        // Username field
        userTextField.attributedPlaceholder = NSAttributedString(
            string: "Usuario",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.white.withAlphaComponent(0.4)]
        )
        userTextField.textColor = .white
        userTextField.font = UIFont.systemFont(ofSize: 16)
        userTextField.autocapitalizationType = .none
        userTextField.autocorrectionType = .no
        userTextField.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        userTextField.layer.cornerRadius = 14
        userTextField.leftView = UIImageView(image: UIImage(systemName: "person.fill")?.withTintColor(UIColor.white.withAlphaComponent(0.5), renderingMode: .alwaysOriginal))
        userTextField.leftView?.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        userTextField.leftViewMode = .always
        userTextField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 44))
        userTextField.rightViewMode = .always
        userTextField.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(userTextField)
        
        // Password field
        passTextField.attributedPlaceholder = NSAttributedString(
            string: "Contraseña",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.white.withAlphaComponent(0.4)]
        )
        passTextField.textColor = .white
        passTextField.font = UIFont.systemFont(ofSize: 16)
        passTextField.isSecureTextEntry = true
        passTextField.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        passTextField.layer.cornerRadius = 14
        passTextField.leftView = UIImageView(image: UIImage(systemName: "lock.fill")?.withTintColor(UIColor.white.withAlphaComponent(0.5), renderingMode: .alwaysOriginal))
        passTextField.leftView?.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        passTextField.leftViewMode = .always
        passTextField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 44))
        passTextField.rightViewMode = .always
        passTextField.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(passTextField)
        
        // Remember me
        rememberLabel.text = "Recordar contraseña"
        rememberLabel.font = UIFont.systemFont(ofSize: 14)
        rememberLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        rememberLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(rememberLabel)
        
        rememberSwitch.onTintColor = UIColor(red: 0.18, green: 0.48, blue: 0.37, alpha: 1)
        rememberSwitch.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(rememberSwitch)
        
        // Login button
        loginButton.setTitle("Iniciar Sesión", for: .normal)
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        loginButton.backgroundColor = UIColor(red: 0.18, green: 0.48, blue: 0.37, alpha: 1)
        loginButton.layer.cornerRadius = 16
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(loginButton)
        
        // Constraints
        NSLayoutConstraint.activate([
            cardView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            cardView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 32),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 28),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -28),
            
            userTextField.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 28),
            userTextField.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            userTextField.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            userTextField.heightAnchor.constraint(equalToConstant: 50),
            
            passTextField.topAnchor.constraint(equalTo: userTextField.bottomAnchor, constant: 14),
            passTextField.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            passTextField.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            passTextField.heightAnchor.constraint(equalToConstant: 50),
            
            rememberLabel.topAnchor.constraint(equalTo: passTextField.bottomAnchor, constant: 16),
            rememberLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            rememberSwitch.centerYAnchor.constraint(equalTo: rememberLabel.centerYAnchor),
            rememberSwitch.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            
            loginButton.topAnchor.constraint(equalTo: rememberLabel.bottomAnchor, constant: 24),
            loginButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            loginButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            loginButton.heightAnchor.constraint(equalToConstant: 52),
            loginButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -28)
        ])
        
        // Version label
        let versionLabel = UILabel()
        versionLabel.text = "v1.1.2"
        versionLabel.font = UIFont.systemFont(ofSize: 11)
        versionLabel.textColor = UIColor.white.withAlphaComponent(0.3)
        versionLabel.textAlignment = .center
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(versionLabel)
        NSLayoutConstraint.activate([
            versionLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            versionLabel.topAnchor.constraint(equalTo: cardView.bottomAnchor, constant: 24),
            versionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
        
        // Add entry animation
        logoContainer.transform = CGAffineTransform(translationX: 0, y: -30).concatenating(CGAffineTransform(scaleX: 0.5, y: 0.5))
        logoContainer.alpha = 0
        titleLabel.transform = CGAffineTransform(translationX: 0, y: -20)
        titleLabel.alpha = 0
        subtitleLabel.transform = CGAffineTransform(translationX: 0, y: -20)
        subtitleLabel.alpha = 0
        cardView.transform = CGAffineTransform(translationX: 0, y: 40)
        cardView.alpha = 0
        
        UIView.animate(withDuration: 0.8, delay: 0.1, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.8, options: []) {
            self.logoContainer.transform = .identity
            self.logoContainer.alpha = 1
        }
        UIView.animate(withDuration: 0.6, delay: 0.2) {
            self.titleLabel.transform = .identity
            self.titleLabel.alpha = 1
            self.subtitleLabel.transform = .identity
            self.subtitleLabel.alpha = 1
        }
        UIView.animate(withDuration: 0.8, delay: 0.3, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: []) {
            self.cardView.transform = .identity
            self.cardView.alpha = 1
        }
    }
    
    private func loadSavedCredentials() {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: "remember") {
            userTextField.text = defaults.string(forKey: "username")
            passTextField.text = defaults.string(forKey: "password")
            rememberSwitch.isOn = true
        }
    }
    
    private func saveCredentials() {
        let defaults = UserDefaults.standard
        defaults.set(rememberSwitch.isOn, forKey: "remember")
        if rememberSwitch.isOn {
            defaults.set(userTextField.text, forKey: "username")
            defaults.set(passTextField.text, forKey: "password")
            if let foto = SessionManager.shared.foto, !foto.isEmpty {
                defaults.set(foto, forKey: "photo")
            }
        } else {
            defaults.removeObject(forKey: "username")
            defaults.removeObject(forKey: "password")
            defaults.removeObject(forKey: "photo")
            defaults.removeObject(forKey: "nombre")
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == userTextField {
            passTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            loginTapped()
        }
        return true
    }
    
    private func triggerShake() {
        let shake = CAKeyframeAnimation(keyPath: "transform.translation.x")
        shake.values = [0, 12, -12, 8, -8, 4, -4, 0]
        shake.duration = 0.5
        cardView.layer.add(shake, forKey: "shake")
        
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    @objc private func loginTapped() {
        dismissKeyboard()
        guard let user = userTextField.text?.trimmingCharacters(in: .whitespaces), !user.isEmpty,
              let password = passTextField.text?.trimmingCharacters(in: .whitespaces), !password.isEmpty else {
            triggerShake()
            return
        }
        
        loginButton.isEnabled = false
        loginButton.setTitle("", for: .normal)
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .white
        indicator.startAnimating()
        loginButton.addSubview(indicator)
        indicator.center = CGPoint(x: loginButton.bounds.width / 2, y: loginButton.bounds.height / 2)
        
        Task {
            do {
                let fb = FirebaseService.shared
                
                // Step 1: Ensure Firebase auth
                if fb.currentUser == nil {
                    do { try await fb.signInAnonymously() }
                    catch {
                        do { try await fb.signInWithEmail() }
                        catch {
                            do { try await fb.createAccount() }
                            catch { }
                        }
                    }
                }
                
                // Step 2: Fetch users
                let usuarios = try await fb.getList("usuarios")
                
                guard !usuarios.isEmpty else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No se pudo obtener la lista de usuarios. Verifica tu conexión a internet."])
                }
                
                // Step 3: Find user match
                let input = user.lowercased()
                guard let match = usuarios.first(where: {
                    ($0["username"] as? String ?? "").lowercased() == input ||
                    ($0["email"] as? String ?? "").lowercased() == input
                }) else {
                    let available = usuarios.compactMap { $0["username"] as? String }.joined(separator: ", ")
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Usuario \"\(user)\" no encontrado. Usuarios disponibles: \(available)"])
                }
                
                // Step 4: Validate password
                guard let storedPass = match["password"] as? String, !storedPass.isEmpty else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "El usuario no tiene contraseña configurada."])
                }
                guard storedPass == password else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Contraseña incorrecta para \"\(match["username"] ?? "")\""])
                }
                
                // Step 5: Load permissions
                let roles = try? await fb.getList("roles")
                SessionManager.shared.setUser(match, roles: roles ?? [])
                self.saveCredentials()
                
                // Step 6: Navigate to home
                await MainActor.run {
                    let homeVC = HomeViewController()
                    let nav = UINavigationController(rootViewController: homeVC)
                    nav.modalPresentationStyle = .fullScreen
                    nav.modalTransitionStyle = .crossDissolve
                    self.present(nav, animated: true)
                }
            } catch {
                await MainActor.run {
                    self.triggerShake()
                    let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
            await MainActor.run {
                self.loginButton.isEnabled = true
                self.loginButton.setTitle("Iniciar Sesión", for: .normal)
                indicator.removeFromSuperview()
            }
        }
    }
    
    deinit {
        displayLink?.invalidate()
    }
}
