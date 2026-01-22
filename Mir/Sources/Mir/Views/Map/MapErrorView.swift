// MapErrorView.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

#if canImport(UIKit)
import UIKit

final class MapErrorView: UIView {
    
    // MARK: - Properties
    
    private let title = UILabel()
    private let message = UILabel()
    
    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpAppearance()
        setUpSubviews()
        addSubviews()
        setUpConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUpAppearance()
        setUpSubviews()
        addSubviews()
        setUpConstraints()
    }
    
    // MARK: - Configuration
    
    func configure(message: String) {
        self.message.text = message
    }
    
    // MARK: - Appearance
    
    private func setUpAppearance() {
        let cornerRadius: UICornerRadius = .containerConcentric(minimum: 12.0)
        cornerConfiguration = .corners(radius: cornerRadius)
        backgroundColor = .systemRed.withAlphaComponent(0.1)
        setUpBorder()
    }
    
    private func setUpBorder() {
        let borderWidth: CGFloat = 2.0
        layer.borderWidth = borderWidth
        updateBorderColor()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.updateBorderColor()
        }
    }
    
    // MARK: - Responding to Appearance Changes
    
    private func updateBorderColor() {
        layer.borderColor = UIColor.systemRed.cgColor
    }
    
    // MARK: - Subviews
    
    private func setUpSubviews() {
        setUpTitle()
        setUpMessage()
    }
    
    private func setUpTitle() {
        title.text = "Error"
        title.textColor = .systemRed
        title.font = .preferredFont(forTextStyle: .headline)
    }
    
    private func setUpMessage() {
        message.numberOfLines = 0
    }
    
    // MARK: - Layout
    
    private func addSubviews() {
        addSubview(title)
        addSubview(message)
    }
    
    private func setUpConstraints() {
        title.translatesAutoresizingMaskIntoConstraints = false
        message.translatesAutoresizingMaskIntoConstraints = false
        message.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        let contentInset: CGFloat = 16.0
        let spacing: CGFloat = 8.0
        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: topAnchor, constant: contentInset),
            title.leadingAnchor.constraint(equalTo: leadingAnchor, constant: contentInset),
            title.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -contentInset),
            message.topAnchor.constraint(equalTo: title.bottomAnchor, constant: spacing),
            message.leadingAnchor.constraint(equalTo: leadingAnchor, constant: contentInset),
            message.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -contentInset),
            message.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -contentInset)
        ])
    }
}
#elseif canImport(AppKit)
import AppKit

final class MapErrorView: NSView {
    
    // MARK: - Properties
    
    private let title = NSTextField(labelWithString: "Error")
    private let message = NSTextField(labelWithString: "")
    
    // MARK: - Initializers
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setUpAppearance()
        setUpSubviews()
        addSubviews()
        setUpConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUpAppearance()
        setUpSubviews()
        addSubviews()
        setUpConstraints()
    }
    
    // MARK: - Configuration
    
    func configure(message: String) {
        self.message.stringValue = message
    }
    
    // MARK: - Appearance
    
    private func setUpAppearance() {
        let cornerRadius: CGFloat = 12.0
        wantsLayer = true
        layer?.cornerRadius = cornerRadius
        setUpBorder()
        updateBackgroundColor()
    }
    
    private func setUpBorder() {
        let borderWidth: CGFloat = 2.0
        layer?.borderWidth = borderWidth
        updateBorderColor()
    }
    
    // MARK: - Responding to Appearance Changes
    
    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateBorderColor()
        updateBackgroundColor()
    }
    
    private func updateBorderColor() {
        layer?.borderColor = NSColor.systemRed.cgColor
    }
    
    private func updateBackgroundColor() {
        layer?.backgroundColor = NSColor.systemRed.withAlphaComponent(0.1).cgColor
    }
    
    // MARK: - Subviews
    
    private func setUpSubviews() {
        setUpTitle()
        setUpMessage()
    }
    
    private func setUpTitle() {
        title.textColor = .systemRed
        title.font = .preferredFont(forTextStyle: .headline)
    }
    
    private func setUpMessage() {
        message.lineBreakMode = .byWordWrapping
    }
    
    // MARK: - Layout
    
    private func addSubviews() {
        addSubview(title)
        addSubview(message)
    }
    
    private func setUpConstraints() {
        title.translatesAutoresizingMaskIntoConstraints = false
        message.translatesAutoresizingMaskIntoConstraints = false
        message.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let contentInset: CGFloat = 16.0
        let spacing: CGFloat = 8.0
        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: topAnchor, constant: contentInset),
            title.leadingAnchor.constraint(equalTo: leadingAnchor, constant: contentInset),
            title.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -contentInset),
            message.topAnchor.constraint(equalTo: title.bottomAnchor, constant: spacing),
            message.leadingAnchor.constraint(equalTo: leadingAnchor, constant: contentInset),
            message.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -contentInset),
            message.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -contentInset)
        ])
    }
}
#endif
