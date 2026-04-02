//
//  KeyboardViewController.swift
//  WordsKeyboard
//
//  Created by Julia Teleki on 3/31/26.
//

import UIKit

final class KeyboardViewController: UIInputViewController {

    private let suggestionContainer = UIView()
    private let suggestionBar = UIStackView()
    private let keyboardStack = UIStackView()

    private var internalBuffer: String = ""
    private var isShiftEnabled = false {
        didSet { refreshLetterKeys() }
    }

    private var letterButtons: [UIButton] = []

    private var currentToken: String = "" {
        didSet { updateSuggestion() }
    }

    private var currentSuggestion: VocabWord? {
        didSet { refreshSuggestionUI() }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        preferredContentSize = CGSize(width: view.bounds.width, height: 230)
    }

    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.82, green: 0.84, blue: 0.88, alpha: 1.0)

        suggestionContainer.translatesAutoresizingMaskIntoConstraints = false
        suggestionContainer.backgroundColor = .clear

        suggestionBar.axis = .horizontal
        suggestionBar.alignment = .fill
        suggestionBar.distribution = .fill
        suggestionBar.spacing = 8
        suggestionBar.translatesAutoresizingMaskIntoConstraints = false

        suggestionContainer.addSubview(suggestionBar)

        NSLayoutConstraint.activate([
            suggestionBar.leadingAnchor.constraint(equalTo: suggestionContainer.leadingAnchor, constant: 8),
            suggestionBar.trailingAnchor.constraint(equalTo: suggestionContainer.trailingAnchor, constant: -8),
            suggestionBar.topAnchor.constraint(equalTo: suggestionContainer.topAnchor, constant: 4),
            suggestionBar.bottomAnchor.constraint(equalTo: suggestionContainer.bottomAnchor, constant: -4),
            suggestionContainer.heightAnchor.constraint(equalToConstant: 36)
        ])

        keyboardStack.axis = .vertical
        keyboardStack.alignment = .fill
        keyboardStack.distribution = .fillEqually
        keyboardStack.spacing = 8
        keyboardStack.translatesAutoresizingMaskIntoConstraints = false

        let root = UIStackView(arrangedSubviews: [suggestionContainer, keyboardStack])
        root.axis = .vertical
        root.spacing = 6
        root.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(root)

        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 6),
            root.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -6),
            root.topAnchor.constraint(equalTo: view.topAnchor, constant: 6),
            root.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -6)
        ])

        addLetterRow("qwertyuiop")
        addLetterRow("asdfghjkl")
        addBottomLetterRow()
        addActionRow()
    }

    private func addLetterRow(_ letters: String) {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .fill
        row.distribution = .fillEqually
        row.spacing = 6

        for char in letters {
            let button = makeLetterButton(title: String(char))
            letterButtons.append(button)
            row.addArrangedSubview(button)
        }

        keyboardStack.addArrangedSubview(row)
    }

    private func addBottomLetterRow() {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .fill
        row.spacing = 6

        let shift = makeModifierButton(title: "⇧", action: #selector(shiftTapped))
        shift.widthAnchor.constraint(equalToConstant: 42).isActive = true

        row.addArrangedSubview(shift)

        let letters = UIStackView()
        letters.axis = .horizontal
        letters.alignment = .fill
        letters.distribution = .fillEqually
        letters.spacing = 6

        for char in "zxcvbnm" {
            let button = makeLetterButton(title: String(char))
            letterButtons.append(button)
            letters.addArrangedSubview(button)
        }

        row.addArrangedSubview(letters)

        let delete = makeModifierButton(title: "⌫", action: #selector(backspaceTapped))
        delete.widthAnchor.constraint(equalToConstant: 42).isActive = true
        row.addArrangedSubview(delete)

        keyboardStack.addArrangedSubview(row)
    }

    private func addActionRow() {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .fill
        row.spacing = 6

        let globe = makeModifierButton(title: "🌐", action: #selector(nextKeyboardTapped))
        globe.widthAnchor.constraint(equalToConstant: 42).isActive = true

        let space = makeWideButton(title: "space", action: #selector(spaceTapped))
        let `return` = makeWideButton(title: "return", action: #selector(returnTapped))
        `return`.widthAnchor.constraint(equalToConstant: 82).isActive = true

        row.addArrangedSubview(globe)
        row.addArrangedSubview(space)
        row.addArrangedSubview(`return`)

        keyboardStack.addArrangedSubview(row)
    }

    private func makeLetterButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 6
        button.backgroundColor = .white
        button.setTitle(title, for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 22)
        button.addTarget(self, action: #selector(letterTapped(_:)), for: .touchUpInside)
        return button
    }

    private func makeModifierButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 6
        button.backgroundColor = UIColor(red: 0.68, green: 0.70, blue: 0.75, alpha: 1.0)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .semibold)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func makeWideButton(title: String, action: Selector) -> UIButton {
        let button = makeModifierButton(title: title, action: action)
        button.titleLabel?.font = .systemFont(ofSize: 18)
        return button
    }

    private func refreshLetterKeys() {
        for button in letterButtons {
            guard let current = button.title(for: .normal) else { continue }
            let updated = isShiftEnabled ? current.uppercased() : current.lowercased()
            button.setTitle(updated, for: .normal)
        }
    }

    private func refreshSuggestionUI() {
        suggestionBar.arrangedSubviews.forEach {
            suggestionBar.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        guard let suggestion = currentSuggestion else { return }

        let chip = UIButton(type: .system)
        chip.layer.cornerRadius = 16
        chip.backgroundColor = .white
        chip.setTitle("Replace with \(suggestion.word)", for: .normal)
        chip.setTitleColor(.black, for: .normal)
        chip.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        chip.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        chip.addTarget(self, action: #selector(applySuggestion), for: .touchUpInside)

        suggestionBar.addArrangedSubview(chip)
    }

    private func updateSuggestion() {
        if let match = VocabData.suggestion(for: currentToken),
           match.word.lowercased() != currentToken.lowercased() {
            currentSuggestion = match
        } else {
            currentSuggestion = nil
        }
    }

    @objc private func letterTapped(_ sender: UIButton) {
        guard let text = sender.title(for: .normal) else { return }
        textDocumentProxy.insertText(text)
        internalBuffer.append(text)
        updateCurrentTokenFromProxy()

        if isShiftEnabled {
            isShiftEnabled = false
        }
    }

    @objc private func shiftTapped() {
        isShiftEnabled.toggle()
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
