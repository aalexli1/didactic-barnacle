//
//  AccessibilityHelpers.swift
//  didactic-barnicle-ios
//
//  Created by Auto Agent on 8/14/25.
//

import SwiftUI

struct AccessibleButton: ViewModifier {
    let label: String
    let hint: String?
    
    func body(content: Content) -> some View {
        content
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "Double tap to activate")
            .accessibilityAddTraits(.isButton)
    }
}

struct AccessibleImage: ViewModifier {
    let label: String
    let isDecorative: Bool
    
    func body(content: Content) -> some View {
        if isDecorative {
            content.accessibilityHidden(true)
        } else {
            content.accessibilityLabel(label)
        }
    }
}

extension View {
    func accessibleButton(label: String, hint: String? = nil) -> some View {
        modifier(AccessibleButton(label: label, hint: hint))
    }
    
    func accessibleImage(label: String, isDecorative: Bool = false) -> some View {
        modifier(AccessibleImage(label: label, isDecorative: isDecorative))
    }
    
    func reduceMotionAnimation<V>(_ animation: Animation?, value: V) -> some View where V: Equatable {
        self.animation(
            UIAccessibility.isReduceMotionEnabled ? .none : animation,
            value: value
        )
    }
    
    func dynamicTypeSize(_ range: ClosedRange<DynamicTypeSize>) -> some View {
        self.dynamicTypeSize(range)
    }
}

struct HapticFeedback {
    static var isEnabled: Bool {
        !UIAccessibility.isReduceMotionEnabled
    }
    
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isEnabled else { return }
        Theme.Haptics.impact(style)
    }
    
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        Theme.Haptics.notification(type)
    }
    
    static func selection() {
        guard isEnabled else { return }
        Theme.Haptics.selection()
    }
}

struct AccessibilityAnnouncement {
    static func announce(_ message: String, priority: UIAccessibility.NotificationPriority = .high) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UIAccessibility.post(
                notification: .announcement,
                argument: NSAttributedString(
                    string: message,
                    attributes: [.accessibilitySpeechQueueAnnouncement: priority == .high]
                )
            )
        }
    }
    
    static func screenChanged() {
        UIAccessibility.post(notification: .screenChanged, argument: nil)
    }
    
    static func layoutChanged() {
        UIAccessibility.post(notification: .layoutChanged, argument: nil)
    }
}