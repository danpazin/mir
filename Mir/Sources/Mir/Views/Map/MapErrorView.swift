// MapErrorView.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

#if canImport(UIKit)
import UIKit

/// A rounded red box that shows an error message where the map would be.
final class MapErrorView: UIView {
    
    // MARK: - Properties
    
    /// The red heading above the message.
    private let title = UILabel()
    /// The text that says what went wrong.
    private let message = UILabel()
    
    // MARK: - Initializers
    
    /// Creates an empty error box, to be given its message later.
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpAppearance()
        setUpSubviews()
        addSubviews()
        setUpConstraints()
    }
    
    /// Creates the error box from an archive, such as a storyboard.
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUpAppearance()
        setUpSubviews()
        addSubviews()
        setUpConstraints()
    }
    
    // MARK: - Configuration
    
    /// Shows a message in the box.
    func configure(message: String) {
        self.message.text = message
    }
    
    // MARK: - Appearance
    
    /// Rounds the corners and gives the box its red tint and border.
    private func setUpAppearance() {
        let cornerRadius: UICornerRadius = .containerConcentric(minimum: 12.0)
        cornerConfiguration = .corners(radius: cornerRadius)
        backgroundColor = .systemRed.withAlphaComponent(0.1)
        setUpBorder()
    }
    
    /// Draws the red border, and redraws it when the interface switches between light and dark.
    private func setUpBorder() {
        let borderWidth: CGFloat = 2.0
        layer.borderWidth = borderWidth
        updateBorderColor()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.updateBorderColor()
        }
    }
    
    // MARK: - Responding to Appearance Changes
    
    /// Sets the border to the system red as a Core Graphics color, which doesn't follow appearance changes by itself, so this runs again after each change.
    private func updateBorderColor() {
        layer.borderColor = UIColor.systemRed.cgColor
    }
    
    // MARK: - Subviews
    
    /// Styles the title and the message.
    private func setUpSubviews() {
        setUpTitle()
        setUpMessage()
    }
    
    /// Makes the title read Error, in red, as a headline.
    private func setUpTitle() {
        title.text = "Error"
        title.textColor = .systemRed
        title.font = .preferredFont(forTextStyle: .headline)
    }
    
    /// Lets the message wrap onto as many lines as it needs.
    private func setUpMessage() {
        message.numberOfLines = 0
    }
    
    // MARK: - Layout
    
    /// Adds the title and the message to the box.
    private func addSubviews() {
        addSubview(title)
        addSubview(message)
    }
    
    /// Places the message under the title, inset from the box's edges.
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

/// A rounded red box that shows an error message where the map would be.
final class MapErrorView: NSView {
    
    // MARK: - Properties
    
    /// The red heading above the message.
    private let title = NSTextField(labelWithString: "Error")
    /// The text that says what went wrong.
    private let message = NSTextField(labelWithString: "")
    
    // MARK: - Initializers
    
    /// Creates an empty error box, to be given its message later.
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setUpAppearance()
        setUpSubviews()
        addSubviews()
        setUpConstraints()
    }
    
    /// Creates the error box from an archive, such as a storyboard.
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUpAppearance()
        setUpSubviews()
        addSubviews()
        setUpConstraints()
    }
    
    // MARK: - Configuration
    
    /// Shows a message in the box.
    func configure(message: String) {
        self.message.stringValue = message
    }
    
    // MARK: - Appearance
    
    /// Rounds the corners and gives the box its red tint and border.
    private func setUpAppearance() {
        let cornerRadius: CGFloat = 12.0
        wantsLayer = true
        layer?.cornerRadius = cornerRadius
        setUpBorder()
        updateBackgroundColor()
    }
    
    /// Draws the red border.
    private func setUpBorder() {
        let borderWidth: CGFloat = 2.0
        layer?.borderWidth = borderWidth
        updateBorderColor()
    }
    
    // MARK: - Responding to Appearance Changes
    
    /// Updates the border and background colors when the appearance switches between light and dark.
    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateBorderColor()
        updateBackgroundColor()
    }
    
    /// Sets the border to the system red as a Core Graphics color, which doesn't follow appearance changes by itself, so this runs again after each change.
    private func updateBorderColor() {
        layer?.borderColor = NSColor.systemRed.cgColor
    }
    
    /// Sets the background to a light tint of the system red as a Core Graphics color, which also has to be set again after each appearance change.
    private func updateBackgroundColor() {
        layer?.backgroundColor = NSColor.systemRed.withAlphaComponent(0.1).cgColor
    }
    
    // MARK: - Subviews
    
    /// Styles the title and the message.
    private func setUpSubviews() {
        setUpTitle()
        setUpMessage()
    }
    
    /// Makes the title red, as a headline.
    private func setUpTitle() {
        title.textColor = .systemRed
        title.font = .preferredFont(forTextStyle: .headline)
    }
    
    /// Lets the message wrap between words.
    private func setUpMessage() {
        message.lineBreakMode = .byWordWrapping
    }
    
    // MARK: - Layout
    
    /// Adds the title and the message to the box.
    private func addSubviews() {
        addSubview(title)
        addSubview(message)
    }
    
    /// Places the message under the title, inset from the box's edges.
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
