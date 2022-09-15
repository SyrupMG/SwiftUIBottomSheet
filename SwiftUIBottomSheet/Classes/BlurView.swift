//
//  BlurView.swift
//  SwiftUIBottomSheet
//
//  Created by Anna Sidorova on 14.09.22.
//

import SwiftUI

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style = .light
    private(set) var blur: CGFloat?
    private(set) var tintColor: Color?
    private(set) var tintAlpha: CGFloat?
    private(set) var saturation: CGFloat?

    public func makeUIView(context: UIViewRepresentableContext<BlurView>) -> VisualEffectView {
        .init(effect: UIBlurEffect(style: style))
    }

    public func updateUIView(_ uiView: VisualEffectView,
                             context: UIViewRepresentableContext<BlurView>) {
        if let tintColor = tintColor {
            uiView.tintColor = tintColor.uiColor()
        }
        if let tintAlpha = tintAlpha {
            uiView.colorTintAlpha = tintAlpha
        }
        if let blur = blur {
            uiView.blurRadius = blur
        }
        if let saturation = saturation {
            uiView.saturation = saturation
        }
    }
}

extension Color {
    func uiColor() -> UIColor {
        if #available(iOS 14.0, *) {
            return UIColor(self)
        }

        let scanner = Scanner(string: description.trimmingCharacters(in: CharacterSet.alphanumerics.inverted))
        var hexNumber: UInt64 = 0
        var r: CGFloat = 0.0, g: CGFloat = 0.0, b: CGFloat = 0.0, a: CGFloat = 0.0

        let result = scanner.scanHexInt64(&hexNumber)
        if result {
            r = CGFloat((hexNumber & 0xFF000000) >> 24) / 255
            g = CGFloat((hexNumber & 0x00FF0000) >> 16) / 255
            b = CGFloat((hexNumber & 0x0000FF00) >> 8) / 255
            a = CGFloat(hexNumber & 0x000000FF) / 255
        }
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}

/// VisualEffectView is a dynamic background blur view.
open class VisualEffectView: UIVisualEffectView {

    /// Returns the instance of UIBlurEffect.
    private let blurEffect = (NSClassFromString("_UICustomBlurEffect") as! UIBlurEffect.Type).init()

    /**
     Tint color.

     The default value is nil.
     */
    open var colorTint: UIColor? {
        get {
            if #available(iOS 14, *) {
                return ios14_colorTint
            } else {
                return _value(forKey: .colorTint)
            }
        }
        set {
            if #available(iOS 14, *) {
                ios14_colorTint = newValue
            } else {
                _setValue(newValue, forKey: .colorTint)
            }
        }
    }

    /**
     Tint color alpha.
     Don't use it unless `colorTint` is not nil.
     The default value is 0.0.
     */
    open var colorTintAlpha: CGFloat {
        get { return _value(forKey: .colorTintAlpha) ?? 0.0 }
        set {
            if #available(iOS 14, *) {
                ios14_colorTint = ios14_colorTint?.withAlphaComponent(newValue)
            } else {
                _setValue(newValue, forKey: .colorTintAlpha)
            }
        }
    }

    /**
     Blur radius.

     The default value is 0.0.
     */
    open var blurRadius: CGFloat {
        get {
            if #available(iOS 14, *) {
                return ios14_blurRadius
            } else {
                return _value(forKey: .blurRadius) ?? 0.0
            }
        }
        set {
            if #available(iOS 14, *) {
                ios14_blurRadius = newValue
            } else {
                _setValue(newValue, forKey: .blurRadius)
            }
        }
    }

    /**
     Saturation.

     The default value is 0.0.
     */
    open var saturation: CGFloat {
        get {
            if #available(iOS 14, *) {
                return ios14_saturation
            } else {
                return _value(forKey: .saturation) ?? 0.0
            }
        }
        set {
            if #available(iOS 14, *) {
                ios14_saturation = newValue
            } else {
                _setValue(newValue, forKey: .saturation)
            }
        }
    }

    /**
     Scale factor.

     The scale factor determines how content in the view is mapped from the logical coordinate space
     (measured in points) to the device coordinate space (measured in pixels).

     The default value is 1.0.
     */
    open var scale: CGFloat {
        get { return _value(forKey: .scale) ?? 1.0 }
        set { _setValue(newValue, forKey: .scale) }
    }

    // MARK: - Initialization

    public override init(effect: UIVisualEffect?) {
        super.init(effect: effect)

        scale = 1
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        scale = 1
    }

}

// MARK: - Helpers
private extension VisualEffectView {

    /// Returns the value for the key on the blurEffect.
    func _value<T>(forKey key: Key) -> T? {
        return blurEffect.value(forKeyPath: key.rawValue) as? T
    }

    /// Sets the value for the key on the blurEffect.
    func _setValue<T>(_ value: T?, forKey key: Key) {
        blurEffect.setValue(value, forKeyPath: key.rawValue)
        if #available(iOS 14, *) {} else {
            self.effect = blurEffect
        }
    }

    enum Key: String {
        case colorTint, colorTintAlpha, blurRadius, scale, saturation
    }

}

@available(iOS 14, *)
extension UIVisualEffectView {
    var ios14_blurRadius: CGFloat {
        get {
            return gaussianBlur?.requestedValues?["inputRadius"] as? CGFloat ?? 0
        }
        set {
            prepareForChanges()
            gaussianBlur?.requestedValues?["inputRadius"] = newValue
            applyChanges()
        }
    }

    var ios14_saturation: CGFloat {
        get {
            return saturationEffect?.requestedValues?["inputAmount"] as? CGFloat ?? 0
        }
        set {
            prepareForChanges()
            saturationEffect?.requestedValues?["inputAmount"] = newValue
            applyChanges()
        }
    }

    var ios14_colorTint: UIColor? {
        get {
            return sourceOver?.value(forKeyPath: "color") as? UIColor
        }
        set {
            prepareForChanges()
            sourceOver?.setValue(newValue, forKeyPath: "color")
            sourceOver?.perform(Selector(("applyRequestedEffectToView:")), with: overlayView)
            applyChanges()
        }
    }
}

private extension UIVisualEffectView {
    var backdropView: UIView? {
        return subview(of: NSClassFromString("_UIVisualEffectBackdropView"))
    }
    var overlayView: UIView? {
        return subview(of: NSClassFromString("_UIVisualEffectSubview"))
    }
    var gaussianBlur: NSObject? {
        return backdropView?.value(forKey: "filters", withFilterType: "gaussianBlur")
    }
    var saturationEffect: NSObject? {
        return backdropView?.value(forKey: "filters", withFilterType: "colorSaturate")
    }
    var sourceOver: NSObject? {
        return overlayView?.value(forKey: "viewEffects", withFilterType: "sourceOver")
    }
    func prepareForChanges() {
        self.effect = UIBlurEffect(style: .light)
        gaussianBlur?.setValue(1.0, forKeyPath: "requestedScaleHint")
    }
    func applyChanges() {
        backdropView?.perform(Selector(("applyRequestedFilterEffects")))
    }
}

private extension NSObject {
    var requestedValues: [String: Any]? {
        get { return value(forKeyPath: "requestedValues") as? [String: Any] }
        set { setValue(newValue, forKeyPath: "requestedValues") }
    }
    func value(forKey key: String, withFilterType filterType: String) -> NSObject? {
        return (value(forKeyPath: key) as? [NSObject])?.first { $0.value(forKeyPath: "filterType") as? String == filterType }
    }
}

private extension UIView {
    func subview(of classType: AnyClass?) -> UIView? {
        return subviews.first { type(of: $0) == classType }
    }
}
