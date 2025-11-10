//
//  UserRulesController.swift
//  ShadowsocksX-NG
//
//  Created by 周斌佳 on 16/8/1.
//  Copyright © 2016年 qiuyuzhou. All rights reserved.
//

import Cocoa

class UserRulesController: NSWindowController {

    @IBOutlet var userRulesView: NSTextView!

    // Quick Add UI elements
    private var quickAddTextField: NSTextField!
    private var addButton: NSButton!
    private var addFromClipboardButton: NSButton!
    private var examplesLabel: NSTextField!
    private var quickAddContainer: NSView!

    override func windowDidLoad() {
        super.windowDidLoad()

        // Enable automatic saving of window frame (position and size)
        window?.setFrameAutosaveName("UserRulesWindow")

        let fileMgr = FileManager.default
        if !fileMgr.fileExists(atPath: PACUserRuleFilePath) {
            guard let src = Bundle.main.path(forResource: "user-rule", ofType: "txt") else {
                ErrorHandler.shared.handle(
                    ResourceError.resourceNotFound(name: "user-rule", type: "txt"),
                    context: "Initialize User Rules",
                    showAlert: true,
                    critical: true
                )
                return
            }
            do {
                try fileMgr.copyItem(atPath: src, toPath: PACUserRuleFilePath)
            } catch {
                ErrorHandler.shared.handle(
                    FileSystemError.writeFailed(path: PACUserRuleFilePath, error: error),
                    context: "Initialize User Rules",
                    showAlert: true
                )
                return
            }
        }

        let str =
            (try? String(contentsOfFile: PACUserRuleFilePath, encoding: String.Encoding.utf8)) ?? ""
        userRulesView.string = str

        setupQuickAddUI()
    }

    private func setupQuickAddUI() {
        guard let contentView = window?.contentView else { return }

        // Find the scroll view that contains the text view
        guard let scrollView = userRulesView.enclosingScrollView else { return }

        // Deactivate existing top constraint for scroll view to avoid conflicts
        for constraint in contentView.constraints {
            if (constraint.firstItem as? NSScrollView) == scrollView
                && constraint.firstAttribute == .top
            {
                constraint.isActive = false
            }
            if (constraint.secondItem as? NSScrollView) == scrollView
                && constraint.secondAttribute == .top
            {
                constraint.isActive = false
            }
        }

        // Create container for quick add controls
        quickAddContainer = NSView()
        quickAddContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(quickAddContainer)

        // Quick add label
        let quickAddLabel = NSTextField(labelWithString: "Quick Add Domain:")
        quickAddLabel.translatesAutoresizingMaskIntoConstraints = false
        quickAddContainer.addSubview(quickAddLabel)

        // Text field for domain input
        quickAddTextField = NSTextField()
        quickAddTextField.translatesAutoresizingMaskIntoConstraints = false
        quickAddTextField.placeholderString = "example.com"
        quickAddContainer.addSubview(quickAddTextField)

        // Add button
        addButton = NSButton(title: "Add", target: self, action: #selector(addDomain(_:)))
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.bezelStyle = .rounded
        quickAddContainer.addSubview(addButton)

        // Add from clipboard button
        addFromClipboardButton = NSButton(
            title: "Add from Clipboard", target: self, action: #selector(addFromClipboard(_:)))
        addFromClipboardButton.translatesAutoresizingMaskIntoConstraints = false
        addFromClipboardButton.bezelStyle = .rounded
        quickAddContainer.addSubview(addFromClipboardButton)

        // Examples label
        examplesLabel = NSTextField(
            labelWithString:
                "Examples: ||domain.com  |http://domain.com  @@||domain.com (whitelist)")
        examplesLabel.translatesAutoresizingMaskIntoConstraints = false
        examplesLabel.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        examplesLabel.textColor = .secondaryLabelColor
        quickAddContainer.addSubview(examplesLabel)

        // Update scroll view constraints
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        // Layout constraints
        NSLayoutConstraint.activate([
            // Container positioning - at the top
            quickAddContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            quickAddContainer.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor, constant: 20),
            quickAddContainer.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor, constant: -20),
            quickAddContainer.heightAnchor.constraint(equalToConstant: 60),

            // Quick add label
            quickAddLabel.leadingAnchor.constraint(equalTo: quickAddContainer.leadingAnchor),
            quickAddLabel.topAnchor.constraint(equalTo: quickAddContainer.topAnchor),

            // Text field
            quickAddTextField.leadingAnchor.constraint(
                equalTo: quickAddLabel.trailingAnchor, constant: 8),
            quickAddTextField.centerYAnchor.constraint(equalTo: quickAddLabel.centerYAnchor),
            quickAddTextField.widthAnchor.constraint(equalToConstant: 200),

            // Add button
            addButton.leadingAnchor.constraint(
                equalTo: quickAddTextField.trailingAnchor, constant: 8),
            addButton.centerYAnchor.constraint(equalTo: quickAddTextField.centerYAnchor),

            // Add from clipboard button
            addFromClipboardButton.leadingAnchor.constraint(
                equalTo: addButton.trailingAnchor, constant: 8),
            addFromClipboardButton.centerYAnchor.constraint(equalTo: addButton.centerYAnchor),

            // Examples label
            examplesLabel.leadingAnchor.constraint(equalTo: quickAddContainer.leadingAnchor),
            examplesLabel.topAnchor.constraint(equalTo: quickAddLabel.bottomAnchor, constant: 8),
            examplesLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: quickAddContainer.trailingAnchor),

            // Adjust scroll view to be below quick add container
            scrollView.topAnchor.constraint(equalTo: quickAddContainer.bottomAnchor, constant: 12),
        ])
    }

    // MARK: - Quick Add Actions

    @objc private func addDomain(_ sender: Any) {
        let input = quickAddTextField.stringValue.trimmingCharacters(in: .whitespaces)
        guard !input.isEmpty else { return }

        // Extract domain if it's a URL
        let domain = extractDomain(from: input)
        guard !domain.isEmpty else {
            showAlert(message: "Invalid domain or URL")
            return
        }

        handleRuleAddition(for: domain, quickAddFieldValue: "")
    }

    @objc private func addFromClipboard(_ sender: Any) {
        guard let pasteboard = NSPasteboard.general.string(forType: .string) else {
            showAlert(message: "No text in clipboard")
            return
        }

        let input = pasteboard.trimmingCharacters(in: .whitespaces)
        guard !input.isEmpty else {
            showAlert(message: "Clipboard is empty")
            return
        }

        // Extract domain from clipboard content (could be URL)
        let domain = extractDomain(from: input)
        guard !domain.isEmpty else {
            showAlert(message: "Could not extract domain from clipboard content")
            return
        }

        handleRuleAddition(for: domain, quickAddFieldValue: domain)
    }

    private func extractDomain(from input: String) -> String {
        var domain = input.trimmingCharacters(in: .whitespaces)

        // If it starts with http:// or https://, parse as URL
        if domain.hasPrefix("http://") || domain.hasPrefix("https://") {
            if let url = URL(string: domain), let host = url.host {
                domain = host
            }
        }
        // If it has :// but not http/https, try to parse anyway
        else if domain.contains("://") {
            if let url = URL(string: domain), let host = url.host {
                domain = host
            }
        }
        // Otherwise, assume it's already a domain
        else {
            // Remove common prefixes like www.
            if domain.hasPrefix("www.") {
                domain = String(domain.dropFirst(4))
            }
        }

        // Basic domain validation
        let domainRegex = try? NSRegularExpression(
            pattern:
                "^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*$"
        )
        let range = NSRange(domain.startIndex..<domain.endIndex, in: domain)
        if domainRegex?.firstMatch(in: domain, range: range) != nil {
            return domain
        }

        return ""
    }

    private func handleRuleAddition(for domain: String, quickAddFieldValue: String) {
        let checker = RuleSimilarityChecker(rulesText: userRulesView.string)
        let rule = "||" + domain

        if let similarity = checker.findSimilarity(for: domain) {
            presentSimilarityAlert(
                for: domain,
                rule: rule,
                quickAddFieldValue: quickAddFieldValue,
                similarity: similarity
            )
        } else {
            finalizeRuleAddition(rule: rule, quickAddFieldValue: quickAddFieldValue)
        }
    }

    private func finalizeRuleAddition(rule: String, quickAddFieldValue: String) {
        quickAddTextField.stringValue = quickAddFieldValue
        addRuleToTextView(rule)
    }

    private func presentSimilarityAlert(
        for domain: String,
        rule: String,
        quickAddFieldValue: String,
        similarity: RuleSimilarity
    ) {
        let alert = NSAlert()
        alert.messageText = "Similar Rule Detected"
        alert.informativeText = similarity.message(for: domain)
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Add Anyway")
        alert.addButton(withTitle: "Cancel")

        guard let window = window else {
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                finalizeRuleAddition(rule: rule, quickAddFieldValue: quickAddFieldValue)
            }
            return
        }

        alert.beginSheetModal(for: window) { [weak self] response in
            guard response == .alertFirstButtonReturn else { return }
            self?.finalizeRuleAddition(rule: rule, quickAddFieldValue: quickAddFieldValue)
        }
    }

    private func addRuleToTextView(_ rule: String) {
        var currentText = userRulesView.string

        // Check if rule already exists
        let lines = currentText.components(separatedBy: .newlines)
        if lines.contains(rule) {
            showAlert(message: "Rule already exists")
            return
        }

        // Add to the end of the text
        if !currentText.isEmpty && !currentText.hasSuffix("\n") {
            currentText += "\n"
        }
        currentText += rule + "\n"

        userRulesView.string = currentText

        // Scroll to bottom
        userRulesView.scrollToEndOfDocument(nil)

        showTemporarySuccess(message: "Added: \(rule)")
    }

    private func showAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = "Quick Add Domain"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        if let window = window {
            alert.beginSheetModal(for: window, completionHandler: nil)
        }
    }

    private func showTemporarySuccess(message: String) {
        // Could implement a temporary status message, for now just update the examples label briefly
        let originalText = "Examples: ||domain.com  |http://domain.com  @@||domain.com (whitelist)"
        examplesLabel.stringValue = "✓ " + message
        examplesLabel.textColor = .systemGreen

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.examplesLabel.stringValue = originalText
            self?.examplesLabel.textColor = .secondaryLabelColor
        }
    }

    @IBAction func didCancel(_ sender: AnyObject) {
        window?.performClose(self)
    }

    @IBAction func didOK(_ sender: AnyObject) {
        if let str = userRulesView?.string {
            do {
                guard let data = str.data(using: String.Encoding.utf8) else {
                    throw NSError(
                        domain: "com.shadowsocksx-ng.userRules",
                        code: -1,
                        userInfo: [
                            NSLocalizedDescriptionKey: "Failed to convert user rules to UTF-8 data"
                        ]
                    )
                }
                try data.write(to: URL(fileURLWithPath: PACUserRuleFilePath), options: .atomic)

                if generatePACFile() {
                    // Send a user notification
                    NotificationService.shared.send(title: "PAC has been updated by User Rules.".localized)
                } else {
                    NotificationService.shared.send(title: "It's failed to update PAC by User Rules.".localized)
                }
            } catch {
                ErrorHandler.shared.handle(
                    FileSystemError.writeFailed(path: PACUserRuleFilePath, error: error),
                    context: "Save User Rules",
                    showAlert: true,
                    critical: true
                )
                // Don't close window on write failure so user can retry
                return
            }
        }
        window?.performClose(self)
    }

}

struct RuleSimilarity {
    enum Relation {
        case exactMatch
        case existingRuleCoversDomain
        case existingRuleMoreSpecific
        case conflictsWithException
    }

    let relation: Relation
    let existingRule: String

    func message(for domain: String) -> String {
        switch relation {
        case .exactMatch:
            return "Rule \"\(existingRule)\" already exists."
        case .existingRuleCoversDomain:
            return "Existing rule \"\(existingRule)\" already covers domain \"\(domain)\"."
        case .existingRuleMoreSpecific:
            return "Existing rule \"\(existingRule)\" is more specific than the domain you are adding."
        case .conflictsWithException:
            return "Whitelist rule \"\(existingRule)\" conflicts with blocking domain \"\(domain)\"."
        }
    }
}

struct RuleSimilarityChecker {
    private let entries: [RuleEntry]

    init(rulesText: String) {
        self.entries = RuleSimilarityChecker.parseEntries(from: rulesText)
    }

    func findSimilarity(for domain: String) -> RuleSimilarity? {
        let normalizedDomain = RuleSimilarityChecker.normalizeCandidate(domain)
        guard !normalizedDomain.isEmpty else { return nil }

        if let exception = entries.first(where: {
            $0.isException && RuleSimilarityChecker.entry($0, matches: normalizedDomain)
        }) {
            return RuleSimilarity(relation: .conflictsWithException, existingRule: exception.originalRule)
        }

        if let exactRule = entries.first(where: {
            !$0.isException && !$0.hasWildcard && $0.normalizedDomain == normalizedDomain
        }) {
            return RuleSimilarity(relation: .exactMatch, existingRule: exactRule.originalRule)
        }

        if let coveringRule = entries.first(where: {
            !$0.isException && RuleSimilarityChecker.entry($0, covers: normalizedDomain)
        }) {
            return RuleSimilarity(
                relation: .existingRuleCoversDomain,
                existingRule: coveringRule.originalRule
            )
        }

        if let specificRule = entries.first(where: {
            !$0.isException && RuleSimilarityChecker.domain(normalizedDomain, coversEntry: $0)
        }) {
            return RuleSimilarity(
                relation: .existingRuleMoreSpecific,
                existingRule: specificRule.originalRule
            )
        }

        return nil
    }

    private static func parseEntries(from text: String) -> [RuleEntry] {
        return text
            .components(separatedBy: .newlines)
            .compactMap { normalizeStoredRule($0) }
    }

    private static func normalizeStoredRule(_ raw: String) -> RuleEntry? {
        var line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !line.isEmpty else { return nil }
        guard !line.hasPrefix("!") else { return nil }

        var isException = false
        if line.hasPrefix("@@") {
            isException = true
            line = String(line.dropFirst(2))
        }

        line = line.trimmingCharacters(in: .whitespaces)

        if line.hasPrefix("||") {
            line = String(line.dropFirst(2))
        } else if line.hasPrefix("|") {
            line = String(line.dropFirst(1))
        }

        let containsWildcard = line.contains("*")

        while line.hasPrefix("*.") {
            line = String(line.dropFirst(2))
        }
        if line.hasPrefix(".") {
            line = String(line.dropFirst())
        }

        if line.contains("://"), let url = URL(string: line), let host = url.host {
            line = host
        }

        line = stripAfterDelimiters(in: line)
        line = line.lowercased()

        if line.hasPrefix("www.") {
            line = String(line.dropFirst(4))
        }

        line = line.trimmingCharacters(in: CharacterSet(charactersIn: "."))
        let normalized = takeDomainPrefix(from: line)

        guard !normalized.isEmpty else { return nil }

        return RuleEntry(
            originalRule: raw,
            normalizedDomain: normalized,
            hasWildcard: containsWildcard,
            isException: isException
        )
    }

    private static func normalizeCandidate(_ domain: String) -> String {
        var candidate = domain.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if candidate.hasPrefix("www.") {
            candidate = String(candidate.dropFirst(4))
        }
        candidate = candidate.trimmingCharacters(in: CharacterSet(charactersIn: "."))
        return takeDomainPrefix(from: candidate)
    }

    private static func stripAfterDelimiters(in text: String) -> String {
        var result = text
        let delimiters: [Character] = ["^", "/", "?", "#", ":"]
        for delimiter in delimiters {
            if let index = result.firstIndex(of: delimiter) {
                result = String(result[..<index])
            }
        }
        return result
    }

    private static func takeDomainPrefix(from text: String) -> String {
        var characters: [Character] = []
        for character in text {
            if character.isLetter || character.isNumber || character == "-" || character == "." {
                characters.append(character)
            } else {
                break
            }
        }
        return String(characters)
    }

    private static func entry(_ entry: RuleEntry, matches domain: String) -> Bool {
        return domain == entry.normalizedDomain
            || domain.hasSuffix("." + entry.normalizedDomain)
    }

    private static func entry(_ entry: RuleEntry, covers domain: String) -> Bool {
        guard entry.normalizedDomain != domain else { return false }
        return domain.hasSuffix("." + entry.normalizedDomain)
    }

    private static func domain(_ domain: String, coversEntry entry: RuleEntry) -> Bool {
        guard entry.normalizedDomain != domain else { return false }
        guard !entry.hasWildcard else { return false }
        return entry.normalizedDomain.hasSuffix("." + domain)
    }

    private struct RuleEntry {
        let originalRule: String
        let normalizedDomain: String
        let hasWildcard: Bool
        let isException: Bool
    }
}
