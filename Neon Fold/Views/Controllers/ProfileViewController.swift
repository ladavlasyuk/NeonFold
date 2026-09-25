import UIKit
import AVFoundation

final class ProfileViewController: UIViewController {
    private var backgroundGradient: CAGradientLayer?
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let portraitView = UIImageView()
    private let initialsLabel = UILabel()
    private let nameField = UITextField()

    private var captureButton: UIButton!
    private var libraryButton: UIButton!
    private var removeButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        backgroundGradient = Theme.applyBackground(to: view)
        setupNavBar()
        setupScroll()
        buildContent()
        refreshPortrait()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        OrientationController.shared.lockToPortrait()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        commitName()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradient?.frame = view.bounds
    }

    private func setupNavBar() {
        let backButton = Theme.backButton(target: self, action: #selector(backTapped))
        view.addSubview(backButton)

        let titleLabel = UILabel()
        titleLabel.text = "PLAYER PROFILE"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .black)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 46),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24)
        ])
    }

    private func setupScroll() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 96),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 4),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -32),
            contentStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -48)
        ])
    }

    private func buildContent() {
        contentStack.addArrangedSubview(makePortraitCard())
        contentStack.addArrangedSubview(makeNameCard())

        captureButton = Theme.gradientButton(title: "TAKE A PHOTO", colors: [Palette.primary, Palette.primaryDark], height: 54, fontSize: 18)
        libraryButton = Theme.flatButton(title: "Choose From Library", height: 50, fontSize: 16)
        removeButton = Theme.flatButton(title: "Remove Photo", height: 44, fontSize: 15)
        removeButton.setTitleColor(Palette.danger, for: .normal)

        contentStack.addArrangedSubview(captureButton)
        contentStack.addArrangedSubview(libraryButton)
        contentStack.addArrangedSubview(removeButton)

        captureButton.addTarget(self, action: #selector(captureTapped), for: .touchUpInside)
        libraryButton.addTarget(self, action: #selector(libraryTapped), for: .touchUpInside)
        removeButton.addTarget(self, action: #selector(removeTapped), for: .touchUpInside)
    }

    private func makePortraitCard() -> UIView {
        let card = UIView()
        card.backgroundColor = Palette.card
        card.layer.cornerRadius = 20
        card.layer.cornerCurve = .continuous

        portraitView.translatesAutoresizingMaskIntoConstraints = false
        portraitView.contentMode = .scaleAspectFill
        portraitView.clipsToBounds = true
        portraitView.layer.cornerRadius = 68
        portraitView.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        portraitView.layer.borderWidth = 2
        portraitView.layer.borderColor = Palette.gold.withAlphaComponent(0.7).cgColor

        initialsLabel.translatesAutoresizingMaskIntoConstraints = false
        initialsLabel.font = UIFont.systemFont(ofSize: 44, weight: .black)
        initialsLabel.textColor = Palette.gold
        initialsLabel.textAlignment = .center

        let noteLabel = UILabel()
        noteLabel.translatesAutoresizingMaskIntoConstraints = false
        noteLabel.text = "Your photo stays on this device."
        noteLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        noteLabel.textColor = UIColor.white.withAlphaComponent(0.6)
        noteLabel.textAlignment = .center
        noteLabel.numberOfLines = 0

        card.addSubview(portraitView)
        card.addSubview(initialsLabel)
        card.addSubview(noteLabel)

        NSLayoutConstraint.activate([
            portraitView.topAnchor.constraint(equalTo: card.topAnchor, constant: 24),
            portraitView.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            portraitView.widthAnchor.constraint(equalToConstant: 136),
            portraitView.heightAnchor.constraint(equalToConstant: 136),

            initialsLabel.centerXAnchor.constraint(equalTo: portraitView.centerXAnchor),
            initialsLabel.centerYAnchor.constraint(equalTo: portraitView.centerYAnchor),

            noteLabel.topAnchor.constraint(equalTo: portraitView.bottomAnchor, constant: 14),
            noteLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            noteLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            noteLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20)
        ])

        return card
    }

    private func makeNameCard() -> UIView {
        let card = UIView()
        card.backgroundColor = Palette.card
        card.layer.cornerRadius = 16
        card.layer.cornerCurve = .continuous

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "DISPLAY NAME"
        titleLabel.font = UIFont.systemFont(ofSize: 12, weight: .heavy)
        titleLabel.textColor = Palette.gold

        nameField.translatesAutoresizingMaskIntoConstraints = false
        nameField.text = ProfileManager.shared.displayName
        nameField.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        nameField.textColor = .white
        nameField.tintColor = Palette.primary
        nameField.autocorrectionType = .no
        nameField.returnKeyType = .done
        nameField.delegate = self
        nameField.attributedPlaceholder = NSAttributedString(
            string: "Neon Folder",
            attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.4)]
        )

        card.addSubview(titleLabel)
        card.addSubview(nameField)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),

            nameField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            nameField.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            nameField.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            nameField.heightAnchor.constraint(equalToConstant: 34),
            nameField.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])

        return card
    }

    private func refreshPortrait() {
        if let portrait = ProfileManager.shared.portrait() {
            portraitView.image = portrait
            initialsLabel.isHidden = true
            removeButton.isHidden = false
        } else {
            portraitView.image = nil
            initialsLabel.text = ProfileManager.shared.initials
            initialsLabel.isHidden = false
            removeButton.isHidden = true
        }
    }

    private func commitName() {
        guard let text = nameField.text else { return }
        ProfileManager.shared.displayName = text
        nameField.text = ProfileManager.shared.displayName
        initialsLabel.text = ProfileManager.shared.initials
    }

    @objc private func captureTapped() {
        HapticsManager.shared.lightImpact()
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            presentNotice(
                title: "Camera unavailable",
                message: "This device does not offer a camera for capturing a photo."
            )
            return
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            presentPicker(source: .camera)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    guard granted else {
                        self?.presentPermissionNotice()
                        return
                    }
                    self?.presentPicker(source: .camera)
                }
            }
        default:
            presentPermissionNotice()
        }
    }

    @objc private func libraryTapped() {
        HapticsManager.shared.lightImpact()
        presentPicker(source: .photoLibrary)
    }

    @objc private func removeTapped() {
        HapticsManager.shared.warning()
        ProfileManager.shared.removePortrait()
        refreshPortrait()
    }

    private func presentPicker(source: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(source) else { return }
        let picker = UIImagePickerController()
        picker.sourceType = source
        picker.delegate = self
        picker.allowsEditing = true
        if source == .camera {
            picker.cameraCaptureMode = .photo
            picker.cameraDevice = .front
        }
        present(picker, animated: true)
    }

    private func presentPermissionNotice() {
        let alert = UIAlertController(
            title: "Camera access needed",
            message: "Allow camera access in system settings to capture a profile photo.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Not now", style: .cancel))
        alert.addAction(UIAlertAction(title: "Open settings", style: .default) { _ in
            guard let settings = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(settings)
        })
        present(alert, animated: true)
    }

    private func presentNotice(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}

extension ProfileViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        commitName()
        return true
    }
}

extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        let picked = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
        picker.dismiss(animated: true) { [weak self] in
            guard let self, let picked else { return }
            ProfileManager.shared.savePortrait(picked)
            self.refreshPortrait()
            HapticsManager.shared.success()
            self.animatePortraitUpdate()
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    private func animatePortraitUpdate() {
        portraitView.transform = CGAffineTransform(scaleX: 0.86, y: 0.86)
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.6,
            initialSpringVelocity: 0.3
        ) {
            self.portraitView.transform = .identity
        }
    }
}
