//
//  KeyboardViewController.swift
//  WordsKeyboard
//
//  Created by Julia Teleki on 3/31/26.
//

import UIKit

final class KeyboardViewController: UIInputViewController {

    private let suggestionBar = UIStackView()
    private let keyboardStack = UIStackView()
    private var internalBuffer: String = ""

    private var currentToken: String = "" {
        didSet { updateSuggestion() }
    }

    private var currentSuggestion: VocabWord? {
        didSet { refreshSuggestionUI() }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        preferredContentSize = CGSize(width: UIScreen.main.bounds.width, height: 260)
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        let minHeightConstraint = view.heightAnchor.constraint(greaterThanOrEqualToConstant: 260)
        minHeightConstraint.isActive = true

        suggestionBar.axis = .horizontal
        suggestionBar.alignment = .fill
        suggestionBar.distribution = .fillProportionally
        suggestionBar.spacing = 8

        let divider = UIView()
        divider.backgroundColor = .separator
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale).isActive = true

        keyboardStack.axis = .vertical
        keyboardStack.alignment = .fill
        keyboardStack.distribution = .fillEqually
        keyboardStack.spacing = 6

        let root = UIStackView(arrangedSubviews: [suggestionBar, divider, keyboardStack])
        root.axis = .vertical
        root.spacing = 8
        root.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(root)

        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            root.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            root.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            root.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8)
        ])

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

        for ch in keys {
            row.addArrangedSubview(makeKeyButton(title: String(ch)))
        }

        keyboardStack.addArrangedSubview(row)
    }

    private func addBottomRow() {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .fill
        row.spacing = 6

        let next = makeSystemButton(title: "🌐", action: #selector(nextKeyboardTapped))

        let letterRow = UIStackView()
        letterRow.axis = .horizontal
        letterRow.alignment = .fill
        letterRow.distribution = .fillEqually
        letterRow.spacing = 6

        for ch in "zxcvbnm" {
            letterRow.addArrangedSubview(makeKeyButton(title: String(ch)))
        }

        let backspace = makeSystemButton(title: "⌫", action: #selector(backspaceTapped))
        let space = makeSystemButton(title: "space", action: #selector(spaceTapped))
        let returnKey = makeSystemButton(title: "return", action: #selector(returnTapped))

        next.widthAnchor.constraint(equalToConstant: 44).isActive = true
        backspace.widthAnchor.constraint(equalToConstant: 52).isActive = true
        returnKey.widthAnchor.constraint(equalToConstant: 72).isActive = true

        row.addArrangedSubview(next)
        row.addArrangedSubview(letterRow)
        row.addArrangedSubview(backspace)
        row.addArrangedSubview(space)
        row.addArrangedSubview(returnKey)

        space.setContentHuggingPriority(.defaultLow, for: .horizontal)
        space.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        keyboardStack.addArrangedSubview(row)
    }

    private func makeKeyButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseBackgroundColor = .secondarySystemBackground
        config.baseForegroundColor = .label
        config.cornerStyle = .large
        button.configuration = config
        button.titleLabel?.font = .systemFont(ofSize: 18)
        button.addTarget(self, action: #selector(keyTapped(_:)), for: .touchUpInside)
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        return button
    }

    private func makeSystemButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.gray()
        config.title = title
        config.cornerStyle = .large
        button.configuration = config
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    @objc private func keyTapped(_ sender: UIButton) {
        guard let text = sender.currentTitle else { return }
        textDocumentProxy.insertText(text)
        internalBuffer.append(text)
        updateCurrentTokenFromProxy()
    }

    @objc private func spaceTapped() {
        textDocumentProxy.insertText(" ")
        internalBuffer.append(" ")
        updateCurrentTokenFromProxy()
    }

    @objc private func backspaceTapped() {
        textDocumentProxy.deleteBackward()
        if !internalBuffer.isEmpty {
            internalBuffer.removeLast()
        }
        updateCurrentTokenFromProxy()
    }

    @objc private func returnTapped() {
        textDocumentProxy.insertText("\n")
        internalBuffer.append("\n")
        updateCurrentTokenFromProxy()
    }

    @objc private func nextKeyboardTapped() {
        advanceToNextInputMode()
    }

    private func refreshSuggestionUI() {
        suggestionBar.arrangedSubviews.forEach { view in
            suggestionBar.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

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

        for _ in 0..<currentToken.count {
            textDocumentProxy.deleteBackward()
        }

        textDocumentProxy.insertText(replacement)

        if !currentToken.isEmpty,
           let range = internalBuffer.range(of: currentToken, options: [.backwards, .caseInsensitive]) {
            internalBuffer.removeSubrange(range)
        }

        internalBuffer.append(replacement)
        currentToken = ""
        currentSuggestion = nil
    }

    private func updateSuggestion() {
        if let match = VocabData.suggestion(for: currentToken),
           match.word.lowercased() != currentToken.lowercased() {
            currentSuggestion = match
        } else {
            currentSuggestion = nil
        }
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        updateCurrentTokenFromProxy()
    }

    override func selectionDidChange(_ textInput: UITextInput?) {
        super.selectionDidChange(textInput)
        updateCurrentTokenFromProxy()
    }

    private func updateCurrentTokenFromProxy() {
        let before = textDocumentProxy.documentContextBeforeInput
        let source = (before?.isEmpty == false) ? before! : internalBuffer
        currentToken = extractLastToken(from: source)
    }

    private func extractLastToken(from text: String) -> String {
        let separators = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)
        let components = text.components(separatedBy: separators).filter { !$0.isEmpty }
        return components.last ?? ""
    }

    private func matchCasing(of typed: String, to suggestion: String) -> String {
        guard !typed.isEmpty else { return suggestion }

        if typed == typed.uppercased() {
            return suggestion.uppercased()
        }

        if typed.prefix(1) == typed.prefix(1).uppercased(),
           typed.dropFirst() == typed.dropFirst().lowercased() {
            return suggestion.prefix(1).uppercased() + suggestion.dropFirst().lowercased()
        }

        return suggestion.lowercased()
    }
}
