//
//  PresentationView.swift
//  MasterMind
//
//  Created by Anna Sidorova on 23.07.2021.
//

import Foundation
import SwiftUI
import UIKit

extension View {
    func presentation<Content: View>(isPresenting: Binding<Bool>, content: @escaping () -> Content) -> some View {

        overlay(
            PresentationView(isPresenting: isPresenting, content: content)
                .frame(width: 0, height: 0)
        )
    }
}

private struct PresentationView<Content: View>: UIViewRepresentable {
    let isPresenting: Binding<Bool>
    let content: () -> Content

    func makeUIView(context: Context) -> SUIVeiw<Content> {
        .init()
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        if isPresenting.wrappedValue {
            if uiView.controller == nil {
                let controller = PresentingController(rootView: content())
                uiView.controller = controller

                uiView.parentViewController?.present(controller, animated: true)
            } else {
                uiView.controller?.setContent(content())
            }

            uiView.controller?.setBinding(isPresenting)

        } else {
            uiView.controller?.dismiss(animated: true)
        }
    }

    final class SUIVeiw<Content: View>: UIView {

        fileprivate weak var controller: PresentingController<Content>?

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
}

struct ScreenTransition {
    enum Phase {
        case appear
        case live
        case disappear
    }

    var animation: Animation = .default
    var phase: Phase = .appear
}

final private class TransitionWrapperViewVM: ObservableObject {
    @Published
    var phase: ScreenTransition = .init()
}

struct ScreenTransitionPhaseKey: EnvironmentKey {
    static let defaultValue: ScreenTransition = .init()
}

extension EnvironmentValues {
    var screenTransition: ScreenTransition {
        get { self[ScreenTransitionPhaseKey.self] }
        set { self[ScreenTransitionPhaseKey.self] = newValue }
    }
}

private struct TransitionWrapperView<Wrapped: View>: View {
    let wrapped: Wrapped
    let animation: Animation

    @ObservedObject
    var vm: TransitionWrapperViewVM

    var body: some View {
        wrapped
            .environment(\.screenTransition, vm.phase)
            .onAppear {
                vm.phase = .init(animation: animation, phase: .live)
            }
    }
}

final private class PresentingController<C: View>: UIHostingController<AnyView>,
                                                   UIViewControllerTransitioningDelegate,
                                                   UIViewControllerAnimatedTransitioning {

    private let vm = TransitionWrapperViewVM()
    private var isPresenting = false
    private var binding: Binding<Bool>?

    static private var animation: Animation {
        .easeOut(duration: animationDuration)
    }

    static private var animationDuration: TimeInterval {
        0.3
    }

    fileprivate func setBinding(_ binding: Binding<Bool>) {
        self.binding = binding
    }

    fileprivate func setContent(_ content: C) {
        rootView = Self.content(for: content, vm: vm)
    }

    init(rootView: C) {
        super.init(rootView: Self.content(for: rootView, vm: vm))

        modalPresentationStyle = .custom
        transitioningDelegate = self
        view.backgroundColor = .clear
    }

    static func content<C: View>(for view: C, vm: TransitionWrapperViewVM) -> AnyView {
        AnyView(
            TransitionWrapperView(wrapped: view, animation: animation, vm: vm)
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if self.isBeingDismissed {
            self.binding?.wrappedValue = false
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.isBeingPresented {
            self.binding?.wrappedValue = true
        }
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        isPresenting = true
        return self
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        isPresenting = false
        return self
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        Self.animationDuration
    }

    @MainActor
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        guard let toViewController = transitionContext.viewController(forKey: .to),
              let fromViewController = transitionContext.viewController(forKey: .from) else {
            return
        }

        let duration = transitionDuration(using: transitionContext)

        let dummy = UIView()
        containerView.addSubview(dummy)

        if isPresenting {
            containerView.addSubview(toViewController.view)
            toViewController.view.frame = containerView.bounds

            UIView.animate(withDuration: duration) {
                dummy.frame = containerView.bounds
            } completion: {
                guard $0 else { return }
                transitionContext.completeTransition(true)
                dummy.removeFromSuperview()
            }
        } else {
            vm.phase = .init(animation: Self.animation, phase: .disappear)

            UIView.animate(withDuration: duration) {
                dummy.frame = containerView.bounds
            } completion: {
                guard $0 else { return }
                transitionContext.completeTransition(true)
                fromViewController.view.removeFromSuperview()
                dummy.removeFromSuperview()
            }
        }
    }
}
