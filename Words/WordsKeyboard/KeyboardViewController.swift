//
//  KeyboardViewController.swift
//  WordsKeyboard
//
//  Created by Julia Teleki on 3/31/26.
//

import UIKit

final class KeyboardViewController: UIInputViewController {

    private enum KeyboardMode {
        case letters
        case numbers
        case symbols
    }

    private let suggestionContainer = UIView()
    private let suggestionBar = UIStackView()
    private let keyboardStack = UIStackView()

    private var internalBuffer: String = ""
    private var keyboardMode: KeyboardMode = .letters
    private var isShiftEnabled = false {
        didSet { rebuildKeyboard() }
    }

    private var currentToken: String = "" {
        didSet { updateSuggestion() }
    }

    private var currentSuggestion: VocabWord? {
        didSet { refreshSuggestionUI() }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        rebuildKeyboard()
        updateCurrentTokenFromProxy()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        preferredContentSize = CGSize(width: view.bounds.width, height: 260)
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        updateCurrentTokenFromProxy()
    }

    override func selectionDidChange(_ textInput: UITextInput?) {
        super.selectionDidChange(textInput)
        updateCurrentTokenFromProxy()
    }

    private func setupUI() {
        view.backgroundColor = keyboardBackgroundColor

        suggestionContainer.translatesAutoresizingMaskIntoConstraints = false
        suggestionContainer.backgroundColor = predictionBarBackgroundColor

        suggestionBar.axis = .horizontal
        suggestionBar.alignment = .fill
        suggestionBar.distribution = .fillEqually
        suggestionBar.spacing = 0
        suggestionBar.translatesAutoresizingMaskIntoConstraints = false

        suggestionContainer.addSubview(suggestionBar)

        NSLayoutConstraint.activate([
            suggestionBar.leadingAnchor.constraint(equalTo: suggestionContainer.leadingAnchor),
            suggestionBar.trailingAnchor.constraint(equalTo: suggestionContainer.trailingAnchor),
            suggestionBar.topAnchor.constraint(equalTo: suggestionContainer.topAnchor),
            suggestionBar.bottomAnchor.constraint(equalTo: suggestionContainer.bottomAnchor),
            suggestionContainer.heightAnchor.constraint(equalToConstant: 38)
        ])

        keyboardStack.axis = .vertical
        keyboardStack.alignment = .fill
        keyboardStack.distribution = .fillEqually
        keyboardStack.spacing = 8
        keyboardStack.translatesAutoresizingMaskIntoConstraints = false

        let root = UIStackView(arrangedSubviews: [suggestionContainer, keyboardStack])
        root.axis = .vertical
        root.spacing = 8
        root.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(root)

        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 6),
            root.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -6),
            root.topAnchor.constraint(equalTo: view.topAnchor, constant: 6),
            root.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -6)
        ])
    }

    private func rebuildKeyboard() {
        keyboardStack.arrangedSubviews.forEach {
            keyboardStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        view.backgroundColor = keyboardBackgroundColor

        switch keyboardMode {
        case .letters:
            addLetterRow("qwertyuiop")
            addLetterRow("asdfghjkl")
            addBottomLetterRow()
            addLetterActionRow()

        case .numbers:
            addCharacterRow(["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"])
            addCharacterRow(["-", "/", ":", ";", "(", ")", "$", "&", "@", "\""])
            addNumbersThirdRow()
            addNumbersActionRow()

        case .symbols:
            addCharacterRow(["[", "]", "{", "}", "#", "%", "^", "*", "+", "="])
            addCharacterRow(["_", "\\", "|", "~", "<", ">", "€", "£", "¥", "•"])
            addSymbolsThirdRow()
            addNumbersActionRow()
        }

        refreshSuggestionUI()
    }

    private func addLetterRow(_ letters: String) {
        let row = makeRow()

        for char in letters {
            row.addArrangedSubview(makeLetterButton(title: displayLetter(for: String(char))))
        }

        keyboardStack.addArrangedSubview(row)
    }

    private func addBottomLetterRow() {
        let row = makeRow()

        let shift = makeModifierButton(title: isShiftEnabled ? "⇪" : "⇧", action: #selector(shiftTapped))
        row.addArrangedSubview(shift)

        for char in "zxcvbnm" {
            row.addArrangedSubview(makeLetterButton(title: displayLetter(for: String(char))))
        }

        let delete = makeModifierButton(title: "⌫", action: #selector(backspaceTapped))
        row.addArrangedSubview(delete)

        keyboardStack.addArrangedSubview(row)
    }

    private func addLetterActionRow() {
        let row = makeRow()

        let numbers = makeModifierButton(title: "123", action: #selector(numbersTapped))

        let globe = makeModifierButton(title: "🌐", action: #selector(nextKeyboardTapped))

        let space = makeSpaceButton()
        let `return` = makeModifierButton(title: "return", action: #selector(returnTapped))

        row.addArrangedSubview(numbers)
        row.addArrangedSubview(globe)
        row.addArrangedSubview(space)
        row.addArrangedSubview(`return`)

        keyboardStack.addArrangedSubview(row)
    }

    private func addCharacterRow(_ characters: [String]) {
        let row = makeRow()

        for character in characters {
            row.addArrangedSubview(makeCharacterButton(title: character))
        }

        keyboardStack.addArrangedSubview(row)
    }

    private func addNumbersThirdRow() {
        let row = makeRow()

        let symbolsToggle = makeModifierButton(title: "#+=", action: #selector(symbolsTapped))
        row.addArrangedSubview(symbolsToggle)

        for character in [".", ",", "?", "!", "'"] {
            row.addArrangedSubview(makeCharacterButton(title: character))
        }

        let delete = makeModifierButton(title: "⌫", action: #selector(backspaceTapped))
        row.addArrangedSubview(delete)

        keyboardStack.addArrangedSubview(row)
    }

    private func addSymbolsThirdRow() {
        let row = makeRow()

        let numbersToggle = makeModifierButton(title: "123", action: #selector(numbersTapped))
        row.addArrangedSubview(numbersToggle)

        for character in [".", ",", "?", "!", "'"] {
            row.addArrangedSubview(makeCharacterButton(title: character))
        }

        let delete = makeModifierButton(title: "⌫", action: #selector(backspaceTapped))
        row.addArrangedSubview(delete)

        keyboardStack.addArrangedSubview(row)
    }

    private func addNumbersActionRow() {
        let row = makeRow()

        let letters = makeModifierButton(title: "ABC", action: #selector(lettersTapped))

        let globe = makeModifierButton(title: "🌐", action: #selector(nextKeyboardTapped))

        let space = makeSpaceButton()
        let `return` = makeModifierButton(title: "return", action: #selector(returnTapped))

        row.addArrangedSubview(letters)
        row.addArrangedSubview(globe)
        row.addArrangedSubview(space)
        row.addArrangedSubview(`return`)

        keyboardStack.addArrangedSubview(row)
    }

    private func makeRow() -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .fill
        row.distribution = .fillEqually
        row.spacing = 6
        return row
    }

    private func makeLetterButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        styleKeyButton(button, backgroundColor: keyColor, titleColor: keyTextColor, font: .systemFont(ofSize: 22))
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: #selector(letterTapped(_:)), for: .touchUpInside)
        return button
    }

    private func makeCharacterButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        styleKeyButton(button, backgroundColor: keyColor, titleColor: keyTextColor, font: .systemFont(ofSize: 21))
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: #selector(characterTapped(_:)), for: .touchUpInside)
        return button
    }

    private func makeModifierButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        styleKeyButton(button, backgroundColor: modifierKeyColor, titleColor: keyTextColor, font: .systemFont(ofSize: 18, weight: .semibold))
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func makeSpaceButton() -> UIButton {
        let button = UIButton(type: .system)
        styleKeyButton(button, backgroundColor: keyColor, titleColor: keyTextColor, font: .systemFont(ofSize: 18))
        button.setTitle("space", for: .normal)
        button.addTarget(self, action: #selector(spaceTapped), for: .touchUpInside)
        return button
    }

    private func styleKeyButton(_ button: UIButton, backgroundColor: UIColor, titleColor: UIColor, font: UIFont) {
        button.backgroundColor = backgroundColor
        button.setTitleColor(titleColor, for: .normal)
        button.titleLabel?.font = font
        button.layer.cornerRadius = 6
        button.layer.masksToBounds = false
        button.layer.shadowColor = UIColor.black.withAlphaComponent(0.18).cgColor
        button.layer.shadowOpacity = 1
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowRadius = 0
    }

    private func refreshSuggestionUI() {
        suggestionBar.arrangedSubviews.forEach {
            suggestionBar.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let predictions = predictionTitles()

        for index in 0..<3 {
            let button = UIButton(type: .system)
            button.backgroundColor = .clear
            button.setTitle(predictions[index], for: .normal)
            button.setTitleColor(predictionTextColor, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 17)
            button.tag = index
            button.addTarget(self, action: #selector(predictionTapped(_:)), for: .touchUpInside)

            let container = UIView()
            container.backgroundColor = .clear
            container.addSubview(button)
            button.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                button.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                button.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                button.topAnchor.constraint(equalTo: container.topAnchor),
                button.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ])

            if index < 2 {
                let separator = UIView()
                separator.backgroundColor = predictionSeparatorColor
                separator.translatesAutoresizingMaskIntoConstraints = false
                container.addSubview(separator)

                NSLayoutConstraint.activate([
                    separator.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                    separator.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
                    separator.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
                    separator.widthAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale)
                ])
            }

            suggestionBar.addArrangedSubview(container)
        }
    }

    private func predictionTitles() -> [String] {
        guard !currentToken.isEmpty else {
            return ["", "", ""]
        }

        if let suggestion = currentSuggestion {
            return ["\"\(currentToken)\"", suggestion.word, "Keep"]
        } else {
            return ["", currentToken, ""]
        }
    }

    private func updateSuggestion() {
        guard !currentToken.isEmpty else {
            currentSuggestion = nil
            return
        }

        if let match = VocabData.suggestion(for: currentToken),
           match.word.lowercased() != currentToken.lowercased() {
            currentSuggestion = match
        } else {
            currentSuggestion = nil
        }
    }

    @objc private func predictionTapped(_ sender: UIButton) {
        switch sender.tag {
        case 1:
            if currentSuggestion != nil {
                applySuggestion()
            }
        default:
            break
        }
    }

    @objc private func letterTapped(_ sender: UIButton) {
        guard let text = sender.title(for: .normal) else { return }
        insertTextAndUpdateState(text)

        if keyboardMode == .letters, isShiftEnabled {
            isShiftEnabled = false
        }
    }

    @objc private func characterTapped(_ sender: UIButton) {
        guard let text = sender.title(for: .normal) else { return }
        insertTextAndUpdateState(text)
    }

    @objc private func shiftTapped() {
        isShiftEnabled.toggle()
    }

    @objc private func spaceTapped() {
        tryAutoReplaceCurrentToken()
        textDocumentProxy.insertText(" ")
        updateCurrentTokenFromProxy()
    }

    @objc private func backspaceTapped() {
        textDocumentProxy.deleteBackward()
        updateCurrentTokenFromProxy()
    }

    @objc private func returnTapped() {
        tryAutoReplaceCurrentToken()
        textDocumentProxy.insertText("\n")
        updateCurrentTokenFromProxy()
    }

    @objc private func nextKeyboardTapped() {
        advanceToNextInputMode()
    }

    @objc private func numbersTapped() {
        keyboardMode = .numbers
        rebuildKeyboard()
    }

    @objc private func symbolsTapped() {
        keyboardMode = .symbols
        rebuildKeyboard()
    }

    @objc private func lettersTapped() {
        keyboardMode = .letters
        rebuildKeyboard()
    }

    @objc private func applySuggestion() {
        guard let suggestion = currentSuggestion else { return }

        let before = textDocumentProxy.documentContextBeforeInput ?? internalBuffer
        let result = lastReplaceableTokenAndTrailingText(from: before)
        let tokenToReplace = result.token
        let trailingText = result.trailingText

        guard !tokenToReplace.isEmpty else { return }

        let replacement = matchCasing(of: tokenToReplace, to: suggestion.word)

        for _ in 0..<(tokenToReplace.count + trailingText.count) {
            textDocumentProxy.deleteBackward()
        }

        textDocumentProxy.insertText(replacement + trailingText)
        updateCurrentTokenFromProxy()
        currentSuggestion = nil
    }

    private func tryAutoReplaceCurrentToken() {
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        let result = lastReplaceableTokenAndTrailingText(from: before)
        let tokenToReplace = result.token
        let trailingText = result.trailingText

        guard !tokenToReplace.isEmpty,
              let suggestion = VocabData.suggestion(for: tokenToReplace),
              suggestion.word.lowercased() != tokenToReplace.lowercased() else {
            return
        }

        let replacement = matchCasing(of: tokenToReplace, to: suggestion.word)

        for _ in 0..<(tokenToReplace.count + trailingText.count) {
            textDocumentProxy.deleteBackward()
        }

        textDocumentProxy.insertText(replacement + trailingText)
        updateCurrentTokenFromProxy()
        currentSuggestion = nil
    }

    private func insertTextAndUpdateState(_ text: String) {
        textDocumentProxy.insertText(text)
        updateCurrentTokenFromProxy()
    }

    private func updateCurrentTokenFromProxy() {
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        internalBuffer = before
        currentToken = extractLastToken(from: before)
    }

    private func splitTrailingSeparators(from text: String) -> (coreText: String, trailingText: String) {
        var core = text
        var trailing = ""

        while let last = core.last, last.isWhitespace || last.isKeyboardPunctuation {
            trailing.insert(last, at: trailing.startIndex)
            core.removeLast()
        }

        return (core, trailing)
    }

    private func lastReplaceableTokenAndTrailingText(from text: String) -> (token: String, trailingText: String) {
        let parts = splitTrailingSeparators(from: text)
        let token = extractLastToken(from: parts.coreText)
        return (token, parts.trailingText)
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

    private func displayLetter(for letter: String) -> String {
        isShiftEnabled ? letter.uppercased() : letter.lowercased()
    }

    private var keyboardBackgroundColor: UIColor {
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.72, green: 0.74, blue: 0.79, alpha: 1.0)
            : UIColor(red: 0.82, green: 0.84, blue: 0.88, alpha: 1.0)
    }

    private var predictionBarBackgroundColor: UIColor {
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.18, green: 0.19, blue: 0.22, alpha: 1.0)
            : UIColor(red: 0.95, green: 0.96, blue: 0.98, alpha: 1.0)
    }

    private var predictionTextColor: UIColor {
        traitCollection.userInterfaceStyle == .dark ? .white : .black
    }

    private var predictionSeparatorColor: UIColor {
        traitCollection.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.15)
            : UIColor.black.withAlphaComponent(0.10)
    }

    private var keyColor: UIColor {
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.23, green: 0.24, blue: 0.27, alpha: 1.0)
            : .white
    }

    private var modifierKeyColor: UIColor {
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.36, green: 0.37, blue: 0.41, alpha: 1.0)
            : UIColor(red: 0.68, green: 0.70, blue: 0.75, alpha: 1.0)
    }

    private var keyTextColor: UIColor {
        traitCollection.userInterfaceStyle == .dark ? .white : .black
    }
}

private extension Character {
    var isKeyboardPunctuation: Bool {
        unicodeScalars.allSatisfy { CharacterSet.punctuationCharacters.contains($0) }
    }
}
