//
//  KeyboardViewController.swift
//  WordsKeyboard
//
//  A minimal custom keyboard that suggests bigger vocab words when the user types a simpler synonym.
//

import UIKit

final class KeyboardViewController: UIInputViewController {

    private let suggestionBar = UIStackView()
    private let keyboardStack = UIStackView()

    // Track the last token to compute suggestions
    private var currentToken: String = "" { didSet { updateSuggestion() } }
    private var currentSuggestion: VocabWord? { didSet { refreshSuggestionUI() } }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground

        // Ensure the keyboard has a reasonable minimum height so rows are visible
        view.translatesAutoresizingMaskIntoConstraints = false
        let minHeightConstraint = view.heightAnchor.constraint(greaterThanOrEqualToConstant: 216)
        minHeightConstraint.priority = .required
        minHeightConstraint.isActive = true

        // Suggestion bar
        suggestionBar.axis = .horizontal
        suggestionBar.alignment = .fill
        suggestionBar.distribution = .fillProportionally
        suggestionBar.spacing = 8

        let divider = UIView()
        divider.backgroundColor = .separator
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale).isActive = true

        // Keyboard stack (rows)
        keyboardStack.axis = .vertical
        keyboardStack.alignment = .fill
        keyboardStack.distribution = .fillEqually
        keyboardStack.spacing = 6

        let root = UIStackView(arrangedSubviews: [suggestionBar, divider, keyboardStack])
        root.axis = .vertical
        root.spacing = 6
        root.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(root)
        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            root.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            root.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            root.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8)
        ])

        // Build a simple QWERTY layout
        addRow(keys: "qwertyuiop")
        addRow(keys: "asdfghjkl")
        addBottomRow()
    }

    private func addRow(keys: String) {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .fill
        row.distribution = .fillEqually
        row.spacing = 6
        for ch in keys { row.addArrangedSubview(makeKeyButton(title: String(ch))) }
        keyboardStack.addArrangedSubview(row)
    }

    private func addBottomRow() {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .fill
        row.spacing = 6

        let next = makeSystemButton(title: "🌐", action: #selector(nextKeyboardTapped))
        let zxcRow = UIStackView()
        zxcRow.axis = .horizontal
        zxcRow.alignment = .fill
        zxcRow.distribution = .fillEqually
        zxcRow.spacing = 6
        for ch in "zxcvbnm" { zxcRow.addArrangedSubview(makeKeyButton(title: String(ch))) }

        let backspace = makeSystemButton(title: "⌫", action: #selector(backspaceTapped))
        let space = makeSystemButton(title: "space", action: #selector(spaceTapped))
        space.contentHorizontalAlignment = .center
        space.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        let `return` = makeSystemButton(title: "return", action: #selector(returnTapped))

        // Layout proportions
        next.widthAnchor.constraint(equalToConstant: 44).isActive = true
        backspace.widthAnchor.constraint(equalToConstant: 52).isActive = true
        `return`.widthAnchor.constraint(equalToConstant: 72).isActive = true

        row.addArrangedSubview(next)
        row.addArrangedSubview(zxcRow)
        row.addArrangedSubview(backspace)
        row.addArrangedSubview(space)
        row.addArrangedSubview(`return`)

        // Make space expand
        space.setContentHuggingPriority(.defaultLow, for: .horizontal)
        space.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        keyboardStack.addArrangedSubview(row)
    }

    private func makeKeyButton(title: String) -> UIButton {
        let b = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseBackgroundColor = .secondarySystemBackground
        config.baseForegroundColor = .label
        config.cornerStyle = .large
        b.configuration = config
        b.titleLabel?.font = .systemFont(ofSize: 18)
        b.addTarget(self, action: #selector(keyTapped(_:)), for: .touchUpInside)
        return b
    }

    private func makeSystemButton(title: String, action: Selector) -> UIButton {
        let b = UIButton(type: .system)
        var config = UIButton.Configuration.gray()
        config.title = title
        config.cornerStyle = .large
        b.configuration = config
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        b.addTarget(self, action: action, for: .touchUpInside)
        return b
    }

    // MARK: - Actions
    @objc private func keyTapped(_ sender: UIButton) {
        guard let t = sender.currentTitle else { return }
        textDocumentProxy.insertText(t)
        updateCurrentTokenFromProxy()
    }

    @objc private func spaceTapped() {
        textDocumentProxy.insertText(" ")
        updateCurrentTokenFromProxy()
    }

    @objc private func backspaceTapped() {
        textDocumentProxy.deleteBackward()
        updateCurrentTokenFromProxy()
    }

    @objc private func returnTapped() {
        textDocumentProxy.insertText("\n")
        updateCurrentTokenFromProxy()
    }

    @objc private func nextKeyboardTapped() {
        advanceToNextInputMode()
    }

    private func refreshSuggestionUI() {
        // Clear existing
        suggestionBar.arrangedSubviews.forEach { $0.removeFromSuperview() }

        guard let suggestion = currentSuggestion else { return }

        let button = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = suggestion.word.capitalized
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        config.cornerStyle = .capsule
        button.configuration = config
        button.addTarget(self, action: #selector(applySuggestion), for: .touchUpInside)

        suggestionBar.addArrangedSubview(button)
    }

    @objc private func applySuggestion() {
        guard let suggestion = currentSuggestion else { return }
        let replacement = matchCasing(of: currentToken, to: suggestion.word)

        // Delete the currently typed token characters
        for _ in 0..<currentToken.count { textDocumentProxy.deleteBackward() }
        // Insert the vocab word with matched casing
        textDocumentProxy.insertText(replacement)

        // Clear suggestion after applying
        currentToken = ""
        currentSuggestion = nil
    }

    private func updateSuggestion() {
        if let match = VocabData.suggestion(for: currentToken), match.word.lowercased() != currentToken.lowercased() {
            currentSuggestion = match
        } else {
            currentSuggestion = nil
        }
    }

    // Called by the system when text around the cursor changes
    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        updateCurrentTokenFromProxy()
    }

    override func selectionDidChange(_ textInput: UITextInput?) {
        super.selectionDidChange(textInput)
        updateCurrentTokenFromProxy()
    }

    private func updateCurrentTokenFromProxy() {
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        currentToken = extractLastToken(from: before)
    }

    private func extractLastToken(from text: String) -> String {
        // Split on whitespace and punctuation to get the last token
        let separators = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)
        let comps = text.components(separatedBy: separators).filter { !$0.isEmpty }
        return comps.last ?? ""
    }

    private func matchCasing(of typed: String, to suggestion: String) -> String {
        guard !typed.isEmpty else { return suggestion }
        if typed == typed.uppercased() { return suggestion.uppercased() }
        if typed.prefix(1) == typed.prefix(1).uppercased() && typed.dropFirst() == typed.dropFirst().lowercased() {
            return suggestion.prefix(1).uppercased() + suggestion.dropFirst().lowercased()
        }
        return suggestion.lowercased()
    }
}

