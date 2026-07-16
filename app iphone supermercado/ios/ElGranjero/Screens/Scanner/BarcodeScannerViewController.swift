import UIKit
import AVFoundation

class BarcodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private let onScan: (String) -> Void
    private var didScan = false

    init(onScan: @escaping (String) -> Void) {
        self.onScan = onScan
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black; setupCamera(); setupOverlay()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if captureSession?.isRunning == false { DispatchQueue.global(qos: .userInitiated).async { self.captureSession?.startRunning() } }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession?.isRunning == true { DispatchQueue.global(qos: .userInitiated).async { self.captureSession?.stopRunning() } }
    }

    private func setupCamera() {
        captureSession = AVCaptureSession()
        guard let device = AVCaptureDevice.default(for: .video), let input = try? AVCaptureDeviceInput(device: device), captureSession.canAddInput(input) else { showError(); return }
        captureSession.addInput(input)

        let output = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            output.metadataObjectTypes = [.ean13, .ean8, .upce, .code128, .code39, .code93, .qr, .pdf417, .dataMatrix]
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds; previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        DispatchQueue.global(qos: .userInitiated).async { self.captureSession.startRunning() }
    }

    private func setupOverlay() {
        let overlay = UIView(); overlay.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        overlay.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(overlay)
        NSLayoutConstraint.activate([overlay.topAnchor.constraint(equalTo: view.topAnchor), overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor), overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor), overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)])

        let scanSize: CGFloat = min(view.bounds.width, view.bounds.height) * 0.6
        let scanRect = CGRect(x: (view.bounds.width - scanSize) / 2, y: (view.bounds.height - scanSize) / 2 - 40, width: scanSize, height: scanSize)
        let path = UIBezierPath(rect: view.bounds); path.append(UIBezierPath(rect: scanRect).reversing())
        let mask = CAShapeLayer(); mask.path = path.cgPath; overlay.layer.mask = mask

        let scanBorder = UIView(); scanBorder.layer.borderColor = UIColor(red: 1, green: 0.84, blue: 0.2, alpha: 0.8).cgColor; scanBorder.layer.borderWidth = 2; scanBorder.layer.cornerRadius = 12
        scanBorder.frame = scanRect; view.addSubview(scanBorder)

        let label = UILabel(); label.text = "Apunte al código de barras"; label.textColor = .white; label.font = .systemFont(ofSize: 16, weight: .medium); label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(label)
        NSLayoutConstraint.activate([label.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -120), label.centerXAnchor.constraint(equalTo: view.centerXAnchor)])

        let cancelBtn = UIButton(type: .system); cancelBtn.setTitle("Cancelar", for: .normal); cancelBtn.setTitleColor(.white, for: .normal)
        cancelBtn.titleLabel?.font = .systemFont(ofSize: 17); cancelBtn.addTarget(self, action: #selector(dismissScanner), for: .touchUpInside)
        cancelBtn.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(cancelBtn)
        NSLayoutConstraint.activate([cancelBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12), cancelBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16)])

        let flashBtn = UIButton(type: .system); flashBtn.setImage(UIImage(systemName: "bolt.slash.fill"), for: .normal); flashBtn.tintColor = .white
        flashBtn.addTarget(self, action: #selector(toggleFlash), for: .touchUpInside)
        flashBtn.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(flashBtn)
        NSLayoutConstraint.activate([flashBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12), flashBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16), flashBtn.widthAnchor.constraint(equalToConstant: 44), flashBtn.heightAnchor.constraint(equalToConstant: 44)])
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !didScan, let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject, let code = obj.stringValue else { return }
        didScan = true; dismiss(animated: true) { self.onScan(code) }
    }

    @objc private func dismissScanner() { dismiss(animated: true) }
    @objc private func toggleFlash() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        try? device.lockForConfiguration(); device.torchMode = device.torchMode == .on ? .off : .on; device.unlockForConfiguration()
    }

    private func showError() {
        let a = UIAlertController(title: "Error", message: "No se pudo acceder a la cámara.", preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in self?.dismissScanner() }); present(a, animated: true)
    }
}
