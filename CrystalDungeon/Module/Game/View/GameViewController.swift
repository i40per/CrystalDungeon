//
//  GameViewController.swift
//  CrystalDungeon
//
//  Created by Евгений Лукин on 18.03.2026.
//

import UIKit

// MARK: - GameViewProtocol
protocol GameViewProtocol: AnyObject {
    func display(output: String)
    func setWaitingForRoomCountState()
    func setGameCommandsState()
}

// MARK: - GameViewController
final class GameViewController: UIViewController {

    // MARK: - Properties
    var presenter: GamePresenterProtocol!

    private var bottomContainerBottomConstraint: NSLayoutConstraint?

    // MARK: - UI
    private let outputScrollView: UIScrollView = .disableTamic(view: UIScrollView()) {
        $0.showsVerticalScrollIndicator = true
        $0.keyboardDismissMode = .interactive
    }

    private let outputContentView: UIView = .disableTamic(view: UIView()) {
        $0.backgroundColor = .clear
    }

    private let outputLabel: UILabel = .disableTamic(view: UILabel()) {
        $0.textColor = .white
        $0.textAlignment = .center
        $0.numberOfLines = 0
        $0.font = .preferredFont(forTextStyle: .title3)
        $0.adjustsFontForContentSizeCategory = true
        $0.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    private let helpLabel: UILabel = .disableTamic(view: UILabel()) {
        $0.textColor = .white
        $0.textAlignment = .center
        $0.numberOfLines = 0
        $0.font = .preferredFont(forTextStyle: .body)
        $0.adjustsFontForContentSizeCategory = true
    }

    private let commandTextField: UITextField = .disableTamic(view: UITextField()) {
        $0.borderStyle = .roundedRect
        $0.backgroundColor = .white
        $0.textColor = .black
        $0.tintColor = .systemBlue
        $0.autocapitalizationType = .none
        $0.autocorrectionType = .no
        $0.returnKeyType = .done
        $0.clearButtonMode = .whileEditing
        $0.font = .preferredFont(forTextStyle: .body)
        $0.adjustsFontForContentSizeCategory = true
    }

    private let sendButton: UIButton = .disableTamic(view: UIButton(type: .system)) {
        var config = UIButton.Configuration.filled()
        
        config.title = "Отправить"
        config.baseForegroundColor = .white
        config.baseBackgroundColor = .darkGray
        
        config.contentInsets = NSDirectionalEdgeInsets(
            top: 12,
            leading: 16,
            bottom: 12,
            trailing: 16
        )
        
        $0.configuration = config
        
        $0.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        $0.titleLabel?.adjustsFontForContentSizeCategory = true
        
        $0.layer.cornerRadius = 10
        $0.clipsToBounds = true
    }

    private let bottomContainer: UIView = .disableTamic(view: UIView()) {
        $0.backgroundColor = .clear
    }

    private lazy var bottomStack: UIStackView = .disableTamic(
        view: UIStackView(arrangedSubviews: [helpLabel, commandTextField, sendButton])
    ) {
        $0.axis = .vertical
        $0.spacing = 16
        $0.alignment = .fill
        $0.distribution = .fill
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        setupKeyboardObservers()
        setupTapToDismissKeyboard()

        setWaitingForRoomCountState()
        presenter.viewDidLoad()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - GameViewProtocol
extension GameViewController: GameViewProtocol {

    func display(output: String) {
        outputLabel.attributedText = makeAttributedOutput(from: output)

        view.layoutIfNeeded()

        let scrollHeight = outputScrollView.bounds.height
        let contentHeight = outputScrollView.contentSize.height

        if contentHeight > scrollHeight {
            outputScrollView.setContentOffset(.zero, animated: false)
        }
    }

    func setWaitingForRoomCountState() {
        helpLabel.text = "Введите количество комнат.\nМинимум: 4"
        commandTextField.placeholder = "Например: 4"
        commandTextField.attributedPlaceholder = NSAttributedString(
            string: "Например: 4",
            attributes: [.foregroundColor: UIColor.lightGray]
        )
        commandTextField.keyboardType = .numberPad

        refreshKeyboardIfNeeded()
    }

    func setGameCommandsState() {
        helpLabel.text = "Команды: n, s, e, w,\nget [item], drop [item], eat [item],\nopen chest, fight"
        commandTextField.placeholder = "Введите команду"
        commandTextField.attributedPlaceholder = NSAttributedString(
            string: "Введите команду",
            attributes: [.foregroundColor: UIColor.lightGray]
        )
        commandTextField.keyboardType = .default

        refreshKeyboardIfNeeded()
    }
}

// MARK: - Setup
private extension GameViewController {

    func setupUI() {
        view.backgroundColor = UIColor(named: "AppBackground") ?? .black

        view.addSubviews(outputScrollView, bottomContainer)
        outputScrollView.addSubview(outputContentView)
        outputContentView.addSubview(outputLabel)
        bottomContainer.addSubview(bottomStack)

        commandTextField.delegate = self

        commandTextField.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        sendButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true

        bottomContainerBottomConstraint = bottomContainer.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor,
            constant: -16
        )

        NSLayoutConstraint.activate([
            outputScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            outputScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            outputScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            outputScrollView.bottomAnchor.constraint(equalTo: bottomContainer.topAnchor, constant: -12),

            bottomContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            bottomContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            bottomContainerBottomConstraint!,

            bottomStack.topAnchor.constraint(equalTo: bottomContainer.topAnchor),
            bottomStack.leadingAnchor.constraint(equalTo: bottomContainer.leadingAnchor),
            bottomStack.trailingAnchor.constraint(equalTo: bottomContainer.trailingAnchor),
            bottomStack.bottomAnchor.constraint(equalTo: bottomContainer.bottomAnchor),

            outputContentView.topAnchor.constraint(equalTo: outputScrollView.contentLayoutGuide.topAnchor),
            outputContentView.leadingAnchor.constraint(equalTo: outputScrollView.contentLayoutGuide.leadingAnchor),
            outputContentView.trailingAnchor.constraint(equalTo: outputScrollView.contentLayoutGuide.trailingAnchor),
            outputContentView.bottomAnchor.constraint(equalTo: outputScrollView.contentLayoutGuide.bottomAnchor),

            outputContentView.widthAnchor.constraint(equalTo: outputScrollView.frameLayoutGuide.widthAnchor),
            outputContentView.heightAnchor.constraint(greaterThanOrEqualTo: outputScrollView.frameLayoutGuide.heightAnchor),

            outputLabel.leadingAnchor.constraint(equalTo: outputContentView.leadingAnchor),
            outputLabel.trailingAnchor.constraint(equalTo: outputContentView.trailingAnchor),
            outputLabel.centerYAnchor.constraint(equalTo: outputContentView.centerYAnchor),
            outputLabel.topAnchor.constraint(greaterThanOrEqualTo: outputContentView.topAnchor),
            outputLabel.bottomAnchor.constraint(lessThanOrEqualTo: outputContentView.bottomAnchor)
        ])
    }

    func setupActions() {
        sendButton.addTarget(self, action: #selector(sendCommand), for: .touchUpInside)
    }

    func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    func setupTapToDismissKeyboard() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
    }

    func refreshKeyboardIfNeeded() {
        guard commandTextField.isFirstResponder else { return }

        commandTextField.resignFirstResponder()
        commandTextField.becomeFirstResponder()
    }

    func makeAttributedOutput(from output: String) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineSpacing = 4

        let attributedText = NSMutableAttributedString(
            string: output,
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: .title3),
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraphStyle
            ]
        )

        let fullText = output as NSString
        let lines = output.components(separatedBy: "\n")
        var searchLocation = 0

        for line in lines {
            let lineRange = fullText.range(
                of: line,
                options: [],
                range: NSRange(location: searchLocation, length: fullText.length - searchLocation)
            )

            guard lineRange.location != NSNotFound else { continue }

            if line.contains("There is an evil") || line.contains("Time left:") {
                attributedText.addAttribute(
                    .foregroundColor,
                    value: UIColor.appDangerText,
                    range: lineRange
                )
            }

            searchLocation = lineRange.location + lineRange.length
        }

        return attributedText
    }
}

// MARK: - Actions
private extension GameViewController {

    @objc func sendCommand() {
        guard let text = commandTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            return
        }

        presenter.handle(command: text)
        commandTextField.text = ""
    }

    @objc func keyboardWillShow(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        else {
            return
        }

        let keyboardFrameInView = view.convert(keyboardFrame, from: nil)
        let overlap = max(0, view.bounds.maxY - keyboardFrameInView.minY)

        bottomContainerBottomConstraint?.constant = -(overlap + 8)

        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        else {
            return
        }

        bottomContainerBottomConstraint?.constant = -16

        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

// MARK: - UITextFieldDelegate
extension GameViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendCommand()
        return true
    }
}

// MARK: - UIGestureRecognizerDelegate
extension GameViewController: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let touchedView = touch.view else { return true }

        if touchedView is UIControl {
            return false
        }

        if touchedView.isDescendant(of: sendButton) || touchedView.isDescendant(of: commandTextField) {
            return false
        }

        return true
    }
}
