//
//  PresentationView.swift
//  MasterMind
//
//  Created by Anna Sidorova on 23.07.2021.
//

import Foundation
import SwiftUI
import UIKit

public extension View {
    @ViewBuilder
    func modal<Content: View>(isPresenting: Binding<Bool>, config: PresentationConfig = .init(), @ViewBuilder content: @escaping () -> Content) -> some View {
        modifier(PresentationViewModifier(isPresented: isPresenting, config: config, content: content))
    }

    @ViewBuilder
    func modal<Content: View, Item>(item: Binding<Item?>, config: PresentationConfig = .init(), @ViewBuilder content: @escaping (Item) -> Content) -> some View {
        modifier(PresentationViewModifier(isPresented: item.asBool(), config: config) {
            if let value = item.wrappedValue {
                content(value)
            } else {
                EmptyView()
            }
        })
    }
}

public struct PresentationConfig {
    public init(style: PresentationConfig.Style = .overlay, transition: PresentationConfig.Transition = .slide, animated: Bool = true) {
        self.style = style
        self.transition = transition
        self.animated = animated
    }

    public var style: Style = .overlay
    public var transition: Transition = .slide
    public var animated = true

    public enum Style {
        case fullscreen
        case overlay
    }

    public enum Transition {
        case fade
        case slide
    }
}

private struct PresentationViewModifier<PresentedContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let config: PresentationConfig
    @ViewBuilder let content: () -> PresentedContent

    func body(content: Content) -> some View {
        ZStack {
            content

            PresentationView(isPresenting: $isPresented, config: config, content: self.content)
        }
    }
}

private struct PresentationView<Content: View>: View {
    @Binding var isPresenting: Bool
    let config: PresentationConfig
    @ViewBuilder let content: () -> Content

    var body: some View {
        _PresentationView(isPresenting: $isPresenting, config: config, content: self.content)
        .frame(width: 0, height: 0)
    }
}

private struct _PresentationView<Content: View>: UIViewRepresentable {
    typealias UIViewType = SuiView<Content>

    @Binding var isPresented: Bool
    let config: PresentationConfig
    let content: () -> Content

    private var view: UIViewType?

    init(isPresenting: Binding<Bool>, config: PresentationConfig = .init(), @ViewBuilder content: @escaping () -> Content) {
        self._isPresented = isPresenting
        self.content = content
        self.config = config
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        uiView.content = content
        uiView.isPresenting = $isPresented
        uiView.config = config

        if isPresented {
            uiView.present()
        } else {
            uiView.dismiss()
        }
    }

    func makeUIView(context: Context) -> UIViewType {
        SuiView(frame: .zero)
    }

    static func dismantleUIView(_ uiView: UIViewType, coordinator: ()) {
        uiView.dismiss(force: true)
    }
}

private class SuiView<Content: View>: UIView {
    var isPresenting: Binding<Bool>!
    var content: (() -> Content)! {
        didSet {
            controller?.content = content
        }
    }
    var config: PresentationConfig!

    private weak var controller: SuiController<Content>?

    func dismiss(force: Bool = false) {
        guard (!isPresenting.wrappedValue || force) && controller != nil else { return }

        controller?.dismiss(animated: config.animated, completion: nil)
        controller = nil
    }

    func present() {
        guard isPresenting.wrappedValue,
              controller == nil,
              let controller = parentViewController,
              controller.presentedViewController == nil,
        let content = content else { return }

        let container = SuiController(rootView: content())
        container.delegate = self
        switch config.style {
            case .overlay:
                container.modalPresentationStyle = .overFullScreen
            case .fullscreen:
                container.modalPresentationStyle = .fullScreen
        }
        switch config.transition {
            case .fade:
                container.modalTransitionStyle = .crossDissolve
            case .slide:
                container.modalTransitionStyle = .coverVertical
        }
        self.controller = container
        controller.present(container, animated: config.animated, completion: nil)
    }

    func controllerDestroyed() {
        isPresenting.wrappedValue = false
    }
}

private class SuiController<Content: View>: UIHostingController<Content> {
    weak var delegate: SuiView<Content>?

    private var isDestroying = false

    var content: (() -> Content)! {
        didSet {
            redraw()
        }
    }

    func redraw() {
        guard !isDestroying else { return }
        rootView = content()
    }

    override func viewWillAppear(_ animated: Bool) {
        if modalPresentationStyle == .overFullScreen {
            view.backgroundColor = UIColor.clear
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        isDestroying = isBeingDismissed
    }

    deinit {
        delegate?.controllerDestroyed()
    }
}

private extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder?.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}
